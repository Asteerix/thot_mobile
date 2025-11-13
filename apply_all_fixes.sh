#!/bin/bash

echo "🚀 Application de toutes les corrections Flutter..."
echo "=================================================="

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

cd "$(dirname "$0")"

echo -e "${BLUE}📝 Phase 1: Corrections de compilation${NC}"
# Les corrections de new_publication_screen.dart sont déjà faites

echo -e "${GREEN}✓ new_publication_screen.dart corrigé${NC}"

echo -e "${BLUE}📝 Phase 2: Modifications visuelles et thème${NC}"

# Remplacer tous les "t.conserv" par "t.conservateur" et "t.progress" par "t.progressiste"
find lib -name "*.dart" -type f -exec sed -i '' 's/t\.conserv\([^a-z]\)/t.conservateur\1/g' {} +
find lib -name "*.dart" -type f -exec sed -i '' 's/t\.progress\([^a-z]\)/t.progressiste\1/g' {} +
find lib -name "*.dart" -type f -exec sed -i '' 's/conserv\([^a-z]\)/conservateur\1/g' {} +
find lib -name "*.dart" -type f -exec sed -i '' 's/progress\([^a-z]\)/progressiste\1/g' {} +

echo -e "${GREEN}✓ Labels politiques mis à jour${NC}"

# Changer les icônes de vérification du bleu au vert
find lib -name "*.dart" -type f -exec sed -i '' 's/Icons\.verified[^,]*color: AppColors\.blue/Icons.verified, color: Colors.green/g' {} +
find lib -name "*.dart" -type f -exec sed -i '' 's/Icons\.check_circle[^,]*color: AppColors\.blue/Icons.check_circle, color: Colors.green/g' {} +
find lib -name "*.dart" -type f -exec sed -i '' 's/verified.*blue/verified, color: Colors.green/g' {} +

echo -e "${GREEN}✓ Icônes de vérification changées en vert${NC}"

echo -e "${BLUE}📝 Phase 3: Formatage et nettoyage${NC}"

# Formater tout le code
flutter format lib/

echo -e "${GREEN}✓ Code formaté${NC}"

echo -e "${BLUE}📝 Phase 4: Analyse et vérification${NC}"

# Analyser le code
flutter analyze --no-fatal-infos --no-fatal-warnings

echo ""
echo -e "${GREEN}✅ TOUTES LES CORRECTIONS AUTOMATIQUES APPLIQUÉES${NC}"
echo ""
echo "⚠️  ACTIONS MANUELLES REQUISES:"
echo "   1. Vérifier feed_filters.dart pour le thème noir et blanc"
echo "   2. Ajouter la navigation profil journaliste dans content_viewer.dart"
echo "   3. Améliorer l'icône opposition dans post_actions.dart"
echo "   4. Implémenter le vote politique pour les shorts"
echo "   5. Corriger le clavier qui cache les commentaires"
echo "   6. Ajouter les listes abonnés/abonnements"
echo "   7. Harmoniser les icônes bottom bar"
echo "   8. Ajouter boutons éditer/statistiques"
echo "   9. Corriger expérience/formation avec dates"
echo "   10. Navigation entre tous types de posts"
echo "   11. Lecture vidéo/podcast"
echo "   12. Paramètre carte journaliste"
echo "   13. Statistiques courant politique"
echo "   14. Route /stats"
echo "   15. Compteurs abonnés/abonnements"
echo ""
echo "📦 Prochaine étape: Mise à jour du backend VPS"
