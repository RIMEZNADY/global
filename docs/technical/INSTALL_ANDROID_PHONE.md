# 📱 Guide : Installer l'application sur téléphone Android

## Prérequis
1. Un téléphone Android (Android 5.0 ou supérieur)
2. Un câble USB pour connecter le téléphone à l'ordinateur
3. Les pilotes USB Android installés (généralement automatiques avec Android SDK)

---

## Étapes

### 1. Activer le Mode Développeur sur ton téléphone

1. Va dans **Paramètres** (Settings)
2. Va dans **À propos du téléphone** (About phone)
3. Trouve **Numéro de build** (Build number) ou **Numéro de version** (Version number)
4. **Tape 7 fois** sur "Numéro de build" jusqu'à voir un message "Vous êtes maintenant développeur!"

### 2. Activer le Débogage USB

1. Retourne dans **Paramètres**
2. Va dans **Options développeur** (Developer options) - devrait apparaître maintenant
3. Active **Débogage USB** (USB debugging)
4. Accepte l'avertissement si demandé

### 3. Connecter le téléphone à l'ordinateur

1. Connecte ton téléphone à l'ordinateur via le câble USB
2. Sur ton téléphone, une popup va apparaître : **"Autoriser le débogage USB?"**
3. Coche **"Toujours autoriser depuis cet ordinateur"**
4. Appuie sur **"Autoriser"** ou **"OK"**

### 4. Vérifier que Flutter détecte ton téléphone

Ouvre un terminal et exécute :
```bash
cd "C:\Users\Rime Znady\Desktop\SMART_MICROGRID\frontend_flutter_mobile\hospital-microgrid"
flutter devices
```

Tu devrais voir ton téléphone dans la liste, par exemple :
```
SM G950F (mobile) • R58M123456 • android-arm64 • Android 12
```

### 5. Lancer l'application sur ton téléphone

```bash
flutter run
```

Ou si plusieurs appareils sont détectés, spécifie le téléphone :
```bash
flutter run -d <device-id>
```

---

## Dépannage

### Flutter ne détecte pas le téléphone ?

1. **Vérifie que le débogage USB est activé**
2. **Essaie un autre câble USB** (certains câbles sont uniquement pour charger)
3. **Vérifie les pilotes USB** :
   - Sur Windows, installe "Android USB Driver" ou "Google USB Driver"
   - Vérifie dans le Gestionnaire de périphériques que le téléphone apparaît
4. **Autorise le débogage USB** à nouveau sur le téléphone
5. **Essaie de brancher/débrancher** le câble

### Erreur "adb devices" ne montre pas le téléphone ?

```bash
# Redémarrer le serveur ADB
adb kill-server
adb start-server
adb devices
```

### Le téléphone demande toujours l'autorisation ?

- Accepte l'autorisation sur le téléphone
- Vérifie que "Toujours autoriser" est coché
- Débranche et rebranche le câble

---

## Alternative : Générer un APK pour installer manuellement

Si tu veux installer l'APK directement sur le téléphone :

```bash
# Build l'APK
flutter build apk --release

# Le fichier sera dans :
# build/app/outputs/flutter-apk/app-release.apk

# Transfère ce fichier sur ton téléphone et installe-le
```

⚠️ **Note** : Pour installer un APK manuellement, tu dois autoriser "Sources inconnues" dans les paramètres de sécurité Android.

---

## Une fois l'application installée

Tu pourras tester :
- ✅ Le dropdown pour choisir 7, 14 ou 30 jours de prévisions
- ✅ Toutes les fonctionnalités de l'application
- ✅ L'interface mobile responsive

Bon test ! 🚀
















