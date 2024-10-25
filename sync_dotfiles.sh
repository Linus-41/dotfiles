#!/bin/zsh

# Define the directory to search for sync.config
scripts_directory="."
# Get the absolute path to the script
script_path=$(realpath "$0")

# Determine the DOTFILES directory based on the script's location
DOTFILES=$(dirname "$script_path")

# Iterate through all sync.config files and process each one
for config_file in $(find "$scripts_directory" -type f -name "sync.config"); do
    # Extract the folder containing sync.config
    folder=$(dirname "$config_file")

    # Debugging information
    echo "Checking folder: $folder"

    # Print and create symbolic links
    echo "Creating symbolic links from $config_file:"

    while IFS= read -r line || [ -n "$line" ]; do
        # Evaluate the line to interpret $HOME as the variable
        eval "line=$line"

        # Extract file paths from the line
        first_filepath=$(echo "$line" | cut -d '=' -f1)
        second_filepath=$(echo "$line" | cut -d '=' -f2)

        echo "FIRST PATH: $first_filepath"
        echo "SECOND PATH: $second_filepath"

        # Create the target directory if it doesn't exist
        mkdir -p "$(dirname "$second_filepath")"

        # Print the extracted file paths
        echo "Creating symbolic link: $first_filepath to $second_filepath"

        # Check if the target path is a symbolic link
        if [ -L "$second_filepath" ]; then
            # Target is a symbolic link, force override
            ln -sf "$first_filepath" "$second_filepath"
        else
            # Target is not a symbolic link, create normally
            ln -s "$first_filepath" "$second_filepath"
        fi
        # Create symbolic link
        # ln -sf "$first_filepath" "$second_filepath"
    done < <(cat "$config_file")
    echo "---------------------------------"
done