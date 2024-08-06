#!/bin/bash

# Specify the list of directories where .car files need to be deleted
directories=("titan_storage_1" "titan_storage_2" "titan_storage_3" "titan_storage_4" "titan_storage_5")

# Iterate over the list of directories
for directory in "${directories[@]}"; do
    directory_path="${directory}/assets"
    
    # Check if the directory exists
    if [ -d "$directory_path" ]; then
        echo "Deleting .car files in directory: $directory_path"
        
        # Delete all files with the .car extension in the directory
        find "$directory_path" -type f -name "*.car" -exec rm {} \;
    else
        echo "Directory not found: $directory_path"
    fi
done