#!/bin/bash

# GitHub Contribution Automation - Master Script
# This script creates the repository if it doesn't exist and runs the commit script

set -e  # Exit on any error

# Configuration
REPO_NAME="github-contribution-graph-action"
REPO_VISIBILITY="private"  # Options: "private" or "public"
LOG_FILE="logs/log.txt"
CRON_SCHEDULE="0 9,14,19 * * *"  # Cron schedule: "minute hour day month weekday" - 9 AM, 2 PM, 7 PM daily

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create logs directory if it doesn't exist
    mkdir -p logs
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Also print to console with colors
    case $level in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        "STEP")
            echo -e "${BLUE}[STEP]${NC} $message"
            ;;
        *)
            echo "[$level] $message"
            ;;
    esac
}

# Function to validate configuration
validate_configuration() {
    log "STEP" "Validating configuration..."
    
    # Validate repository visibility
    if [[ "$REPO_VISIBILITY" != "private" && "$REPO_VISIBILITY" != "public" ]]; then
        log "ERROR" "Invalid REPO_VISIBILITY: '$REPO_VISIBILITY'. Must be 'private' or 'public'."
        exit 1
    fi
    
    # Validate cron schedule format (basic validation - check for 5 fields)
    local cron_fields=$(echo "$CRON_SCHEDULE" | wc -w)
    if [[ $cron_fields -ne 5 ]]; then
        log "ERROR" "Invalid CRON_SCHEDULE format: '$CRON_SCHEDULE'. Cron schedule must have exactly 5 fields (minute hour day month weekday)."
        exit 1
    fi
    
    log "INFO" "Configuration validated successfully"
}

# Function to check prerequisites
check_prerequisites() {
    log "STEP" "Checking prerequisites..."
    
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        log "ERROR" "GitHub CLI (gh) is not installed. Please install it first."
        exit 1
    fi
    
    # Check if gh is authenticated
    if ! gh auth status &> /dev/null; then
        log "ERROR" "GitHub CLI is not authenticated. Please run 'gh auth login' first."
        exit 1
    fi
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        log "ERROR" "Git is not installed. Please install it first."
        exit 1
    fi
    
    log "INFO" "All prerequisites are satisfied"
}

# Function to check if repository exists
check_repo_exists() {
    if gh repo view "$REPO_NAME" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to create repository
create_repository() {
    log "STEP" "Creating repository $REPO_NAME as $REPO_VISIBILITY..."
    
    if gh repo create "$REPO_NAME" --"$REPO_VISIBILITY" --description "Automated GitHub contribution graph tool"; then
        log "INFO" "Repository created successfully as $REPO_VISIBILITY"
        return 0
    else
        log "ERROR" "Failed to create repository"
        return 1
    fi
}

# Function to run commit script
run_commit_script() {
    log "STEP" "Running commit script..."
    
    if [ -f "commit.sh" ]; then
        chmod +x commit.sh
        if ./commit.sh; then
            log "INFO" "Commit script completed successfully"
            return 0
        else
            log "ERROR" "Commit script failed"
            return 1
        fi
    else
        log "ERROR" "commit.sh script not found"
        return 1
    fi
}

# Function to setup cron job
setup_cron() {
    log "STEP" "Setting up cron job..."
    
    # Get the absolute path of the current directory
    local current_dir=$(pwd)
    local cronjob_script="$current_dir/cronjob.sh"
    
    # Create cronjob script if it doesn't exist
    if [ ! -f "cronjob.sh" ]; then
        log "INFO" "Creating cronjob.sh script..."
        cat > cronjob.sh << EOF
#!/bin/bash
cd "$current_dir"
./run-all.sh >> logs/cron.log 2>&1
EOF
        chmod +x cronjob.sh
    fi
    
    # Check if cron job already exists
    local cron_entry="$CRON_SCHEDULE $cronjob_script"
    if crontab -l 2>/dev/null | grep -q "$cronjob_script"; then
        log "WARN" "Cron job already exists"
    else
        # Add cron job
        if (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -; then
            log "INFO" "Cron job added successfully"
            log "INFO" "Schedule: $CRON_SCHEDULE"
            log "INFO" "Cron entry: $cron_entry"
        else
            log "ERROR" "Failed to add cron job"
            return 1
        fi
    fi
}

# Main execution
main() {
    log "INFO" "Starting GitHub contribution automation setup..."
    
    # Validate configuration
    validate_configuration
    
    # Check prerequisites
    check_prerequisites
    
    # Check if repository exists
    if check_repo_exists; then
        log "INFO" "Repository $REPO_NAME already exists"
    else
        # Create repository
        if ! create_repository; then
            log "ERROR" "Failed to create repository. Exiting."
            exit 1
        fi
    fi
    
    # Run commit script
    if ! run_commit_script; then
        log "ERROR" "Failed to run commit script. Exiting."
        exit 1
    fi
    
    # Setup cron job
    setup_cron
    
    log "INFO" "Setup completed successfully!"
    log "INFO" "The automation will run automatically according to schedule: $CRON_SCHEDULE"
    log "INFO" "You can check logs at: $LOG_FILE"
}

# Run main function
main "$@"
