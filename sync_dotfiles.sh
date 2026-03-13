#!/bin/zsh

# Define the directory to search for sync.config
scripts_directory="."
# Get the absolute path to the script
script_path=$(realpath "$0")

# Determine the DOTFILES directory based on the script's location
DOTFILES=$(dirname "$script_path")

# Iterate through all sync.config files and process each one
while IFS= read -r -d '' config_file; do
    # Extract the folder containing sync.config
    folder=$(dirname "$config_file")

    # Debugging information
    echo "Checking folder: $folder"

    # Print and create symbolic links
    echo "Creating symbolic links from $config_file:"

    while IFS= read -r line || [ -n "$line" ]; do
        # Skip blank lines and comments
        [ -z "$line" ] && continue
        [[ "$line" == \#* ]] && continue

        # Validate and parse source=target mapping
        if [[ "$line" != *"="* ]]; then
            echo "Skipping invalid mapping in $config_file: $line"
            continue
        fi

        # Extract file paths from the line
        first_filepath="${line%%=*}"
        second_filepath="${line#*=}"

        # Expand known variables without using eval
        first_filepath="${first_filepath//\$DOTFILES/$DOTFILES}"
        first_filepath="${first_filepath//\$HOME/$HOME}"
        second_filepath="${second_filepath//\$DOTFILES/$DOTFILES}"
        second_filepath="${second_filepath//\$HOME/$HOME}"

        # Interpret escaped spaces from config values (e.g. "\ ")
        first_filepath="${first_filepath//\\ / }"
        second_filepath="${second_filepath//\\ / }"

        echo "FIRST PATH: $first_filepath"
        echo "SECOND PATH: $second_filepath"

        # Create the target directory if it doesn't exist
        mkdir -p "$(dirname "$second_filepath")"

        # Print the extracted file paths
        echo "Creating symbolic link: $first_filepath to $second_filepath"

        # Replace existing links, and safely back up real files/directories.
        if [ -L "$second_filepath" ]; then
            # Target is a symbolic link, force override.
            ln -sf "$first_filepath" "$second_filepath"
        elif [ -e "$second_filepath" ]; then
            backup_path="${second_filepath}.backup.$(date +%Y%m%d%H%M%S)"
            echo "Target exists and is not a symlink. Backing up to: $backup_path"
            mv "$second_filepath" "$backup_path"
            ln -s "$first_filepath" "$second_filepath"
        else
            ln -s "$first_filepath" "$second_filepath"
        fi
        # Create symbolic link
        # ln -sf "$first_filepath" "$second_filepath"
    done < "$config_file"
    echo "---------------------------------"
done < <(find "$scripts_directory" -type f -name "sync.config" -print0)
Add custom command to generate AI commit message from staged changes.