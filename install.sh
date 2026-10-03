#!/usr/bin/env bash
#
# Aplica as configurações deste repositório neste usuário.
#
#   ./install.sh              só arquivos + GNOME (padrão, seguro)
#   ./install.sh --dry-run    mostra o que faria, sem alterar nada
#   ./install.sh --packages   instala os pacotes dnf da lista
#   ./install.sh --flatpak    instala os apps flatpak da lista
#   ./install.sh --themes     instala tema/ícones/cursores WhiteSur
#   ./install.sh --all        tudo acima
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_HOME="$HOME"

DO_PACKAGES=0
DO_FLATPAK=0
DO_THEMES=0
DRY_RUN=0

for arg in "$@"; do
    case "$arg" in
        --packages) DO_PACKAGES=1 ;;
        --flatpak)  DO_FLATPAK=1 ;;
        --themes)   DO_THEMES=1 ;;
        --all)      DO_PACKAGES=1; DO_FLATPAK=1; DO_THEMES=1 ;;
        --dry-run)  DRY_RUN=1 ;;
        -h|--help)  grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "opção desconhecida: $arg"; exit 1 ;;
    esac
done

BACKUP_DIR="$DEST_HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
BACKUP_FEITO=0

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}

reservar() {
    # move o arquivo atual para o backup antes de sobrescrever
    local destino="$1"
    [ "$DRY_RUN" -eq 1 ] && return 0
    [ -e "$destino" ] || return 0
    if [ "$BACKUP_FEITO" -eq 0 ]; then
        mkdir -p "$BACKUP_DIR"
        BACKUP_FEITO=1
    fi
    local rel="${destino#"$DEST_HOME"/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$destino" "$BACKUP_DIR/$rel"
    echo "    backup -> ${BACKUP_DIR#"$DEST_HOME"/}/$rel"
}

instalar_arvore() {
    # instalar_arvore <origem> <destino>
    local src="$1" dst="$2"
    [ -d "$src" ] || return 0
    while IFS= read -r f; do
        local rel="${f#"$src"/}"
        reservar "$dst/$rel"
        run mkdir -p "$(dirname "$dst/$rel")"
        run cp -a "$f" "$dst/$rel"
        echo "  = ${dst#"$DEST_HOME"/}/$rel"
    done < <(find "$src" -type f)
}

echo "== Arquivos do home =="
instalar_arvore "$REPO_DIR/home" "$DEST_HOME"

echo
echo "== ~/.config =="
instalar_arvore "$REPO_DIR/config" "$DEST_HOME/.config"

echo
echo "== Aplicativos (VS Code / Zed) =="
if [ -f "$REPO_DIR/apps/vscode/settings.json" ]; then
    VS_DST="$DEST_HOME/.var/app/com.visualstudio.code/config/Code/User"
    reservar "$VS_DST/settings.json"
    run mkdir -p "$VS_DST"
    run cp -a "$REPO_DIR/apps/vscode/settings.json" "$VS_DST/settings.json"
    echo "  = .var/app/com.visualstudio.code/config/Code/User/settings.json"
fi
if [ -f "$REPO_DIR/apps/zed/settings.json" ]; then
    ZED_DST="$DEST_HOME/.var/app/dev.zed.Zed/config/zed"
    reservar "$ZED_DST/settings.json"
    run mkdir -p "$ZED_DST"
    run cp -a "$REPO_DIR/apps/zed/settings.json" "$ZED_DST/settings.json"
    echo "  = .var/app/dev.zed.Zed/config/zed/settings.json"
fi

echo
echo "== GNOME (dconf) =="
if [ -f "$REPO_DIR/gnome/dconf.ini" ] && command -v dconf >/dev/null 2>&1; then
    run dconf load / < "$REPO_DIR/gnome/dconf.ini"
    echo "  = dconf load /"
else
    echo "  - pulado (sem dconf ou sem gnome/dconf.ini)"
fi

echo
echo "== Extensões do GNOME =="
if [ -f "$REPO_DIR/system/extensions-packages.txt" ] && command -v dnf >/dev/null 2>&1; then
    mapfile -t EXT < <(grep -v '^manual:' "$REPO_DIR/system/extensions-packages.txt" | sort -u)
    if [ "${#EXT[@]}" -gt 0 ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "  [dry-run] dnf install -y ${EXT[*]}"
        else
            sudo dnf install -y "${EXT[@]}"
        fi
    fi
fi

if [ "$DO_PACKAGES" -eq 1 ]; then
    echo
    echo "== Pacotes dnf =="
    LISTA="$REPO_DIR/system/packages-notable.txt"
    if [ -f "$LISTA" ]; then
        mapfile -t PKGS < <(grep -vE '^(#|$)' "$LISTA")
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "  [dry-run] dnf install -y ${PKGS[*]}"
        else
            sudo dnf install -y "${PKGS[@]}"
        fi
        echo "  ${#PKGS[@]} pacotes"
    fi
fi

if [ "$DO_FLATPAK" -eq 1 ] && command -v flatpak >/dev/null 2>&1; then
    echo
    echo "== Flatpak =="
    if [ -s "$REPO_DIR/system/flatpak.txt" ]; then
        while read -r app _branch origin; do
            [ -n "$app" ] || continue
            if [ "$DRY_RUN" -eq 1 ]; then
                echo "  [dry-run] flatpak install -y ${origin:-flathub} $app"
            else
                flatpak install -y "${origin:-flathub}" "$app" || echo "  ! falhou: $app"
            fi
        done < <(tail -n +1 "$REPO_DIR/system/flatpak.txt" | grep -E '[a-zA-Z]')
    fi
fi

if [ "$DO_THEMES" -eq 1 ]; then
    echo
    echo "== Temas =="
    if [ -x "$REPO_DIR/themes/install-themes.sh" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "  [dry-run] themes/install-themes.sh"
        else
            "$REPO_DIR/themes/install-themes.sh"
        fi
    fi
fi

echo
if [ "$BACKUP_FEITO" -eq 1 ]; then
    echo "Arquivos antigos guardados em: $BACKUP_DIR"
fi
if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry-run: nada foi alterado."
else
    echo "Concluído. Faça logout/login (ou reinicie) para o GNOME aplicar tudo."
fi
