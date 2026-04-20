import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:isi_quiz/features/quiz/presentation/create_quiz_page.dart';
import 'package:isi_quiz/features/quiz/presentation/pages/join_quiz_page.dart';
import 'package:isi_quiz/features/quiz/services/quiz_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final QuizService _quizService = QuizService();
  bool _isJoining = false;
  bool _hasError = false;
  String _errorMessage = '';

  static const Color primaryColor   = Color(0xFF003366);
  static const Color secondaryColor = Color(0xFF4A5F70);
  static const Color tertiaryColor  = Color(0xFF592300);
  static const Color neutralColor   = Color(0xFFF5F5F5);

  @override
  void dispose() {
    for (final c in _pinControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onPinChanged(String value, int index) {
    // Clear error state when user starts typing
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    }
    
    if (value.length == 1 && index < _pinControllers.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto-submit when PIN is complete
    if (_isPinComplete()) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_isPinComplete() && !_isJoining) {
          _joinQuiz();
        }
      });
    }
  }

  String _pinCodeValue() {
    return _pinControllers.map((controller) => controller.text.trim()).join();
  }

  bool _isPinComplete() {
    final pin = _pinCodeValue();
    return pin.length == _pinControllers.length && RegExp(r'^[0-9]{6}$').hasMatch(pin);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _joinQuiz() async {
    final pin = _pinCodeValue();
    if (!_isPinComplete()) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Veuillez entrer un code PIN à 6 chiffres.';
      });
      _shakePinFields();
      return;
    }

    setState(() => _isJoining = true);
    try {
      final quizData = await _quizService.getQuizByPinCode(pin);
      if (quizData == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Quiz introuvable ou non disponible.';
        });
        _shakePinFields();
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JoinQuizPage(quiz: quizData),
        ),
      );
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur lors de la recherche du quiz : $e';
      });
      _shakePinFields();
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }
  
  void _shakePinFields() {
    for (final controller in _pinControllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }
  
  void _clearPin() {
    for (final controller in _pinControllers) {
      controller.clear();
    }
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    _focusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          // Decorative circles on dark background
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tertiaryColor.withOpacity(0.2),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Hero text on dark bg ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prêt pour\nl\'examen ?',
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
                        'Entrez le code PIN fourni par votre instructeur.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Light sheet ─────────────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: neutralColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        children: [

                          // ── PIN Card ────────────────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section label with accent bar
                                Row(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: tertiaryColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'CODE PIN DU QUIZ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.8,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // PIN boxes with enhanced UI
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(6, (index) {
                                        final hasText = _pinControllers[index].text.isNotEmpty;
                                        final isFocused = _focusNodes[index].hasFocus;
                                        final isError = _hasError;
                                        
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeInOut,
                                          child: SizedBox(
                                            width: 54,
                                            height: 62,
                                            child: TextField(
                                              controller: _pinControllers[index],
                                              focusNode: _focusNodes[index],
                                              textAlign: TextAlign.center,
                                              keyboardType: TextInputType.number,
                                              maxLength: 1,
                                              onChanged: (v) => _onPinChanged(v, index),
                                              style: TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800,
                                                color: isError ? Colors.red : primaryColor,
                                              ),
                                              decoration: InputDecoration(
                                                counterText: '',
                                                filled: true,
                                                fillColor: isError 
                                                    ? Colors.red.withOpacity(0.1)
                                                    : isFocused
                                                        ? primaryColor.withOpacity(0.1)
                                                        : const Color(0xFFF0F3F8),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(14),
                                                  borderSide: BorderSide(
                                                    color: isError ? Colors.red : Colors.transparent,
                                                    width: isError ? 2 : 0,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(14),
                                                  borderSide: BorderSide(
                                                    color: isError ? Colors.red : primaryColor,
                                                    width: 2,
                                                  ),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                    if (_hasError) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: _clearPin,
                                              child: Icon(Icons.close, size: 16, color: Colors.red.shade700),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Rejoindre button with enhanced state
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: (_isJoining || !_isPinComplete()) ? null : _joinQuiz,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isPinComplete() && !_hasError 
                                          ? primaryColor 
                                          : Colors.grey.shade300,
                                      foregroundColor: Colors.white,
                                      elevation: _isPinComplete() && !_hasError ? 2 : 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isJoining
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'Rejoindre',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              if (_isPinComplete() && !_hasError) ...[
                                                const SizedBox(width: 8),
                                                const Icon(Icons.arrow_forward_rounded, size: 18),
                                              ],
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Pas de code
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Pas de code ?',
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Explorer
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Ou explorer les Quiz publics',
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: primaryColor, size: 18),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Créer un Quiz ────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CreateQuizPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_rounded, size: 22),
                              label: const Text(
                                'Créer un nouveau Quiz',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tertiaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
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
    );
  }
}