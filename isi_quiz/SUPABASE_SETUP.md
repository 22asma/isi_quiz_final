# Guide de Configuration Supabase pour ISI Quiz

## Étape 1 : Obtenir les bonnes clés Supabase

1. Allez sur [supabase.com](https://supabase.com)
2. Connectez-vous ou créez un compte
3. Créez un nouveau projet
4. Dans votre projet, allez dans **Settings > API**
5. Copiez :
   - **Project URL** (ex: `https://your-project-id.supabase.co`)
   - **anon public** key (ex: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

## Étape 2 : Mettre à jour la configuration Flutter

Modifiez `lib/core/constants/app_constants.dart` :

```dart
class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://your-project-id.supabase.co'; // Remplacez par votre URL
  static const String supabaseAnonKey = 'your-anon-key-here'; // Remplacez par votre clé
  
  // ... reste du code
}
```

## Étape 3 : Créer les tables dans Supabase

1. Dans votre projet Supabase, allez dans **SQL Editor**
2. Copiez et collez le contenu du fichier `database_setup.sql`
3. Cliquez sur **Run** pour exécuter le script

Ou exécutez manuellement ces commandes SQL :

```sql
-- Créer la table profiles
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  university TEXT,
  institute TEXT,
  role TEXT DEFAULT 'Student',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activer RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Créer policies
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Créer trigger automatique
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, university, institute, role)
  VALUES (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'university',
    new.raw_user_meta_data->>'institute',
    new.raw_user_meta_data->>'role'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

## Étape 4 : Configurer l'authentification

1. Allez dans **Authentication > Settings**
2. Activez **Email authentication**
3. Configurez les URLs de redirection si nécessaire
4. Testez avec l'application Flutter

## Étape 5 : Vérifier la connexion

Lancez l'application et vérifiez dans la console que vous voyez :
```
supabase.supabase_flutter: INFO: ***** Supabase init completed *****
```

## Problèmes Communs

### "Server error occurred" lors de l'inscription
- Vérifiez que l'URL Supabase est correcte
- Assurez-vous que la table `profiles` existe
- Vérifiez que les RLS policies sont configurées

### "Invalid URL" error
- L'URL doit commencer par `https://` et finir par `.supabase.co`
- Ne pas utiliser l'URL PostgreSQL locale

### Permission denied
- Vérifiez que les RLS policies sont activées
- Assurez-vous que l'utilisateur est authentifié

## Test de Connexion

Pour tester si Supabase est bien connecté, ajoutez ce code temporaire dans `main.dart` :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  
  // Test de connexion
  try {
    final client = Supabase.instance.client;
    print('Supabase URL: ${client.supabaseUrl}');
    print('Connexion réussie!');
  } catch (e) {
    print('Erreur de connexion: $e');
  }
  
  await initializeDependencies();
  runApp(const MyApp());
}
```
