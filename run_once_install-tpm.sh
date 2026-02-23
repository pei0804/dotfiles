#!/bin/bash
# TPM (Tmux Plugin Manager) のインストール

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ ! -d "$TPM_DIR" ]; then
  echo "Installing TPM (Tmux Plugin Manager)..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  echo "TPM installed. Run 'prefix + I' inside tmux to install plugins."
else
  echo "TPM is already installed."
fi
