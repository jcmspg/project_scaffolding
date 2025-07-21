#!/bin/bash
VERSION="1.0"
# ========== Config ==========
TEMPLATE_DIR="$HOME/.createproj_templates"
PROJECT_DIR="$PWD"
SCRIPT_DIR="$(dirname "$0")"  # to locate generate_template.sh

# ========== Help ==========
print_help() {
  echo "Usage: createproj [options] <project-name>"
  echo ""
  echo "Options:"
  echo "  --lang <language>      Language type: c, cpp, rust, go, python, js, html"
  echo "  --github               Automatically create and push to a GitHub repo (requires 'gh' CLI)"
  echo "  -h, --help             Show this help menu"
  echo ""
  echo "Examples:"
  echo "  createproj --lang c mytool"
  echo "  createproj --lang python myscript --github"
}

# ========== Argument Parsing ==========
LANG=""
PROJECT_NAME=""
USE_GITHUB=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --lang)
      LANG="$2"
      shift 2
      ;;
    --github)
      USE_GITHUB=true
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME="$1"
      else
        echo "Unknown argument: $1"
        print_help
        exit 1
      fi
      shift
      ;;
  esac
done

# ========== Validations ==========
if [[ -z "$PROJECT_NAME" || -z "$LANG" ]]; then
  echo "Error: --lang and project name are required."
  print_help
  exit 1
fi

LANG_TEMPLATE="$TEMPLATE_DIR/$LANG"
TARGET_DIR="$PROJECT_DIR/$PROJECT_NAME"

# ========== Auto-generate missing template ==========
if [ ! -d "$LANG_TEMPLATE" ]; then
  echo "Template for '$LANG' not found. Generating..."
  if [ -x "$SCRIPT_DIR/generate_template.sh" ]; then
    "$SCRIPT_DIR/generate_template.sh" "$LANG"
  else
    echo "Error: generate_template.sh not found or not executable."
    exit 1
  fi

  # Recheck after generation
  if [ ! -d "$LANG_TEMPLATE" ]; then
    echo "Error: Failed to generate template for '$LANG'"
    exit 1
  fi
fi

# ========== Project Creation ==========
echo "Creating $LANG project: $PROJECT_NAME"
mkdir -p "$TARGET_DIR"
cp -r "$LANG_TEMPLATE/"* "$TARGET_DIR"

cd "$TARGET_DIR" || exit 1
git init >/dev/null
echo "# $PROJECT_NAME" > README.md

# ========== Optional GitHub Creation ==========
if [ "$USE_GITHUB" = true ]; then
  if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) not found. Install it or remove --github flag."
    exit 1
  fi

  echo "Creating GitHub repository..."
  gh repo create "$PROJECT_NAME" --source=. --public --push
fi

echo "✅ Project '$PROJECT_NAME' created successfully."
