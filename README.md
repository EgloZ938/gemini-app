# ✨ Application Gemini Multi-Chat 📱

Bienvenue dans l'application **Gemini Multi-Chat** ! Il s'agit d'une application **Flutter** qui supporte les thèmes **clairs** et **sombres**, 
avec une messagerie en temps réel entre utilisateurs et une interface de chat avec une IA. L'application permet de catégoriser et filtrer les conversations, 
renommer les chats, et stocker les données de manière persistante avec **Shared Preferences**. 🗂️

## 🌟 Fonctionnalités

- **💬 Chat en temps réel** : Engagez des conversations avec une IA ou d'autres utilisateurs de manière fluide.
- **🌙 Support du mode sombre** : Passez facilement entre les thèmes clairs et sombres, avec les préférences stockées localement.
- **🔍 Recherche de chats** : Trouvez rapidement vos chats ou messages avec la fonctionnalité de recherche.
- **📁 Catégorisation des chats** : Groupez vos conversations par catégories pour une meilleure organisation.
- **✍️ Renommage des chats** : Personnalisez vos discussions en renommant les salons de chat.
- **💾 Stockage persistant** : Sauvegardez les conversations, les préférences et les paramètres de thème à travers les lancements de l'application.
- **🔄 Animations fluides** : Des animations douces et esthétiques grâce au package **flutter_staggered_animations**.
  
## 🛠️ Technologies Utilisées

- **Flutter** : Framework pour construire des applications compilées nativement pour mobile, web, et desktop à partir d'une seule base de code.
- **Shared Preferences** : Stockage local pour conserver les données utilisateur, l'historique des chats et les préférences.
- **HTTP** : Requêtes vers un serveur distant pour récupérer les réponses de l'IA dans le chat.
- **Intl** : Formatage des dates et des nombres de manière localisée.
- **Google Fonts** : Utilisation de belles polices pour améliorer l'interface utilisateur.
- **Gemini AI API** : Intégration de l'API Gemini AI pour générer des réponses intelligentes dans le chat.

## 🚀 Commencer avec le projet

Pour démarrer avec ce projet, suivez ces étapes :

1. **Cloner le dépôt** :

   ```bash
   git clone https://github.com/nomutilisateur/gemini-multi-chat.git
   ```

2. **Installer les dépendances** :

   ```bash
   cd gemini-multi-chat
   flutter pub get
   ```

3. **Configurer la clé API** :
   - Copiez le fichier `lib/config.dart.example` vers `lib/config.dart`
   - Créez votre clé API sur [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Remplacez `VOTRE_CLE_API_ICI` dans `config.dart` par votre clé API :
     ```dart
     class Config {
       static const String apiKey = 'VOTRE_CLE_API_ICI';
     }
     ```
   > Note : Le fichier `config.dart` est dans le .gitignore et ne sera pas partagé sur GitHub pour des raisons de sécurité.

4. **Lancer l'application** :

   ```bash
   flutter run -d web-server
   ```

## 🎨 Personnalisation

Vous pouvez facilement modifier et étendre cette application :

- **Thèmes** : Modifiez les thèmes clairs et sombres dans `MyApp` pour correspondre à vos besoins en design.
- **Catégories de chat** : Ajoutez ou modifiez des catégories de chat selon vos besoins.
- **Backend API** : Remplacez l'API Gemini AI par une autre API de chatbot de votre choix.
  
## 🤝 Contribuer

N'hésitez pas à soumettre des **issues** et des **pull requests** pour aider à améliorer le projet ! 💻

1. Forkez le dépôt.
2. Créez une nouvelle branche.
3. Apportez vos modifications.
4. Soumettez une pull request.

## ⚙️ Dépendances

- `flutter`
- `http`
- `intl`
- `shared_preferences`
- `google_fonts`
- `flutter_staggered_animations`
- `file_picker`
