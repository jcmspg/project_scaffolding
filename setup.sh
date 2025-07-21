#!/bin/bash

set -e

BIN_DIR="$HOME/bin"
CREATEPROJ_BIN="$BIN_DIR/createproj"
GENERATE_BIN="$BIN_DIR/generate_template.sh"
SHELL_RC=""

# Your local script versions (update when you modify scripts)
LOCAL_VERSION="1.0"

# Function to get installed version from the script (expects a VERSION=1.0 line)
get_installed_version() {
  if [ -f "$1" ]; then
    grep -Eo 'VERSION="[0-9.]+"' "$1" | cut -d'"' -f2 || echo "0"
  else
    echo "0"
  fi
}

print_help() {
  echo "Usage: $0 [install|uninstall]"
  echo ""
  echo "install   - Install createproj scripts"
  echo "uninstall - Remove installed scripts and clean PATH"
}

detect_shell_rc() {
  if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
  elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
  else
    SHELL_RC="$HOME/.profile"
  fi
}

backup_shell_rc() {
  if [ -f "$SHELL_RC" ]; then
    cp "$SHELL_RC" "${SHELL_RC}.bak.$(date +%s)"
    echo "Backed up $SHELL_RC to ${SHELL_RC}.bak.$(date +%s)"
  fi
}

install_scripts() {
  echo "Installing createproj tool..."

  mkdir -p "$BIN_DIR"

  # Check versions before overwriting
  local_installed_version=$(get_installed_version "$CREATEPROJ_BIN")
  if [[ "$local_installed_version" > "$LOCAL_VERSION" ]]; then
    echo "Installed createproj version ($local_installed_version) is newer than local ($LOCAL_VERSION). Skipping overwrite."
  else
    cp createproj generate_template.sh "$BIN_DIR/"
    chmod +x "$CREATEPROJ_BIN" "$GENERATE_BIN"
    echo "Copied scripts to $BIN_DIR"
  fi

  detect_shell_rc

  backup_shell_rc

  # Add to PATH if not already
  if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$SHELL_RC" 2>/dev/null; then
    echo '' >> "$SHELL_RC"
    echo '# Add ~/bin to PATH for createproj tool' >> "$SHELL_RC"
    echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_RC"
    echo "Added ~/bin to PATH in $SHELL_RC"
  else
    echo "~/bin already in PATH ($SHELL_RC)"
  fi

  echo ""
  echo "Installation complete! Restart your terminal or run:"
  echo "  source $SHELL_RC"
}

uninstall_scripts() {
  echo "Uninstalling createproj tool..."

  detect_shell_rc
  backup_shell_rc

  # Remove scripts
  rm -f "$CREATEPROJ_BIN" "$GENERATE_BIN"
  echo "Removed scripts from $BIN_DIR"

  # Remove PATH export line
  sed -i '/# Add ~\/bin to PATH for createproj tool/,+1d' "$SHELL_RC"
  echo "Removed PATH export from $SHELL_RC"

  echo ""
  echo "Uninstallation complete! Restart your terminal or run:"
  echo "  source $SHELL_RC"
}

# Main
if [ $# -ne 1 ]; then
  print_help
  exit 1
fi

case "$1" in
  install)
    install_scripts
    ;;
  uninstall)
    uninstall_scripts
    ;;
  *)
    print_help
    exit 1
    ;;
esac
