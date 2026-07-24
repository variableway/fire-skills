#!/usr/bin/env bash
# Extract a skill from mono-repo into its own standalone repo
# Usage: ./scripts/extract-skill.sh <skill-name> [--private|--public]
#
# This script:
# 1. Creates a temp directory
# 2. Initializes a git repo
# 3. Copies skill files
# 4. Creates GitHub repo
# 5. Pushes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REMOTE_BASE="git@github.com:variableway"

# Skills list: "repo-name|source-path"
SKILLS_LIST=(
    "skill-anysearch|skills/base/anysearch"
    "skill-gh-create-release|skills/devops/gh-create-release"
    "skill-git-workflow|skills/devops/git-workflow"
    "skill-github-cli|skills/devops/github-cli-skill"
    "skill-local-workflow|skills/devops/local-workflow"
    "skill-scanning-secrets|skills/devops/scanning-for-secrets"
    "skill-creator|skills/meta/skill-creator"
    "skill-test-case-generator|skills/qa/test-case-generator"
    "skill-find-skills|skills/shared/find-skills"
    "skill-scaffold-app|skills/shared/scaffold-app"
    "skill-thought-distiller|skills/figures/thought-distiller"
    "skill-design|skills/content/design"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
    cat <<EOF
Extract Skill to Independent Repo

Usage: $0 <skill-name> [--private|--public]

This extracts a skill from the mono-repo into its own standalone GitHub repo.

Examples:
  $0 skill-anysearch
  $0 skill-git-workflow --private
  $0 skill-design --public

Available skills:
$(for entry in "${SKILLS_LIST[@]}"; do
    repo="${entry%%|*}"
    path="${entry#*|}"
    echo "  $repo → $path"
done)
EOF
}

get_source_path() {
    local skill="$1"
    for entry in "${SKILLS_LIST[@]}"; do
        local repo="${entry%%|*}"
        local path="${entry#*|}"
        if [[ "$repo" == "$skill" ]]; then
            echo "$path"
            return 0
        fi
    done
    log_error "Unknown skill: $skill"
    log_info "Available skills:"
    for entry in "${SKILLS_LIST[@]}"; do
        echo "  ${entry%%|*}"
    done
    exit 1
}

extract_skill() {
    local skill="$1"
    local visibility="${2:---private}"
    local src_path
    src_path=$(get_source_path "$skill")

    if [[ ! -d "$REPO_ROOT/$src_path" ]]; then
        log_error "Source directory not found: $REPO_ROOT/$src_path"
        exit 1
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local repo_dir="$tmp_dir/$skill"

    log_info "Extracting $skill from $src_path..."
    log_info "Temp directory: $tmp_dir"

    # Copy skill files
    mkdir -p "$repo_dir"
    cp -R "$REPO_ROOT/$src_path/." "$repo_dir/"

    # Initialize git repo
    cd "$repo_dir"
    git init
    git checkout -b main

    # Add all files
    git add -A
    git commit -m "Initial commit: extract $skill from fire-skills mono-repo"

    # Create GitHub repo
    if command -v gh &>/dev/null; then
        log_info "Creating GitHub repo: $skill ($visibility)"
        gh repo create "$REMOTE_BASE/$skill" "$visibility" --source="." --push
        log_ok "Repo created and pushed: $REMOTE_BASE/$skill"
    else
        log_warn "GitHub CLI not found. Manual steps:"
        log_warn "  1. Create repo on GitHub: $REMOTE_BASE/$skill"
        log_warn "  2. git remote add origin $REMOTE_BASE/$skill.git"
        log_warn "  3. git push -u origin main"
    fi

    # Cleanup
    rm -rf "$tmp_dir"
    log_ok "Extraction complete!"
}

# Main
SKILL="${1:-}"
VISIBILITY="${2:---private}"

case "$SKILL" in
    ""|"--help"|"-h")
        usage
        exit 0
        ;;
    *)
        extract_skill "$SKILL" "$VISIBILITY"
        ;;
esac
