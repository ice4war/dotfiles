GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'
BOLD='\e[1m'
NORMAL='\e[0m'
set -eux

install_configs () {
    echo -e "${CYAN}[+] Creating folders...${RESET}"
    mkdir -p ~/{.icons,.themes,.fonts} 2>/dev/null

    echo -e "${CYAN}[+] Installing configurations...${RESET}"
    cp -rf config/* ~/.config/ 2>/dev/null

    echo -e "${CYAN}[+] Installing fonts...${RESET}"
    cp -fr fonts/*.ttf ~/.fonts 2>/dev/null

    echo -e "${CYAN}[+] Installing tmux...${RESET}"

    mkdir -p $HOME/.tmux/plugins 2>/dev/null
    git clone --depth=1 https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
    cp -r .tmux.conf $HOME 2>/dev/null

    echo -e "${GREEN}${BOLD}Done..${NORMAL}${RESET}"
}

if [ -d ~/.config ]; then
    install_configs
else
    mkdir ~/.config
    install_configs
fi
