import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart';
import '../widgets/custom_text_field.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        ResetPasswordEvent(email: _emailController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Forgot Password',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      body: BlocListener<AuthBloc, AuthStatus>(
        listener: (context, state) {
          if (state is AuthPasswordReset) {
            setState(() {
              _emailSent = true;
            });
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _emailSent ? _buildEmailSentView() : _buildResetPasswordView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetPasswordView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reset Password Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.lock_reset,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Reset Password',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Description
          Text(
            'Enter the email address associated with your academic account to receive a secure recovery link.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 30),
          
          // Email Field
          CustomTextField(
            controller: _emailController,
            label: 'ACADEMIC EMAIL',
            hintText: 'name@isi.utm.tn',
            prefixIcon: FontAwesomeIcons.envelope,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your email';
              }
              if (!RegExp(AppConstants.emailRegex).hasMatch(value!)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 30),
          
          // Send Reset Link Button
          BlocBuilder<AuthBloc, AuthStatus>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: state is AuthLoading ? null : _resetPassword,
                  icon: state is AuthLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.arrow_forward, size: 18),
                  label: Text(state is AuthLoading ? 'Sending...' : 'Send Reset Link'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSentView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Email Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.email_outlined,
            size: 40,
            color: AppTheme.successColor,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Title
        Text(
          'Check your Email',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Description
        Text(
          'We\'ve sent a password reset link to your inbox. Please check your spam folder if you don\'t see it within a few minutes.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 30),
        
        // Open Email App Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Open email app
            },
            icon: const Icon(Icons.email, size: 18),
            label: const Text('Open Email App'),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Resend Link
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(
            'Resend reset link',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
