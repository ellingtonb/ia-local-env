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

# Função para exibir cabeçalho
show_header() {
    clear
    echo -e "${CYAN}============================="
    echo -e "    AI Local Environment    "
    echo -e "=============================${NC}\n"
}

# Função para instalar Homebrew
install_homebrew() {
    bash "$MENU_DIR/install_homebrew.sh"
}

# Função para instalar Ollama
install_ollama() {
    bash "$MENU_DIR/install_ollama.sh"
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
            echo -e "0) Exit"
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
                echo -e "0) Exit"
                read -p $'\nChoose an option: ' opt
                case $opt in
                    1) install_ollama ;;
                    0) exit 0 ;;
                    *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
                esac
            else
                echo -e "1) Open-WebUI"
                echo
                echo -e "0) Exit"
                read -p $'\nChoose an option: ' opt
                case $opt in
                    1) open_webui_menu ;;
                    0) exit 0 ;;
                    *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
                esac
            fi
        fi
    done
}

main_menu

