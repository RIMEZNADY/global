#!/bin/bash

# Script pour arrêter tous les services du projet Microgrid Hospitalier
# Usage: ./stop-all-services.sh

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
LOG_DIR="$PROJECT_ROOT/logs"

echo -e "${CYAN}=== ARRÊT DE TOUS LES SERVICES ===${NC}"
echo ""

# Fonction pour arrêter un processus par PID
stop_process() {
    local pid_file=$1
    local service_name=$2
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${YELLOW}Arrêt de $service_name (PID: $pid)...${NC}"
            kill "$pid" 2>/dev/null || true
            sleep 2
            # Force kill si toujours en cours
            if ps -p "$pid" > /dev/null 2>&1; then
                kill -9 "$pid" 2>/dev/null || true
            fi
            echo -e "${GREEN}✓ $service_name arrêté${NC}"
            rm -f "$pid_file"
        else
            echo -e "${YELLOW}⚠ $service_name n'était pas en cours d'exécution${NC}"
            rm -f "$pid_file"
        fi
    else
        echo -e "${YELLOW}⚠ Fichier PID non trouvé pour $service_name${NC}"
    fi
}

# Arrêter par port si PID non trouvé
stop_by_port() {
    local port=$1
    local service_name=$2
    
    local pids=$(lsof -ti :$port 2>/dev/null || echo "")
    if [ ! -z "$pids" ]; then
        echo -e "${YELLOW}Arrêt de $service_name sur le port $port...${NC}"
        for pid in $pids; do
            kill "$pid" 2>/dev/null || true
        done
        sleep 2
        # Force kill si toujours en cours
        local remaining_pids=$(lsof -ti :$port 2>/dev/null || echo "")
        if [ ! -z "$remaining_pids" ]; then
            for pid in $remaining_pids; do
                kill -9 "$pid" 2>/dev/null || true
            done
        fi
        echo -e "${GREEN}✓ $service_name arrêté${NC}"
    else
        echo -e "${YELLOW}⚠ $service_name n'était pas en cours d'exécution${NC}"
    fi
}

# 1. Arrêter Backend Spring Boot
echo -e "${YELLOW}1. Arrêt du Backend Spring Boot...${NC}"
stop_process "$LOG_DIR/backend.pid" "Backend"
stop_by_port 8080 "Backend"
# Arrêter aussi par processus Java/Maven
pkill -f "spring-boot:run" 2>/dev/null || true

# 2. Arrêter AI Microservice
echo -e "${YELLOW}2. Arrêt du Microservice IA...${NC}"
stop_process "$LOG_DIR/ai-service.pid" "AI Microservice"
stop_by_port 8000 "AI Microservice"
# Arrêter aussi par processus Python/uvicorn
pkill -f "uvicorn.*src.api:app" 2>/dev/null || true

# Résumé
echo ""
echo -e "${CYAN}=== VÉRIFICATION FINALE ===${NC}"

# Vérifier les ports
if lsof -ti :8000 >/dev/null 2>&1; then
    echo -e "${RED}⚠ Port 8000 toujours utilisé${NC}"
else
    echo -e "${GREEN}✓ Port 8000 libéré${NC}"
fi

if lsof -ti :8080 >/dev/null 2>&1; then
    echo -e "${RED}⚠ Port 8080 toujours utilisé${NC}"
else
    echo -e "${GREEN}✓ Port 8080 libéré${NC}"
fi

# Note: Flutter n'est pas géré par ce script (lancé manuellement)

echo ""
echo -e "${GREEN}=== TOUS LES SERVICES ARRÊTÉS ===${NC}"

