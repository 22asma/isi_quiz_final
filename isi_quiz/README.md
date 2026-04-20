# ISI Quiz App

Une application Flutter de quiz avec Supabase pour l'authentification et la gestion des données.

## Architecture

Ce projet suit une architecture propre (Clean Architecture) avec les couches suivantes :

### 📁 Structure du Projet

```
lib/
├── core/                          # Couche principale
│   ├── constants/                  # Constantes de l'application
│   ├── errors/                     # Gestion des erreurs
│   ├── services/                   # Injection de dépendances
│   └── theme/                      # Thème et styles
├── features/                      # Fonctionnalités
│   └── auth/                      # Authentification
│       ├── data/                   # Couche de données
│       │   ├── datasources/        # Sources de données (Supabase)
│       │   ├── models/             # Modèles de données
│       │   └── repositories/       # Implémentation des repositories
│       ├── domain/                 # Couche métier
│       │   ├── entities/           # Entités métier
│       │   ├── repositories/       # Interfaces des repositories
│       │   └── usecases/          # Cas d'utilisation
│       └── presentation/           # Couche de présentation
│           ├── bloc/               # Gestion d'état (BLoC)
│           ├── pages/              # Écrans
│           └── widgets/           # Composants réutilisables
└── main.dart                      # Point d'entrée
```

## 🚀 Fonctionnalités d'Authentification

- ✅ Page d'accueil (Splash Screen)
- ✅ Connexion (Sign In)
- ✅ Inscription (Sign Up)
- ✅ Mot de passe oublié (Forgot Password)
- ✅ Validation des formulaires
- ✅ Gestion des erreurs
- ✅ États de chargement

## 🛠️ Technologies Utilisées

- **Flutter** - Framework de développement mobile
- **Supabase** - Backend as a Service (Base de données & Authentification)
- **BLoC** - Gestion d'état
- **Get It** - Injection de dépendances
- **Go Router** - Navigation
- **Google Fonts** - Typographie
- **Font Awesome** - Icônes

## 📋 Prérequis

1. Flutter SDK (>= 3.11.0)
2. Un compte Supabase
3. Dart SDK

## 🛠️ Installation

1. **Cloner le projet**
   ```bash
   git clone <repository-url>
   cd isi_quiz
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Configurer Supabase**
   - Créer un nouveau projet sur [Supabase](https://supabase.com)
   - Copier l'URL et la clé anonyme
   - Mettre à jour `lib/core/constants/app_constants.dart` avec vos credentials

4. **Créer les tables Supabase**
   ```sql
   -- Table profiles
   CREATE TABLE profiles (
     id UUID REFERENCES auth.users(id) PRIMARY KEY,
     email TEXT,
     full_name TEXT,
     university TEXT,
     institute TEXT,
     role TEXT DEFAULT 'Student',
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   
   -- Trigger pour créer un profil automatiquement
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

5. **Lancer l'application**
   ```bash
   flutter run
   ```

## 📱 Pages d'Authentification

### 1. Splash Page
- Page d'accueil avec animation
- Logo et tagline de l'application
- Redirection automatique vers la connexion

### 2. Sign In
- Formulaire de connexion
- Validation email et mot de passe
- Gestion des erreurs
- Lien vers mot de passe oublié et inscription

### 3. Sign Up
- Formulaire d'inscription complet
- Sélection université/institut
- Choix du rôle (Student/Instructor)
- Validation des champs

### 4. Forgot Password
- Récupération de mot de passe
- Envoi d'email de réinitialisation
- Interface de confirmation

## 🎨 Thème et Design

- **Couleurs** : Palette basée sur les images fournies
- **Typographie** : Manrope (headers) et Inter (body)
- **Composants** : Design system cohérent
- **Responsive** : Adaptation aux différentes tailles d'écran

## 🔄 Flux d'Authentification

```
Splash Page → Sign In → Home
            ↓
         Sign Up → Home
            ↓
    Forgot Password → Sign In
```

## 🐛 Dépannage

### Problèmes Communs

1. **Erreur de connexion Supabase**
   - Vérifier les credentials dans `app_constants.dart`
   - S'assurer que le projet Supabase est actif

2. **Erreur de build**
   - Nettoyer le cache : `flutter clean`
   - Réinstaller les dépendances : `flutter pub get`

3. **Problème de navigation**
   - Vérifier les routes dans `main.dart`
   - S'assurer que les imports sont corrects

## 📝 Prochaines Étapes

- [ ] Implémentation des fonctionnalités de quiz
- [ ] Gestion des profils utilisateurs
- [ ] Tableau de bord administrateur
- [ ] Notifications push
- [ ] Mode hors ligne

## 🤝 Contribution

1. Fork le projet
2. Créer une branche de fonctionnalité
3. Commit les changements
4. Push vers la branche
5. Créer une Pull Request

## 📄 Licence

Ce projet est sous licence MIT.
