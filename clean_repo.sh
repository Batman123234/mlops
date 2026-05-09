#!/bin/bash

# ==============================================================================
# Script: clean_repo.sh
# Description: Nettoie le dépôt des fichiers inutiles, crée une sauvegarde,
#              met à jour le .gitignore et force-push vers origin master.
# Usage: ./clean_repo.sh
# ==============================================================================

# Arrêter le script en cas d'erreur
set -e

REPO_ROOT=$(pwd)
BACKUP_BASE="$HOME/Desktop/mlops_backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "------------------------------------------------------------"
echo "🚀 Démarrage du nettoyage du dépôt : $REPO_ROOT"
echo "------------------------------------------------------------"

# 1. SAUVEGARDE CRITIQUE
# ------------------------------------------------------------------------------
if [ -d "$BACKUP_BASE" ]; then
    echo "⚠️ Le dossier de sauvegarde existe déjà. Renommage..."
    mv "$BACKUP_BASE" "${BACKUP_BASE}_$TIMESTAMP"
    echo "✅ Ancien backup déplacé vers : ${BACKUP_BASE}_$TIMESTAMP"
fi

echo "📦 Création d'une nouvelle sauvegarde..."
mkdir -p "$BACKUP_BASE"
cp -R . "$BACKUP_BASE/"
echo "✅ Sauvegarde terminée dans : $BACKUP_BASE"

# 2. NETTOYAGE DES FICHIERS INUTILES
# ------------------------------------------------------------------------------
echo "🧹 Nettoyage des dossiers et fichiers inutiles..."

# Dossiers à supprimer (récursif)
FOLDERS_TO_DEL=("__pycache__" "mlartifacts" "mlruns")

for folder in "${FOLDERS_TO_DEL[@]}"; do
    echo "Searching for $folder..."
    find . -type d -name "$folder" -not -path "./.git/*" -prune -exec rm -rfv {} +
done

# Fichiers à supprimer (récursif)
FILES_TO_DEL=("*.pkl" "*.db" "*.sqlite3" "*.log" "*.pyc" ".env" ".env.*" "mlflow.db")

for pattern in "${FILES_TO_DEL[@]}"; do
    echo "Searching for $pattern..."
    find . -type f -name "$pattern" -not -path "./.git/*" -exec rm -fv {} +
done

# Cas spécial : fichiers CSV (avec confirmation)
echo "❓ Des fichiers .csv ont été trouvés. Voulez-vous les supprimer ? (yes/no)"
read -r confirm_csv
if [[ "$confirm_csv" == "yes" ]]; then
    echo "🗑️ Suppression des fichiers .csv..."
    find . -type f -name "*.csv" -not -path "./.git/*" -exec rm -fv {} +
else
    echo "⏭️ Suppression des fichiers .csv annulée."
fi

# 3. MISE À JOUR DU .GITIGNORE
# ------------------------------------------------------------------------------
echo "📝 Mise à jour du fichier .gitignore..."
cat <<EOF > .gitignore
__pycache__/
*.pyc
*.pkl
*.db
*.sqlite3
.env*
mlartifacts/
mlruns/
mlflow.db
*.log
.vscode/
.idea/
EOF
echo "✅ .gitignore mis à jour."

# 4. GIT CLEANUP & COMMIT
# ------------------------------------------------------------------------------
echo "🔄 Mise à jour de l'index Git..."
git rm -r --cached . > /dev/null 2>&1 || true
git add .
git commit -m "Clean repo: remove binaries and caches" || echo "⚠️ Rien à committer (déjà propre)."

# 5. FORCE PUSH (OPÉRATION DANGEREUSE)
# ------------------------------------------------------------------------------
echo "------------------------------------------------------------"
echo "⚠️  ATTENTION : OPÉRATION DANGEREUSE"
echo "Cette action va OVERWRITER l'historique sur 'origin master'."
echo "Toute modification distante non présente ici sera PERDUE."
echo "------------------------------------------------------------"

echo "👉 Êtes-vous SÛR de vouloir forcer le push ? (yes/no)"
read -r confirm_push

if [[ "$confirm_push" == "yes" ]]; then
    echo "🚀 Force-push en cours vers origin master..."
    git push --force origin master
    echo "✅ Dépôt nettoyé et mis à jour avec succès !"
else
    echo "❌ Opération de push annulée."
fi

echo "------------------------------------------------------------"
echo "🏁 Fin du script."
