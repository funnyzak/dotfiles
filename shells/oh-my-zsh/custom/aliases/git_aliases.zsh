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

# Helper function to show error messages
_git_show_error() {
  echo "Error: $1" >&2
  return 1
}

#===================================
# Basic Git operations
#===================================

# Add specified files to staging area
alias gadd='() {
  echo -e "Add files to Git staging area.\nUsage:\n gadd [file_paths...]"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Adding files to staging area"
  git add "$@"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to add files to staging area. Check file paths and permissions."
    return 1
  fi

  return 0
}' # Add files to Git staging area

# Check repository status
alias gst='() {
  echo -e "Check Git repository status.\nUsage:\n gst"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Checking Git status"
  git status
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to get repository status."
    return 1
  fi

  return 0
}' # Check Git repository status

# Commit changes
alias gcmt='() {
  echo -e "Commit staged changes to Git repository.\nUsage:\n gcmt [-m "message"] [other_options]"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Committing changes"
  git commit "$@"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to commit changes. Make sure you have staged changes and provided a valid commit message."
    return 1
  fi

  return 0
}' # Commit staged changes to Git repository

# Push to remote repository
alias gpush='() {
  echo -e "Push commits to remote repository.\nUsage:\n gpush [remote:origin] [branch:current] [options]"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Pushing changes to remote"
  git push "$@"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to push changes. Check your network connection and remote repository access."
    return 1
  fi

  return 0
}' # Push commits to remote repository

#===================================
# Branch operations
#===================================

# Create and switch to new branch
alias gbranch='() {
  echo -e "Create and switch to a new Git branch.\nUsage:\n gbranch <branch_name:required>"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Branch name is required. Usage: gbranch <branch_name>"
    return 1
  fi

  local branch_name="$1"
  echo "Creating and switching to new branch: $branch_name"
  git checkout -b "$branch_name"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to create branch '$branch_name'. The branch may already exist or there might be uncommitted changes."
    return 1
  fi

  return 0
}' # Create and switch to a new Git branch

# Create a branch with no history
alias gorphan='() {
  echo -e "Create and switch to a new orphan branch (branch with no history).\nUsage:\n gorphan <branch_name:required>"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Branch name is required. Usage: gorphan <branch_name>"
    return 1
  fi

  local branch_name="$1"
  echo "Creating and switching to a new orphan branch: $branch_name"
  git checkout --orphan "$branch_name"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to create orphan branch '$branch_name'."
    return 1
  fi

  return 0
}' # Create and switch to a new orphan branch

# Switch to specified branch
alias gco='() {
  echo -e "Switch to specified Git branch.\nUsage:\n gco <branch_name:required>"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Branch name is required. Usage: gco <branch_name>"
    return 1
  fi

  local branch_name="$1"
  echo "Switching to branch: $branch_name"
  git checkout "$branch_name"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to switch to branch '$branch_name'. The branch may not exist or there might be uncommitted changes."
    return 1
  fi

  return 0
}' # Switch to specified Git branch

# Switch to main branch
alias gcomain='() {
  echo -e "Switch to main branch.\nUsage:\n gcomain"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Switching to main branch"
  git checkout main
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to switch to main branch. The branch may not exist or there might be uncommitted changes."
    return 1
  fi

  return 0
}' # Switch to main branch

# Switch to dev branch
alias gcodev='() {
  echo -e "Switch to dev branch.\nUsage:\n gcodev"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Switching to dev branch"
  git checkout dev
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to switch to dev branch. The branch may not exist or there might be uncommitted changes."
    return 1
  fi

  return 0
}' # Switch to dev branch

#===================================
# Push operations
#===================================

# Push current or specified branch to remote
alias gpushbr='() {
  echo -e "Push branch to remote repository.\nUsage:\n gpushbr [branch:current] [remote:origin]"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  local branch=${1:-$(_git_current_branch)}
  local remote=${2:-origin}

  echo "Pushing branch ${branch} to ${remote}"
  git push "${remote}" "${branch}"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to push branch '${branch}' to remote '${remote}'. Check your network connection and remote repository access."
    return 1
  fi

  return 0
}' # Push branch to remote repository

# Set current branch to track remote
alias gtrack='() {
  echo -e "Set current branch to track remote branch.\nUsage:\n gtrack"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  local current_branch=$(_git_current_branch)

  echo "Setting upstream tracking for branch: $current_branch"
  git branch --set-upstream-to=origin/$current_branch $current_branch
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to set upstream tracking. The remote branch may not exist."
    return 1
  fi

  return 0
}' # Set current branch to track remote branch

# Push all branches to remote
alias gpushall='() {
  echo -e "Push all branches to remote repository.\nUsage:\n gpushall"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Pushing all branches to remote"
  git push --all
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to push all branches. Check your network connection and remote repository access."
    return 1
  fi

  return 0
}' # Push all branches to remote repository

# Push all tags to remote
alias gpushtags='() {
  echo -e "Push all tags to remote repository.\nUsage:\n gpushtags [remote:origin] [-a|--all]"
  echo -e "Options:\n  -a, --all  Push tags to all remotes"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ "$1" = "-a" ] || [ "$1" = "--all" ]; then
    echo "Pushing all tags to all remotes"
    if ! git remote | grep -q .; then
      _git_show_error "No remote repositories found."
      return 1
    fi

    git remote | while read -r remote; do
      echo "Pushing tags to remote: ${remote}"
      git push "${remote}" --tags
      local push_status=$?

      if [ $push_status -ne 0 ]; then
        echo "Warning: Failed to push tags to remote '${remote}'." >&2
      fi
    done
  else
    local remote=${1:-origin}
    echo "Pushing all tags to remote: ${remote}"
    git push "${remote}" --tags
    local status=$?

    if [ $status -ne 0 ]; then
      _git_show_error "Failed to push tags to remote '${remote}'. Check your network connection and remote repository access."
      return 1
    fi
  fi

  return 0
}' # Push all tags to remote repository

# Force push all tags to remote
alias gpushtagsf='() {
  echo -e "Force push all tags to remote repository.\nUsage:\n gpushtagsf [remote:origin] [-a|--all]"
  echo -e "Options:\n  -a, --all  Force push tags to all remotes"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ "$1" = "-a" ] || [ "$1" = "--all" ]; then
    echo "Force pushing all tags to all remotes"
    if ! git remote | grep -q .; then
      _git_show_error "No remote repositories found."
      return 1
    fi

    git remote | while read -r remote; do
      echo "Force pushing tags to remote: ${remote}"
      git push "${remote}" --tags --force
      local push_status=$?

      if [ $push_status -ne 0 ]; then
        echo "Warning: Failed to force push tags to remote '${remote}'." >&2
      fi
    done
  else
    local remote=${1:-origin}
    echo "Force pushing all tags to remote: ${remote}"
    git push "${remote}" --tags --force
    local status=$?

    if [ $status -ne 0 ]; then
      _git_show_error "Failed to force push tags to remote '${remote}'. Check your network connection and remote repository access."
      return 1
    fi
  fi

  return 0
}' # Force push all tags to remote repository

# Push current branch to all remotes
alias gpushallr='() {
  echo -e "Push current branch to all remote repositories.\nUsage:\n gpushallr"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Pushing current branch to all remotes"
  local current_branch=$(_git_current_branch)

  if ! git remote | grep -q .; then
    _git_show_error "No remote repositories found."
    return 1
  fi

  local success=true
  git remote | while read -r remote; do
    echo "Pushing branch ${current_branch} to ${remote}"
    git push "${remote}" "${current_branch}"
    local push_status=$?

    if [ $push_status -ne 0 ]; then
      echo "Warning: Failed to push branch '${current_branch}' to remote '${remote}'." >&2
      success=false
    fi
  done

  if [ "$success" = false ]; then
    return 1
  fi

  return 0
}' # Push current branch to all remote repositories

#===================================
# Pull operations
#===================================

# Pull updates from remote for current branch
alias gpull='() {
  echo -e "Pull changes from remote repository for current branch.\nUsage:\n gpull [remote:origin]"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  local remote=${1:-origin}
  local branch=$(_git_current_branch)

  echo "Pulling changes from remote ${remote} for branch ${branch}"
  git pull ${remote} ${branch}
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to pull changes. There might be conflicts or network issues."
    return 1
  fi

  return 0
}' # Pull changes from remote repository for current branch

# Pull main branch
alias gpullmain='() {
  echo -e "Pull main branch from origin.\nUsage:\n gpullmain"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Pulling main branch from origin"
  git pull origin main
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to pull main branch. There might be conflicts or network issues."
    return 1
  fi

  return 0
}' # Pull main branch from origin

# Pull dev branch
alias gpulldev='() {
  echo -e "Pull dev branch from origin.\nUsage:\n gpulldev"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Pulling dev branch from origin"
  git pull origin dev
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to pull dev branch. There might be conflicts or network issues."
    return 1
  fi

  return 0
}' # Pull dev branch from origin

#===================================
# Merge operations
#===================================

# Merge specified branch into current branch
alias gmerge='() {
  echo -e "Merge target branch into current branch.\nUsage:\n gmerge <target_branch:required>"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Target branch name is required. Usage: gmerge <target_branch>"
    return 1
  fi

  local target_branch="$1"
  local current_branch=$(_git_current_branch)

  echo "Merging $target_branch into $current_branch"
  git merge "$target_branch"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to merge '$target_branch' into '$current_branch'. There might be conflicts."
    return 1
  fi

  return 0
}' # Merge target branch into current branch

# Merge specified branch into current branch and push
alias gmergepush='() {
  echo -e "Merge target branch into current branch and push to remote.\nUsage:\n gmergepush <target_branch:required>"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Target branch name is required. Usage: gmergepush <target_branch>"
    return 1
  fi

  local target_branch="$1"
  local current_branch=$(_git_current_branch)

  echo "Merging $target_branch into $current_branch and pushing"
  git merge "$target_branch" && git push
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to merge and push. There might be conflicts or network issues."
    return 1
  fi

  return 0
}' # Merge target branch into current branch and push to remote

#===================================
# Reset operations
#===================================

# Reset to remote main branch
alias gresetmain='() {
  echo -e "Reset current branch to match origin/main.\nUsage:\n gresetmain"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Resetting to origin/main"
  git reset --hard origin/main
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to reset to origin/main. The remote branch may not exist or there might be network issues."
    return 1
  fi

  return 0
}' # Reset current branch to match origin/main

# Reset to remote dev branch
alias gresetdev='() {
  echo -e "Reset current branch to match origin/dev.\nUsage:\n gresetdev"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Resetting to origin/dev"
  git reset --hard origin/dev
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to reset to origin/dev. The remote branch may not exist or there might be network issues."
    return 1
  fi

  return 0
}' # Reset current branch to match origin/dev

# Reset current branch to specified commit
alias gresetcom='() {
  echo -e "Reset current branch to specific commit.\nUsage:\n gresetcom <commit_id:required>"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Commit ID is required. Usage: gresetcom <commit_id>"
    return 1
  fi

  local commit_id="$1"
  echo "Resetting current branch to commit ${commit_id}"
  git reset --hard "${commit_id}"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to reset to commit '${commit_id}'. The commit may not exist."
    return 1
  fi

  return 0
}' # Reset current branch to specific commit

# Reset current branch to commit and force push
alias gresetpush='() {
  echo -e "Reset current branch to commit and force push to remote.\nUsage:\n gresetpush <commit_id:required> [remote:origin]"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Commit ID is required. Usage: gresetpush <commit_id> [remote:origin]"
    return 1
  fi

  local commit_id="$1"
  local remote_name=${2:-origin}
  local current_branch=$(_git_current_branch)

  echo "Resetting current branch to commit ${commit_id} and force pushing to ${remote_name}/${current_branch}"
  git reset --hard "${commit_id}" && git push "${remote_name}" --force
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to reset and force push. The commit may not exist or there might be network issues."
    return 1
  fi

  return 0
}' # Reset current branch to commit and force push to remote

#===================================
# Quick combined operations
#===================================

# Add all and commit
alias gaddcmt='() {
  echo -e "Add all changes and commit with message.\nUsage:\n gaddcmt [commit_message:chore:update]"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  local msg="${1:-chore:update}"
  echo "Adding and committing changes with message: ${msg}"

  git add .
  local add_status=$?

  if [ $add_status -ne 0 ]; then
    _git_show_error "Failed to add changes."
    return 1
  fi

  git commit -m "${msg}"
  local commit_status=$?

  if [ $commit_status -ne 0 ]; then
    _git_show_error "Failed to commit changes. There might be no changes to commit."
    return 1
  fi

  return 0
}' # Add all changes and commit with message

# Add all, commit and push
alias gaddcmtpu='() {
  echo -e "Add all changes, commit with message, and push to remote.\nUsage:\n gaddcmtpu [commit_message:chore:update]"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  local msg="${1:-chore:update}"
  echo "Adding, committing and pushing changes with message: ${msg}"

  git add .
  local add_status=$?

  if [ $add_status -ne 0 ]; then
    _git_show_error "Failed to add changes."
    return 1
  fi

  git commit -m "${msg}"
  local commit_status=$?

  if [ $commit_status -ne 0 ]; then
    _git_show_error "Failed to commit changes. There might be no changes to commit."
    return 1
  fi

  git push
  local push_status=$?

  if [ $push_status -ne 0 ]; then
    _git_show_error "Failed to push changes. Check your network connection and remote repository access."
    return 1
  fi

  return 0
}' # Add all changes, commit with message, and push to remote

# Commit and push
alias gcmtpush='() {
  echo -e "Commit with message and push to remote.\nUsage:\n gcmtpush [commit_message:chore:update]"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  local msg="${1:-chore:update}"
  echo "Committing and pushing changes with message: ${msg}"

  git commit -m "${msg}"
  local commit_status=$?

  if [ $commit_status -ne 0 ]; then
    _git_show_error "Failed to commit changes. There might be no staged changes to commit."
    return 1
  fi

  git push
  local push_status=$?

  if [ $push_status -ne 0 ]; then
    _git_show_error "Failed to push changes. Check your network connection and remote repository access."
    return 1
  fi

  return 0
}' # Commit with message and push to remote

#===================================
# Rebase operations
#===================================

# Rebase operation
alias grebase='() {
  echo -e "Rebase current branch onto target branch.\nUsage:\n grebase <target_branch:required> [start_commit:HEAD] [end_commit:1]"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Target branch name is required. Usage: grebase <target_branch> [start_commit] [end_commit]"
    return 1
  fi

  local target_branch="$1"
  local current_branch=$(_git_current_branch)

  echo "Rebasing $current_branch onto $target_branch"
  git rebase $target_branch ${2:-HEAD}~${3:-1}
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to rebase onto '$target_branch'. There might be conflicts."
    return 1
  fi

  return 0
}' # Rebase current branch onto target branch

#===================================
# Branch renaming
#===================================

# Rename current branch
alias grename='() {
  echo -e "Rename current branch.\nUsage:\n grename <new_name:required>"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "New branch name is required. Usage: grename <new_name>"
    return 1
  fi

  local new_name="$1"
  local current=$(_git_current_branch)

  echo "Renaming branch from $current to $new_name"
  git branch -m "$new_name"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to rename branch to '$new_name'. The name may already be in use."
    return 1
  fi

  return 0
}' # Rename current branch

# Rename and set remote tracking
alias grenametrack='() {
  echo -e "Rename current branch and set remote tracking.\nUsage:\n grenametrack <new_name:required>"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "New branch name is required. Usage: grenametrack <new_name>"
    return 1
  fi

  local new_name="$1"
  local current=$(_git_current_branch)

  echo "Renaming branch from $current to $new_name and setting remote tracking"

  git branch -m "$new_name"
  local rename_status=$?

  if [ $rename_status -ne 0 ]; then
    _git_show_error "Failed to rename branch to '$new_name'. The name may already be in use."
    return 1
  fi

  git fetch origin
  local fetch_status=$?

  if [ $fetch_status -ne 0 ]; then
    _git_show_error "Failed to fetch from origin. Check your network connection."
    return 1
  fi

  git branch -u origin/"$new_name" "$new_name"
  local track_status=$?

  if [ $track_status -ne 0 ]; then
    _git_show_error "Failed to set upstream tracking. The remote branch may not exist."
    return 1
  fi

  git remote set-head origin -a

  return 0
}' # Rename current branch and set remote tracking

#===================================
# Remote repository operations
#===================================

# Set remote repository URL
alias gsetremote='() {
  echo -e "Set remote origin URL.\nUsage:\n gsetremote <url:required>"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Remote URL is required. Usage: gsetremote <url>"
    return 1
  fi

  local remote_url="$1"
  echo "Setting remote origin URL to: $remote_url"
  git remote set-url origin "$remote_url"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to set remote URL."
    return 1
  fi

  return 0
}' # Set remote origin URL

# Remove remote repository
alias grmremote='() {
  echo -e "Remove remote origin.\nUsage:\n grmremote"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Removing remote origin"
  git remote rm origin
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to remove remote origin. It may not exist."
    return 1
  fi

  return 0
}' # Remove remote origin

#===================================
# Clone operations
#===================================

# Clone repository
alias gclone='() {
  echo -e "Clone Git repository.\nUsage:\n gclone <repo_url:required> [folder:auto-name]"

  if ! _git_check_command; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Repository URL is required. Usage: gclone <repo_url> [folder]"
    return 1
  fi

  local repo_url="$1"
  local folder=${2:-$(basename $1 .git)}

  echo "Cloning $repo_url into $folder"
  git clone "$repo_url" "$folder"
  local clone_status=$?

  if [ $clone_status -ne 0 ]; then
    _git_show_error "Failed to clone repository. Check the URL and your network connection."
    return 1
  fi

  cd "$folder" 2>/dev/null
  local cd_status=$?

  if [ $cd_status -ne 0 ]; then
    _git_show_error "Failed to change directory to $folder."
    return 1
  fi

  echo "Clone completed, changed directory to $folder"
  return 0
}' # Clone Git repository

#===================================
# Staging operations
#===================================

# Unstage all files
alias gunstage='() {
  echo -e "Unstage all staged changes.\nUsage:\n gunstage"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Unstaging all staged changes"
  git restore --staged .
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to unstage changes. There might be no staged changes."
    return 1
  fi

  return 0
}' # Unstage all staged changes

# Restore working directory changes
alias grestore='() {
  echo -e "Restore changes in working directory.\nUsage:\n grestore <file_path:required>"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "File path is required. Usage: grestore <file_path>"
    return 1
  fi

  echo "Restoring changes in working directory"
  git restore "$@"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to restore changes. The file may not exist or there might be no changes to restore."
    return 1
  fi

  return 0
}' # Restore changes in working directory

#===================================
# Tag operations
#===================================

# Create and push tag
alias gtag='() {
  echo -e "Create Git tag and push to remote.\nUsage:\n gtag <tag_name:required>"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Tag name is required. Usage: gtag <tag_name>"
    return 1
  fi

  local tag_name="$1"
  echo "Creating tag $tag_name"

  git tag "$tag_name" -m "bump v${tag_name}"
  local tag_status=$?

  if [ $tag_status -ne 0 ]; then
    _git_show_error "Failed to create tag '$tag_name'. The tag may already exist."
    return 1
  fi

  git push --tags
  local push_status=$?

  if [ $push_status -ne 0 ]; then
    _git_show_error "Failed to push tags. Check your network connection and remote repository access."
    return 1
  fi

  return 0
}' # Create Git tag and push to remote

# List all tags
alias gltags='() {
  echo -e "List all Git tags.\nUsage:\n gltags"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Listing all Git tags"
  git tag -l | sort -V | xargs -n 1 -I {} echo {}
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to list tags. There might be no tags in the repository."
    return 1
  fi

  return 0
}' # List all Git tags

# Delete local and remote tag
alias grmtag='() {
  echo -e "Remove Git tag locally and from remote.\nUsage:\n grmtag <tag_name:required>"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Tag name is required. Usage: grmtag <tag_name>"
    return 1
  fi

  local tag_name="$1"
  echo "Removing tag $tag_name"

  git tag -d "$tag_name"
  local local_status=$?

  if [ $local_status -ne 0 ]; then
    _git_show_error "Failed to remove local tag '$tag_name'. The tag may not exist."
    return 1
  fi

  git push origin :refs/tags/"$tag_name"
  local remote_status=$?

  if [ $remote_status -ne 0 ]; then
    echo "Warning: Failed to remove remote tag '$tag_name'. It may not exist on the remote." >&2
  fi

  return 0
}' # Remove Git tag locally and from remote

# Remove all local tags
alias grmalltags='() {
  echo -e "Remove all local Git tags.\nUsage:\n grmalltags"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Removing all Git tags"
  local tags=$(git tag -l)

  if [ -z "$tags" ]; then
    echo "No tags found to remove."
    return 0
  fi

  git tag -l | xargs git tag -d
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to remove all tags."
    return 1
  fi

  return 0
}' # Remove all local Git tags

#===================================
# Logs and diffs
#===================================

# Get latest commit hash
alias ghash='() {
  echo -e "Get latest commit hash.\nUsage:\n ghash"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Getting latest commit hash"
  git rev-parse HEAD
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to get commit hash. The repository may be empty."
    return 1
  fi

  return 0
}' # Get latest commit hash

# Get latest commit date
alias gdate='() {
  echo -e "Get latest commit date.\nUsage:\n gdate"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Getting latest commit date"
  git log -1 --format=%cd
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to get commit date. The repository may be empty."
    return 1
  fi

  return 0
}' # Get latest commit date

# View log with graph
alias glog='() {
  echo -e "View Git log with graph visualization.\nUsage:\n glog [options]"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Viewing Git log with graph"
  git log --oneline --decorate --graph "$@"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to display git log. The repository may be empty."
    return 1
  fi

  return 0
}' # View Git log with graph visualization

#===================================
# Archive
#===================================

# Create archive of current repository
alias garchive='() {
  echo -e "Create archive of current Git repository.\nUsage:\n garchive"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo "Creating Git archive"
  local current_branch=$(_git_current_branch)
  local output_file="../$(basename $(pwd))_${current_branch}_$(date +%Y%m%d%H%M%S).zip"

  git archive -o "$output_file" "$current_branch" -0
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to create archive. The branch may be empty or there might be permission issues."
    return 1
  fi

  echo "Archive created, exported to $output_file"
  return 0
}' # Create archive of current Git repository

#===================================
# GitHub operations
#===================================

# Create GitHub repository
alias ghcreate='() {
  echo -e "Create GitHub repository.\nUsage:\n ghcreate <repo_name:required> [repo_description:A new repository]"

  if ! command -v gh &> /dev/null; then
    _git_show_error "GitHub CLI not found. Please install it first."
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Repository name is required. Usage: ghcreate <repo_name> [repo_description]"
    return 1
  fi

  local repo_name="${1}"
  local repo_desc="${2:-A new repository}"

  echo "Creating GitHub repository: $repo_name"
  gh repo create "$repo_name" -y -d "$repo_desc"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to create GitHub repository. The name may already be in use or there might be authentication issues."
    return 1
  fi

  echo "GitHub repository $repo_name created successfully"
  return 0
}' # Create GitHub repository

# Initialize a new Git repository
alias ginit='() {
  echo -e "Initialize a new Git repository.\nUsage:\n ginit <repo_name:required>"

  if ! _git_check_command; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Repository name is required. Usage: ginit <repo_name>"
    return 1
  fi

  local repo_name="${1}"

  echo "Initializing new Git repository: $repo_name"
  mkdir -p "$repo_name"
  local mkdir_status=$?

  if [ $mkdir_status -ne 0 ]; then
    _git_show_error "Failed to create directory '$repo_name'. Check permissions or if it already exists."
    return 1
  fi

  cd "$repo_name"
  local cd_status=$?

  if [ $cd_status -ne 0 ]; then
    _git_show_error "Failed to change directory to '$repo_name'."
    return 1
  fi

  git init -b main
  local init_status=$?

  if [ $init_status -ne 0 ]; then
    _git_show_error "Failed to initialize Git repository."
    return 1
  fi

  echo "# $repo_name" > README.md
  git add .
  git commit -m "chore: init"

  echo "Git repository initialized"
  return 0
}' # Initialize a new Git repository

#===================================
# GitHub downloads
#===================================

# Download GitHub repository branch
alias gdlbranch='() {
  echo -e "Download GitHub project branch.\nUsage:\n gdlbranch <repository:required> [branch:main]"

  if ! command -v wget &> /dev/null; then
    _git_show_error "wget command not found. Please install it first."
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Repository is required. Usage: gdlbranch <repository> [branch:main]"
    return 1
  fi

  local repo="$1"
  local branch=${2:-main}
  local output="$(basename $repo)_${branch}.tar.gz"

  echo "Downloading branch $branch from repository $repo..."
  wget -O "$output" --no-check-certificate --progress=bar:force "https://github.com/$repo/archive/refs/heads/${branch}.tar.gz"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to download branch. Check the repository name, branch name, and your network connection."
    return 1
  fi

  echo "Download complete, saved to $output"
  return 0
}' # Download GitHub project branch

# Download GitHub repository tag
alias gdltag='() {
  echo -e "Download GitHub project tag.\nUsage:\n gdltag <repository:required> [tag:v1.0.0]"

  if ! command -v wget &> /dev/null; then
    _git_show_error "wget command not found. Please install it first."
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Repository is required. Usage: gdltag <repository> [tag:v1.0.0]"
    return 1
  fi

  local repo="$1"
  local tag=${2:-v1.0.0}
  local output="$(basename $repo)_${tag}.zip"

  echo "Downloading tag $tag from repository $repo..."
  wget -O "$output" --no-check-certificate --progress=bar:force "https://github.com/$repo/archive/refs/tags/${tag}.zip"
  local status=$?

  if [ $status -ne 0 ]; then
    _git_show_error "Failed to download tag. Check the repository name, tag name, and your network connection."
    return 1
  fi

  echo "Download complete, saved to $output"
  return 0
}' # Download GitHub project tag

# Download GitHub repository release assets
alias gdlrelease='() {
  echo -e "Download GitHub project release assets.\nUsage:\n gdlrelease <repository:required> [version:latest] [save_path]"

  if ! command -v curl &> /dev/null; then
    _git_show_error "curl command not found. Please install it first."
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    _git_show_error "jq command not found. Please install it first."
    return 1
  fi

  if [ $# -lt 1 ]; then
    _git_show_error "Repository is required. Usage: gdlrelease <repository> [version:latest] [save_path]"
    return 1
  fi

  local repo="$1"
  local version=${2:-latest}
  local save_path="${3:-$1}"

  if [ "$save_path" = "$1" ]; then
    save_path="$save_path/$version"
  fi

  echo "Downloading release $version assets from repository $repo..."
  mkdir -p "$save_path"
  local mkdir_status=$?

  if [ $mkdir_status -ne 0 ]; then
    _git_show_error "Failed to create directory '$save_path'. Check permissions."
    return 1
  fi

  local release_url
  if [ "$version" = "latest" ]; then
    release_url="https://api.github.com/repos/$repo/releases/latest"
  else
    release_url="https://api.github.com/repos/$repo/releases/tags/$version"
  fi

  local asset_urls=$(curl -s "$release_url" | jq -r ".assets[].browser_download_url")
  local curl_status=$?

  if [ $curl_status -ne 0 ] || [ -z "$asset_urls" ]; then
    _git_show_error "Failed to get release information. Check the repository name, version, and your network connection."
    return 1
  fi

  local download_success=true
  echo "$asset_urls" | while IFS= read -r asset_url; do
    if [ -n "$asset_url" ]; then
      local filename=$(basename "$asset_url")
      echo "Downloading: $asset_url"
      curl -o "$save_path/$filename" -LJ "$asset_url"
      local dl_status=$?

      if [ $dl_status -ne 0 ]; then
        echo "Warning: Failed to download asset from $asset_url" >&2
        download_success=false
      else
        echo "Release asset $save_path/$filename downloaded"
      fi
    fi
  done

  if [ "$download_success" = false ]; then
    return 1
  fi

  return 0
}' # Download GitHub project release assets

#===================================
# Branch deletion operations
#===================================

# Delete local branch and optionally remote branches
alias gdelbr='() {
  echo -e "Delete local branch and optionally remote branches.\nUsage:\n gdelbr <branch_name:required> [-r|-ra] [remote_name:origin]\nOptions:\n  -r   - Delete from specified remote (or origin if not specified)\n  -ra  - Delete from all remote repositories\nExamples:\n  gdelbr feature-123      - Delete local branch only\n  gdelbr feature-123 -r   - Delete local branch and remote branch on origin\n  gdelbr feature-123 -r github  - Delete local branch and remote branch on github\n  gdelbr feature-123 -ra  - Delete local branch and branch on all remotes"

  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ $# -eq 0 ]; then
    _git_show_error "Branch name is required. See usage above."
    return 1
  fi

  # Parse parameters
  local branch_name="$1"
  local delete_remote=""
  local remote_name="origin"

  # Check for remote deletion option
  if [ $# -gt 1 ]; then
    if [ "$2" = "-r" ]; then
      delete_remote="single"
      if [ $# -gt 2 ]; then
        remote_name="$3"
      fi
    elif [ "$2" = "-ra" ]; then
      delete_remote="all"
    fi
  fi

  # Verify branch exists locally
  if ! git show-ref --verify --quiet refs/heads/${branch_name}; then
    _git_show_error "Branch \"${branch_name}\" does not exist locally."
    return 1
  fi

  # Check if branch is the current branch
  local current_branch=$(_git_current_branch)
  if [ "${branch_name}" = "${current_branch}" ]; then
    _git_show_error "Cannot delete the current branch. Please switch to another branch first."
    return 1
  fi

  # Delete local branch
  echo "Deleting local branch \"${branch_name}\"..."
  if git branch -D "${branch_name}"; then
    echo "Local branch \"${branch_name}\" deleted successfully."
  else
    _git_show_error "Failed to delete local branch \"${branch_name}\"."
    return 1
  fi

  # Handle remote branch deletion if requested
  if [ "${delete_remote}" = "single" ]; then
    echo "Deleting remote branch \"${branch_name}\" from \"${remote_name}\"..."
    if git push "${remote_name}" --delete "${branch_name}" 2>/dev/null; then
      echo "Remote branch \"${branch_name}\" deleted from \"${remote_name}\" successfully."
    else
      echo "Warning: Failed to delete remote branch \"${branch_name}\" from \"${remote_name}\". It might not exist." >&2
    fi
  elif [ "${delete_remote}" = "all" ]; then
    if ! git remote | grep -q .; then
      echo "No remote repositories found." >&2
    else
      git remote | while read -r remote; do
        echo "Deleting remote branch \"${branch_name}\" from \"${remote}\"..."
        if git push "${remote}" --delete "${branch_name}" 2>/dev/null; then
          echo "Remote branch \"${branch_name}\" deleted from \"${remote}\" successfully."
        else
          echo "Warning: Failed to delete remote branch \"${branch_name}\" from \"${remote}\". It might not exist." >&2
        fi
      done
    fi
  fi

  return 0
}' # Delete local branch and optionally remote branches


# Help function for Git aliases
alias git-help='() {
  echo -e "Git Management Aliases Help\nUsage:\n git-help"

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
  echo "  gdelbr            - Delete local branch and optionally remote branches"
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