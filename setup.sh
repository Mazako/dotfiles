#!/bin/bash
set -e

SSH_KEY="$HOME/.ssh/id_ed25519"
CONF="/etc/pacman.conf"

log() {
  echo -e "\033[1;32m[✔]\033[0m $1"
}

error() {
  echo -e "\033[1;31m[✖]\033[0m $1" >&2
  exit 1
}

install_base() {
  log "Updating system and installing base packages..."
  sudo pacman -Syu --noconfirm
  sudo pacman -S --needed --noconfirm base-devel zsh git curl wget openssl zlib xz tk zstd eza nvidia nvidia-utils vim btop neofetch vlc kitty zip unzip cava
}

enable_multilib() {
  log "Enabling multilib repository..."
  sudo sed -i '/#\[multilib\]/,/^#Include/s/^#//' "$CONF"
  sudo pacman -Sy --noconfirm
  sudo pacman -S --needed --noconfirm lib32-nvidia-utils
}

install_yazi() {
  log "Installing Yazi file manager and its dependencies..."
  sudo pacman -S --needed --noconfirm yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick
}

install_yay() {
  if ! command -v yay &>/dev/null; then
    log "Installing yay..."
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir"
    (cd "$tmpdir" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
  else
    log "Yay already installed – skipping."
  fi
}

install_aur_apps() {
  log "Installing Brave and VS Code (AUR)..."
  yay -S --needed --noconfirm brave-bin visual-studio-code-bin
}

install_dev_tools() {
  log "Installing developer tools (fnm, sdkman, pyenv, docker)..."

  git config --global user.email "michal.maziarz12@gmail.com"
  git config --global user.name "Mazako"

  curl -fsSL https://fnm.vercel.app/install | bash
  curl -s "https://get.sdkman.io" | bash
  curl -fsSL https://pyenv.run | bash

  sudo pacman -S --needed --noconfirm docker docker-compose docker-buildx shellcheck
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"

  log "Docker enabled and added $USER to docker group (relogin required)."
}

setup_ssh_key() {
  if [ ! -f "$SSH_KEY" ]; then
    log "Generating new SSH key (ed25519, no passphrase)..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "michal.maziarz12@gmail.com" -N "" -f "$SSH_KEY"
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$SSH_KEY"
    log "SSH key created. Add this public key to GitHub/GitLab:"
    cat "${SSH_KEY}.pub"
  else
    log "SSH key already exists – skipping generation."
  fi
}

install_zsh() {
  log "Installing and configuring Oh My Zsh..."
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    log "Oh My Zsh already installed – skipping."
  fi

  # Plugins
  ZSH_PLUGINS="$HOME/.oh-my-zsh/plugins"
  mkdir -p "$ZSH_PLUGINS"
  if [ ! -d "$ZSH_PLUGINS/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_PLUGINS/zsh-autosuggestions"
  fi

  chsh -s "$(which zsh)"
  log "Zsh set as default shell."
}

install_jetbrains_toolbox() {
  local url="https://download.jetbrains.com/toolbox/jetbrains-toolbox-3.0.0.59313.tar.gz"
  local dest="$HOME/jetbrains-toolbox"
  local tmp="/tmp/jetbrains-toolbox.tar.gz"

  [ -d "$dest" ] && return

  curl -L "$url" -o "$tmp"
  mkdir -p "$dest"
  tar -xzf "$tmp" -C "$dest" --strip-components=1
  rm -f "$tmp"
  log "Toolbox installed successfully"
}

main() {
  install_base
  enable_multilib
  install_yazi
  install_yay
  install_aur_apps
  install_dev_tools
  setup_ssh_key
  install_jetbrains_toolbox
  install_zsh

  log "✅ All tasks completed!"
  echo "➡️  Relog or restart to finalize Docker and Zsh setup."
}

main "$@"
