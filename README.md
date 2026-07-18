# 📱 Discipline App — Guide d'installation Flutter

Application mobile de discipline financière et personnelle.

---

## Structure du projet

```
discipline_app/
├── lib/
│   ├── main.dart                    ← Point d'entrée + navigation
│   ├── theme.dart                   ← Couleurs et styles
│   ├── models/
│   │   └── models.dart              ← Modèles de données
│   ├── providers/
│   │   └── app_provider.dart        ← État + persistance locale
│   └── screens/
│       ├── budget_screen.dart       ← Écran budget mensuel
│       ├── tasks_screen.dart        ← Écran tâches journalières
│       └── learning_screen.dart     ← Écran apprentissage
├── pubspec.yaml
└── README.md
```

---

## 🚀 Installation rapide

### 1. Installer Flutter (si pas encore fait)
```bash
# Sur Linux/Mac
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
```

### 2. Créer le projet Flutter
```bash
flutter create discipline_app
cd discipline_app
```

### 3. Remplacer les fichiers
Copie tous les fichiers fournis dans les bons dossiers :
- `lib/main.dart` → remplace le fichier existant
- `lib/theme.dart` → nouveau fichier
- `lib/models/models.dart` → crée le dossier `models/`
- `lib/providers/app_provider.dart` → crée le dossier `providers/`
- `lib/screens/budget_screen.dart` → crée le dossier `screens/`
- `lib/screens/tasks_screen.dart`
- `lib/screens/learning_screen.dart`
- `pubspec.yaml` → remplace le fichier existant

### 4. Installer les dépendances
```bash
flutter pub get
```

### 5. Lancer sur ton téléphone
```bash
# Connecte ton téléphone en USB avec le débogage USB activé
flutter devices    # vérifie que ton phone est détecté
flutter run
```

### 6. Builder l'APK pour installer
```bash
flutter build apk --release
# L'APK se trouve dans: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📋 Fonctionnalités

### 💰 Budget mensuel
- Définir un budget global par mois
- Ajouter des catégories avec icônes (carburant, loyer, aide famille, vêtements, etc.)
- Saisir le montant prévu ET le montant réel observé
- Voir automatiquement le bénéfice ou déficit à la fin du mois
- Barre de progression par catégorie (rouge si dépassé, vert si OK)
- Navigation entre les mois

### ✅ Tâches journalières
- Sélectionner n'importe quel jour
- Ajouter des tâches avec heure optionnelle
- Cocher/décocher les tâches (glisser pour supprimer)
- Voir la progression du jour en %
- Sélecteur rapide des 7 derniers jours

### 📚 Journal d'apprentissage
- Saisir ce qu'on a appris chaque jour
- Catégoriser : Finance, Business, Perso, Tech, Santé, Spirituel, Autre
- Voir le nombre de jours consécutifs (streak)
- Filtrer l'historique par catégorie
- Glisser pour supprimer une entrée

### 💾 Persistance
Toutes les données sont sauvegardées localement sur le téléphone (SharedPreferences). Rien n'est envoyé sur internet.

---

## 🎨 Personnalisation facile

Dans `lib/theme.dart` :
- `kPrimary` → couleur principale (violet par défaut)
- `kSuccess` → couleur succès (vert)
- `kDanger` → couleur alerte (rouge)

Dans `lib/screens/budget_screen.dart` :
- La liste d'icônes disponibles est dans `_showAddCategoryDialog`
- Tu peux ajouter d'autres emojis facilement

---

## 📦 Dépendances utilisées
- `shared_preferences` — sauvegarde locale des données
- `intl` — formatage des dates et nombres en français
- `fl_chart` — graphiques (pour évolution future)
- `uuid` — identifiants uniques pour chaque entrée
- `provider` — gestion de l'état
- `flutter_localizations` — interface en français
