#!/bin/zsh

# Script to switch Git configuration for different GitHub accounts
# Usage: ./git_acc_switcher.zsh [account-name]

# Path to config file
CONFIG_FILE="$HOME/scripts/git_acc_switcher_config.json"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Please install jq first:"
    echo "  For Ubuntu/Debian: sudo apt-get install jq"
    echo "  For MacOS: brew install jq"
    exit 1
fi

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: git_acc_switcher_config.json not found!"
    echo "Expected path: $CONFIG_FILE"
    echo "Please create the config file with your git accounts"
    exit 1
fi

# Function to show current Git configuration
show_current_config() {
    echo "Current Git Configuration:"
    echo "User name: $(git config user.name)"
    echo "User email: $(git config user.email)"
    echo "SSH key: $(git config core.sshCommand 2>/dev/null || echo 'Default SSH key')"
}

# Function to switch Git configuration
switch_config() {
    local account=$1
    
    if [[ -z "$account" ]]; then
        echo "Error: Please specify an account name"
        echo "Available accounts:"
        jq -r 'keys[]' "$CONFIG_FILE"
        exit 1
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir &> /dev/null; then
        echo "Error: Not a git repository"
        exit 1
    fi
    
    # Read configuration from JSON file
    local name=$(jq -r ".$account.name" "$CONFIG_FILE")
    local email=$(jq -r ".$account.email" "$CONFIG_FILE")
    local ssh_path=$(jq -r ".$account.sshPath" "$CONFIG_FILE")
    
    # Check if any values are null (meaning they weren't found in config)
    if [[ "$name" == "null" || "$email" == "null" || "$ssh_path" == "null" ]]; then
        echo "Error: Account '$account' not found in config file"
        echo "Available accounts:"
        jq -r 'keys[]' "$CONFIG_FILE"
        exit 1
    fi
    
    # Apply configuration
    git config user.name "$name"
    git config user.email "$email"
    git config core.sshCommand "ssh -i $ssh_path"
    
    echo "Successfully switched to $account"
    show_current_config
}

# Show usage if no arguments provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [account-name]"
    echo "Available accounts:"
    jq -r 'keys[]' "$CONFIG_FILE"
    echo "\nCurrent configuration:"
    show_current_config
    exit 0
fi

# Switch configuration
switch_config $1