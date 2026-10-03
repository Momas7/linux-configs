#!/usr/bin/env bash
#
# Coleta as configurações ativas deste sistema para dentro do repositório.
# Rode de novo sempre que mudar alguma configuração para atualizar o snapshot.
#
#   ./snapshot.sh
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_HOME="$HOME"

OUT_HOME="$REPO_DIR/home"
OUT_CONFIG="$REPO_DIR/config"
OUT_GNOME="$REPO_DIR/gnome"
OUT_APPS="$REPO_DIR/apps"
OUT_SYSTEM="$REPO_DIR/system"

# ---------------------------------------------------------------- helpers ---

copiar() {
    # copiar <origem> <destino>
    local src="$1" dst="$2"
    if [ -e "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        echo "  + ${dst#"$REPO_DIR"/}"
    else
        echo "  - ausente: $src"
    fi
}

# ------------------------------------------------------------------- home ---

echo "== Shell e git =="
for f in .bashrc .bash_profile .bash_logout .gitconfig; do
    copiar "$SRC_HOME/$f" "$OUT_HOME/$f"
done

echo "== Entradas de aplicativo (.desktop) =="
if [ -d "$SRC_HOME/.local/share/applications" ]; then
    for f in "$SRC_HOME/.local/share/applications"/*.desktop; do
        [ -e "$f" ] || continue
        copiar "$f" "$OUT_HOME/.local/share/applications/$(basename "$f")"
    done
fi

# ----------------------------------------------------------------- config ---

echo "== ~/.config =="

CONFIG_FILES=(
    "gtk-3.0/settings.ini"
    "gtk-4.0/settings.ini"
    "ghostty/config.ghostty"
    "spicetify/config-xpui.ini"
    "gh/config.yml"
    "user-dirs.dirs"
    "user-dirs.locale"
    "mimeapps.list"
    "monitors.xml"
)

for f in "${CONFIG_FILES[@]}"; do
    copiar "$SRC_HOME/.config/$f" "$OUT_CONFIG/$f"
done

# ------------------------------------------------------------------ gnome ---

echo "== GNOME =="

mkdir -p "$OUT_GNOME"
if command -v dconf >/dev/null 2>&1; then
    dconf dump / > "$OUT_GNOME/dconf.ini"
    echo "  + gnome/dconf.ini ($(wc -l < "$OUT_GNOME/dconf.ini") linhas)"
fi

if command -v gnome-extensions >/dev/null 2>&1; then
    gnome-extensions list > "$OUT_GNOME/extensions.txt"
    echo "  + gnome/extensions.txt"
fi

if command -v gnome-shell >/dev/null 2>&1; then
    gnome-shell --version > "$OUT_GNOME/shell-version.txt"
fi

# ------------------------------------------------------------------- apps ---

echo "== Aplicativos =="
VS_CODE="$SRC_HOME/.var/app/com.visualstudio.code/config/Code/User"
ZED="$SRC_HOME/.var/app/dev.zed.Zed/config/zed"

copiar "$VS_CODE/settings.json"   "$OUT_APPS/vscode/settings.json"
copiar "$SRC_HOME/.vscode/argv.json" "$OUT_APPS/vscode/argv.json"
copiar "$ZED/settings.json"       "$OUT_APPS/zed/settings.json"

# ----------------------------------------------------------------- system ---

echo "== Sistema =="

mkdir -p "$OUT_SYSTEM"

if command -v rpm >/dev/null 2>&1; then
    rpm -qa --qf '%{NAME}\n' | LC_ALL=C sort -u > "$OUT_SYSTEM/packages-rpm.txt"
    echo "  + system/packages-rpm.txt ($(wc -l < "$OUT_SYSTEM/packages-rpm.txt") pacotes)"
fi

if command -v flatpak >/dev/null 2>&1; then
    flatpak list --app --columns=application,branch,origin 2>/dev/null \
        > "$OUT_SYSTEM/flatpak.txt" || true
    echo "  + system/flatpak.txt"
fi

if [ -d /etc/yum.repos.d ]; then
    find /etc/yum.repos.d -name '*.repo' -printf '%f\n' | LC_ALL=C sort \
        > "$OUT_SYSTEM/repos.txt"
    echo "  + system/repos.txt"
fi

if command -v gnome-extensions >/dev/null 2>&1; then
    gnome-extensions list | while read -r ext; do
        rpm -qf "/usr/share/gnome-shell/extensions/$ext" 2>/dev/null \
            || echo "manual: $ext"
    done > "$OUT_SYSTEM/extensions-packages.txt"
fi

{
    echo "os=$(. /etc/os-release && echo "$PRETTY_NAME")"
    echo "kernel=$(uname -r)"
    echo "desktop=$(echo "${XDG_CURRENT_DESKTOP:-}")"
    echo "shell=${SHELL:-}"
    echo "data=$(date -I)"
} > "$OUT_SYSTEM/vars.txt"
echo "  + system/vars.txt"

# ------------------------------------------------------------------ guard ---

echo "== Varredura de segredos =="

PADRAO='(ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|"password"[[:space:]]*:|"token"[[:space:]]*:|oauth_token:)'

falhas=0
while IFS= read -r arquivo; do
    # o próprio script contém o padrão de busca — não é um segredo
    [ "$arquivo" = "$REPO_DIR/snapshot.sh" ] && continue
    if grep -Iq . "$arquivo" 2>/dev/null && grep -IEn "$PADRAO" "$arquivo" >/dev/null 2>&1; then
        echo "  !! POSSÍVEL SEGREDO em ${arquivo#"$REPO_DIR"/}"
        grep -IEn "$PADRAO" "$arquivo" | sed 's/^/     /' | cut -c1-160
        falhas=$((falhas + 1))
    fi
done < <(find "$REPO_DIR" \
            -path "$REPO_DIR/.git" -prune -o -type f -print)

if [ "$falhas" -gt 0 ]; then
    echo
    echo "ERRO: $falhas arquivo(s) com possível segredo. Corrija antes de commitar."
    exit 1
fi

echo "  ok, nada sensível encontrado."
echo
echo "Snapshot concluído. Revise com: git -C \"$REPO_DIR\" status"
