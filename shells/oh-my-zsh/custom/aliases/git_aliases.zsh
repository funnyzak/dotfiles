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
alias git_add='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Adding files to staging area"
  git add "$@"
}'

# Check repository status
alias git_status='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Checking Git status"
  git status
}'

# Commit changes
alias git_commit='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Committing changes"
  git commit "$@"
}'

# Push to remote repository
alias git_push='() {
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
alias git_branch_new='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Create and switch to new branch.\nUsage:\n git_branch_new <branch_name>"
    return 1
  fi
  
  echo "Creating and switching to new branch"
  git checkout -b "$1"
}'

# Create a branch with no history
alias git_branch_orphan='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Create and switch to a new orphan branch.\nUsage:\n git_branch_orphan <branch_name>"
    return 1
  fi
  
  echo "Creating and switching to a new orphan branch"
  git checkout --orphan "$@"
}'

# Switch to specified branch
alias git_checkout='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Switch to specified branch.\nUsage:\n git_checkout <branch_name>"
    return 1
  fi
  
  echo "Switching branch"
  git checkout "$@"
}'

# Switch to main branch
alias git_checkout_main='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Switching to main branch"
  git checkout main
}'

# Switch to dev branch
alias git_checkout_dev='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Switching to dev branch"
  git checkout dev
}'

#===================================
# Push operations
#===================================

# Push current or specified branch to remote
alias git_push_branch='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  remote=${2:-origin}
  branch=${1:-$(_git_current_branch)}
  
  if [ $# -eq 0 ]; then
    echo "Push branch to remote.\nUsage:\n git_push_branch [branch:current] [remote:origin]"
  fi
  
  echo "Pushing branch ${branch} to ${remote}"
  git push "${remote}" "${branch}"
}'

# Set current branch to track remote
alias git_track_remote='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  current_branch=$(_git_current_branch)
  
  echo "Setting upstream tracking branch"
  git branch --set-upstream-to=origin/$current_branch $current_branch
}'

# Push all branches to remote
alias git_push_all='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Pushing all branches to remote"
  git push --all
}'

# Push all tags to remote
alias git_push_tags='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Pushing all tags to remote"
  git push --tags
}'

# Force push all tags to remote
alias git_push_tags_force='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Force pushing all tags to remote"
  git push --tags --force
}'

# Push current branch to all remotes
alias git_push_all_remotes='() {
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
alias git_pull='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Pull changes from remote.\nUsage:\n git_pull [remote:origin]"
  fi
  
  remote=${1:-origin}
  branch=$(_git_current_branch)
  
  echo "Pulling changes from remote ${remote} for branch ${branch}"
  git pull ${remote} ${branch}
}'

# Pull main branch
alias git_pull_main='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Pulling main branch from origin"
  git pull origin main
}'

# Pull dev branch
alias git_pull_dev='() {
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
alias git_merge='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Merge target branch into current branch.\nUsage:\n git_merge <target_branch>"
    return 1
  fi
  
  current_branch=$(_git_current_branch)
  echo "Merging $1 into $current_branch"
  git merge "$1"
}'

# Merge specified branch into current branch and push
alias git_merge_push='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Merge target branch into current branch and push.\nUsage:\n git_merge_push <target_branch>"
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
alias git_reset_main='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Resetting to origin/main"
  git reset --hard origin/main
}'

# Reset to remote dev branch
alias git_reset_dev='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Resetting to origin/dev"
  git reset --hard origin/dev
}'

# Reset current branch to specified commit
alias git_reset_commit='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Reset current branch to specific commit.\nUsage:\n git_reset_commit <commit_id>"
    return 1
  fi
  
  commit_id=$1
  echo "Resetting current branch to commit ${commit_id}"
  git reset --hard "${commit_id}"
}'

# Reset current branch to commit and force push
alias git_reset_push_force='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Reset current branch to commit and force push.\nUsage:\n git_reset_push_force <commit_id> [remote:origin]"
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
alias git_add_commit='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  msg="${1:-chore:update}"
  echo "Adding and committing changes with message: ${msg}"
  git add .
  git commit -m "${msg}"
}'

# Add all, commit and push
alias git_add_commit_push='() {
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
alias git_commit_push='() {
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
alias git_rebase='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Rebase current branch onto target branch.\nUsage:\n git_rebase <target_branch> [start_commit] [end_commit]"
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
alias git_rename_branch='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Rename current branch.\nUsage:\n git_rename_branch <new_name>"
    return 1
  fi
  
  current=$(_git_current_branch)
  echo "Renaming branch from $current to $1"
  git branch -m "$1"
}'

# Rename and set remote tracking
alias git_rename_track='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Rename current branch and set remote tracking.\nUsage:\n git_rename_track <new_name>"
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
alias git_set_remote='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Set remote origin URL.\nUsage:\n git_set_remote <url>"
    return 1
  fi
  
  echo "Setting remote origin URL"
  git remote set-url origin "$1"
}'

# Remove remote repository
alias git_remove_remote='() {
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
alias git_clone='() {
  if ! _git_check_command; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Clone repository.\nUsage:\n git_clone <repo_url> [folder:auto-name]"
    return 1
  fi
  
  repo_url=$1
  folder=${2:-$(basename $1 .git)}
  
  echo "Cloning $repo_url into $folder"
  git clone "$repo_url" "$folder" &&
  cd "$folder" && echo "Clone completed, changed directory to $folder"
}'

#===================================
# Staging operations
#===================================

# Unstage all files
alias git_unstage='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Unstaging all staged changes"
  git restore --staged .
}'

# Restore working directory changes
alias git_restore='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Restore changes in working directory.\nUsage:\n git_restore <file_path>"
    return 1
  fi
  
  echo "Restoring changes in working directory"
  git restore "$@"
}'

#===================================
# Tag operations
#===================================

# Create and push tag
alias git_tag='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Create Git tag.\nUsage:\n git_tag <tag_name>"
    return 1
  fi
  
  echo "Creating tag $1"
  git tag "$1" -m "bump v${1}" &&
  git push --tags
}'

# List all tags
alias git_list_tags='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Listing all Git tags"
  git tag -l | sort -V | xargs -n 1 -I {} echo {}
}'

# Delete local and remote tag
alias git_remove_tag='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Remove Git tag.\nUsage:\n git_remove_tag <tag_name>"
    return 1
  fi
  
  echo "Removing tag $1"
  git tag -d "$1" &&
  git push origin :refs/tags/"$1"
}'

# Remove all local tags
alias git_remove_all_tags='() {
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
alias git_hash='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Getting latest commit hash"
  git rev-parse HEAD
}'

# Get latest commit date
alias git_date='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi
  
  echo "Getting latest commit date"
  git log -1 --format=%cd
}'

# View log with graph
alias git_log='() {
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
alias git_archive='() {
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
alias git_hub_create='() {
  if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI not found. Please install it first." >&2
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Create GitHub repository.\nUsage:\n git_hub_create <repo_name> [repo_description]"
    return 1
  fi
  
  repo_name=${1}
  repo_desc=${2:-"A new repository"}
  
  echo "Creating GitHub repository: $repo_name"
  gh repo create "$repo_name" -y -d "$repo_desc"
  echo "GitHub repository $repo_name created successfully"
}'

# Initialize a new Git repository
alias git_init='() {
  if ! _git_check_command; then
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Initialize Git repository.\nUsage:\n git_init <repo_name>"
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
alias git_download_branch='() {
  if ! command -v wget &> /dev/null; then
    echo "Error: wget command not found. Please install it first." >&2
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Download GitHub project branch.\nUsage:\n git_download_branch <repository> [branch:main]"
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
alias git_download_tag='() {
  if ! command -v wget &> /dev/null; then
    echo "Error: wget command not found. Please install it first." >&2
    return 1
  fi
  
  if [ $# -eq 0 ]; then
    echo "Download GitHub project tag.\nUsage:\n git_download_tag <repository> [tag:v1.0.0]"
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
alias git_download_release='() {
  if ! command -v curl &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Error: curl or jq command not found. Please install them first." >&2
    return 1
  fi
  
  if [ $# -lt 1 ]; then
    echo "Download GitHub project release assets.\nUsage:\n git_download_release <repository> [version:latest] [save_path]"
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
