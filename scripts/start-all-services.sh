#!/bin/bash

# Script pour lancer tous les services du projet Microgrid Hospitalier
# Usage: ./start-all-services.sh

set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Répertoires
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend_common"
AI_DIR="$PROJECT_ROOT/ai_microservices"
FLUTTER_DIR="$PROJECT_ROOT/hospital-microgrid"

# Fichiers de logs
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR"
BACKEND_LOG="$LOG_DIR/backend.log"
AI_LOG="$LOG_DIR/ai-service.log"
FLUTTER_LOG="$LOG_DIR/flutter.log"

echo -e "${CYAN}=== LANCEMENT DE TOUS LES SERVICES ===${NC}"
echo ""

# Fonction pour vérifier si un port est utilisé
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        return 0
    else
        return 1
    fi
}

# Fonction pour attendre qu'un service soit prêt
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=0
    
    echo -e "${YELLOW}Attente de $service_name...${NC}"
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "$url" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ $service_name est prêt${NC}"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
    echo -e "${RED}⚠ $service_name n'a pas répondu après ${max_attempts}s${NC}"
    return 1
}

# 1. Vérifier PostgreSQL
echo -e "${YELLOW}1. Vérification PostgreSQL...${NC}"
if docker ps --filter "name=postgres" --format "{{.Names}}" 2>/dev/null | grep -q "microgrid-postgres"; then
    echo -e "${GREEN}   ✓ PostgreSQL déjà en cours d'exécution${NC}"
else
    echo -e "${YELLOW}   ⚠ PostgreSQL non détecté. Vérifiez que Docker est lancé.${NC}"
    echo -e "${YELLOW}   Lancez: docker start microgrid-postgres${NC}"
fi

# 2. Lancer le microservice AI
echo -e "${YELLOW}2. Lancement Microservice IA (port 8000)...${NC}"
if check_port 8000; then
    echo -e "${GREEN}   ✓ Microservice IA déjà en cours d'exécution${NC}"
else
    cd "$AI_DIR"
    echo -e "${YELLOW}   Démarrage du microservice AI...${NC}"
    
    # Vérifier si un environnement virtuel existe
    if [ -d "venv" ]; then
        source venv/bin/activate
    fi
    
    # Installer les dépendances si nécessaire
    if ! python3 -c "import fastapi" 2>/dev/null; then
        echo -e "${YELLOW}   Installation des dépendances Python...${NC}"
        pip install -q -r requirements.txt
    fi
    
    # Lancer le service en arrière-plan
    nohup python3 -m uvicorn src.api:app --host 0.0.0.0 --port 8000 --reload > "$AI_LOG" 2>&1 &
    AI_PID=$!
    echo $AI_PID > "$LOG_DIR/ai-service.pid"
    echo -e "${GREEN}   ✓ Microservice IA lancé (PID: $AI_PID)${NC}"
    echo -e "${CYAN}   Logs: $AI_LOG${NC}"
    sleep 3
fi

# 3. Lancer le Backend Spring Boot
echo -e "${YELLOW}3. Lancement Backend Spring Boot (port 8080)...${NC}"
if check_port 8080; then
    echo -e "${GREEN}   ✓ Backend déjà en cours d'exécution${NC}"
else
    cd "$BACKEND_DIR"
    echo -e "${YELLOW}   Démarrage du backend Spring Boot...${NC}"
    
    # Vérifier si Maven wrapper existe
    if [ -f "mvnw" ]; then
        MVN_CMD="./mvnw"
    else
        MVN_CMD="mvn"
    fi
    
    # Lancer le backend en arrière-plan
    nohup $MVN_CMD spring-boot:run > "$BACKEND_LOG" 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$LOG_DIR/backend.pid"
    echo -e "${GREEN}   ✓ Backend lancé (PID: $BACKEND_PID)${NC}"
    echo -e "${CYAN}   Logs: $BACKEND_LOG${NC}"
    sleep 5
fi

# 4. Vérifier les services
echo ""
echo -e "${CYAN}=== VÉRIFICATION DES SERVICES ===${NC}"

# Vérifier AI Service
echo -e "${YELLOW}AI Service (8000):${NC}" -n
if wait_for_service "http://localhost:8000/health" "AI Service"; then
    echo -e "${GREEN} ✓ OK${NC}"
else
    echo -e "${YELLOW} ⚠ Port ouvert mais endpoint non accessible${NC}"
fi

# Vérifier Backend
echo -e "${YELLOW}Backend (8080):${NC}" -n
if wait_for_service "http://localhost:8080/actuator/health" "Backend" || \
   wait_for_service "http://localhost:8080/api/health" "Backend"; then
    echo -e "${GREEN} ✓ OK${NC}"
else
    echo -e "${YELLOW} ⚠ Port ouvert mais endpoint non accessible${NC}"
fi

# 4. Instructions pour Flutter (à lancer manuellement)
echo ""
echo -e "${CYAN}=== INSTRUCTIONS FLUTTER ===${NC}"
echo -e "${YELLOW}Flutter doit être lancé manuellement dans un terminal séparé.${NC}"
echo ""
echo -e "${CYAN}Commandes disponibles:${NC}"
echo ""
echo -e "${GREEN}Pour iPhone 16 Pro Max:${NC}"
echo -e "  ${YELLOW}cd $FLUTTER_DIR${NC}"
echo -e "  ${YELLOW}flutter run -d AD6D5A7B-B6C6-4506-AA12-5DF8B2463F0F${NC}"
echo ""
echo -e "${GREEN}Pour détecter automatiquement l'appareil:${NC}"
echo -e "  ${YELLOW}cd $FLUTTER_DIR${NC}"
echo -e "  ${YELLOW}flutter devices${NC}"
echo -e "  ${YELLOW}flutter run -d <DEVICE_ID>${NC}"
echo ""
echo -e "${GREEN}Pour Chrome (web):${NC}"
echo -e "  ${YELLOW}cd $FLUTTER_DIR${NC}"
echo -e "  ${YELLOW}flutter run -d chrome --web-port=3000${NC}"
echo ""

# Résumé final
echo ""
echo -e "${CYAN}=== RÉSUMÉ DES SERVICES ===${NC}"
echo -e "${GREEN}✓ AI Microservice:${NC} http://localhost:8000"
echo -e "${GREEN}✓ Backend Spring Boot:${NC} http://localhost:8080"
echo -e "${YELLOW}⚠ Flutter:${NC} À lancer manuellement (voir instructions ci-dessus)"
echo ""
echo -e "${CYAN}=== INFORMATIONS ===${NC}"
echo -e "Logs disponibles dans: ${YELLOW}$LOG_DIR${NC}"
echo -e "PIDs sauvegardés dans: ${YELLOW}$LOG_DIR/*.pid${NC}"
echo ""
echo -e "${YELLOW}Pour arrêter les services, utilisez:${NC}"
echo -e "  ${CYAN}./stop-all-services.sh${NC}"
echo ""
echo -e "${GREEN}=== SERVICES LANCÉS ===${NC}"

