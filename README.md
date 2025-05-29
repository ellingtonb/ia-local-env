# AI Local Environment

This project provides a local environment for running and managing AI models and tools via the terminal.

## Features

- Ollama
- Open WebUI

## Prerequisites
- macOS or Linux (recommended)
- Bash shell
- [Homebrew](https://brew.sh/) (for macOS)
- Docker (for some features)

## Getting Started

1. **Clone the repository:**
```sh
git clone https://github.com/ellingtonb/ia-local-env.git && cd ia-local-env
```

2. **Add executable permissions:**
```sh
find . -type f -name "*.sh" -exec chmod +x {} \;
```

3. **Run the main script:**
```sh
./run.sh
```
- Follow the on-screen instructions to install, update, or run AI models.

## File Structure
- `run.sh`: Main entry point for terminal usage.
- `recommended_models`: List of recommended AI models.

## License
MIT

