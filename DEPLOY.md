# Deployment Scripts

Automated deployment scripts for Claude Code session management commands.

## Quick Start

### Deploy to a Project
```bash
./deploy-to-project.sh /path/to/your/project --backup
```

### Deploy Globally
```bash
./deploy-global.sh --backup
```

## Scripts

### `deploy-to-project.sh`
Deploy session commands to a specific project directory.

**Usage:**
```bash
./deploy-to-project.sh <target_directory> [options]
```

**Options:**
- `--claude-structure`: Use `.claude/` directory structure (default: auto-detect)
- `--standalone`: Use standalone structure (`commands/` and `sessions/`)
- `--backup`: Create backup of existing files
- `--dry-run`: Show what would be done without making changes
- `--help`: Show help message

**Examples:**
```bash
# Deploy with backup
./deploy-to-project.sh /path/to/project --backup

# Force Claude structure
./deploy-to-project.sh /path/to/project --claude-structure

# Test deployment without changes
./deploy-to-project.sh /path/to/project --standalone --dry-run
```

### `deploy-global.sh`
Deploy session commands globally to `~/.claude/commands/`.

**Usage:**
```bash
./deploy-global.sh [options]
```

**Options:**
- `--prefix PREFIX`: Command prefix (default: 'session')
- `--backup`: Create backup of existing files
- `--dry-run`: Show what would be done without making changes
- `--help`: Show help message

**Examples:**
```bash
# Deploy globally with backup
./deploy-global.sh --backup

# Use custom prefix
./deploy-global.sh --prefix mysession --dry-run
```

## Configuration

The `deploy-config.json` file contains deployment configuration options:

```json
{
  "deployment": {
    "default_structure": "auto",
    "backup_by_default": true,
    "global_prefix": "session"
  },
  "paths": {
    "claude_structure": {
      "commands": ".claude/commands",
      "sessions": ".claude/sessions"
    },
    "standalone_structure": {
      "commands": "commands",
      "sessions": "sessions"
    }
  }
}
```

## How It Works

### Structure Detection
The scripts automatically detect the target project structure:
- **Claude Structure**: Projects with `.claude/` directory or standard project files
- **Standalone Structure**: Simple directory with `commands/` and `sessions/` folders

### Path Updates
Commands are automatically updated to use the correct session storage paths:
- Claude structure: `.claude/sessions/`
- Standalone structure: `sessions/`
- Global deployment: `~/.claude/sessions/`

### Backup System
When `--backup` is used, existing files are backed up with timestamp:
```
commands/ → commands.backup.20250710_1037/
```

## Available Commands

After deployment, these commands become available:

### Project Deployment
- `/session-start` - Start a new development session
- `/session-end` - End the current session
- `/session-list` - List all sessions
- `/session-current` - Show current session
- `/session-update` - Update current session
- `/session-help` - Show session help

### Global Deployment
- `/session-start` - Start a new development session
- `/session-end` - End the current session
- `/session-list` - List all sessions
- `/session-current` - Show current session
- `/session-update` - Update current session
- `/session-help` - Show session help

## Troubleshooting

### Permission Errors
Ensure the target directory is writable:
```bash
chmod 755 /path/to/target/directory
```

### Missing Commands
Verify the source `commands/` directory exists and contains `.md` files:
```bash
ls -la commands/
```

### Path Issues
Use `--dry-run` to preview changes before deployment:
```bash
./deploy-to-project.sh /path/to/project --dry-run
```

## Testing

Test deployments with dry-run mode:
```bash
# Test project deployment
./deploy-to-project.sh /tmp/test-project --dry-run

# Test global deployment
./deploy-global.sh --dry-run
```