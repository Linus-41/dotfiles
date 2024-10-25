#!/bin/zsh

# Parse command line options
list_mode=false
while getopts "l" opt; do
    case $opt in
        l)
            list_mode=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            echo "Usage: $0 [-l]"
            echo "  -l  List mode: only show local-only branches without prompting for deletion"
            exit 1
            ;;
    esac
done

# Check if current directory is a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Current directory is not a git repository"
    exit 1
fi

# Fetch from remote to ensure we have latest information
echo "Fetching from remote..."
git fetch origin

# Get list of local branches
local_branches=$(git branch --format="%(refname:short)")

# Get list of remote branches without 'origin/' prefix
remote_branches=$(git branch -r --format="%(refname:short)" | sed 's#^origin/##')

# Initialize counter for branches checked
branches_checked=0
branches_deleted=0

if $list_mode; then
    echo "\nLocal-only branches:"
else
    echo "\nChecking for local-only branches..."
fi

# Check each local branch
for branch in ${(f)local_branches}; do
    # Skip if it's the current branch
    if [[ $branch == $(git rev-parse --abbrev-ref HEAD) ]]; then
        if ! $list_mode; then
            echo "Skipping current branch: $branch"
        fi
        continue
    fi
    
    # Check if branch exists in remote branches
    if ! echo $remote_branches | grep -q "^${branch}$"; then
        branches_checked=$((branches_checked + 1))
        
        if $list_mode; then
            # In list mode, just show the branch and its last commit
            echo "\n$branch"
            echo "Last commit: $(git log -1 --format="%h %s" $branch)"
        else
            # Interactive mode with deletion prompts
            echo "\nFound local-only branch: $branch"
            echo "Last commit: $(git log -1 --format="%h %s" $branch)"
            echo -n "Delete this branch? [y/N] "
            read response
            
            if [[ $response =~ ^[Yy]$ ]]; then
                if git branch -D $branch; then
                    echo "Deleted branch: $branch"
                    branches_deleted=$((branches_deleted + 1))
                else
                    echo "Failed to delete branch: $branch"
                fi
            else
                echo "Keeping branch: $branch"
            fi
        fi
    fi
done

# Summary
if ! $list_mode; then
    echo "\nSummary:"
    echo "Branches checked: $branches_checked"
    echo "Branches deleted: $branches_deleted"
fi