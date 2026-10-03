#!/usr/bin/env bash
#
# Habilita os repositórios extras usados neste sistema.
# Rode como usuário normal — o script chama sudo quando precisa.
#
set -euo pipefail

echo "==> RPM Fusion (free + nonfree, inclui driver NVIDIA e Steam)"
sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

echo
echo "==> Copr: Ghostty (scottames:ghostty)"
sudo dnf copr enable -y scottames/ghostty

echo
echo "==> Copr: PyCharm (phracek:PyCharm)"
sudo dnf copr enable -y phracek/PyCharm

echo
echo "==> Spotify (negativo17)"
sudo dnf config-manager setopt fedora-spotify.enabled=1 2>/dev/null || true

echo
echo "==> Google Chrome"
sudo dnf install -y https://dl.google.com/linux/linux_signing_key.pub 2>/dev/null || true
cat <<'EOF' | sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
enabled=1
EOF

echo
echo "==> Flatpak + Flathub"
sudo dnf install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo
echo "Repositórios prontos. Rode ./install.sh --packages para instalar os pacotes."
