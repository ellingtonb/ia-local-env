#!/bin/bash

# Always run from the script's directory
cd "$(dirname "$0")/../../.."

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
NC="\033[0m"

SCRIPT_DIR="$(pwd)"

open_webui_menu() {
    while true; do
        clear
        # Get container status
        local container_id=""
        local status="Not Started"
        local status_color="$RED"
        local exists=""
        local port="3000" # default from docker-compose
        local browser_url="http://localhost:$port"
        # Get port from docker-compose.yml if possible
        if [ -f "$SCRIPT_DIR/ui/docker-compose.yml" ]; then
            port=$(grep -A 2 'open-webui:' "$SCRIPT_DIR/ui/docker-compose.yml" | grep 'ports:' -A 1 | grep -o '^[^:]*' | grep -Eo '[0-9]+' | head -1)
            if [ -z "$port" ]; then
                port="3000"
            fi
            browser_url="http://localhost:$port"
        fi
        container_id=$(docker-compose -f "$SCRIPT_DIR/ui/docker-compose.yml" ps -q open-webui | cut -c1-12)
        exists="$container_id"
        if [ -n "$container_id" ]; then
            if docker ps -q | grep -q "$container_id"; then
                status="Running"
                status_color="$GREEN"
            elif docker ps -aq | grep -q "$container_id"; then
                status="Stopped"
                status_color="$YELLOW"
            fi
        fi
        echo -e "${CYAN}==========================="
        echo -e "        Open-WebUI        "
        echo -e "===========================${NC}"
        echo -e "Status: ${status_color}$status${NC}"
        if [ "$status" = "Running" ]; then
            echo -e "URL: ${CYAN}$browser_url${NC}\n"
        else
            echo
        fi

        # Check if Docker is installed
        if ! command -v docker &> /dev/null; then
            echo -e "${RED}Docker is required but not installed. Please install Docker to use Open-WebUI management.${NC}"
            echo
            echo -e "0) Back"
            read -p $'\nChoose an option: ' opt
            case $opt in
                0) break ;;
                *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
            esac
            continue
        fi

        # Check if Docker is running
        if ! docker info &> /dev/null; then
            echo -e "${YELLOW}Docker is installed but not running. Please start Docker to use Open-WebUI management.${NC}"
            echo
            echo -e "0) Back"
            read -p $'\nChoose an option: ' opt
            case $opt in
                0) break ;;
                *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
            esac
            continue
        fi

        if [ ! -d "$SCRIPT_DIR/ui" ]; then
            echo -e "${RED}Directory $SCRIPT_DIR/ui does not exist!${NC}"
            echo -e "${YELLOW}Please create the 'ui' directory and add a docker-compose.yml file to use Open-WebUI management.${NC}"
            echo
            echo -e "0) Back"
            read -p $'\nChoose an option: ' opt
            case $opt in
                0) break ;;
                *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
            esac
            continue
        fi

        # Check Open-WebUI container status
        local status_code=0
        if [ -n "$container_id" ]; then
            if docker ps -q | grep -q "$container_id"; then
                status_code=1
            fi
        elif docker ps -aq | grep -q "$container_id"; then
            status_code=2
        fi

        if [[ "$status_code" == "1" ]]; then
            echo -e "1) Stop"
        elif [[ "$status_code" == "2" ]]; then
            echo -e "1) Start"
            echo -e "2) Remove"
        elif [[ -n "$exists" ]]; then
            echo -e "1) Start"
        else
            echo -e "1) Start"
        fi
        echo
        echo -e "0) Back"
        read -p $'\nChoose an option: ' opt
        case $opt in
            1)
                if [[ "$status_code" == "1" ]]; then
                    (cd "$SCRIPT_DIR/ui" && docker-compose stop open-webui)
                    echo -e "${YELLOW}Stopping Open-WebUI...${NC}"
                else
                    (cd "$SCRIPT_DIR/ui" && docker-compose up -d open-webui)
                    echo -e "${GREEN}Starting Open-WebUI...${NC}"
                fi
                sleep 2
                ;;
            2)
                if [[ "$status_code" == "2" ]]; then
                    (cd "$SCRIPT_DIR/ui" && docker-compose rm -f open-webui)
                    echo -e "${YELLOW}Removing stopped Open-WebUI container...${NC}"
                    sleep 2
                else
                    echo -e "${RED}Invalid option!${NC}"; sleep 1
                fi
                ;;
            0) break ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

open_webui_menu

