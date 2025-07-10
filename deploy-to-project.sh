#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_COMMANDS_DIR="$SCRIPT_DIR/commands"

print_usage() {
    echo "Usage: $0 <target_directory> [options]"
    echo ""
    echo "Options:"
    echo "  --claude-structure    Use .claude/ directory structure (default: auto-detect)"
    echo "  --standalone         Use standalone structure (commands/ and sessions/)"
    echo "  --backup             Create backup of existing files"
    echo "  --dry-run            Show what would be done without making changes"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/project --backup"
    echo "  $0 /path/to/project --claude-structure"
    echo "  $0 /path/to/project --standalone --dry-run"
}

log() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1" >&2
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

detect_structure() {
    local target_dir="$1"
    
    if [[ -d "$target_dir/.claude" ]]; then
        echo "claude"
    elif [[ -f "$target_dir/package.json" ]] || [[ -f "$target_dir/Cargo.toml" ]] || [[ -f "$target_dir/pyproject.toml" ]]; then
        echo "claude"
    else
        echo "standalone"
    fi
}

backup_existing() {
    local target_path="$1"
    local backup_path="${target_path}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -e "$target_path" ]]; then
        log "Creating backup: $backup_path"
        cp -r "$target_path" "$backup_path"
    fi
}

copy_commands() {
    local target_commands_dir="$1"
    local structure="$2"
    local create_backup="$3"
    local dry_run="$4"
    
    if [[ "$create_backup" == "true" && -d "$target_commands_dir" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            log "Would create backup of: $target_commands_dir"
        else
            backup_existing "$target_commands_dir"
        fi
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        log "Would create directory: $target_commands_dir"
        log "Would copy commands from: $SOURCE_COMMANDS_DIR"
    else
        log "Creating commands directory: $target_commands_dir"
        mkdir -p "$target_commands_dir"
        
        log "Copying commands..."
        cp "$SOURCE_COMMANDS_DIR"/*.md "$target_commands_dir/"
    fi
    
    if [[ "$structure" == "claude" ]]; then
        update_command_paths "$target_commands_dir" ".claude/sessions/" "$dry_run"
    else
        update_command_paths "$target_commands_dir" "sessions/" "$dry_run"
    fi
}

update_command_paths() {
    local commands_dir="$1"
    local sessions_path="$2"
    local dry_run="$3"
    
    if [[ "$dry_run" == "true" ]]; then
        log "Would update session paths in commands to: $sessions_path"
        return
    fi
    
    log "Updating session paths in commands to: $sessions_path"
    
    if command -v sed >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            find "$commands_dir" -name "*.md" -exec sed -i '' "s|\.claude/sessions/|${sessions_path}|g" {} \;
            find "$commands_dir" -name "*.md" -exec sed -i '' "s|sessions/|${sessions_path}|g" {} \;
        else
            find "$commands_dir" -name "*.md" -exec sed -i "s|\.claude/sessions/|${sessions_path}|g" {} \;
            find "$commands_dir" -name "*.md" -exec sed -i "s|sessions/|${sessions_path}|g" {} \;
        fi
    else
        warn "sed not found, skipping path updates"
    fi
}

create_sessions_dir() {
    local target_sessions_dir="$1"
    local dry_run="$2"
    
    if [[ "$dry_run" == "true" ]]; then
        log "Would create sessions directory: $target_sessions_dir"
    else
        log "Creating sessions directory: $target_sessions_dir"
        mkdir -p "$target_sessions_dir"
    fi
}

main() {
    local target_dir=""
    local structure="auto"
    local create_backup="false"
    local dry_run="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --claude-structure)
                structure="claude"
                shift
                ;;
            --standalone)
                structure="standalone"
                shift
                ;;
            --backup)
                create_backup="true"
                shift
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            --help)
                print_usage
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                if [[ -z "$target_dir" ]]; then
                    target_dir="$1"
                else
                    error "Multiple target directories specified"
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "$target_dir" ]]; then
        error "Target directory is required"
    fi
    
    if [[ ! -d "$target_dir" ]]; then
        error "Target directory does not exist: $target_dir"
    fi
    
    if [[ ! -d "$SOURCE_COMMANDS_DIR" ]]; then
        error "Source commands directory not found: $SOURCE_COMMANDS_DIR"
    fi
    
    if [[ "$structure" == "auto" ]]; then
        structure=$(detect_structure "$target_dir")
        log "Auto-detected structure: $structure"
    fi
    
    if [[ "$structure" == "claude" ]]; then
        target_commands_dir="$target_dir/.claude/commands"
        target_sessions_dir="$target_dir/.claude/sessions"
    else
        target_commands_dir="$target_dir/commands"
        target_sessions_dir="$target_dir/sessions"
    fi
    
    log "Deploying to: $target_dir"
    log "Structure: $structure"
    log "Commands target: $target_commands_dir"
    log "Sessions target: $target_sessions_dir"
    
    if [[ "$dry_run" == "true" ]]; then
        log "DRY RUN - No changes will be made"
    fi
    
    copy_commands "$target_commands_dir" "$structure" "$create_backup" "$dry_run"
    create_sessions_dir "$target_sessions_dir" "$dry_run"
    
    if [[ "$dry_run" == "true" ]]; then
        log "Deployment simulation completed"
    else
        log "Deployment completed successfully!"
        log "Commands available at: $target_commands_dir"
        log "Sessions will be stored in: $target_sessions_dir"
    fi
}

main "$@"