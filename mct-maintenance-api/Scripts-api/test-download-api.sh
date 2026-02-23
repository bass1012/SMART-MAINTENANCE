#!/bin/bash

# Script de test du téléchargement de PDF via l'API

echo "🧪 Test de téléchargement de PDF via l'API"
echo ""

# Demander le token
echo "📝 Collez votre token JWT (ou appuyez sur Entrée pour utiliser le token admin par défaut):"
read TOKEN

if [ -z "$TOKEN" ]; then
  # Token admin par défaut (à remplacer par un vrai token)
  TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NiwiZW1haWwiOiJhZG1pbkBtY3QtbWFpbnRlbmFuY2UuY29tIiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNzYwNjg1MzYxLCJleHAiOjE3NjEyOTAxNjF9.RBCTildhTue6s1mNo4QF1TpDy8qawJ5GGIngbHyVoMo"
  echo "⚠️  Utilisation du token par défaut"
fi

echo ""
echo "🔄 Téléchargement de la facture pour la commande #4..."
echo ""

# Télécharger le PDF
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/payments/invoice/4/download \
  --output test-api-download.pdf \
  -w "\n📊 Status HTTP: %{http_code}\n📦 Taille: %{size_download} bytes\n⏱️  Temps: %{time_total}s\n"

echo ""

# Vérifier le fichier
if [ -f "test-api-download.pdf" ]; then
  SIZE=$(wc -c < test-api-download.pdf)
  echo "✅ Fichier téléchargé: test-api-download.pdf"
  echo "📊 Taille du fichier: $SIZE bytes"
  
  # Vérifier le type de fichier
  FILE_TYPE=$(file test-api-download.pdf)
  echo "📄 Type: $FILE_TYPE"
  
  # Vérifier le header PDF
  HEADER=$(head -c 5 test-api-download.pdf)
  if [ "$HEADER" = "%PDF-" ]; then
    echo "✅ Header PDF valide"
    echo ""
    echo "🎉 Succès! Vous pouvez ouvrir le fichier avec:"
    echo "   open test-api-download.pdf"
  else
    echo "❌ Header PDF invalide: $HEADER"
    echo "Le fichier est peut-être corrompu"
  fi
else
  echo "❌ Échec du téléchargement"
fi
