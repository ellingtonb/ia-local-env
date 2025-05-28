#!/bin/bash

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
NC="\033[0m" # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RECOMMENDED_MODELS=()
if [ -f "$SCRIPT_DIR/recommended_models" ]; then
    while IFS= read -r line; do
        [ -n "$line" ] && RECOMMENDED_MODELS+=("$line")
    done < "$SCRIPT_DIR/recommended_models"
fi

# Função para obter status do Ollama
get_ollama_status() {
    if ! command -v ollama &> /dev/null; then
        echo "Not Installed"
    elif ! pgrep -x ollama &> /dev/null; then
        echo "Stopped"
    else
        echo "Running"
    fi
}

# Função para iniciar o Ollama em background e manter rodando
start_ollama() {
    if ! pgrep -x ollama &> /dev/null; then
        nohup ollama serve > "$HOME/.ollama_server.log" 2>&1 &
        disown
        sleep 2
    fi
}

# Função para parar o Ollama
stop_ollama() {
    pkill -x ollama
    sleep 2
}

# Função para listar modelos instalados
list_installed_models() {
    if ! command -v ollama &> /dev/null; then
        return 1
    fi
    if ! ollama ps &> /dev/null; then
        return 2
    fi
    ollama ps | awk 'NR>1 {print $1":"$2}'
}

# Função para instalar modelo
install_model() {
    local model="$1"
    ollama pull "$model"
    read -n 1 -s -r -p "Press any key to return to menu..."
}

# Função para remover modelo
remove_model() {
    local model="$1"
    ollama rm "$model"
    read -n 1 -s -r -p "Press any key to return to menu..."
}

# Submenu de modelos
models_menu() {
    while true; do
        clear
        echo -e "${CYAN}================================${NC}"
        echo -e "${CYAN}============ Models ============${NC}"
        echo -e "${CYAN}================================${NC}"
        models=()
        while IFS= read -r line; do
            models+=("$line")
        done < <(list_installed_models)
        status=$?
        if [ $status -eq 1 ]; then
            echo
            echo -e "${RED}Ollama não está instalado.${NC}"
            echo
            echo -e "0) Back"
            read -p $'\nChoose an option: ' opt
            [ "$opt" = "0" ] && return
        elif [ $status -eq 2 ]; then
            echo
            echo -e "${YELLOW}Ollama is not running or not responding.${NC}"
            echo
            echo -e "0) Back"
            read -p $'\nChoose an option: ' opt
            [ "$opt" = "0" ] && return
        elif [ ${#models[@]} -eq 0 ]; then
            echo
            echo -e "${YELLOW}No models installed.${NC}"
            echo
            echo -e "${GREEN}1) Install${NC}"
            echo
            echo -e "0) Back"
            read -p $'\nChoose an option: ' opt
            case $opt in
                1) install_menu ;;
                0) return ;;
                *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
            esac
        else
            for i in "${!models[@]}"; do
                echo "$((i+2))) ${models[$i]}"
            done
            echo -e "0) Back"
            read -p $'\nChoose an option: ' opt
            if [ "$opt" = "0" ]; then
                return
            elif [ "$opt" = "1" ]; then
                install_menu
            elif [[ "$opt" =~ ^[0-9]+$ ]] && [ "$opt" -ge 2 ] && [ "$opt" -le $(( ${#models[@]} + 1 )) ]; then
                model_actions_menu "${models[$((opt-2))]}"
            else
                echo -e "${RED}Invalid Option!${NC}"; sleep 1
            fi
        fi
    done
}

# Submenu de ações para modelo
model_actions_menu() {
    local model="$1"
    while true; do
        clear
        echo -e "${CYAN}Model: $model${NC}"
        echo -e "1) Remove"
        echo -e "0) Back"
        read -p $'\nChoose an option: ' opt
        case $opt in
            1) remove_model "$model"; return ;;
            0) return ;;
            *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
        esac
    done
}

# Submenu de instalação de modelos
install_menu() {
    installed=()
    status=0
    while IFS= read -r line; do
        # Garante que a linha não está vazia
        [ -n "$line" ] && installed+=("$line")
    done < <(list_installed_models)
    status=$?
    declare -A installed_map
    if [ $status -eq 0 ]; then
        for m in "${installed[@]}"; do
            # Considera apenas o nome do modelo antes dos dois pontos e remove possíveis sufixos
            model_name="${m%%:*}"
            model_name="${model_name%%@*}"
            installed_map["$model_name"]=1
        done
    fi
    local available=()
    # print all recomended models from RECOMMENDED_MODELS
    for m in "${RECOMMENDED_MODELS[@]}"; do
        model_name="${m%%:*}"
        if [ $status -ne 0 ] || [ -z "${installed_map[$model_name]}" ]; then
            available+=("$m")
        fi
    done
    while true; do
        clear
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}====== Install Recommended Models ======${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo

        # Show error if no recommended models found
        if [ ${#RECOMMENDED_MODELS[@]} -eq 0 ]; then
            echo -e "${RED}No recommended models found! Please check the 'recommended_models' file.${NC}\n"
            echo -e "0) Back"
            read -p $'\nChoose an option: ' opt
            [ "$opt" = "0" ] && return
        fi

        if [ $status -eq 1 ]; then
            echo -e "${RED}Ollama is not installed.${NC}"
            echo -e "0) Back"
            read -p $'\nChoose an option: ' opt
            [ "$opt" = "0" ] && return
        elif [ $status -eq 2 ]; then
            echo -e "${YELLOW}Ollama is not running or not responding.${NC}"
            echo -e "0) Back"
            read -p $'\nChoose an option: ' opt
            [ "$opt" = "0" ] && return
        elif [ ${#available[@]} -eq 0 ] && [ ${#RECOMMENDED_MODELS[@]} -ne 0 ]; then
            echo -e "${GREEN}All recommended models are already installed.${NC}"
            echo
            echo -e "0) Back"
            read -p $'\nChoose an option: ' opt
            [ "$opt" = "0" ] && return
        else
            for i in "${!available[@]}"; do
                echo "$((i+1))) ${available[$i]}"
            done
            echo
            echo -e "0) Back"
            read -p $'\nChoose a model to install: ' opt
            if [ "$opt" = "0" ]; then
                return
            elif [[ "$opt" =~ ^[0-9]+$ ]] && [ "$opt" -ge 1 ] && [ "$opt" -le ${#available[@]} ]; then
                install_model "${available[$((opt-1))]}"
                return
            else
                echo -e "${RED}Invalid Option!${NC}"; sleep 1
            fi
        fi
    done
}

# Submenu para visualizar o log do Ollama
ollama_log_menu() {
    clear
    echo -e "${CYAN}=========== Ollama Log (Press Ctrl+C to exit) ===========${NC}"
    echo
    echo -e "Log File: $HOME/.ollama_server.log"
    echo
    tail -f "$HOME/.ollama_server.log"
}

# Menu principal do Ollama
ollama_menu() {
    while true; do
        clear
        status=$(get_ollama_status)
        case $status in
            "Not Installed") color="$RED" ;;
            "Stopped") color="$YELLOW" ;;
            "Running") color="$GREEN" ;;
            *) color="$NC" ;;
        esac
        echo -e "${CYAN}============================${NC}"
        echo -e "${CYAN}========== Ollama ==========${NC}"
        echo -e "${CYAN}============================${NC}"
        echo -e "Status: ${color}${status}${NC}"
        echo -e "${CYAN}============================${NC}"
        echo

        case $status in
            "Not Installed")
                echo -e "${RED}Ollama isn't installed!${NC}"
                echo -e "0) Back"
                read -p $'\nChoose an option: ' opt
                [ "$opt" = "0" ] && return
                ;;
            "Stopped")
                echo -e "1) Start"
                echo -e "2) Models"
                echo -e "0) Voltar"
                read -p $'\nEscolha uma opção: ' opt
                case $opt in
                    1) start_ollama ;;
                    2) models_menu ;;
                    0) return ;;
                    *) echo -e "${RED}Opção inválida!${NC}"; sleep 1 ;;
                esac
                ;;
            "Running")
                echo -e "1) Stop"
                echo -e "2) Models"
                echo -e "3) Log"
                echo -e "0) Voltar"
                read -p $'\nEscolha uma opção: ' opt
                case $opt in
                    1) stop_ollama ;;
                    2) models_menu ;;
                    3) ollama_log_menu ;;
                    0) return ;;
                    *) echo -e "${RED}Opção inválida!${NC}"; sleep 1 ;;
                esac
                ;;
        esac
    done
}

ollama_menu
