#!/usr/bin/env bash

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Find and select launchsettings file
launchsettings_file=$(fd --type f launchsettings.json | fzf --exit-0)
if [ -z "$launchsettings_file" ]; then
    echo "Error: launchsettings.json not found or selection cancelled"
    exit 1
fi

# Get profile from launchsettings
profile=$(jq -r '.profiles | keys[]' "$launchsettings_file" | fzf --exit-0)
if [ -z "$profile" ]; then
    echo "Error: No profile selected"
    exit 1
fi

# Get project directory and file
project_path=$(dirname "$launchsettings_file")
project_path=$(realpath "$project_path/../")

# Find .csproj files
csproj_files=$(fd -d 1 "\.csproj$" "$project_path")
csproj_count=$(echo "$csproj_files" | wc -l)

if [ -z "$csproj_files" ]; then
    echo "Error: No .csproj file found"
    exit 1
elif [ "$csproj_count" -eq 1 ]; then
    project_file="$csproj_files"
else
    project_file=$(echo "$csproj_files" | fzf --exit-0)
    if [ -z "$project_file" ]; then
        echo "Error: No .csproj file selected"
        exit 1
    fi
fi

# Extract just the filename from project_file path
project_file=$(basename "$project_file")

# Run the project
dotnet run --project "${project_path}/${project_file}" --launch-profile "$profile"
 
