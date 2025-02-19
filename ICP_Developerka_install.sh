#!/bin/bash

# Sprawdzenie czy skrypt nie jest uruchomiony jako root
if [ "$(id -u)" = "0" ]; then
    echo "❌ Błąd: Ten skrypt nie powinien być uruchamiany jako root"
    echo "Uruchom go jako normalny użytkownik: ./install_dev.sh"
    exit 1
fi

TOTAL_STEPS=12
CURRENT_STEP=0

show_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local completed=$((percent / 2))
    local remaining=$((50 - completed))
    
    echo -ne "\rPostęp instalacji: ["
    for ((i = 0; i < completed; i++)); do echo -n "#"; done
    for ((i = 0; i < remaining; i++)); do echo -n " "; done
    echo -ne "] ${percent}%"
    echo
}

execute_step() {
    echo -e "\n🔹 $1..."
    if eval "$2"; then
        echo "✅ Sukces: $1"
        show_progress
    else
        echo "❌ Błąd: $1"
        exit 1
    fi
}

echo "🔄 Rozpoczynam instalację środowiska na Ubuntu..."


execute_step "Instalacja wymaganych pakietów systemowych" "sudo apt update && sudo apt install -y curl wget gpg"

execute_step "Dodawanie repozytorium Microsoft" "
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg &&
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg &&
    sudo sh -c 'echo \"deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main\" > /etc/apt/sources.list.d/vscode.list' &&
    rm -f packages.microsoft.gpg &&
    sudo apt update &&
    sudo apt install -y code
"
execute_step "Instalacja NVM (Node Version Manager)" "
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash &&
    export NVM_DIR=\"\$HOME/.nvm\" &&
    [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


if ! command -v nvm &> /dev/null; then
    echo "❌ Błąd: NVM nie został poprawnie zainstalowany!"
    echo "Spróbuj wykonać następujące kroki:"
    echo "1. source ~/.bashrc"
    echo "2. source \$HOME/.nvm/nvm.sh"
    exit 1
fi

execute_step "Instalacja Node.js (LTS)" "nvm install --lts && nvm use --lts"
execute_step "Sprawdzenie wersji Node.js" "node -v"
execute_step "Aktualizacja npm" "npm install -g npm"


execute_step "Instalacja DFINITY SDK (dfx)" "
    DFX_VERSION=\"0.14.1\" sh -ci \"\$(curl -fsSL https://internetcomputer.org/install.sh)\" &&
    mkdir -p \$HOME/.config/dfx &&
    chmod 755 \$HOME/.config/dfx
"


execute_step "Konfiguracja PATH dla dfx" "
    echo 'export PATH=\"\$PATH:\$HOME/.local/share/dfx/bin\"' >> \$HOME/.bashrc &&
    echo 'source \"\$HOME/.local/share/dfx/env\"' >> \$HOME/.bashrc &&
    export PATH=\"\$PATH:\$HOME/.local/share/dfx/bin\" &&
    source \"\$HOME/.local/share/dfx/env\"
"


if ! command -v dfx &> /dev/null; then
    echo "❌ Błąd: dfx nie został poprawnie zainstalowany!"
    echo "Spróbuj wykonać następujące kroki:"
    echo "1. export PATH=\"\$PATH:\$HOME/.local/share/dfx/bin\""
    echo "2. source \$HOME/.local/share/dfx/env"
    exit 1
fi


execute_step "Aktywacja środowiska" "
    source \$HOME/.bashrc &&
    source \$HOME/.profile
"

echo -e "\n✅ Instalacja zakończona pomyślnie!"
echo "Zainstalowano:"
echo "  - curl, wget, gpg"
echo "  - NVM + Node.js (LTS)"
echo "  - npm"
echo "  - DFINITY SDK (dfx)"
echo "  - Visual Studio Code"
echo -e "\nŚrodowisko Developerskie skrojone pod ICP jest gotowe do użycia."
echo -e "Aby zacząć nowy projekt, użyj komendy: dfx new <nazwa_projektu>"
