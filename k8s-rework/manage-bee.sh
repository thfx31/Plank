#!/bin/bash

# --- PALETTE DE COULEURS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- CONFIGURATION ---
NAMESPACE="algohive"
SEARCH_PATTERN="API key initialized"

# --- FONCTIONS ---

show_menu() {
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${BOLD}🐝  ALGOHIVE - INFRA MANAGER (PLANK)${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo "1) Toulouse (Déployer & Clé)"
    echo "2) Montpellier (Déployer & Clé)"
    echo "3) Lyon (Déployer & Clé)"
    echo "4) Staging (Déployer & Clé)"
    echo "5) TOUT DÉPLOYER (Stack complète)"
    echo -e "${CYAN}=========================================${NC}"
    echo -n "Votre choix : "
    read CHOICE
}

# Fonction générique pour appliquer un dossier
deploy_step() {
    local FOLDER=$1
    local DESC=$2
    if [ -d "$FOLDER" ]; then
        echo -e -n "🏗️   Déploiement de ${BOLD}${DESC}${NC}..."
        # On capture la sortie pour rester propre, sauf erreur
        OUTPUT=$(kubectl apply -R -f "$FOLDER" 2>&1)
        if [ $? -eq 0 ]; then
            echo -e " ${GREEN}OK${NC}"
        else
            echo -e " ${RED}ERREUR${NC}"
            echo "$OUTPUT"
        fi
    else
        echo -e "${YELLOW}⚠️   Dossier '$FOLDER' introuvable (étape ignorée)${NC}"
    fi
}

# Fonction qui lance toute l'infrastructure commune
deploy_infra() {
    echo -e "${BLUE}🔧  Vérification/Déploiement de l'infrastructure...${NC}"
    deploy_step "00-initialization" "Namespace"
    deploy_step "01-common" "Configs & Secrets"
    deploy_step "02-infrastructure" "Infrastructure (DB & Redis)"
    deploy_step "03-apps" "Applications (Client, Server, Bees...)"
    echo "-----------------------------------------"
}

get_api_key() {
    local CITY=$1
    local LABEL="app=beeapi-server-${CITY}"
    
    echo -e "${YELLOW}⏳  [${CITY}] Recherche du Pod et de la clé...${NC}"

    # 1. Vérification du Pod
    local POD_NAME=""
    local RETRY_POD=0
    # On essaye pendant 10 secondes de trouver le pod (le temps que le déploiement se fasse)
    while [ -z "$POD_NAME" ] && [ $RETRY_POD -lt 10 ]; do
        POD_NAME=$(kubectl get pods -n ${NAMESPACE} -l ${LABEL} -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
        if [ -z "$POD_NAME" ]; then
            sleep 1
            ((RETRY_POD++))
        fi
    done

    if [ -z "$POD_NAME" ]; then
        echo -e "${RED}❌  [${CITY}] Pod introuvable malgré le déploiement.${NC}"
        return
    fi

    # 2. Récupération des logs (Retry loop)
    local MAX_RETRIES=30 
    local COUNT=0
    local KEY_FOUND=""

    while [ $COUNT -lt $MAX_RETRIES ]; do
        local LOG_LINE=$(kubectl logs ${POD_NAME} -n ${NAMESPACE} 2>/dev/null | grep "${SEARCH_PATTERN}")

        if [ -n "$LOG_LINE" ]; then
            KEY_FOUND=$(echo "$LOG_LINE" | awk '{print $NF}')
            break
        fi
        sleep 2
        ((COUNT++))
    done

    # 3. Affichage
    if [ -n "$KEY_FOUND" ]; then
        echo -e "${GREEN}🔑  [${CITY}] Clé : ${BOLD}${KEY_FOUND}${NC}"
    else
        echo -e "${RED}⚠️   [${CITY}] Timeout : La clé n'est pas encore apparue dans les logs.${NC}"
    fi
}

# --- EXÉCUTION DU PROGRAMME PRINCIPAL ---

show_menu

# Pour les choix 1 à 4, on lance l'infra PUIS on cherche la clé spécifique
case $CHOICE in
    1)
        deploy_infra
        get_api_key "tlse"
        ;;
    2)
        deploy_infra
        get_api_key "mpl"
        ;;
    3)
        deploy_infra
        get_api_key "lyon"
        ;;
    4)
        deploy_infra
        get_api_key "staging"
        ;;
    5)
        deploy_infra
        echo -e "${BLUE}📋  Récupération de TOUTES les clés...${NC}"
        # On lance tout à la suite
        get_api_key "tlse"
        get_api_key "mpl"
        get_api_key "lyon"
        get_api_key "staging"
        ;;
    *)
        echo -e "${RED}❌ Choix invalide.${NC}"
        ;;
esac

echo "-----------------------------------------"
echo -e "${GREEN}🎉  Terminé.${NC}"