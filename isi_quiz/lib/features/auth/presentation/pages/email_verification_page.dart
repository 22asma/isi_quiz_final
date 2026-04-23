import 'dart:async';
import 'package:flutter/material.dart';
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

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  late StreamSubscription<AuthState> _authSubscription;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  String get _emailDomain => widget.email.split('@').last;

  @override
  void initState() {
    super.initState();
    // Écouter Supabase auth : dès que l'email est vérifié, naviguer
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
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  void _resendEmail() {
    if (_resendCooldown > 0) return;
    context.read<AuthBloc>().add(
      ResendVerificationEmailEvent(email: widget.email),
    );
    _startCooldown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification email resent!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // pas de retour arrière
        title: Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: BlocListener<AuthBloc, AuthStatus>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône email
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  FontAwesomeIcons.envelopeCircleCheck,
                  size: 44,
                  color: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Check your inbox',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 16),

              Text(
                'We sent a verification link to:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                widget.email,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Rappel domaine
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.amber.shade700, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Check your @$_emailDomain mailbox',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Bouton vérifier manuellement
              BlocBuilder<AuthBloc, AuthStatus>(
                builder: (context, state) {
                  return EnhancedButton.primary(
                    text: "I've verified my email",
                    onPressed: state is AuthLoading
                        ? () {}
                        : () => context
                            .read<AuthBloc>()
                            .add(CheckAuthStatusEvent()),
                    isLoading: state is AuthLoading,
                    icon: FontAwesomeIcons.circleCheck,
                  );
                },
              ),

              const SizedBox(height: 16),

              // Renvoyer avec cooldown
              TextButton.icon(
                onPressed: _resendCooldown > 0 ? null : _resendEmail,
                icon: Icon(
                  FontAwesomeIcons.rotateRight,
                  size: 14,
                  color: _resendCooldown > 0
                      ? AppTheme.textSecondary
                      : AppTheme.primaryColor,
                ),
                label: Text(
                  _resendCooldown > 0
                      ? 'Resend in ${_resendCooldown}s'
                      : 'Resend verification email',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _resendCooldown > 0
                            ? AppTheme.textSecondary
                            : AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),

              const SizedBox(height: 24),

              // Retour vers Sign In
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppConstants.signInRoute),
                child: Text(
                  'Back to Sign In',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}