#!/bin/bash

# Script de build iOS pour TestFlight - Thot
# Exécute toutes les étapes de préparation automatiquement

set -e  # Arrêter en cas d'erreur

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                              ║"
echo "║               🚀 BUILD iOS POUR TESTFLIGHT - THOT v1.0.1                    ║"
echo "║                                                                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Vérifier qu'on est dans le dossier mobile
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Erreur: Ce script doit être exécuté depuis le dossier mobile/"
    echo "   Exécutez: cd mobile && ./BUILD_NOW.sh"
    exit 1
fi

echo "✓ Dossier mobile confirmé"
echo ""

# Vérifier que Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé ou pas dans le PATH"
    exit 1
fi

echo "✓ Flutter installé: $(flutter --version | head -n 1)"
echo ""

# Vérifier la configuration de production
echo "📋 Vérification de la configuration..."
if [ ! -f ".env.production" ]; then
    echo "❌ Fichier .env.production introuvable"
    exit 1
fi

PROD_URL=$(grep "API_BASE_URL" .env.production | cut -d '=' -f 2)
echo "✓ URL de production: $PROD_URL"
echo ""

# Vérifier que le backend répond
echo "🔍 Vérification du backend..."
BACKEND_URL="https://app-b73e2919-0361-42d6-ba77-d154856cefb3.cleverapps.io/health"
if curl -s -f "$BACKEND_URL" > /dev/null; then
    echo "✓ Backend accessible et fonctionnel"
else
    echo "⚠️  Warning: Le backend ne répond pas"
    echo "   URL testée: $BACKEND_URL"
    read -p "   Continuer quand même? (y/N): " CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        echo "Build annulé"
        exit 1
    fi
fi
echo ""

# Nettoyer
echo "🧹 Nettoyage du projet..."
flutter clean
echo "✓ Nettoyage terminé"
echo ""

# Récupérer les dépendances
echo "📦 Récupération des dépendances..."
flutter pub get
echo "✓ Dépendances installées"
echo ""

# Analyser le code
echo "🔍 Analyse du code..."
if flutter analyze; then
    echo "✓ Analyse du code OK"
else
    echo "⚠️  Warning: Des problèmes ont été détectés"
    read -p "   Continuer quand même? (y/N): " CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        echo "Build annulé"
        exit 1
    fi
fi
echo ""

# Build iOS en mode release
echo "🔨 Build iOS en mode release..."
echo "   Version: 1.0.1"
echo "   Build number: 2"
echo "   Configuration: .env.production"
echo ""

flutter build ios --release \
  --dart-define-from-file=.env.production \
  --build-name=1.0.1 \
  --build-number=2

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ BUILD RÉUSSI!"
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                          📱 PROCHAINES ÉTAPES                                 ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "1. Ouvrir le projet dans Xcode:"
    echo "   $ open ios/Runner.xcworkspace"
    echo ""
    echo "2. Dans Xcode:"
    echo "   - Sélectionner 'Any iOS Device (arm64)' dans le menu déroulant"
    echo "   - Vérifier Signing & Capabilities (Team et Provisioning Profile)"
    echo "   - Product > Archive"
    echo ""
    echo "3. Une fois l'archive créée:"
    echo "   - Dans Organizer, sélectionner l'archive"
    echo "   - Distribute App > App Store Connect > Upload"
    echo ""
    echo "4. Après l'upload:"
    echo "   - Aller sur https://appstoreconnect.apple.com"
    echo "   - Onglet TestFlight"
    echo "   - Attendre le traitement (15-30 minutes)"
    echo "   - Configurer les testeurs"
    echo ""
    echo "📖 Guide complet: BUILD_TESTFLIGHT.md"
    echo ""

    # Demander si on doit ouvrir Xcode
    read -p "Voulez-vous ouvrir Xcode maintenant? (Y/n): " OPEN_XCODE
    if [ "$OPEN_XCODE" != "n" ] && [ "$OPEN_XCODE" != "N" ]; then
        echo "Ouverture de Xcode..."
        open ios/Runner.xcworkspace
    fi

else
    echo ""
    echo "❌ Le build a échoué"
    echo ""
    echo "Solutions possibles:"
    echo "1. Nettoyer complètement:"
    echo "   $ flutter clean && cd ios && pod deintegrate && pod install && cd .."
    echo ""
    echo "2. Vérifier les certificats dans Xcode:"
    echo "   $ open ios/Runner.xcworkspace"
    echo "   Signing & Capabilities"
    echo ""
    echo "3. Consulter le guide: BUILD_TESTFLIGHT.md"
    exit 1
fi
