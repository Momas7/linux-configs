# linux-configs

Minhas configurações de Linux — **Fedora Workstation 44 + GNOME**, com visual
WhiteSur (estilo macOS), terminal Ghostty/Ptyxis e setup de desenvolvimento.

Serve para restaurar esta máquina inteira em um sistema novo em poucos minutos.

---

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `home/` | Arquivos da home: `.bashrc`, `.bash_profile`, `.gitconfig`, entradas `.desktop` |
| `config/` | Espelho do `~/.config`: GTK, Ghostty, Spicetify, GitHub CLI, monitores, MIME |
| `gnome/` | `dconf.ini` (todas as preferências do GNOME) e extensões ativas |
| `apps/` | Configurações do VS Code e do Zed |
| `system/` | Lista de pacotes RPM, Flatpaks, repositórios e script de repositórios |
| `themes/` | Script que baixa e instala WhiteSur (GTK, ícones e cursores) |
| `install.sh` | Aplica tudo neste usuário |
| `snapshot.sh` | Recolhe as configs atuais do sistema para o repositório |

---

## Instalar do zero

```bash
git clone https://github.com/Momas7/linux-configs.git
cd linux-configs
```

**Só os arquivos (rápido e seguro):**

```bash
./install.sh
```

**Tudo — arquivos + pacotes + Flatpaks + temas:**

```bash
./system/setup-repos.sh   # habilita RPM Fusion, Copr, Flathub
./install.sh --all
```

Depois **faça logout e login** para o GNOME aplicar o dconf.

### Opções

| Opção | O que faz |
|---|---|
| *(nenhuma)* | Copia arquivos e carrega o dconf |
| `--dry-run` | Mostra o que faria, sem alterar nada |
| `--packages` | Instala a lista de `system/packages-notable.txt` via dnf |
| `--flatpak` | Instala os apps de `system/flatpak.txt` |
| `--themes` | Baixa e instala o visual WhiteSur |
| `--all` | Todas as opções acima |

Qualquer arquivo que já existir é movido para
`~/.dotfiles-backup-AAAA-MM-DD-HHMMSS/` antes de ser sobrescrito — nada é
destruído.

---

## Atualizar o repositório

Depois de mexer em alguma configuração no sistema, rode:

```bash
./snapshot.sh
git add -A
git commit -m "Atualiza configurações"
git push
```

O `snapshot.sh` tem uma **varredura de segredos** no final e aborta se achar
token, chave ou senha em algum arquivo.

---

## O que fica de fora

Arquivos que carregam credencial ou sessão nunca são versionados:

- `~/.config/gh/hosts.yml` — token do GitHub CLI
- `~/.config/opencode/service.json` — senha do serviço
- `~/.claude.json` e `~/.config/Claude/` — sessões e chaves
- `~/.config/dconf/user` (binário) — substituído pelo texto `gnome/dconf.ini`
- Temas, ícones e cursores WhiteSur (~271 MB) — instalados pelo
  `themes/install-themes.sh` em vez de ir para o git

O `.gitignore` bloqueia também `*.pem`, `id_rsa*`, `.env`, etc.

---

## Restauração completa, passo a passo

```bash
# 1. repositórios e flatpak
./system/setup-repos.sh

# 2. arquivos + GNOME + pacotes + apps + temas
./install.sh --all

# 3. layout de teclado customizado (repo separado)
git clone https://github.com/Momas7/dotfiles.git ~/.dotfiles-teclado
~/.dotfiles-teclado/scripts/setup-keyboard.sh

# 4. GitHub CLI
gh auth login

# 5. reiniciar
logout
```

---

## Sistema atual

| | |
|---|---|
| SO | Fedora Linux 44 (Workstation) |
| Desktop | GNOME |
| Tema GTK | WhiteSur-Dark |
| Ícones | WhiteSur-dark / WhiteSur |
| Cursores | macOS |
| Fonte | Inter 11 |
| Terminal | Ptyxis, Ghostty |
| Player | Spotify + Spicetify (tema Sleek) |
| Extensões | Dash to Dock, Apps Menu, Places Menu, Window List, User Theme, Background Logo |
| Navegadores | Firefox, Zen (Flatpak) |
| Editores | VS Code (Flatpak), Zed (Flatpak) |

O detalhamento completo está em `system/vars.txt` e `system/packages-rpm.txt`.

---

## Ver também

- [Momas7/dotfiles](https://github.com/Momas7/dotfiles) — layout de teclado
  `us(intl)` customizado para escrever em português (Caps Lock vira AltGr).
