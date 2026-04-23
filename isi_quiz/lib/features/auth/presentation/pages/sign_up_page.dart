import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:isi_quiz/features/auth/presentation/pages/email_verification_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/segmented_control.dart';
import '../widgets/password_validation_widget.dart';
import '../widgets/enhanced_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/university_data_complete.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _universityController = TextEditingController();
  final _instituteController = TextEditingController();
  
  String _selectedRole = 'Student';
  String? _selectedUniversity;
  String? _selectedFaculty;
  bool _showPasswordValidation = false;
  bool _isCustomUniversity = false;
  bool _isCustomFaculty = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _universityController.dispose();
    _instituteController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        SignUpEvent(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          university: _isCustomUniversity ? _universityController.text.trim() : _selectedUniversity,
          institute: _isCustomFaculty ? _instituteController.text.trim() : _selectedFaculty,
          role: _selectedRole,
        ),
      );
    }
  }

  void _onPasswordChanged(String password) {
    setState(() {
      _showPasswordValidation = password.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
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
    } else if (state is EmailNotVerified) {  // ✅ AJOUTÉ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationPage(email: state.email),
        ),
      );
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Create Account Text
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Join ISI Quiz and start your learning journey',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Full Name Field
                  CustomTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: FontAwesomeIcons.user,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // University Field with Dropdown or Manual Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _universityController,
                              label: 'University',
                              hintText: _isCustomUniversity ? 'Enter university name' : 'Select your university',
                              prefixIcon: FontAwesomeIcons.graduationCap,
                              readOnly: !_isCustomUniversity,
                              onTap: _isCustomUniversity ? null : () {
                                _showUniversityDialog();
                              },
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter or select your university';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isCustomUniversity = !_isCustomUniversity;
                                if (_isCustomUniversity) {
                                  _universityController.clear();
                                  _selectedUniversity = null;
                                  _selectedFaculty = null;
                                  _instituteController.clear();
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCustomUniversity ? AppTheme.primaryColor : Colors.grey[200],
                              foregroundColor: _isCustomUniversity ? Colors.white : AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(_isCustomUniversity ? 'List' : 'Other'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Institute/Faculty Field with Dropdown or Manual Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _instituteController,
                              label: 'Institute/Faculty',
                              hintText: _isCustomFaculty ? 'Enter institute/faculty name' : 'Select your institute/faculty',
                              prefixIcon: FontAwesomeIcons.building,
                              readOnly: !_isCustomFaculty,
                              onTap: _isCustomFaculty ? null : () {
                                if (_selectedUniversity != null && !_isCustomUniversity) {
                                  _showFacultyDialog();
                                } else if (_isCustomUniversity) {
                                  setState(() {
                                    _isCustomFaculty = true;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a university first'),
                                      backgroundColor: AppTheme.warningColor,
                                    ),
                                  );
                                }
                              },
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter or select your institute/faculty';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isCustomFaculty = !_isCustomFaculty;
                                if (_isCustomFaculty) {
                                  _instituteController.clear();
                                  _selectedFaculty = null;
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCustomFaculty ? AppTheme.primaryColor : Colors.grey[200],
                              foregroundColor: _isCustomFaculty ? Colors.white : AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(_isCustomFaculty ? 'List' : 'Other'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Email Field (auto-generated based on selection)
                  CustomTextField(
                    controller: _emailController,
                    label: 'University Email',
                    hintText: 'name@yourdomain.tn',
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
                  
                  const SizedBox(height: 20),
                  
                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hintText: 'Create a strong password',
                    prefixIcon: FontAwesomeIcons.lock,
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter a password';
                      }
                      // Enhanced password validation
                      if (value!.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'Password must contain at least one uppercase letter';
                      }
                      if (!value.contains(RegExp(r'[a-z]'))) {
                        return 'Password must contain at least one lowercase letter';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Password must contain at least one number';
                      }
                      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                        return 'Password must contain at least one special character';
                      }
                      return null;
                    },
                    onChanged: _onPasswordChanged,
                  ),
                  
                  // Password Validation Widget
                  PasswordValidationWidget(
                    password: _passwordController.text,
                    showValidation: _showPasswordValidation,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Role Selection
                  Text(
                    'Role',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedControl(
                    options: const ['Student', 'Instructor'],
                    selectedOption: _selectedRole,
                    onOptionChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Sign Up Button
                  BlocBuilder<AuthBloc, AuthStatus>(
                    builder: (context, state) {
                      return EnhancedButton.primary(
                        text: 'Sign Up',
                        onPressed: state is AuthLoading
                            ? () {}
                            : () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  _signUp();
                                }
                              },
                        isLoading: state is AuthLoading,
                        icon: FontAwesomeIcons.userPlus,
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Sign In Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppConstants.signInRoute);
                          },
                          child: Text(
                            'Log in',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUniversityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select University'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: UniversityData.getUniversityNames().map((university) => ListTile(
              title: Text(university),
              onTap: () {
                setState(() {
                  _selectedUniversity = university;
                  _universityController.text = university;
                  _selectedFaculty = null;
                  _instituteController.clear();
                });
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _showFacultyDialog() {
    final faculties = UniversityData.getFacultiesForUniversity(_selectedUniversity!);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Institute/Faculty - $_selectedUniversity'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: faculties.map((faculty) => ListTile(
              title: Text(faculty.name),
              subtitle: Text(faculty.abbreviation),
              onTap: () {
                setState(() {
                  _selectedFaculty = faculty.name;
                  _instituteController.text = faculty.name;
                  // Auto-update email hint based on faculty
                  _emailController.clear();
                });
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }
  
}
