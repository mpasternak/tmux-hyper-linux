#!/bin/bash
# Instalator tmux-hyper-linux (Debian/Ubuntu). Uruchom jako zwykly user:
#   ./install.sh
# Sam poprosi o sudo tam, gdzie trzeba.
set -euo pipefail
cd "$(dirname "$0")"

echo ">> Pakiety: keyd tmux wl-clipboard"
sudo apt-get install -y keyd tmux wl-clipboard

# Stare ustawienie caps:* w GNOME koliduje z keyd -- zdejmij je.
if command -v gsettings >/dev/null; then
    opts=$(gsettings get org.gnome.desktop.input-sources xkb-options)
    if [[ "$opts" == *caps:* ]]; then
        echo ">> UWAGA: GNOME ma ustawione $opts -- usun opcje caps:*,"
        echo "   bo bedzie sie gryzc z keyd (gnome-tweaks / gsettings)."
    fi
fi

echo ">> keyd: /etc/keyd/default.conf"
if [[ -f /etc/keyd/default.conf ]]; then
    sudo cp /etc/keyd/default.conf "/etc/keyd/default.conf.bak.$(date +%s)"
fi
sudo install -Dm644 keyd/default.conf /etc/keyd/default.conf
sudo systemctl enable keyd
sudo systemctl restart keyd
systemctl is-active keyd

# Debian/Ubuntu nazywa binarke keyd.rvaiya (konflikt nazw z innym pakietem).
KEYD=$(command -v keyd || command -v keyd.rvaiya || echo keyd)

echo ">> tmux: ~/.tmux.conf"
if [[ -f ~/.tmux.conf ]] && ! cmp -s tmux.conf ~/.tmux.conf; then
    cp ~/.tmux.conf ~/.tmux.conf.bak."$(date +%s)"
    echo "   (stary ~/.tmux.conf -> backup)"
fi
cp tmux.conf ~/.tmux.conf
if tmux info >/dev/null 2>&1; then
    tmux source-file ~/.tmux.conf
fi

echo ">> Gotowe. Test: sudo $(basename "$KEYD") monitor, potem tmux i Caps+N."
