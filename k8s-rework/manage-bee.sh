#!/bin/bash

# --- CONFIGURATION ---
NAMESPACE="algohive"
K8S_PATH="../k8s-rework" #

# Pattern pour la clé API
SEARCH_PATTERN="API"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- FONCTION DE DEPLOIEMENT DU SOCLE ---
function deploy_base() {
    echo -e "${CYAN}   DÉPLOIEMENT DU SOCLE (Infra + Core Apps)...${NC}"
    
    # 1. INITIALIZATION & COMMON
    echo -n "   -> 00 & 01 (Namespace, Configs)... "
    kubectl apply -f ${K8S_PATH}/00-initialization/ > /dev/null 2>&1
    kubectl apply -f ${K8S_PATH}/01-common/ > /dev/null 2>&1
    echo "OK"
    
    # 2. INFRASTRUCTURE (DB & Redis)
    echo -n "   -> 02-infrastructure (Postgres, Redis)... "
    kubectl apply -f ${K8S_PATH}/02-infrastructure/ -R > /dev/null 2>&1
    echo "OK"

    # 3. CORE APPS (Backend, Client, BeeHub)
    # On lance explicitement les dossiers "communs" de 03-apps
    echo "   -> 03-apps (Core)... "
    
    # Backend (Visible sur ton image)
    echo -n "      - Backend: "
    kubectl apply -f ${K8S_PATH}/03-apps/backend/ && echo "OK" || echo "Erreur ou manquant"

    # Client (Supposé présent dans 03-apps)
    echo -n "      - Client: "
    if [ -d "${K8S_PATH}/03-apps/client" ]; then
        kubectl apply -f ${K8S_PATH}/03-apps/client/ > /dev/null 2>&1 && echo "OK"
    else
        echo "Pas trouvé (ignoré)"
    fi

    # BeeHub (Supposé présent dans 03-apps)
    echo -n "      - BeeHub: "
    if [ -d "${K8S_PATH}/03-apps/beehub" ]; then
        kubectl apply -f ${K8S_PATH}/03-apps/beehub/ > /dev/null 2>&1 && echo "OK"
    else
        echo "Pas trouvé (ignoré)"
    fi
    
    echo -e "${GREEN}  Socle opérationnel.${NC}"
    echo "---------------------------------------------------"
}

# --- FONCTION RECUPERATION CLE ---
function wait_and_get_key() {
    local APP_LABEL=$1
    echo -e "${BLUE}Attente du démarrage du Pod (${APP_LABEL})...${NC}"
    
    # Attente active
    kubectl wait --for=condition=Ready pod -l app=${APP_LABEL} -n ${NAMESPACE} --timeout=90s > /dev/null
    
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Timeout : Le pod n'est pas prêt.${NC}"
        return
    fi

    POD_NAME=$(kubectl get pod -l app=${APP_LABEL} -n ${NAMESPACE} -o jsonpath="{.items[0].metadata.name}")
    echo -e "${GREEN}Pod prêt : ${POD_NAME}${NC}"
    
    # Recherche dans les logs
    echo -e "${CYAN}Recherche de '${SEARCH_PATTERN}' dans les logs...${NC}"
    LOG_RESULT=$(kubectl logs ${POD_NAME} -n ${NAMESPACE} | grep "${SEARCH_PATTERN}")
    
    if [ -z "$LOG_RESULT" ]; then
        echo "Clé non trouvée (grep vide). Derniers logs :"
        kubectl logs ${POD_NAME} -n ${NAMESPACE} | tail -n 3
    else
        echo -e "${GREEN}${LOG_RESULT}${NC}"
    fi
    echo "---------------------------------------------------"
}

# --- MENU ---
clear
echo -e "${YELLOW}🐝  ALGOHIVE DEPLOYER${NC}"
echo "1) Toulouse"
echo "2) Montpellier"
echo "3) Lyon"
echo "4) Staging"
echo "5) Tout lancer"
read -p "Choix : " choice

# ON LANCE LE SOCLE EN PREMIER (TOUJOURS)
deploy_base

case $choice in
  1)
    echo -e "${BLUE}Lancement BeeAPI TOULOUSE...${NC}"
    kubectl apply -f ${K8S_PATH}/03-apps/beeapi/toulouse/
    wait_and_get_key "beeapi-server-tlse"
    ;;
  2)
    echo -e "${BLUE}Lancement BeeAPI MONTPELLIER...${NC}"
    kubectl apply -f ${K8S_PATH}/03-apps/beeapi/montpellier/
    wait_and_get_key "beeapi-server-mpl"
    ;;
  3)
    echo -e "${BLUE}Lancement BeeAPI LYON...${NC}"
    kubectl apply -f ${K8S_PATH}/03-apps/beeapi/lyon/
    wait_and_get_key "beeapi-server-lyon"
    ;;
  4)
    echo -e "${BLUE}Lancement BeeAPI STAGING...${NC}"
    kubectl apply -f ${K8S_PATH}/03-apps/beeapi/staging/
    wait_and_get_key "beeapi-server-staging"
    ;;
  5)
    echo -e "${BLUE}Lancement de TOUS les BeeAPI...${NC}"
    kubectl apply -f ${K8S_PATH}/03-apps/beeapi/ -R
    echo -e "${GREEN}Tout est lancé.${NC}"
    ;;
  *)
    echo "Choix invalide."
    ;;
esac