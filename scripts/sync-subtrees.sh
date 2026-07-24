#!/usr/bin/env bash
# Sync skills between mono-repo and individual repos via git subtree
# Usage: ./scripts/sync-subtrees.sh <action> [skill-name]
#   action: add | pull | push | split | list | create-repo
#   skill-name: (optional) specific skill to sync, or all if omitted

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REMOTE_BASE="git@github.com:variableway"
BRANCH="main"

# Skills list: "repo-name|subtree-prefix"
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

usage() {
    cat <<EOF
Fire-Skills Subtree Sync Tool

Usage: $0 <action> [skill-name]

Actions:
  add <skill>     Add a skill repo as subtree (first time)
  pull <skill>    Sync FROM individual repo TO mono-repo
  push <skill>    Sync FROM mono-repo TO individual repo
  split <skill>   Extract subtree into its own branch
  list            List all tracked skills and their status
  create-repo <skill>  Create GitHub repo for a skill

Examples:
  $0 add skill-anysearch
  $0 pull skill-git-workflow
  $0 push skill-creator
  $0 list
  $0 create-repo skill-anysearch
EOF
}

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

get_prefix() {
    local skill="$1"
    for entry in "${SKILLS_LIST[@]}"; do
        local repo="${entry%%|*}"
        local prefix="${entry#*|}"
        if [[ "$repo" == "$skill" ]]; then
            echo "$prefix"
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

get_remote_url() {
    local skill="$1"
    echo "$REMOTE_BASE/$skill.git"
}

do_add() {
    local skill="$1"
    local prefix
    prefix=$(get_prefix "$skill")
    local remote
    remote=$(get_remote_url "$skill")

    if [[ -d "$REPO_ROOT/$prefix" ]]; then
        log_warn "Directory already exists: $prefix"
        log_info "Use 'pull' to update instead"
        return 0
    fi

    log_info "Adding subtree: $skill → $prefix"
    cd "$REPO_ROOT"
    git subtree add --prefix="$prefix" "$remote" "$BRANCH" --squash
    log_ok "Added $skill"
}

do_pull() {
    local skill="$1"
    local prefix
    prefix=$(get_prefix "$skill")
    local remote
    remote=$(get_remote_url "$skill")

    log_info "Pulling updates for: $skill ($prefix)"
    cd "$REPO_ROOT"
    git subtree pull --prefix="$prefix" "$remote" "$BRANCH" --squash
    log_ok "Pulled $skill"
}

do_push() {
    local skill="$1"
    local prefix
    prefix=$(get_prefix "$skill")
    local remote
    remote=$(get_remote_url "$skill")

    log_info "Pushing changes for: $skill ($prefix)"
    cd "$REPO_ROOT"
    git subtree push --prefix="$prefix" "$remote" "$BRANCH"
    log_ok "Pushed $skill"
}

do_split() {
    local skill="$1"
    local prefix
    prefix=$(get_prefix "$skill")

    log_info "Splitting subtree: $prefix → branch $skill"
    cd "$REPO_ROOT"
    git subtree split --prefix="$prefix" -b "$skill"
    log_ok "Split complete. Branch: $skill"
    log_info "Push to remote: git push $REMOTE_BASE/$skill.git $skill:$BRANCH"
}

do_list() {
    echo ""
    echo -e "${BLUE}Tracked Skills:${NC}"
    echo "────────────────────────────────────────────────────────"
    printf "%-30s %-40s %s\n" "REPO" "PREFIX" "STATUS"
    echo "────────────────────────────────────────────────────────"

    for entry in "${SKILLS_LIST[@]}"; do
        local repo="${entry%%|*}"
        local prefix="${entry#*|}"
        local status
        if [[ -d "$REPO_ROOT/$prefix" ]]; then
            status="${GREEN}present${NC}"
        else
            status="${RED}missing${NC}"
        fi
        printf "%-30s %-40s " "$repo" "$prefix"
        echo -e "$status"
    done
    echo ""
}

do_create_repo() {
    local skill="$1"
    local prefix
    prefix=$(get_prefix "$skill")

    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) is required. Install: brew install gh"
        exit 1
    fi

    log_info "Creating GitHub repo: $skill"
    cd "$REPO_ROOT"

    # Split subtree to temp branch
    local temp_branch="temp-$skill"
    git subtree split --prefix="$prefix" -b "$temp_branch"

    # Create repo on GitHub
    gh repo create "$REMOTE_BASE/$skill" --private --source="." --push --head="$temp_branch"

    # Clean up temp branch
    git branch -D "$temp_branch"

    log_ok "Created repo: $REMOTE_BASE/$skill"
}

# Main
ACTION="${1:-}"
SKILL="${2:-}"

case "$ACTION" in
    add)
        [[ -z "$SKILL" ]] && { log_error "Usage: $0 add <skill-name>"; exit 1; }
        do_add "$SKILL"
        ;;
    pull)
        [[ -z "$SKILL" ]] && { log_error "Usage: $0 pull <skill-name>"; exit 1; }
        do_pull "$SKILL"
        ;;
    push)
        [[ -z "$SKILL" ]] && { log_error "Usage: $0 push <skill-name>"; exit 1; }
        do_push "$SKILL"
        ;;
    split)
        [[ -z "$SKILL" ]] && { log_error "Usage: $0 split <skill-name>"; exit 1; }
        do_split "$SKILL"
        ;;
    list)
        do_list
        ;;
    create-repo)
        [[ -z "$SKILL" ]] && { log_error "Usage: $0 create-repo <skill-name>"; exit 1; }
        do_create_repo "$SKILL"
        ;;
    *)
        usage
        exit 1
        ;;
esac
