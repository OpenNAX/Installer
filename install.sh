#!/bin/sh

VERSION="v1.0.0"

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'
BOLD='\033[1m'

clear
printf "%b\n" "${CYAN}${BOLD}"
echo "    ███████                                  ██████   █████   █████████   █████ █████ "
echo "  ███░░░░░███                               ░░██████ ░░███   ███░░░░░███ ░░███ ░░███  "
echo " ███     ░░███ ████████   ██████  ████████   ░███░███ ░███  ░███    ░███  ░░███ ███   "
echo "░███      ░███░░███░░███ ███░░███░░███░░███  ░███░░███░███  ░███████████   ░░█████    "
echo "░███      ░███ ░███ ░███░███████  ░███ ░███  ░███ ░░██████  ░███░░░░░███    ███░███   "
echo "░░███     ███  ░███ ░███░███░░░   ░███ ░███  ░███  ░░█████  ░███    ░███   ███ ░░███  "
echo " ░░░███████░   ░███████ ░░██████  ████ █████ █████  ░░█████ █████   █████ █████ █████ "
echo "   ░░░░░░░     ░███░░░   ░░░░░░  ░░░░ ░░░░░ ░░░░░    ░░░░░ ░░░░░   ░░░░░ ░░░░░ ░░░░░  "
echo "               ░███                                                                   "
printf "%b\n" "               █████"
printf "%b\n" "              ░░░░░                                                                   ${NC}"
echo ""

print_info() { printf "%b\n" "${CYAN}[*] $1${NC}"; }
print_success() { printf "%b\n" "${GREEN}[+] $1${NC}"; }
print_warning() { printf "%b\n" "${YELLOW}[!] $1${NC}"; }
print_error() { printf "%b\n" "${RED}[ERROR] $1${NC}"; exit 1; }

CLEANUP_ZIP=""
CLEANUP_DIR=""

cleanup() {
    EXIT_CODE=$?
    if [ -n "$CLEANUP_ZIP" ] || [ -n "$CLEANUP_DIR" ]; then
        echo ""
        print_warning "Installation interrupted or failed. Rolling back changes..."
        if [ -n "$CLEANUP_ZIP" ] && [ -f "$CLEANUP_ZIP" ]; then
            rm -f "$CLEANUP_ZIP"
            print_warning "Removed incomplete download: $CLEANUP_ZIP"
        fi
        if [ -n "$CLEANUP_DIR" ] && [ -d "$CLEANUP_DIR" ]; then
            rm -rf "$CLEANUP_DIR"
            print_warning "Removed incomplete extraction: $CLEANUP_DIR"
        fi
    fi
    exit $EXIT_CODE
}

trap cleanup INT TERM HUP EXIT

OS_TYPE="unknown"
if [ -n "$TERMUX_VERSION" ]; then
    OS_TYPE="termux"
elif [ "$(uname -s)" = "Darwin" ]; then
    OS_TYPE="macos"
elif command -v apt >/dev/null 2>&1; then
    OS_TYPE="debian"
elif command -v dnf >/dev/null 2>&1; then
    OS_TYPE="fedora"
elif command -v pacman >/dev/null 2>&1; then
    OS_TYPE="arch"
else
    print_warning "Unsupported OS. Proceeding with manual dependency assumptions."
fi

check_deps() {
    if [ "$OS_TYPE" = "macos" ]; then
        return
    fi

    NEEDS_INSTALL=0
    if ! command -v unzip >/dev/null 2>&1; then
        NEEDS_INSTALL=1
    fi

    if [ "$NEEDS_INSTALL" -eq 1 ]; then
        print_info "Installing missing minimal dependencies (unzip)..."
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
                print_error "Required tools ('unzip') are missing and could not be installed automatically."
                ;;
        esac
    fi
}

install_project() {
    PROJ_NAME=$1
    ZIP_URL="https://github.com/OpenNAX/${PROJ_NAME}/archive/refs/heads/main.zip"
    ZIP_FILE="${PROJ_NAME}.zip"
    EXTRACT_DIR="${PROJ_NAME}-main"

    CLEANUP_ZIP="$ZIP_FILE"
    CLEANUP_DIR="$EXTRACT_DIR"

    echo ""
    print_info "Downloading ${PROJ_NAME}..."
    curl -s -L -o "$ZIP_FILE" "$ZIP_URL" || print_error "Failed to download ${PROJ_NAME}. Check your connection."
    
    print_info "Extracting ${PROJ_NAME}..."
    unzip -q -o "$ZIP_FILE" || print_error "Failed to extract ${PROJ_NAME}. Zip file may be corrupted."
    
    rm -rf "${PROJ_NAME}"
    mv "$EXTRACT_DIR" "${PROJ_NAME}"
    rm -f "$ZIP_FILE"

    if [ -d "${PROJ_NAME}" ]; then
        find "${PROJ_NAME}" -type f -name "*.sh" -exec chmod +x {} \;
    fi

    CLEANUP_ZIP=""
    CLEANUP_DIR=""

    print_success "${PROJ_NAME} installed in ./${PROJ_NAME}/"
}

printf "%b\n" "What would you like to install?\n"
printf "%b\n" "  ${BOLD}1)${NC} OpenNAX AILab"
printf "%b\n" "  ${BOLD}0)${NC} Exit"
echo ""

if [ -t 0 ]; then
    printf "Select an option [0-1] (Default: 1): "
    read choice
    choice=${choice:-1}
else
    print_info "Non-interactive mode detected. Defaulting to 1 (AILab)."
    choice=1
fi

case $choice in
    1)
        check_deps
        install_project "AILab"
        ;;
    0)
        print_info "Exiting..."
        exit 0
        ;;
    *)
        print_error "Invalid option selected."
        ;;
esac

echo ""
printf "%b\n" "${GREEN}-----------------------------------------------------${NC}"
printf "%b\n" "${BOLD}Installation complete!${NC}"
printf "%b\n" "${GREEN}-----------------------------------------------------${NC}"