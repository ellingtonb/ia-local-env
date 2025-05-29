#!/bin/bash

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
NC="\033[0m" # No Color

# Diretório base para scripts auxiliares
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_DIR="$SCRIPT_DIR/scripts/cli/menu"

# Cria diretórios de menu se não existirem
mkdir -p "$MENU_DIR"

# Função para obter status de um serviço
get_service_status() {
    local service_name="$1"
    local status="Not Installed"
    local color="$RED"
    local extra=""
    if [ "$service_name" = "Docker" ]; then
        if ! command -v docker &> /dev/null; then
            status="Not Installed"
            color="$RED"
        elif ! docker info &> /dev/null; then
            status="Stopped"
            color="$YELLOW"
        else
            status="Running"
            color="$GREEN"
        fi
    elif [ "$service_name" = "Ollama" ]; then
        if ! command -v ollama &> /dev/null; then
            status="Not Installed"
            color="$RED"
        elif ! pgrep -x ollama &> /dev/null; then
            status="Stopped"
            color="$YELLOW"
        else
            status="Running"
            color="$GREEN"
        fi
    elif [ "$service_name" = "Open-WebUI" ]; then
        local container_id=""
        local status_code=0
        local port="3000"
        local browser_url="http://localhost:$port"
        local ports_list=""
        local ports_count=0
        if [ -f "$SCRIPT_DIR/ui/docker-compose.yml" ]; then
            ports_list=$(awk '/open-webui:/,0 {if ($1 == "ports:") p=1; else if (p && $1 == "-") print $2; else if (p && $1 != "-") exit}' "$SCRIPT_DIR/ui/docker-compose.yml" | awk -F: '{gsub(/\"/, "", $1); print $1}' | tr '\n' ',' | sed 's/,*$//;s/, /, /g')
            if [ -n "$ports_list" ]; then
                ports_count=$(echo "$ports_list" | awk -F',' '{print NF}')
            fi
        fi
        container_id=$(docker-compose -f "$SCRIPT_DIR/ui/docker-compose.yml" ps -q open-webui | cut -c1-12 2>/dev/null)
        if [ -n "$container_id" ]; then
            if docker ps -q | grep -q "$container_id"; then
                status="Running"
                color="$GREEN"
                if [ "$ports_count" -eq 1 ]; then
                    port=$(echo "$ports_list" | cut -d',' -f1 | xargs)
                    browser_url="http://localhost:$port"
                    extra=" ($browser_url)"
                fi
            elif docker ps -aq | grep -q "$container_id"; then
                status="Stopped"
                color="$YELLOW"
            else
                status="Stopped"
                color="$YELLOW"
            fi
        else
            status="Stopped"
            color="$YELLOW"
        fi
    fi
    echo -e "${color}$status${NC}${extra}"
}

# Função para exibir cabeçalho
show_header() {
    clear
    echo -e "${CYAN}============================================"
    echo -e "           AI Local Environment    "
    echo -e "============================================${NC}"
    echo -e "Docker: $(get_service_status Docker)"
    echo -e "Ollama: $(get_service_status Ollama)"
    echo -e "Open-WebUI: $(get_service_status Open-WebUI)"
    echo -e "${CYAN}============================================${NC}\n"
}

# Função para instalar Homebrew
install_homebrew() {
    bash "$MENU_DIR/install_homebrew.sh"
}

# Função para instalar Ollama
install_ollama() {
    bash "$MENU_DIR/install_ollama.sh"
}

# Função para submenu do Ollama
ollama_menu() {
    bash "$MENU_DIR/ollama_menu.sh"
}

# Open-WebUI submenu
open_webui_menu() {
    bash "$MENU_DIR/open_webui_menu.sh"
}

# Main menu function
main_menu() {
    while true; do
        show_header
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            echo -e "${YELLOW}Homebrew is not installed.${NC}"
            echo -e "1) Install Homebrew"
            echo -e "2) Install Ollama ${RED}(requires Homebrew)${NC}"
            echo
            echo -e "${RED}0) Exit${NC}"
            read -p $'\nChoose an option: ' opt
            case $opt in
                1) install_homebrew ;;
                2) echo -e "${RED}You need to install Homebrew first!${NC}"; echo; read -n 1 -s -r -p "Press any key to return to the menu..." ;;
                0) exit 0 ;;
                *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
            esac
        else
            if ! command -v ollama &> /dev/null; then
                echo -e "1) Install Ollama"
                echo
                echo -e "${RED}0) Exit${NC}"
                read -p $'\nChoose an option: ' opt
                case $opt in
                    1) install_ollama ;;
                    0) exit 0 ;;
                    *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
                esac
            else
                echo -e "1) Ollama"
                echo -e "2) Open-WebUI"
                echo
                echo -e "${RED}0) Exit${NC}"
                read -p $'\nChoose an option: ' opt
                case $opt in
                    1) ollama_menu ;;
                    2) open_webui_menu ;;
                    0) exit 0 ;;
                    *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
                esac
            fi
        fi
    done
}

main_menu

