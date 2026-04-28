class AppConstants {
  // Supabase Configuration
  //static const String supabaseUrl = 'http://10.0.2.2:54321';
  static const String supabaseUrl = 'http://192.168.0.8:54321';
  static const String supabaseAnonKey = '625729a08b95bf1b7ff351a663f3a23c';
  
  // App Configuration
  static const String appName = 'ISI Quiz';
  static const String appVersion = '1.0.0';
  static const String tagline = 'THE DIGITAL LYCEUM';
  
  // Routes
  static const String splashRoute = '/splash';
  static const String signInRoute = '/sign-in';
  static const String signUpRoute = '/sign-up';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String homeRoute = '/home';
  
  // Validation
  static const int minPasswordLength = 6;
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double largeBorderRadius = 24.0;
  
  // Colors
  static const int primaryColorValue = 0xFF003366;
  static const int secondaryColorValue = 0xFF4A5F70;
  static const int tertiaryColorValue = 0xFF592300;
  static const int backgroundColorValue = 0xFFF5F5F5;
}
