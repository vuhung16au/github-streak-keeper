#!/bin/bash

# GitHub Contribution Automation - Cron Job Script
# This script is executed by cron to run the automation

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory
cd "$SCRIPT_DIR"

# Run the master script and log output
./run-all.sh >> logs/cron.log 2>&1
