# Description: Git related aliases for common git commands and workflows.

#===================================
# Helper functions
#===================================

# Helper function to check if a Git command exists
_git_check_command() {
  if ! command -v git &> /dev/null; then
    echo "Error: Git command not found. Please install Git first." >&2
    return 1
  fi
  return 0
}

# Helper function to check if current directory is a git repository
_git_check_repository() {
  if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "Error: Not inside a Git repository." >&2
    return 1
  fi
  return 0
}

# Helper function to get current branch name
_git_current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main"
}

#===================================
# Basic Git operations
#===================================

# Add specified files to staging area
alias gadd='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Adding files to staging area"
  git add "$@"
}'

# Check repository status
alias gst='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Checking Git status"
  git status
}'

# Commit changes
alias gcmt='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Committing changes"
  git commit "$@"
}'

# Push to remote repository
alias gpush='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Pushing changes to remote"
  git push "$@"
}'

#===================================
# Branch operations
#===================================

# Create and switch to new branch
alias gbranch='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Create and switch to new branch.\nUsage:\n gbranch <branch_name>"
    return 1
  fi

  echo "Creating and switching to new branch"
  git checkout -b "$1"
}'

# Create a branch with no history
alias gorphan='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Create and switch to a new orphan branch.\nUsage:\n gorphan <branch_name>"
    return 1
  fi

  echo "Creating and switching to a new orphan branch"
  git checkout --orphan "$@"
}'

# Switch to specified branch
alias gco='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Switch to specified branch.\nUsage:\n gco <branch_name>"
    return 1
  fi

  echo "Switching branch"
  git checkout "$@"
}'

# List all branches
alias gbranchl='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Listing all branches"
  git branch -a
}'

# Switch to main branch
alias gcomain='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Switching to main branch"
  git checkout main
}'

# Switch to dev branch
alias gcodev='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Switching to dev branch"
  git checkout dev
}'

#===================================
# Branch deletion operations
#===================================
# Delete specified branch(es) locally and optionally from remotes
alias grmbr='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo -e "Delete specified branch(es) locally and optionally from remotes.\nUsage:\n grmbr <branch_name> [branch_name2 ...] [-r] [-a]"
    echo -e "Options:\n  -r  - Also delete from origin\n  -a  - Delete from all remotes"
    return 1
  fi

  current_branch=$(_git_current_branch)
  delete_from_origin=false
  delete_from_all=false
  branches_to_delete=()

  # Parse arguments to separate branches from options
  for arg in "$@"; do
    if [ "$arg" = "-r" ]; then
      delete_from_origin=true
    elif [ "$arg" = "-a" ]; then
      delete_from_all=true
    else
      branches_to_delete+=("$arg")
    fi
  done

  # Process each branch
  for branch_name in "${branches_to_delete[@]}"; do
    # Check if trying to delete current branch
    if [ "$branch_name" = "$current_branch" ]; then
      echo "Error: Cannot delete the currently checked out branch '$branch_name'. Switch to a different branch first." >&2
      continue
    fi

    # Delete local branch if it exists
    if git show-ref --verify --quiet refs/heads/"$branch_name"; then
      echo "Deleting local branch: $branch_name"
      git branch -D "$branch_name"
      if [ $? -ne 0 ]; then
        echo "Error: Failed to delete local branch '$branch_name'." >&2
      fi
    else
      echo "Notice: Branch '$branch_name' does not exist locally, proceeding with remote deletion if requested." >&2
    fi

    # Handle remote deletion
    if [ "$delete_from_origin" = true ]; then
      echo "Deleting branch from origin remote: $branch_name"
      git push origin --delete "$branch_name" 2>/dev/null
      if [ $? -ne 0 ]; then
        echo "Warning: Failed to delete branch '$branch_name' from origin. Branch may not exist on remote." >&2
      fi
    fi

    if [ "$delete_from_all" = true ]; then
      if ! git remote | grep -q .; then
        echo "No remote repositories found." >&2
      else
        git remote | while read -r remote; do
          echo "Deleting branch from remote $remote: $branch_name"
          git push "$remote" --delete "$branch_name" 2>/dev/null
          if [ $? -ne 0 ]; then
            echo "Warning: Failed to delete branch '$branch_name' from remote '$remote'. Branch may not exist on this remote." >&2
          fi
        done
      fi
    fi
  done

  echo "Branch deletion operations completed."
}'

# Delete all fully merged branches
alias gclbr='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo -e "Clean merged branches locally and optionally from remotes.\nUsage:\n gclbr [-r] [-a]"

  current_branch=$(_git_current_branch)

  # Get merged branches, excluding main/master, develop branches and current branch
  merged_branches=$(git branch --merged | grep -v "\*" | grep -v "main" | grep -v "master" | grep -v "develop" | grep -v "dev" | sed "s/^[ \t]*//" | sed "s/^[ \t]*//")

  if [ -z "$merged_branches" ]; then
    echo "No merged branches to clean."
    return 0
  fi

  echo "The following merged branches will be deleted:"
  echo "$merged_branches"
  echo ""
  echo "Proceed with deletion? (y/N)"
  read -k 1 confirm
  echo ""

  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Operation cancelled."
    return 0
  fi

  # Delete local merged branches
  echo "$merged_branches" | while read -r branch; do
    if [ -n "$branch" ]; then
      echo "Deleting local branch: $branch"
      git branch -d "$branch"
    fi
  done

  # Check for remote deletion options
  for arg in "$@"; do
    if [ "$arg" = "-r" ]; then
      echo "Deleting merged branches from origin remote"
      echo "$merged_branches" | while read -r branch; do
        if [ -n "$branch" ]; then
          echo "Deleting branch from origin: $branch"
          git push origin --delete "$branch" 2>/dev/null
          if [ $? -ne 0 ]; then
            echo "Warning: Failed to delete branch '$branch' from origin. Branch may not exist on remote." >&2
          fi
        fi
      done
    elif [ "$arg" = "-a" ]; then
      if ! git remote | grep -q .; then
        echo "No remote repositories found." >&2
      else
        git remote | while read -r remote; do
          echo "Deleting merged branches from remote $remote"
          echo "$merged_branches" | while read -r branch; do
            if [ -n "$branch" ]; then
              echo "Deleting branch from remote $remote: $branch"
              git push "$remote" --delete "$branch" 2>/dev/null
              if [ $? -ne 0 ]; then
                echo "Warning: Failed to delete branch '$branch' from remote '$remote'. Branch may not exist on this remote." >&2
              fi
            fi
          done
        done
      fi
    fi
  done

  echo "Branch cleanup completed."
}'



#===================================
# Push operations
#===================================

# Push current or specified branch to remote
alias gpushbr='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  remote=${2:-origin}
  branch=${1:-$(_git_current_branch)}

  if [ $# -eq 0 ]; then
    echo "Push branch to remote.\nUsage:\n gpushbr [branch:current] [remote:origin]"
  fi

  echo "Pushing branch ${branch} to ${remote}"
  git push "${remote}" "${branch}"
}'

# Set current branch to track remote
alias gtrack='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  current_branch=$(_git_current_branch)

  echo "Setting upstream tracking branch"
  git branch --set-upstream-to=origin/$current_branch $current_branch
}'

# Push all branches to remote
alias gpushall='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Pushing all branches to remote"
  git push --all
}'

# Push all tags to remote
alias gpushtags='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Pushing all tags to remote"
  git push --tags
}'

# Force push all tags to remote
alias gpushtagsf='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Force pushing all tags to remote"
  git push --tags --force
}'

# Push current branch to all remotes
alias gpushallr='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Pushing current branch to all remotes"
  current_branch=$(_git_current_branch)

  if ! git remote | grep -q .; then
    echo "No remote repositories found."
    return 1
  fi

  git remote | while read -r remote; do
    echo "Pushing branch ${current_branch} to ${remote}"
    git push "${remote}" "${current_branch}"
  done
}'

#===================================
# Pull operations
#===================================

# Pull updates from remote for current branch
alias gpull='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Pull changes from remote.\nUsage:\n gpull [remote:origin]"
  fi

  remote=${1:-origin}
  branch=$(_git_current_branch)

  echo "Pulling changes from remote ${remote} for branch ${branch}"
  git pull ${remote} ${branch}
}'

# Pull main branch
alias gpullmain='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Pulling main branch from origin"
  git pull origin main
}'

# Pull dev branch
alias gpulldev='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Pulling dev branch from origin"
  git pull origin dev
}'

#===================================
# Merge operations
#===================================

# Merge specified branch into current branch
alias gmerge='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Merge target branch into current branch.\nUsage:\n gmerge <target_branch>"
    return 1
  fi

  current_branch=$(_git_current_branch)
  echo "Merging $1 into $current_branch"
  git merge "$1"
}'

# Merge specified branch into current branch and push
alias gmergepush='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Merge target branch into current branch and push.\nUsage:\n gmergepush <target_branch>"
    return 1
  fi

  current_branch=$(_git_current_branch)
  echo "Merging $1 into $current_branch and pushing"
  git merge "$1" && git push
}'

#===================================
# Reset operations
#===================================

# Reset to remote main branch
alias gresetmain='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Resetting to origin/main"
  git reset --hard origin/main
}'

# Reset to remote dev branch
alias gresetdev='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Resetting to origin/dev"
  git reset --hard origin/dev
}'

# Reset current branch to specified commit
alias gresetcom='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Reset current branch to specific commit.\nUsage:\n gresetcom <commit_id>"
    return 1
  fi

  commit_id=$1
  echo "Resetting current branch to commit ${commit_id}"
  git reset --hard "${commit_id}"
}'

# Reset current branch to commit and force push
alias gresetpush='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Reset current branch to commit and force push.\nUsage:\n gresetpush <commit_id> [remote:origin]"
    return 1
  fi

  commit_id=$1
  remote_name=${2:-origin}
  current_branch=$(_git_current_branch)

  echo "Resetting current branch to commit ${commit_id} and force pushing to ${remote_name}/${current_branch}"
  git reset --hard "${commit_id}" && git push "${remote_name}" --force
}'

#===================================
# Quick combined operations
#===================================

# Add all and commit
alias gaddcmt='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  msg="${1:-chore:update}"
  echo "Adding and committing changes with message: ${msg}"
  git add .
  git commit -m "${msg}"
}'

# Add all, commit and push
alias gaddcmtpu='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  msg="${1:-chore:update}"
  echo "Adding, committing and pushing changes with message: ${msg}"
  git add .
  git commit -m "${msg}" &&
  git push
}'

# Commit and push
alias gcmtpush='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  msg="${1:-chore:update}"
  echo "Committing and pushing changes with message: ${msg}"
  git commit -m "${msg}" &&
  git push
}'

#===================================
# Rebase operations
#===================================

# Rebase operation
alias grebase='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Rebase current branch onto target branch.\nUsage:\n grebase <target_branch> [start_commit] [end_commit]"
    return 1
  fi

  current_branch=$(_git_current_branch)
  echo "Rebasing $current_branch onto $1"
  git rebase $1 ${2:-HEAD}~${3:-1}
}'

#===================================
# Branch renaming
#===================================

# Rename current branch
alias grename='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Rename current branch.\nUsage:\n grename <new_name>"
    return 1
  fi

  current=$(_git_current_branch)
  echo "Renaming branch from $current to $1"
  git branch -m "$1"
}'

# Rename and set remote tracking
alias grenametrack='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Rename current branch and set remote tracking.\nUsage:\n grenametrack <new_name>"
    return 1
  fi

  current=$(_git_current_branch)
  echo "Renaming branch from $current to $1 and setting remote tracking"
  git branch -m "$1" &&
  git fetch origin &&
  git branch -u origin/"$1" "$1" &&
  git remote set-head origin -a
}'

#===================================
# Remote repository operations
#===================================

# Set remote repository URL
alias gsetremote='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Set remote origin URL.\nUsage:\n gsetremote <repo_url> [remote:origin]"
    return 1
  fi

  remote_name=${2:-origin}

  if ! git remote | grep -q "^${remote_name}$"; then
    git remote add "${remote_name}" "$1"
    echo "Remote ${remote_name} added with URL $1"
  else
    git remote set-url "${remote_name}" "$1"
    echo "Remote URL set to $1 for ${remote_name}"
  fi
}'

# Remove remote repository
alias grmremote='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Removing remote origin"
  git remote rm origin
}'

#===================================
# Clone operations
#===================================

# Clone repository
alias gclone='() {
  if ! _git_check_command; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Clone repository.\nUsage:\n gclone <repo_url> [folder:auto-name] [-b branch] [--additional-params]"
    echo "Example:\n gclone <repo_url> [folder_name] -b branch_name"
    return 1
  fi

  repo_url=$1
  shift

  # Default folder name from repo URL
  folder=""
  branch=""
  extra_args=""

  # Parse arguments
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -b|--branch)
        branch="$2"
        shift 2
        ;;
      -b=*|--branch=*)
        branch="${1#*=}"
        shift
        ;;
      -*)
        # Collect other git clone arguments
        extra_args="$extra_args $1"
        shift
        ;;
      *)
        # First non-option argument is the folder
        if [ -z "$folder" ]; then
          folder="$1"
        else
          # Add to extra args if more arguments
          extra_args="$extra_args $1"
        fi
        shift
        ;;
    esac
  done

  # If no folder specified, extract from repo URL
  if [ -z "$folder" ]; then
    folder=$(basename "$repo_url" .git)
  fi

  # Build the command
  clone_cmd="git clone"

  if [ -n "$branch" ]; then
    clone_cmd="$clone_cmd -b $branch"
  fi

  if [ -n "$extra_args" ]; then
    clone_cmd="$clone_cmd $extra_args"
  fi

  echo "Cloning $repo_url into $folder"
  if [ -n "$branch" ]; then
    echo "Using branch: $branch"
  fi

  # Execute the clone command
  eval "$clone_cmd \"$repo_url\" \"$folder\"" &&
  cd "$folder" && echo "Clone completed, changed directory to $folder"
}'

#===================================
# Staging operations
#===================================

# Unstage all files
alias gunstage='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Unstaging all staged changes"
  git restore --staged .
}'

# Restore working directory changes
alias grestore='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Restore changes in working directory.\nUsage:\n grestore <file_path>"
    return 1
  fi

  echo "Restoring changes in working directory"
  git restore "$@"
}'

#===================================
# Tag operations
#===================================

# Create and push tag
alias gtag='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Create Git tag.\nUsage:\n gtag <tag_name>"
    return 1
  fi

  echo "Creating tag $1"
  git tag "$1" -m "bump v${1}" &&
  git push --tags
}'

# List all tags
alias gltags='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Listing all Git tags"
  git tag -l | sort -V | xargs -n 1 -I {} echo {}
}'

# Delete local and remote tag
alias grmtag='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Remove Git tag.\nUsage:\n grmtag <tag_name>"
    return 1
  fi

  echo "Removing tag $1"
  git tag -d "$1" &&
  git push origin :refs/tags/"$1"
}'

# Remove all local tags
alias grmalltags='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Removing all Git tags"
  git tag -l | xargs git tag -d
}'

#===================================
# Logs and diffs
#===================================

# Get latest commit hash
alias ghash='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Getting latest commit hash"
  git rev-parse HEAD
}'

# Get latest commit date
alias gdate='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Getting latest commit date"
  git log -1 --format=%cd
}'

# View log with graph
alias glog='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Viewing Git log with graph"
  git log --oneline --decorate --graph "$@"
}'

#===================================
# Archive
#===================================

# Create archive of current repository
alias garchive='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Creating Git archive"
  current_branch=$(_git_current_branch)
  output_file="../$(basename $(pwd))_${current_branch}_$(date +%Y%m%d%H%M%S).zip"

  git archive -o "$output_file" "$current_branch" -0 &&
  echo "Archive created, exported to $output_file"
}'

#===================================
# GitHub operations
#===================================

# Create GitHub repository
alias ghcreate='() {
  if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI not found. Please install it first." >&2
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Create GitHub repository.\nUsage:\n ghcreate <repo_name> [repo_description]"
    return 1
  fi

  repo_name=${1}
  repo_desc=${2:-"A new repository"}

  echo "Creating GitHub repository: $repo_name"
  gh repo create "$repo_name" -y -d "$repo_desc"
  echo "GitHub repository $repo_name created successfully"
}'

# Initialize a new Git repository
alias ginit='() {
  if ! _git_check_command; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Initialize Git repository.\nUsage:\n ginit <repo_name>"
    return 1
  fi

  repo_name=${1}

  echo "Initializing new Git repository: $repo_name"
  mkdir -p "$repo_name"
  cd "$repo_name"
  git init -b main
  echo "# $repo_name" > README.md
  git add .
  git commit -m "chore: init"
  echo "Git repository initialized"
}'

#===================================
# GitHub downloads
#===================================

# Download GitHub repository branch
alias gdlbranch='() {
  if ! command -v wget &> /dev/null; then
    echo "Error: wget command not found. Please install it first." >&2
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Download GitHub project branch.\nUsage:\n gdlbranch <repository> [branch:main]"
    return 1
  fi

  repo=$1
  branch=${2:-main}
  output="$(basename $repo)_${branch}.tar.gz"

  echo "Downloading branch $branch from repository $repo..."
  wget -O "$output" --no-check-certificate --progress=bar:force "https://github.com/$repo/archive/refs/heads/${branch}.tar.gz" &&
  echo "Download complete, saved to $output"
}'

# Download GitHub repository tag
alias gdltag='() {
  if ! command -v wget &> /dev/null; then
    echo "Error: wget command not found. Please install it first." >&2
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Download GitHub project tag.\nUsage:\n gdltag <repository> [tag:v1.0.0]"
    return 1
  fi

  repo=$1
  tag=${2:-v1.0.0}
  output="$(basename $repo)_${tag}.zip"

  echo "Downloading tag $tag from repository $repo..."
  wget -O "$output" --no-check-certificate --progress=bar:force "https://github.com/$repo/archive/refs/tags/${tag}.zip" &&
  echo "Download complete, saved to $output"
}'

# Download GitHub repository release assets
alias gdlrelease='() {
  if ! command -v curl &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Error: curl or jq command not found. Please install them first." >&2
    return 1
  fi

  if [ $# -lt 1 ]; then
    echo "Download GitHub project release assets.\nUsage:\n gdlrelease <repository> [version:latest] [save_path]"
    return 1
  fi

  repo=$1
  version=${2:-latest}
  save_path="${3:-$1}"

  if [ "$save_path" = "$1" ]; then
    save_path="$save_path/$version"
  fi

  echo "Downloading release $version assets from repository $repo..."
  mkdir -p "$save_path"

  if [ "$version" = "latest" ]; then
    release_url="https://api.github.com/repos/$repo/releases/latest"
  else
    release_url="https://api.github.com/repos/$repo/releases/tags/$version"
  fi

  asset_urls=$(curl -s "$release_url" | jq -r ".assets[].browser_download_url")

  echo "$asset_urls" | while IFS= read -r asset_url; do
    if [ -n "$asset_url" ]; then
      filename=$(basename "$asset_url")
      echo "Downloading: $asset_url"
      curl -o "$save_path/$filename" -LJ "$asset_url"
      echo "Release asset $save_path/$filename downloaded"
    fi
  done
}'

# Help function for Git aliases
alias git-help='() {
  echo "Git Management Aliases Help"
  echo "========================="
  echo "Available commands:"
  echo "  Basic Git operations:"
  echo "  gadd              - Add specified files to staging area"
  echo "  gst               - Check repository status"
  echo "  gcmt              - Commit changes"
  echo "  gpush             - Push to remote repository"
  echo ""
  echo "  Branch operations:"
  echo "  gbranch           - Create and switch to new branch"
  echo "  gorphan           - Create a branch with no history"
  echo "  gco               - Switch to specified branch"
  echo "  gcomain           - Switch to main branch"
  echo "  gcodev            - Switch to dev branch"
  echo "  grmbr            - Delete specified branch(es) locally and optionally from remotes"
  echo "  gclbr            - Clean merged branches locally and optionally from remotes"
  echo "  gbranchl         - List all branches"
  echo ""
  echo "  Push operations:"
  echo "  gpushbr           - Push current or specified branch to remote"
  echo "  gtrack            - Set current branch to track remote"
  echo "  gpushall          - Push all branches to remote"
  echo "  gpushtags         - Push all tags to remote"
  echo "  gpushtagsf        - Force push all tags to remote"
  echo "  gpushallr         - Push current branch to all remotes"
  echo ""
  echo "  Pull operations:"
  echo "  gpull             - Pull updates from remote for current branch"
  echo "  gpullmain         - Pull main branch"
  echo "  gpulldev          - Pull dev branch"
  echo ""
  echo "  Merge operations:"
  echo "  gmerge            - Merge specified branch into current branch"
  echo "  gmergepush        - Merge specified branch into current branch and push"
  echo ""
  echo "  Reset operations:"
  echo "  gresetmain        - Reset to remote main branch"
  echo "  gresetdev         - Reset to remote dev branch"
  echo "  gresetcom         - Reset current branch to specified commit"
  echo "  gresetpush        - Reset current branch to commit and force push"
  echo ""
  echo "  Quick combined operations:"
  echo "  gaddcmt           - Add all and commit"
  echo "  gaddcmtpu         - Add all, commit and push"
  echo "  gcmtpush          - Commit and push"
  echo ""
  echo "  GitHub operations:"
  echo "  ghcreate          - Create GitHub repository"
  echo "  ginit             - Initialize a new Git repository"
  echo "  gdlbranch         - Download GitHub repository branch"
  echo "  gdltag            - Download GitHub repository tag"
  echo "  gdlrelease        - Download GitHub project release assets"
  echo ""
  echo "  git-help          - Display this help message"
}' # Display help for Git management aliases
