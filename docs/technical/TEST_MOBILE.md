# 📱 Guide de Test Mobile

## Option 1: Test sur Chrome avec Simulation Mobile (RAPIDE)

### Étape 1: Lancer Flutter sur Chrome
```bash
cd frontend_flutter_mobile/hospital-microgrid
flutter run -d chrome --web-port=3000
```

### Étape 2: Activer le Mode Mobile dans Chrome
1. Une fois l'app lancée, appuyez sur **F12** pour ouvrir les DevTools
2. Cliquez sur l'icône **Toggle device toolbar** (ou Ctrl+Shift+M)
3. Sélectionnez un preset mobile :
   - **iPhone 14 Pro** (390 x 844)
   - **iPhone SE** (375 x 667)
   - **Pixel 7** (412 x 915)
   - **Galaxy S20** (360 x 800)

### Étape 3: Tester
- L'app s'adaptera automatiquement à la taille mobile
- Vous pouvez tester les tooltips et la responsivité
- Rafraîchir la page si nécessaire (F5)

---

## Option 2: Créer un Nouvel Émulateur Android

### Via Android Studio (Recommandé)
1. Ouvrir **Android Studio**
2. Aller dans **Tools > Device Manager**
3. Cliquer sur **Create Device**
4. Choisir un device :
   - **Pixel 7** (recommandé - taille moyenne)
   - **Pixel 5**
   - **Galaxy S21**
5. Choisir une image système : **API 34** (Android 14) ou **API 33**
6. Cliquer sur **Finish**

### Via Ligne de Commande
```bash
# Lister les images système disponibles
sdkmanager --list | Select-String "system-images"

# Créer un nouvel émulateur (exemple Pixel 7)
avdmanager create avd -n Pixel_7_API_34 -k "system-images;android-34;google_apis;x86_64" -d "pixel_7"

# Lancer l'émulateur
emulator -avd Pixel_7_API_34
```

### Lancer Flutter sur l'émulateur
```bash
# D'abord, vérifier que l'émulateur est détecté
flutter devices

# Lancer l'app
flutter run
```

---

## Option 3: Test sur iPhone Simulator (macOS uniquement)

Si vous êtes sur macOS :
```bash
# Ouvrir le simulateur iOS
open -a Simulator

# Lancer Flutter
flutter run -d ios
```

---

## Vérification Mobile

Une fois lancé, vérifiez :
- ✅ Les tooltips fonctionnent au tap (pas seulement hover)
- ✅ Les formulaires sont facilement utilisables
- ✅ Les graphiques s'affichent correctement
- ✅ La navigation est intuitive
- ✅ Les textes sont lisibles sans zoom
- ✅ Les boutons sont assez grands pour être cliqués facilement

---

## Dépannage

### Émulateur qui affiche un écran noir
1. Arrêter l'émulateur
2. Wipe Data dans Android Studio Device Manager
3. Relancer l'émulateur
4. Ou créer un nouvel émulateur

### Flutter ne détecte pas l'émulateur
```bash
flutter doctor -v
adb devices  # Vérifier que l'émulateur est listé
flutter devices
```

### Problème de performance
- Réduire la résolution de l'émulateur
- Fermer les autres applications
- Augmenter la RAM allouée à l'émulateur dans AVD Manager









