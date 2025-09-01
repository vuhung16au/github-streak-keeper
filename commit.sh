#!/bin/bash

# GitHub Contribution Automation - Commit Script
# This script creates a timestamp file and commits it to the repository

set -e  # Exit on any error

# Configuration
REPO_NAME="github-contribution-graph-action"
TIMESTAMP_FILE="timestamp.txt"
LOG_FILE="logs/log.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
        *)
            echo "[$level] $message"
            ;;
    esac
}

# Function to check if repository exists
check_repo_exists() {
    if gh repo view "$REPO_NAME" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to clone repository
clone_repo() {
    log "INFO" "Cloning repository $REPO_NAME..."
    
    # Remove existing clone if it exists
    if [ -d "$REPO_NAME" ]; then
        log "INFO" "Removing existing local clone..."
        rm -rf "$REPO_NAME"
    fi
    
    # Clone the repository
    if gh repo clone "$REPO_NAME"; then
        log "INFO" "Repository cloned successfully"
        return 0
    else
        log "ERROR" "Failed to clone repository"
        return 1
    fi
}

# Function to create timestamp file
create_timestamp_file() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local commit_message="Update timestamp: $timestamp"
    
    log "INFO" "Creating timestamp file..."
    
    # Create timestamp file
    echo "Last updated: $timestamp" > "$REPO_NAME/$TIMESTAMP_FILE"
    echo "This file is automatically updated by the contribution automation tool." >> "$REPO_NAME/$TIMESTAMP_FILE"
    echo "Created at: $(date)" >> "$REPO_NAME/$TIMESTAMP_FILE"
    
    log "INFO" "Timestamp file created: $timestamp"
    echo "$commit_message"
}

# Function to commit and push changes
commit_and_push() {
    local commit_message="$1"
    
    cd "$REPO_NAME"
    
    log "INFO" "Adding files to git..."
    git add "$TIMESTAMP_FILE"
    
    log "INFO" "Committing changes..."
    if git commit -m "$commit_message"; then
        log "INFO" "Changes committed successfully"
    else
        log "ERROR" "Failed to commit changes"
        cd ..
        return 1
    fi
    
    log "INFO" "Pushing changes to remote..."
    if git push origin main; then
        log "INFO" "Changes pushed successfully"
    else
        log "ERROR" "Failed to push changes"
        cd ..
        return 1
    fi
    
    cd ..
}

# Main execution
main() {
    log "INFO" "Starting commit automation..."
    
    # Check if repository exists
    if ! check_repo_exists; then
        log "ERROR" "Repository $REPO_NAME does not exist. Please create it first using run-all.sh"
        exit 1
    fi
    
    # Clone repository
    if ! clone_repo; then
        log "ERROR" "Failed to clone repository. Exiting."
        exit 1
    fi
    
    # Create timestamp file and get commit message
    commit_message=$(create_timestamp_file)
    
    # Commit and push changes
    if ! commit_and_push "$commit_message"; then
        log "ERROR" "Failed to commit and push changes. Exiting."
        exit 1
    fi
    
    log "INFO" "Commit automation completed successfully!"
}

# Run main function
main "$@"
