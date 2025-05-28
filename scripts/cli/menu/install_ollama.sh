#!/bin/bash

RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

if ! command -v brew &> /dev/null; then
    echo -e "${RED}Homebrew is not installed. Please install Homebrew first.${NC}"
    echo
    read -n 1 -s -r -p "Press any key to return to the menu..."
    exit 1
fi

if command -v ollama &> /dev/null; then
    echo -e "${GREEN}Ollama is already installed.${NC}"
    echo
    read -n 1 -s -r -p "Press any key to return to the menu..."
    exit 0
fi

echo -e "Installing Ollama via Homebrew..."
brew install ollama

if command -v ollama &> /dev/null; then
    echo -e "${GREEN}Ollama installed successfully!${NC}"
else
    echo -e "${RED}Failed to install Ollama.${NC}"
fi
echo
read -n 1 -s -r -p "Press any key to return to the menu..."
