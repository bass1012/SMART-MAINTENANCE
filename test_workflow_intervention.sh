#!/bin/bash

# Script de test du workflow complet d'intervention
# Usage: ./test_workflow_intervention.sh <intervention_id> <technician_token>

set -e

INTERVENTION_ID=${1:-1}
TOKEN=${2:-"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}
BASE_URL="http://localhost:3000/api"

echo "🧪 Test du workflow d'intervention"
echo "=================================="
echo "Intervention ID: $INTERVENTION_ID"
echo ""

# Fonction pour faire une requête API
test_step() {
    local step_name=$1
    local endpoint=$2
    local expected_status=$3
    
    echo "📍 Test: $step_name"
    echo "   Endpoint: POST $BASE_URL$endpoint"
    
    response=$(curl -s -w "\n%{http_code}" -X POST \
        "$BASE_URL$endpoint" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq "$expected_status" ]; then
        echo "   ✅ Status: $http_code"
        echo "   Response: $(echo $body | jq -r '.message')"
        echo ""
        return 0
    else
        echo "   ❌ Status: $http_code (attendu: $expected_status)"
        echo "   Response: $body"
        echo ""
        return 1
    fi
}

# Obtenir l'état actuel
echo "🔍 État actuel de l'intervention"
current_state=$(curl -s -X GET \
    "$BASE_URL/interventions/$INTERVENTION_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json")

current_status=$(echo $current_state | jq -r '.data.status')
echo "   Statut actuel: $current_status"
echo ""

# Tests du workflow
echo "🚀 Lancement des tests du workflow"
echo "=================================="
echo ""

# Étape 1: Accepter
if [ "$current_status" = "assigned" ] || [ "$current_status" = "pending" ]; then
    test_step "1. Accepter l'intervention" "/interventions/$INTERVENTION_ID/accept" 200
else
    echo "⏭️  Étape 1: Acceptation - Déjà passée (statut: $current_status)"
    echo ""
fi

# Étape 2: En route
if [ "$current_status" = "accepted" ]; then
    test_step "2. Signaler en route" "/interventions/$INTERVENTION_ID/on-the-way" 200
else
    echo "⏭️  Étape 2: En route - Déjà passée ou pas encore disponible"
    echo ""
fi

# Étape 3: Arrivé
if [ "$current_status" = "on_the_way" ]; then
    test_step "3. Signaler arrivée" "/interventions/$INTERVENTION_ID/arrived" 200
else
    echo "⏭️  Étape 3: Arrivée - Déjà passée ou pas encore disponible"
    echo ""
fi

# Étape 4: Démarrer
if [ "$current_status" = "arrived" ]; then
    test_step "4. Démarrer l'intervention" "/interventions/$INTERVENTION_ID/start" 200
else
    echo "⏭️  Étape 4: Démarrage - Déjà passée ou pas encore disponible"
    echo ""
fi

# Étape 5: Terminer
if [ "$current_status" = "in_progress" ]; then
    test_step "5. Terminer l'intervention" "/interventions/$INTERVENTION_ID/complete" 200
else
    echo "⏭️  Étape 5: Terminaison - Déjà passée ou pas encore disponible"
    echo ""
fi

# État final
echo "🏁 État final de l'intervention"
echo "================================"
final_state=$(curl -s -X GET \
    "$BASE_URL/interventions/$INTERVENTION_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json")

final_status=$(echo $final_state | jq -r '.data.status')
accepted_at=$(echo $final_state | jq -r '.data.accepted_at // "N/A"')
departed_at=$(echo $final_state | jq -r '.data.departed_at // "N/A"')
arrived_at=$(echo $final_state | jq -r '.data.arrived_at // "N/A"')
started_at=$(echo $final_state | jq -r '.data.started_at // "N/A"')
completed_at=$(echo $final_state | jq -r '.data.completed_at // "N/A"')

echo "Statut final: $final_status"
echo ""
echo "Timestamps:"
echo "  - Acceptée:  $accepted_at"
echo "  - En route:  $departed_at"
echo "  - Arrivée:   $arrived_at"
echo "  - Démarrage: $started_at"
echo "  - Fin:       $completed_at"
echo ""

if [ "$final_status" = "completed" ]; then
    echo "🎉 Workflow terminé avec succès!"
else
    echo "⏸️  Workflow en cours (statut: $final_status)"
fi

echo ""
echo "✅ Tests terminés"
