#!/bin/bash

# Script pour basculer entre Bureau et Maison

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_DIR="$SCRIPT_DIR/mct-maintenance-dashboard"
MOBILE_CONFIG="$SCRIPT_DIR/mct_maintenance_mobile/lib/config/environment.dart"

# Fonction pour changer la localisation dans environment.dart
change_mobile_location() {
  local new_location=$1
  local old_location=$2
  
  if [ -f "$MOBILE_CONFIG" ]; then
    # Utiliser perl pour un remplacement multi-lignes plus robuste
    perl -i -pe "s/const Location currentLocation =\s*Location\.$old_location;/const Location currentLocation =\n    Location.$new_location;/g" "$MOBILE_CONFIG"
    
    # Vérifier si le changement a été effectué
    if grep -q "Location.$new_location" "$MOBILE_CONFIG"; then
      echo "✅ Mobile: Configuration $new_location activée"
      return 0
    else
      echo "⚠️  Mobile: Erreur lors du changement (vérifiez manuellement)"
      return 1
    fi
  else
    echo "❌ Mobile: Fichier environment.dart non trouvé"
    return 1
  fi
}

# Fonction pour afficher la configuration actuelle
show_current_config() {
  echo ""
  echo "📍 Configuration actuelle:"
  
  # Vérifier la config mobile
  if [ -f "$MOBILE_CONFIG" ]; then
    if grep -q "Location.office" "$MOBILE_CONFIG"; then
      echo "   Mobile: BUREAU (192.168.1.139)"
    elif grep -q "Location.home" "$MOBILE_CONFIG"; then
      echo "   Mobile: MAISON (192.168.1.14)"
    else
      echo "   Mobile: INCONNUE"
    fi
  fi
  
  # Vérifier la config dashboard
  if [ -f "$DASHBOARD_DIR/.env" ]; then
    local dash_ip=$(grep "REACT_APP_API_URL" "$DASHBOARD_DIR/.env" | cut -d'/' -f3 | cut -d':' -f1)
    if [ "$dash_ip" = "192.168.1.139" ]; then
      echo "   Dashboard: BUREAU (192.168.1.139)"
    elif [ "$dash_ip" = "192.168.1.14" ]; then
      echo "   Dashboard: MAISON (192.168.1.14)"
    else
      echo "   Dashboard: $dash_ip"
    fi
  fi
  echo ""
}

# Afficher la configuration actuelle
show_current_config

echo "🔧 Configuration Bureau/Maison"
echo ""
echo "Où voulez-vous basculer ?"
echo "1) Bureau (192.168.1.139)"
echo "2) Maison (192.168.1.14)"
echo "3) Annuler"
echo ""
read -p "Votre choix (1, 2 ou 3): " choice

case $choice in
  1)
    echo ""
    echo "📍 Basculement vers le BUREAU..."
    echo ""
    
    # Dashboard
    if [ -f "$DASHBOARD_DIR/.env.office" ]; then
      cp "$DASHBOARD_DIR/.env.office" "$DASHBOARD_DIR/.env"
      echo "✅ Dashboard: .env mis à jour → 192.168.1.139"
    else
      echo "⚠️  Dashboard: .env.office non trouvé"
    fi
    
    # Mobile
    change_mobile_location "office" "home"
    
    echo ""
    echo "🎉 Configuration BUREAU activée !"
    echo "   📱 Mobile: 192.168.1.139:3000"
    echo "   🌐 Dashboard: 192.168.1.139:3000"
    ;;
    
  2)
    echo ""
    echo "📍 Basculement vers la MAISON..."
    echo ""
    
    # Dashboard
    if [ -f "$DASHBOARD_DIR/.env.home" ]; then
      cp "$DASHBOARD_DIR/.env.home" "$DASHBOARD_DIR/.env"
      echo "✅ Dashboard: .env mis à jour → 192.168.1.14"
    else
      echo "⚠️  Dashboard: .env.home non trouvé"
    fi
    
    # Mobile
    change_mobile_location "home" "office"
    
    echo ""
    echo "🎉 Configuration MAISON activée !"
    echo "   📱 Mobile: 192.168.1.14:3000"
    echo "   🌐 Dashboard: 192.168.1.14:3000"
    ;;
    
  3)
    echo ""
    echo "❌ Opération annulée"
    exit 0
    ;;
    
  *)
    echo ""
    echo "❌ Choix invalide"
    exit 1
    ;;
esac

echo ""
echo "📝 Prochaines étapes:"
echo "   1. Backend: Doit tourner sur la nouvelle IP"
echo "      → Vérifiez avec: curl http://NOUVELLE_IP:3000/health"
echo "   2. Dashboard: Rechargez la page (Cmd+R)"
echo "   3. Mobile: Hot Restart (R) dans Flutter"
echo ""
echo "💡 Astuce: Le backend s'adapte automatiquement à votre réseau"
