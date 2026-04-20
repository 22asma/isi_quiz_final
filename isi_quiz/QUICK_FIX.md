# Correction Rapide - Problème Supabase

## Le Problème Principal
Votre configuration utilise une URL PostgreSQL locale au lieu d'une URL Supabase Cloud.

## Solution Immédiate

### 1. Mettre à jour les clés Supabase
Dans `lib/core/constants/app_constants.dart`, remplacez :

```dart
// AVANT (incorrect)
static const String supabaseUrl = 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';
static const String supabaseAnonKey = '625729a08b95bf1b7ff351a663f3a23c';

// APRÈS (correct)
static const String supabaseUrl = 'https://votre-projet-id.supabase.co';
static const String supabaseAnonKey = 'votre-clé-anon-key';
```

### 2. Comment obtenir les vraies clés
1. Allez sur [supabase.com](https://supabase.com)
2. Connectez-vous/créez un compte
3. Créez un nouveau projet
4. Dans **Settings > API** :
   - Copiez **Project URL** (ex: `https://abc123def.supabase.co`)
   - Copiez **anon public** key

### 3. Test avec ces clés de test (temporaire)
```dart
static const String supabaseUrl = 'https://demo.supabase.co';
static const String supabaseAnonKey = 'demo-key';
```

### 4. Une fois les clés mises à jour
1. Lancez `flutter run -d chrome`
2. Regardez la console pour les logs DEBUG
3. Essayez de créer un compte

## Logs à Regarder
Les logs ajoutés vont afficher :
- Email utilisé
- Supabase URL
- Réponse de l'API
- Erreurs détaillées

## Si ça ne fonctionne toujours pas
1. Vérifiez que l'URL commence par `https://` et finit par `.supabase.co`
2. Vérifiez que la clé anon est longue (commence par `eyJ...`)
3. Créez les tables SQL dans Supabase (voir `database_setup.sql`)
