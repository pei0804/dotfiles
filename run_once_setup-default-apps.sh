#!/bin/bash
# Set default applications for file types using duti

if ! command -v duti &>/dev/null; then
  echo "duti not found, skipping default app setup"
  exit 0
fi

WEZTERM="com.github.wez.wezterm"

# Shell scripts
duti -s "$WEZTERM" .sh all
duti -s "$WEZTERM" .bash all
duti -s "$WEZTERM" .zsh all
duti -s "$WEZTERM" .fish all
duti -s "$WEZTERM" .csh all
duti -s "$WEZTERM" .ksh all
duti -s "$WEZTERM" .command all
duti -s "$WEZTERM" public.shell-script all

echo "Default apps configured."
