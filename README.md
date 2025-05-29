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

4. **Install Ollama:**

    If you don't have Ollama installed, you can install it through the menu `Ollama` -> `Install` in the terminal.


5. **Start Ollama:**

    You can start Ollama by selecting the `Ollama` -> `Start` option in the terminal.


6. **Install Models:**

    You can install models through the `Ollama` -> `Models` -> `Install` menu selecting from the list of recommended models, or you can input the name of the required model to install.


7. **Start Open WebUI:**

    Access the `Open-WebUI` menu in the terminal to start the web interface.
    
    Open the web interface in your browser at `http://localhost:3000`.


8. **It's All!**

    Check the other options in the terminal menu to explore more features and functionalities.

## File Structure
- `run.sh`: Main entry point for terminal usage.
- `recommended_models`: List of recommended AI models.

## License
MIT

