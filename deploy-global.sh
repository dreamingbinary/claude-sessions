#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_COMMANDS_DIR="$SCRIPT_DIR/commands"
GLOBAL_CLAUDE_DIR="$HOME/.claude"
GLOBAL_COMMANDS_DIR="$GLOBAL_CLAUDE_DIR/commands"
GLOBAL_SESSIONS_DIR="$GLOBAL_CLAUDE_DIR/sessions"

print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --prefix PREFIX      Command prefix (default: 'session')"
    echo "  --backup             Create backup of existing files"
    echo "  --dry-run            Show what would be done without making changes"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --backup"
    echo "  $0 --prefix mysession --dry-run"
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

backup_existing() {
    local target_path="$1"
    local backup_path="${target_path}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -e "$target_path" ]]; then
        log "Creating backup: $backup_path"
        cp -r "$target_path" "$backup_path"
    fi
}

copy_global_commands() {
    local prefix="$1"
    local create_backup="$2"
    local dry_run="$3"
    
    if [[ "$create_backup" == "true" && -d "$GLOBAL_COMMANDS_DIR" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            log "Would create backup of: $GLOBAL_COMMANDS_DIR"
        else
            backup_existing "$GLOBAL_COMMANDS_DIR"
        fi
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        log "Would create directory: $GLOBAL_COMMANDS_DIR"
    else
        log "Creating global commands directory: $GLOBAL_COMMANDS_DIR"
        mkdir -p "$GLOBAL_COMMANDS_DIR"
    fi
    
    log "Copying commands with prefix: $prefix"
    
    for cmd_file in "$SOURCE_COMMANDS_DIR"/*.md; do
        if [[ -f "$cmd_file" ]]; then
            local basename=$(basename "$cmd_file" .md)
            local global_name="${prefix}-${basename#session-}.md"
            local target_file="$GLOBAL_COMMANDS_DIR/$global_name"
            
            if [[ "$dry_run" == "true" ]]; then
                log "Would copy: $cmd_file -> $target_file"
            else
                log "Copying: $cmd_file -> $target_file"
                cp "$cmd_file" "$target_file"
            fi
        fi
    done
    
    update_global_command_paths "$GLOBAL_COMMANDS_DIR" "$GLOBAL_SESSIONS_DIR" "$dry_run"
}

update_global_command_paths() {
    local commands_dir="$1"
    local sessions_dir="$2"
    local dry_run="$3"
    
    if [[ "$dry_run" == "true" ]]; then
        log "Would update session paths in commands to: $sessions_dir"
        return
    fi
    
    log "Updating session paths in commands to: $sessions_dir"
    
    if command -v sed >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            find "$commands_dir" -name "*.md" -exec sed -i '' "s|\.claude/sessions/|${sessions_dir}/|g" {} \;
            find "$commands_dir" -name "*.md" -exec sed -i '' "s|sessions/|${sessions_dir}/|g" {} \;
        else
            find "$commands_dir" -name "*.md" -exec sed -i "s|\.claude/sessions/|${sessions_dir}/|g" {} \;
            find "$commands_dir" -name "*.md" -exec sed -i "s|sessions/|${sessions_dir}/|g" {} \;
        fi
    else
        warn "sed not found, skipping path updates"
    fi
}

create_global_sessions_dir() {
    local dry_run="$1"
    
    if [[ "$dry_run" == "true" ]]; then
        log "Would create global sessions directory: $GLOBAL_SESSIONS_DIR"
    else
        log "Creating global sessions directory: $GLOBAL_SESSIONS_DIR"
        mkdir -p "$GLOBAL_SESSIONS_DIR"
    fi
}

check_claude_installation() {
    if ! command -v claude >/dev/null 2>&1; then
        warn "Claude CLI not found in PATH"
        warn "Commands will be available but may not work without Claude CLI"
    fi
}

main() {
    local prefix="session"
    local create_backup="false"
    local dry_run="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --prefix)
                prefix="$2"
                shift 2
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
                error "Unexpected argument: $1"
                ;;
        esac
    done
    
    if [[ ! -d "$SOURCE_COMMANDS_DIR" ]]; then
        error "Source commands directory not found: $SOURCE_COMMANDS_DIR"
    fi
    
    if [[ -z "$prefix" ]]; then
        error "Command prefix cannot be empty"
    fi
    
    log "Deploying globally to: $GLOBAL_CLAUDE_DIR"
    log "Command prefix: $prefix"
    log "Global commands target: $GLOBAL_COMMANDS_DIR"
    log "Global sessions target: $GLOBAL_SESSIONS_DIR"
    
    if [[ "$dry_run" == "true" ]]; then
        log "DRY RUN - No changes will be made"
    fi
    
    check_claude_installation
    
    copy_global_commands "$prefix" "$create_backup" "$dry_run"
    create_global_sessions_dir "$dry_run"
    
    if [[ "$dry_run" == "true" ]]; then
        log "Global deployment simulation completed"
    else
        log "Global deployment completed successfully!"
        log "Commands available globally with prefix: /$prefix-"
        log "Sessions will be stored in: $GLOBAL_SESSIONS_DIR"
        log ""
        log "Available commands:"
        if [[ -d "$GLOBAL_COMMANDS_DIR" ]]; then
            for cmd_file in "$GLOBAL_COMMANDS_DIR"/*.md; do
                if [[ -f "$cmd_file" ]]; then
                    local basename=$(basename "$cmd_file" .md)
                    log "  /$basename"
                fi
            done
        fi
    fi
}

main "$@"