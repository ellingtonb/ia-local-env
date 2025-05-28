#!/bin/bash

RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

if command -v brew &> /dev/null; then
    echo -e "${GREEN}Homebrew is already installed.${NC}"
    read -n 1 -s -r -p "\nPress any key to return to the menu..."
    exit 0
fi

echo -e "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if command -v brew &> /dev/null; then
    echo -e "${GREEN}Homebrew installed successfully!${NC}"
else
    echo -e "${RED}Failed to install Homebrew.${NC}"
fi
read -n 1 -s -r -p "\nPress any key to return to the menu..."
