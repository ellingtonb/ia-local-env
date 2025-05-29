#!/bin/bash

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
NC="\033[0m" # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Corrige o caminho para o arquivo recommended_models na raiz do projeto
RECOMMENDED_MODELS=()
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RECOMMENDED_MODELS_FILE="$PROJECT_ROOT/recommended_models"
if [ -f "$RECOMMENDED_MODELS_FILE" ]; then
    while IFS= read -r line; do
        [ -n "$line" ] && RECOMMENDED_MODELS+=("$line")
    done < "$RECOMMENDED_MODELS_FILE"
fi

# Função para ler modelos recomendados por seção
read_recommended_models() {
    local section=""
    CODE_MODELS=()
    GENERAL_MODELS=()
    if [ -f "$RECOMMENDED_MODELS_FILE" ]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            if [[ "$line" =~ ^\[.*\]$ ]]; then
                section="${line//[\[\]]/}"
                continue
            fi
            case "$section" in
                code) CODE_MODELS+=("$line") ;;
                general) GENERAL_MODELS+=("$line") ;;
            esac
        done < "$RECOMMENDED_MODELS_FILE"
    fi
}

# Chame a função após definir o caminho do arquivo
read_recommended_models

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
    if ! ollama list &> /dev/null; then
        return 2
    fi
    ollama list | awk 'NR>1 {print $1":"$2}'
}

# Função para instalar modelo
install_model() {
    local model="$1"
    ollama pull "$model"
    echo -e "\n${YELLOW}Press any key to return to menu...${NC}"
    read -n 1 -s -r
}

# Função para remover modelo
remove_model() {
    local model="$1"
    ollama rm "$model"
    echo -e "\n${YELLOW}Press any key to return to menu...${NC}"
    read -n 1 -s -r
}

# Função para verificar se um modelo está rodando
is_model_running() {
    local model="$1"
    ollama ps 2>/dev/null | awk '{print $1}' | grep -q "^$model$"
}

# Função para iniciar um modelo específico
start_model() {
    local model="$1"
    nohup ollama run "$model" > "$HOME/.ollama_${model}_run.log" 2>&1 &
    disown
    sleep 2
}

# Função para parar um modelo específico
stop_model() {
    local model="$1"
    ollama stop "$model"
    sleep 2
}

# Função para exibir detalhes do modelo
model_details() {
    local model="$1"
    clear
    echo -e "${CYAN}Model Details: $model${NC}\n"
    ollama show "$model" 2>/dev/null || echo "Could not get details."
    echo -e "\n${YELLOW}Press any key to return...${NC}"
    read -n 1 -s -r
}

# Submenu de modelos
models_menu() {
    while true; do
        clear
        echo -e "${CYAN}================================${NC}"
        echo -e "${CYAN}============ Models ============${NC}"
        echo -e "${CYAN}================================${NC}"
        echo
        echo -e "${GREEN}1) Install${NC}"
        echo
        echo -e "${YELLOW}Installed Models:${NC}"
        echo
        models=()
        while IFS= read -r line; do
            models+=("$line")
        done < <(list_installed_models)
        status=$?
        if [ $status -eq 1 ]; then
            echo
            echo -e "${RED}Ollama não está instalado.${NC}"
            echo
            echo -e "${RED}0) Back${NC}"
            read -p $'\nChoose an option: ' opt
            [ "$opt" = "0" ] && return
        elif [ $status -eq 2 ]; then
            echo
            echo -e "${YELLOW}Ollama is not running or not responding.${NC}"
            echo
            echo -e "${RED}0) Back${NC}"
            read -p $'\nChoose an option: ' opt
            [ "$opt" = "0" ] && return
        fi
        for i in "${!models[@]}"; do
            echo "$((i+2))) ${models[$i]}"
        done
        echo
        echo -e "${RED}0) Back${NC}"
        read -p $'\nChoose an option or a model to see more options: ' opt
        if [ "$opt" = "0" ]; then
            return
        elif [ "$opt" = "1" ]; then
            install_menu
        elif [[ "$opt" =~ ^[0-9]+$ ]] && [ "$opt" -ge 2 ] && [ "$opt" -le $(( ${#models[@]} + 1 )) ]; then
            model_actions_menu "${models[$((opt-2))]}"
        else
            echo -e "${RED}Invalid Option!${NC}"; sleep 1
        fi
    done
}

# Submenu de ações para modelo
model_actions_menu() {
    local model="$1"
    local model_name="${model%:*}"
    while true; do
        clear
        echo -e "${CYAN}Model: $model_name${NC}\n"
        if is_model_running "$model_name"; then
            echo -e "1) Stop"
            echo -e "2) Details"
            echo -e "3) Remove"
        else
            echo -e "1) Start"
            echo -e "2) Details"
            echo -e "3) Remove"
        fi
        echo -e "\n${RED}0) Back${NC}"
        read -p $'\nChoose an option: ' opt
        if is_model_running "$model_name"; then
            case $opt in
                1) stop_model "$model_name";;
                2) model_details "$model_name";;
                3) remove_model "$model"; return ;;
                0) return ;;
                *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
            esac
        else
            case $opt in
                1) start_model "$model_name";;
                2) model_details "$model_name";;
                3) remove_model "$model"; return ;;
                0) return ;;
                *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
            esac
        fi
    done
}

# Submenu de instalação de modelos
install_menu() {
    installed=()
    while IFS= read -r line; do
        model_name="${line%:*}"
        [ -n "$line" ] && installed+=("$model_name")
    done < <(list_installed_models)

    local all_models=()
    for recommended_model_name in "${RECOMMENDED_MODELS[@]}"; do
        found=0
        for inst in "${installed[@]}"; do
          if [ "$inst" = "$recommended_model_name" ]; then
              found=1
              break
          fi
        done
        if [ $found -eq 1 ]; then
            all_models+=("$recommended_model_name|installed")
        else
            all_models+=("$recommended_model_name|not_installed")
        fi
    done

    while true; do
        clear
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}====== Install Recommended Models ======${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo

        echo -e "${BLUE}Code Models:${NC}"
        for i in "${!CODE_MODELS[@]}"; do
            model="${CODE_MODELS[$i]}"
            if [[ " ${installed[*]} " == *" $model "* ]]; then
                echo -e "$((i+1))) ${GREEN}${model} (already installed)${NC}"
            else
                echo -e "$((i+1))) $model"
            fi
        done

        offset=${#CODE_MODELS[@]}
        echo -e "\n${BLUE}General Models:${NC}"
        for i in "${!GENERAL_MODELS[@]}"; do
            model="${GENERAL_MODELS[$i]}"
            idx=$((offset + i + 1))
            if [[ " ${installed[*]} " == *" $model "* ]]; then
                echo -e "$idx) ${GREEN}${model} (already installed)${NC}"
            else
                echo -e "$idx) $model"
            fi
        done
        total=$(( ${#CODE_MODELS[@]} + ${#GENERAL_MODELS[@]} ))

        if [ ${#RECOMMENDED_MODELS[@]} -eq 0 ]; then
            echo -e "${RED}No recommended models found! Please check the 'recommended_models' file.${NC}\n"
            echo -e "${RED}0) Back${NC}"
            read -p $'\nChoose an option: ' opt
            [ "$opt" = "0" ] && return
        fi
        if [ $status -eq 1 ]; then
            echo -e "${RED}Ollama is not installed.${NC}"
            echo -e "${RED}0) Back${NC}"
            read -p $'\nChoose an option: ' opt
            [ "$opt" = "0" ] && return
        elif [ $status -eq 2 ]; then
            echo -e "${YELLOW}Ollama is not running or not responding.${NC}"
            echo -e "${RED}0) Back${NC}"
            read -p $'\nChoose an option: ' opt
            [ "$opt" = "0" ] && return
        else
            echo
            echo -e "${RED}0) Back${NC}"
            read -p $'\nChoose a model to install: ' opt
            if [ "$opt" = "0" ]; then
                return
            elif [[ "$opt" =~ ^[0-9]+$ ]] && [ "$opt" -ge 1 ] && [ "$opt" -le $total ]; then
                if [ "$opt" -le "${#CODE_MODELS[@]}" ]; then
                    model="${CODE_MODELS[$((opt-1))]}"
                else
                    idx=$((opt-1-${#CODE_MODELS[@]}))
                    model="${GENERAL_MODELS[$idx]}"
                fi
                if [[ " ${installed[*]} " == *" $model "* ]]; then
                    echo -e "${YELLOW}This model is already installed.${NC}"
                    sleep 1
                else
                    install_model "$model"
                fi
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
                echo -e "${RED}0) Back${NC}"
                read -p $'\nChoose an option: ' opt
                [ "$opt" = "0" ] && return
                ;;
            "Stopped")
                echo -e "1) Start"
                echo -e "2) Models"
                echo -e "\n${RED}0) Back${NC}"
                read -p $'\nChoose an option: ' opt
                case $opt in
                    1) start_ollama ;;
                    2) models_menu ;;
                    0) return ;;
                    *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
                esac
                ;;
            "Running")
                echo -e "1) Stop"
                echo -e "2) Models"
                echo -e "3) Log"
                echo -e "\n${RED}0) Back${NC}"
                read -p $'\nChoose an option: ' opt
                case $opt in
                    1) stop_ollama ;;
                    2) models_menu ;;
                    3) ollama_log_menu ;;
                    0) return ;;
                    *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
                esac
                ;;
        esac
    done
}

ollama_menu
