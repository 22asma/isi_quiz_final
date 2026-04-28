import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_quiz/features/home/presentation/pages/home_page.dart';
import 'package:isi_quiz/features/home/presentation/pages/main_navigation_page.dart';
import 'package:isi_quiz/features/profile/presentation/pages/profile_page.dart';
import 'package:isi_quiz/features/quiz/presentation/pages/quiz_list_page.dart';
import 'package:isi_quiz/features/quiz/presentation/create_quiz_page.dart';
import 'package:isi_quiz/features/quiz/presentation/edit_quiz_page.dart';
import 'package:isi_quiz/features/quiz/presentation/pages/quiz_ranking_page.dart';
import 'package:isi_quiz/features/quiz/presentation/pages/quiz_results_page.dart';
import 'package:isi_quiz/features/ranks/presentation/pages/ranks_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/sign_in_page.dart';
import 'features/auth/presentation/pages/sign_up_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/role_router_page.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/sign_in_usecase.dart';
import 'features/auth/domain/usecases/sign_up_usecase.dart';
import 'features/auth/domain/usecases/reset_password_usecase.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'package:app_links/app_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // ✅ Gérer le deep link initial (app fermée puis ouverte via lien)
  final appLinks = AppLinks();
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null && initialUri.scheme == 'isiquiz') {
    await Supabase.instance.client.auth.getSessionFromUrl(initialUri);
  }

  // ✅ Gérer les deep links quand l'app est déjà ouverte
  appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'isiquiz') {
      Supabase.instance.client.auth.getSessionFromUrl(uri);
    }
  });

  final supabaseClient = Supabase.instance.client;
  final authRemoteDataSource = AuthRemoteDataSourceImpl(supabaseClient: supabaseClient);
  final authRepository = AuthRepositoryImpl(remoteDataSource: authRemoteDataSource);
  final signInUseCase = SignInUseCase(authRepository);
  final signUpUseCase = SignUpUseCase(authRepository);
  final resetPasswordUseCase = ResetPasswordUseCase(authRepository);

  runApp(MyApp(
    signInUseCase: signInUseCase,
    signUpUseCase: signUpUseCase,
    resetPasswordUseCase: resetPasswordUseCase,
  ));
}

class MyApp extends StatelessWidget {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  const MyApp({
    super.key,
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.resetPasswordUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(
        signInUseCase: signInUseCase,
        signUpUseCase: signUpUseCase,
        resetPasswordUseCase: resetPasswordUseCase,
      ),
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: AppConstants.splashRoute,
        routes: {
          AppConstants.splashRoute: (context) => const SplashPage(),
          AppConstants.signInRoute: (context) => const SignInPage(),
          AppConstants.signUpRoute: (context) => const SignUpPage(),
          AppConstants.forgotPasswordRoute: (context) => const ForgotPasswordPage(),
          AppConstants.homeRoute: (context) => const MainNavigationPage(),
          '/quiz': (context) => const QuizListPage(),
          '/create-quiz': (context) => const CreateQuizPage(),
          '/edit-quiz': (context) {
            final quiz = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return EditQuizPage(quiz: quiz ?? {});
          },
          '/quiz-results': (context) => const QuizResultsPage(),
          '/quiz-ranking': (context) => const QuizRankingPage(),
          '/ranks': (context) => const RanksPage(),
          '/profile': (context) => const ProfilePage(),

        },
      ),
    );
  }
}