#!/usr/bin/env bash
#
# Instala o visual WhiteSur (GTK + ícones + cursores) usado neste sistema.
# Os temas não são versionados no git (~271 MB) — este script baixa e instala.
#
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Clonando repositórios do tema"
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git   "$WORK/WhiteSur-gtk-theme"
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git   "$WORK/WhiteSur-icon-theme"
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-cursors.git      "$WORK/WhiteSur-cursors"

echo
echo "==> GTK theme (Light + Dark, só seu usuário)"
"$WORK/WhiteSur-gtk-theme/install.sh" -t both -l -c only -i

echo
echo "==> Ícones (WhiteSur + WhiteSur-dark + variantes macOS)"
"$WORK/WhiteSur-icon-theme/install.sh"

echo
echo "==> Cursores (macOS)"
"$WORK/WhiteSur-cursors/install.sh"

echo
echo "==> Aplicando no GNOME"
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'macOS'
gsettings set org.gnome.desktop.interface font-name 'Inter 11'
gsettings set org.gnome.desktop.interface document-font-name 'Inter 11'

echo
echo "Concluído. Reinicie a sessão para o cursor/tema aplicar em tudo."
