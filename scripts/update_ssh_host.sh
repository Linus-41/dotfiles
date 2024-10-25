#!/bin/bash

# Specify the path to your SSH config file
config_file=~/.ssh/config

# Prompt the user for the Host to edit
read -p "Enter the Host to edit: " host

# Check if the Host exists in the config file
if grep -q "Host $host$" $config_file; then
    # Prompt the user for the new IP address
    read -p "Enter the new IP address for $host: " new_ip

    # Update the HostName in the config file
    sed -i -e "/Host $host$/,/^[[:space:]]*$/ s/HostName .*/HostName $new_ip/" $config_file

    echo "Host $host updated with new IP address $new_ip."
else
    echo "Host $host not found in $config_file."
fi
