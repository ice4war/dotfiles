GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'
BOLD='\e[1m'
NORMAL='\e[0m'

install_configs () {
    echo -e "${CYAN}[1] Creating folders...${RESET}"
    mkdir -p ~/{.icons,.themes,.fonts}
    echo -e "${CYAN}[2] Installing configurations...${RESET}"
    cp -rf config/* ~/.config/

    echo -e "${CYAN}[3] Installing fonts...${RESET}"
    cp -fr fonts/*.ttf ~/.fonts

    echo -e "${CYAN}[4] Installing themes..${RESET}"
    find ./themes -name "*.tar.xz" -exec tax xf {} -C ~/.themes \;

    echo -e "${CYAN}[5] Installing Neovim ...${RESET}"
    if [ ! -d ~/.config/nvim ]; then
        git clone https://github.com/LazyVim/starter ~/.config/nvim
        rm -rf ~/.config/nvim/.git
        rm -rf ~/.config/nvim/lua/plugins/example.lua
        cp nvim/*.lua ~/.config/nvim/lua/plugins/
    fi
    echo -e "${GREEN}${BOLD}Done..${NORMAL}${RESET}"
}

if [ -d ~/.config ]; then
    install_configs
else
    mkdir ~/.config
    install_configs
fi
