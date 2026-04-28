import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart';
import '../widgets/enhanced_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  const EmailVerificationPage({super.key, required this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late StreamSubscription<AuthState> _authSubscription;
  late AnimationController _shakeController;
  late AnimationController _successController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _successAnimation;

  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  bool _isVerifying = false;
  bool _hasError = false;
  bool _isSuccess = false;

  static const Color primaryColor  = Color(0xFF003366);
  static const Color errorColor    = Color(0xFFE53935);
  static const Color successColor  = Color(0xFF2E7D32);

  String get _emailDomain => widget.email.split('@').last;
  String get _otp => _otpControllers.map((c) => c.text).join();
  bool get _isOtpComplete => _otp.length == 6;

  @override
  void initState() {
    super.initState();

    // Animation shake (erreur)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Animation succès
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    // Écouter Supabase auth
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.userUpdated) {
        final user = data.session?.user;
        if (user?.emailConfirmedAt != null && mounted) {
          context.read<AuthBloc>().add(CheckAuthStatusEvent());
        }
      }
    });

    // Focus sur le premier champ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _cooldownTimer?.cancel();
    _shakeController.dispose();
    _successController.dispose();
    for (var c in _otpControllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    // Reset erreur à chaque saisie
    if (_hasError) setState(() => _hasError = false);

    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {}); // Refresh indicateurs

    if (_isOtpComplete) {
      Future.delayed(const Duration(milliseconds: 100), _verifyOtp);
    }
  }

  // Gérer la touche backspace
  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].clear();
      setState(() {});
    }
  }

  void _verifyOtp() {
    if (!_isOtpComplete || _isVerifying) return;
    setState(() { _isVerifying = true; _hasError = false; });
    context.read<AuthBloc>().add(
      VerifyOtpEvent(email: widget.email, token: _otp),
    );
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  void _resendEmail() {
    if (_resendCooldown > 0) return;
    context.read<AuthBloc>().add(
      ResendVerificationEmailEvent(email: widget.email),
    );
    _startCooldown();
    // Reset OTP
    for (var c in _otpControllers) c.clear();
    setState(() { _hasError = false; });
    _focusNodes[0].requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Nouveau code envoyé !'),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: BlocListener<AuthBloc, AuthStatus>(
        listener: (context, state) {
          if (state is Authenticated) {
            setState(() { _isSuccess = true; _isVerifying = false; });
            _successController.forward();
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                Navigator.pushReplacementNamed(
                    context, AppConstants.homeRoute);
              }
            });
          } else if (state is AuthError) {
            setState(() { _isVerifying = false; _hasError = true; });
            _triggerShake();
            for (var c in _otpControllers) c.clear();
            _focusNodes[0].requestFocus();
          }
        },
        child: Stack(
          children: [
            // Cercles décoratifs (même style que HomePage)
            Positioned(
              top: -60, right: -60,
              child: Container(width: 200, height: 200,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05))),
            ),
            Positioned(
              top: 40, right: 20,
              child: Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07))),
            ),
            Positioned(
              top: 100, left: -20,
              child: Container(width: 110, height: 110,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: const Color(0xFF592300).withOpacity(0.2))),
            ),

            SafeArea(
              child: Column(
                children: [
                  // AppBar custom
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, AppConstants.signInRoute),
                        ),
                        const Spacer(),
                        Text(
                          AppConstants.appName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48), // équilibrer
                      ],
                    ),
                  ),

                  // Hero section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vérifiez\nvotre email',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Code envoyé à ${widget.email}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                              height: 1.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Feuille blanche
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(36),
                          topRight: Radius.circular(36),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                        child: Column(
                          children: [
                            // Info email domaine
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.amber.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      color: Colors.amber.shade700,
                                      size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Consultez votre boîte @$_emailDomain',
                                      style: TextStyle(
                                        color: Colors.amber.shade700,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Card OTP
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.08),
                                    blurRadius: 28,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Icône état
                                  _buildStatusIcon(),

                                  const SizedBox(height: 20),

                                  Text(
                                    _isSuccess
                                        ? 'Email vérifié !'
                                        : 'Entrez le code à 6 chiffres',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: _isSuccess
                                          ? successColor
                                          : primaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  if (!_isSuccess) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      _hasError
                                          ? 'Code incorrect. Réessayez.'
                                          : 'Le code expire dans 1 heure',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _hasError
                                            ? errorColor
                                            : Colors.grey.shade500,
                                        fontWeight: _hasError
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],

                                  const SizedBox(height: 28),

                                  // Champs OTP avec shake
                                  if (!_isSuccess)
                                    AnimatedBuilder(
                                      animation: _shakeAnimation,
                                      builder: (context, child) {
                                        final offset = _hasError
                                            ? 8.0 *
                                                (0.5 -
                                                    (_shakeAnimation.value *
                                                            6)
                                                        .round()
                                                        .toDouble()
                                                        .abs()
                                                        .clamp(0, 1))
                                            : 0.0;
                                        return Transform.translate(
                                          offset: Offset(offset, 0),
                                          child: child,
                                        );
                                      },
                                      child: _buildOtpFields(),
                                    ),

                                  const SizedBox(height: 28),

                                  // Bouton Vérifier
                                  if (!_isSuccess)
                                    BlocBuilder<AuthBloc, AuthStatus>(
                                      builder: (context, state) {
                                        final isLoading =
                                            state is AuthLoading ||
                                                _isVerifying;
                                        return SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: ElevatedButton(
                                            onPressed: (isLoading ||
                                                    !_isOtpComplete)
                                                ? null
                                                : _verifyOtp,
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor: _isOtpComplete
                                                  ? primaryColor
                                                  : Colors.grey.shade300,
                                              foregroundColor: Colors.white,
                                              elevation:
                                                  _isOtpComplete ? 2 : 0,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16)),
                                            ),
                                            child: isLoading
                                                ? const SizedBox(
                                                    height: 22,
                                                    width: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                              Colors.white),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Text(
                                                        'Vérifier le code',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          letterSpacing: 0.3,
                                                        ),
                                                      ),
                                                      if (_isOtpComplete) ...[
                                                        const SizedBox(
                                                            width: 8),
                                                        const Icon(
                                                            Icons
                                                                .arrow_forward_rounded,
                                                            size: 18),
                                                      ],
                                                    ],
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Renvoyer le code
                            if (!_isSuccess)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.05),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Pas reçu le code ?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _resendCooldown > 0
                                          ? null
                                          : _resendEmail,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        backgroundColor: _resendCooldown > 0
                                            ? Colors.grey.shade100
                                            : primaryColor.withOpacity(0.08),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        _resendCooldown > 0
                                            ? '${_resendCooldown}s'
                                            : 'Renvoyer',
                                        style: TextStyle(
                                          color: _resendCooldown > 0
                                              ? Colors.grey.shade400
                                              : primaryColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Retour connexion
                            if (!_isSuccess)
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushReplacementNamed(
                                        context, AppConstants.signInRoute),
                                child: Text(
                                  'Retour à la connexion',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_isSuccess) {
      return ScaleTransition(
        scale: _successAnimation,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: successColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: successColor,
            size: 44,
          ),
        ),
      );
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: _hasError
            ? errorColor.withOpacity(0.1)
            : primaryColor.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _hasError
            ? Icons.error_outline_rounded
            : Icons.mark_email_unread_outlined,
        color: _hasError ? errorColor : primaryColor,
        size: 36,
      ),
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        final isFilled = _otpControllers[index].text.isNotEmpty;
        final isFocused = _focusNodes[index].hasFocus;

        return KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) => _onKeyEvent(index, event),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 56,
            decoration: BoxDecoration(
              color: _hasError
                  ? errorColor.withOpacity(0.07)
                  : isFilled
                      ? primaryColor.withOpacity(0.07)
                      : const Color(0xFFF0F3F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hasError
                    ? errorColor.withOpacity(0.6)
                    : isFocused
                        ? primaryColor
                        : isFilled
                            ? primaryColor.withOpacity(0.3)
                            : Colors.transparent,
                width: isFocused || _hasError ? 2 : 1,
              ),
              boxShadow: isFocused && !_hasError
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: TextField(
              controller: _otpControllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _hasError ? errorColor : primaryColor,
                letterSpacing: 0,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) => _onOtpChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}