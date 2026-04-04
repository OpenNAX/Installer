VERSION="v1.0.0"

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo -e "${CYAN}${BOLD}"
echo "    ███████                                  ██████   █████   █████████   █████ █████ "
echo "  ███░░░░░███                               ░░██████ ░░███   ███░░░░░███ ░░███ ░░███  "
echo " ███     ░░███ ████████   ██████  ████████   ░███░███ ░███  ░███    ░███  ░░███ ███   "
echo "░███      ░███░░███░░███ ███░░███░░███░░███  ░███░░███░███  ░███████████   ░░█████    "
echo "░███      ░███ ░███ ░███░███████  ░███ ░███  ░███ ░░██████  ░███░░░░░███    ███░███   "
echo "░░███     ███  ░███ ░███░███░░░   ░███ ░███  ░███  ░░█████  ░███    ░███   ███ ░░███  "
echo " ░░░███████░   ░███████ ░░██████  ████ █████ █████  ░░█████ █████   █████ █████ █████ "
echo "   ░░░░░░░     ░███░░░   ░░░░░░  ░░░░ ░░░░░ ░░░░░    ░░░░░ ░░░░░   ░░░░░ ░░░░░ ░░░░░  "
echo "               ░███                                                                   "
echo -e "               █████"
echo -e "              ░░░░░                                                                   ${NC}"
echo ""

print_info() { echo -e "${CYAN}[*] $1${NC}"; }
print_success() { echo -e "${GREEN}[+] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[!] $1${NC}"; }
print_error() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }

CLEANUP_ZIP=""
CLEANUP_DIR=""

cleanup() {
    local EXIT_CODE=$?
    if [[ -n "$CLEANUP_ZIP" ]] || [[ -n "$CLEANUP_DIR" ]]; then
        echo -e "\n${YELLOW}[!] Installation interrupted or failed. Rolling back changes...${NC}"
        if [[ -n "$CLEANUP_ZIP" && -f "$CLEANUP_ZIP" ]]; then
            rm -f "$CLEANUP_ZIP"
            print_info "[!] Removed incomplete download: $CLEANUP_ZIP"
        fi
        if [[ -n "$CLEANUP_DIR" && -d "$CLEANUP_DIR" ]]; then
            rm -rf "$CLEANUP_DIR"
            print_info "[!] Removed incomplete extraction: $CLEANUP_DIR"
        fi
    fi
    exit $EXIT_CODE
}

trap cleanup SIGINT SIGTERM SIGHUP EXIT

OS_TYPE="unknown"
if [[ -n "$TERMUX_VERSION" ]]; then
    OS_TYPE="termux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
elif command -v apt >/dev/null 2>&1; then
    OS_TYPE="debian"
elif command -v dnf >/dev/null 2>&1; then
    OS_TYPE="fedora"
elif command -v pacman >/dev/null 2>&1; then
    OS_TYPE="arch"
else
    print_warning "[!] Unsupported OS. Proceeding with manual dependency assumptions."
fi

check_deps() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        return
    fi

    local NEEDS_INSTALL=0
    if ! command -v unzip >/dev/null 2>&1; then
        NEEDS_INSTALL=1
    fi

    if [[ "$NEEDS_INSTALL" -eq 1 ]]; then
        print_info "[*] Installing missing minimal dependencies (unzip)..."
        case "$OS_TYPE" in
            "termux")
                pkg update -y > /dev/null 2>&1
                pkg install unzip -y > /dev/null 2>&1
                ;;
            "debian")
                sudo apt update -y > /dev/null 2>&1
                sudo apt install unzip -y > /dev/null 2>&1
                ;;
            "fedora")
                sudo dnf install unzip -y > /dev/null 2>&1
                ;;
            "arch")
                sudo pacman -Sy unzip --noconfirm > /dev/null 2>&1
                ;;
            *)
                print_error "[!] Required tools ('unzip') are missing and could not be installed automatically."
                ;;
        esac
    fi
}

install_project() {
    local PROJ_NAME=$1
    local ZIP_URL="https://github.com/OpenNAX/${PROJ_NAME}/archive/refs/heads/main.zip"
    local ZIP_FILE="${PROJ_NAME}.zip"
    local EXTRACT_DIR="${PROJ_NAME}-main"

    CLEANUP_ZIP="$ZIP_FILE"
    CLEANUP_DIR="$EXTRACT_DIR"

    echo ""
    print_info "[*] Downloading ${PROJ_NAME}..."
    curl -s -L -o "$ZIP_FILE" "$ZIP_URL" || print_error "[!] Failed to download ${PROJ_NAME}. Check your connection."
    
    print_info "[*] Extracting ${PROJ_NAME}..."
    unzip -q -o "$ZIP_FILE" || print_error "[!] Failed to extract ${PROJ_NAME}. Zip file may be corrupted."
    
    rm -rf "${PROJ_NAME}"
    mv "$EXTRACT_DIR" "${PROJ_NAME}"
    rm -f "$ZIP_FILE"

    if [ -d "${PROJ_NAME}" ]; then
        find "${PROJ_NAME}" -type f -name "*.sh" -exec chmod +x {} \;
    fi

    CLEANUP_ZIP=""
    CLEANUP_DIR=""

    print_success "[+] ${PROJ_NAME} installed in ./${PROJ_NAME}/"
}

echo -e "What would you like to install?\n"
echo -e "  ${BOLD}1)${NC} OpenNAX AILab (AI & Ollama Manager)"
echo -e "  ${BOLD}2)${NC} OpenNAX NetLab"
echo -e "  ${BOLD}3)${NC} Both (AILab & NetLab)"
echo -e "  ${BOLD}0)${NC} Exit"
echo ""

read -p "Select an option [0-3]: " choice

case $choice in
    1)
        check_deps
        install_project "AILab"
        ;;
    2)
        check_deps
        install_project "NetLab"
        ;;
    3)
        check_deps
        install_project "AILab"
        install_project "NetLab"
        ;;
    0)
        print_info "[*] Exiting..."
        exit 0
        ;;
    *)
        print_error "[!] Invalid option selected."
        ;;
esac

echo ""
echo -e "${GREEN}-----------------------------------------------------${NC}"
echo -e "${BOLD}Installation complete!${NC}"
echo -e "${GREEN}-----------------------------------------------------${NC}"