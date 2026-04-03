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

  echo -e "Push current or specified branch to remote.\nUsage:\n gpushbr [branch:current] [-r remote:origin]"

  local branch_name=""
  local remote_name="origin"

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      -r)
        if [ $# -lt 2 ]; then
          echo "Error: -r option requires a remote name" >&2
          return 1
        fi
        remote_name="$2"
        shift 2
        ;;
      *)
        if [ -z "$branch_name" ]; then
          branch_name="$1"
        else
          echo "Error: Multiple branch names specified" >&2
          return 1
        fi
        shift
        ;;
    esac
  done

  # Use current branch if no branch specified
  if [ -z "$branch_name" ]; then
    branch_name=$(_git_current_branch)
  fi

  echo "Pushing branch ${branch_name} to ${remote_name}"
  git push "${remote_name}" "${branch_name}"
}'

# Set current branch to track remote
alias gtrack='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo -e "Set current branch to track remote.\nUsage:\n gtrack [-r remote:origin]"

  local remote_name="origin"

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      -r)
        if [ $# -lt 2 ]; then
          echo "Error: -r option requires a remote name" >&2
          return 1
        fi
        remote_name="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown argument $1" >&2
        return 1
        ;;
    esac
  done

  local current_branch=$(_git_current_branch)

  echo "Setting upstream tracking branch for ${current_branch} to ${remote_name}/${current_branch}"
  git branch --set-upstream-to="${remote_name}/${current_branch}" "${current_branch}"
}'

# Push all branches to remote
alias gpushall='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo -e "Push all branches to remote.\nUsage:\n gpushall [-r remote:origin]"

  local remote_name="origin"

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      -r)
        if [ $# -lt 2 ]; then
          echo "Error: -r option requires a remote name" >&2
          return 1
        fi
        remote_name="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown argument $1" >&2
        return 1
        ;;
    esac
  done

  echo "Pushing all branches to ${remote_name}"
  git push --all "${remote_name}"
}'

# Push all tags to remote
alias gpushtags='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo -e "Push all tags to remote.\nUsage:\n gpushtags [-r remote:origin]"

  local remote_name="origin"

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      -r)
        if [ $# -lt 2 ]; then
          echo "Error: -r option requires a remote name" >&2
          return 1
        fi
        remote_name="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown argument $1" >&2
        return 1
        ;;
    esac
  done

  echo "Pushing all tags to ${remote_name}"
  git push --tags "${remote_name}"
}'

# Force push all tags to remote
alias gpushtagsf='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  echo -e "Force push all tags to remote.\nUsage:\n gpushtagsf [-r remote:origin]"

  local remote_name="origin"

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      -r)
        if [ $# -lt 2 ]; then
          echo "Error: -r option requires a remote name" >&2
          return 1
        fi
        remote_name="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown argument $1" >&2
        return 1
        ;;
    esac
  done

  echo "Force pushing all tags to ${remote_name}"
  git push --tags --force "${remote_name}"
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
    echo -e "Remove Git tag locally and optionally from remote.\nUsage:\n grmtag <tag_name> [-r] [remote_name:origin]"
    echo -e "Examples:\n grmtag v1.0.0\n grmtag v1.0.0 -r\n grmtag v1.0.0 -r upstream"
    return 1
  fi

  local tag_name="$1"
  local remove_remote=false
  local remote_name="origin"

  # Parse arguments
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      -r)
        remove_remote=true
        shift
        ;;
      *)
        if [ "$remove_remote" = true ]; then
          remote_name="$1"
        fi
        shift
        ;;
    esac
  done

  # Remove local tag
  echo "Removing local tag: $tag_name"
  if ! git tag -d "$tag_name"; then
    echo "Error: Failed to remove local tag $tag_name" >&2
    return 1
  fi

  # Remove remote tag if requested
  if [ "$remove_remote" = true ]; then
    echo "Removing remote tag: $tag_name from $remote_name"
    if ! git push "$remote_name" :refs/tags/"$tag_name"; then
      echo "Error: Failed to remove remote tag $tag_name from $remote_name" >&2
      return 1
    fi
  fi

  echo "Tag $tag_name removed successfully"
}'

alias grmalltags='() {
  if ! _git_check_command || ! _git_check_repository; then
    return 1
  fi

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo -e "Remove all Git tags locally and optionally from remote.\nUsage:\n grmalltags [-r] [remote_name:origin]"
    echo -e "Examples:\n grmalltags\n grmalltags -r\n grmalltags -r upstream"
    return 0
  fi

  local remove_remote=false
  local remote_name="origin"

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      -r)
        remove_remote=true
        shift
        ;;
      *)
        if [ "$remove_remote" = true ]; then
          remote_name="$1"
        fi
        shift
        ;;
    esac
  done

  # Get all local tags
  local tags
  tags=$(git tag -l)

  if [ -z "$tags" ]; then
    echo "No tags found in repository"
    return 0
  fi

  echo "Removing all local tags..."
  if ! echo "$tags" | xargs git tag -d; then
    echo "Error: Failed to remove some local tags" >&2
    return 1
  fi

  # Remove remote tags if requested
  if [ "$remove_remote" = true ]; then
    echo "Removing all remote tags from $remote_name..."
    local failed_tags=""

    echo "$tags" | while read -r tag; do
      if [ -n "$tag" ]; then
        if ! git push "$remote_name" ":refs/tags/$tag" 2>/dev/null; then
          failed_tags="$failed_tags $tag"
        fi
      fi
    done

    if [ -n "$failed_tags" ]; then
      echo "Warning: Failed to remove some remote tags:$failed_tags" >&2
    fi
  fi

  echo "All tags removed successfully"
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
alias gh-dl-branch='() {
  if ! command -v wget &> /dev/null; then
    echo "Error: wget command not found. Please install it first." >&2
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Download GitHub project branch.\nUsage:\n gh-dl-branch <repository> [branch:main]"
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
alias gh-dl-tag='() {
  if ! command -v wget &> /dev/null; then
    echo "Error: wget command not found. Please install it first." >&2
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "Download GitHub project tag.\nUsage:\n gh-dl-tag <repository> [tag:v1.0.0]"
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
alias gh-dl-release='() {
  if ! command -v curl &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Error: curl or jq command not found. Please install them first." >&2
    return 1
  fi

  if [ $# -lt 1 ]; then
    echo "Download GitHub project release assets.\nUsage:\n gh-dl-release <repository> [version:latest] [save_path]"
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

alias gh-to-ssh='() {
  # Convert HTTPS GitHub URLs to SSH format recursively
  echo -e "Convert HTTPS GitHub URLs to SSH format recursively.\nUsage:\n gh-to-ssh [search_directory:.] [--dry-run] [--verbose]"
  echo -e "Examples:\n gh-to-ssh\n gh-to-ssh ~/projects --verbose\n gh-to-ssh . --dry-run"

  local search_directory="${1:-.}"
  local is_dry_run=false
  local is_verbose=false
  local converted_count=0
  local total_repository_count=0
  local converted_repositories=()
  local failed_repositories=()

  # Parse optional parameters
  for argument in "$@"; do
    case "$argument" in
      --dry-run)
        is_dry_run=true
        ;;
      --verbose)
        is_verbose=true
        ;;
      -*)
        echo "Error: Unknown option $argument" >&2
        echo "Usage: gh-to-ssh [search_directory:.] [--dry-run] [--verbose]" >&2
        return 1
        ;;
    esac
  done

  # Validate search directory
  if [[ ! -d "$search_directory" ]]; then
    echo "Error: Directory \"$search_directory\" does not exist" >&2
    return 1
  fi

  # Check if git is available
  if ! command -v git >/dev/null 2>&1; then
    echo "Error: Git is not installed or not in PATH" >&2
    return 1
  fi

  # Check if find command is available
  if ! command -v find >/dev/null 2>&1; then
    echo "Error: find command is not available" >&2
    return 1
  fi

  # Check if sed command is available
  if ! command -v sed >/dev/null 2>&1; then
    echo "Error: sed command is not available" >&2
    return 1
  fi

  echo "Searching for Git repositories in: $search_directory"
  if [[ "$is_dry_run" == "true" ]]; then
    echo "DRY RUN MODE - No changes will be made"
  fi
  echo "----------------------------------------"

  # Find all .git directories and process them
  while IFS= read -r -d "" git_directory; do
    local repository_path
    repository_path=$(dirname "$git_directory")

    # Skip if not a valid git repository
    if [[ ! -d "$git_directory" ]] || [[ ! -f "$git_directory/config" ]]; then
      if [[ "$is_verbose" == "true" ]]; then
        echo "Warning: Skipping invalid git directory: $git_directory" >&2
      fi
      continue
    fi

    total_repository_count=$((total_repository_count + 1))

    # Get current remote URL with error handling
    local current_remote_url
    if ! current_remote_url=$(cd "$repository_path" && git remote get-url origin 2>/dev/null); then
      if [[ "$is_verbose" == "true" ]]; then
        echo "Warning: Failed to get remote URL for repository: $repository_path" >&2
      fi
      continue
    fi

    # Validate that we got a non-empty URL
    if [[ -z "$current_remote_url" ]]; then
      if [[ "$is_verbose" == "true" ]]; then
        echo "Warning: Empty remote URL for repository: $repository_path" >&2
      fi
      continue
    fi

    # Check if URL is HTTPS GitHub format
    if [[ "$current_remote_url" =~ ^https://github\.com/ ]]; then
      # Convert HTTPS to SSH format
      local ssh_remote_url
      ssh_remote_url=$(echo "$current_remote_url" | sed "s|^https://github\.com/|git@github.com:|")

      # Validate the conversion was successful
      if [[ -z "$ssh_remote_url" ]] || [[ "$ssh_remote_url" == "$current_remote_url" ]]; then
        echo "Error: Failed to convert URL format for repository: $repository_path" >&2
        failed_repositories+=("$repository_path")
        continue
      fi

      if [[ "$is_verbose" == "true" ]]; then
        echo "Repository: $repository_path"
        echo "  Current URL: $current_remote_url"
        echo "  New URL: $ssh_remote_url"
      fi

      if [[ "$is_dry_run" == "true" ]]; then
        echo "Would convert: $repository_path"
        echo "  $current_remote_url -> $ssh_remote_url"
        converted_repositories+=("$repository_path")
        converted_count=$((converted_count + 1))
      else
        # Convert to SSH with proper error handling
        if (cd "$repository_path" && git remote set-url origin "$ssh_remote_url") 2>/dev/null; then
          # Verify the change was successful
          local verification_url
          if verification_url=$(cd "$repository_path" && git remote get-url origin 2>/dev/null) && [[ "$verification_url" == "$ssh_remote_url" ]]; then
            converted_count=$((converted_count + 1))
            converted_repositories+=("$repository_path")
            echo "✓ Converted: $repository_path"
            if [[ "$is_verbose" == "true" ]]; then
              echo "  $current_remote_url -> $ssh_remote_url"
            fi
          else
            failed_repositories+=("$repository_path")
            echo "✗ Error: Verification failed for repository: $repository_path" >&2
          fi
        else
          failed_repositories+=("$repository_path")
          echo "✗ Error: Failed to set remote URL for repository: $repository_path" >&2
        fi
      fi
    elif [[ "$is_verbose" == "true" ]]; then
      echo "Skipped: $repository_path (not HTTPS GitHub URL: $current_remote_url)"
    fi
  done < <(find "$search_directory" -name ".git" -type d -print0 2>/dev/null)

  # Check if find command succeeded
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to search for git repositories in directory: $search_directory" >&2
    return 1
  fi

  echo "----------------------------------------"
  echo "Summary:"
  echo "  Total repositories found: $total_repository_count"
  if [[ "$is_dry_run" == "true" ]]; then
    echo "  Would convert: $converted_count repositories"
  else
    echo "  Successfully converted: $converted_count repositories"
    if [[ ${#failed_repositories[@]} -gt 0 ]]; then
      echo "  Failed to convert: ${#failed_repositories[@]} repositories"
    fi
  fi

  # List converted repositories
  if [[ ${#converted_repositories[@]} -gt 0 ]]; then
    echo ""
    if [[ "$is_dry_run" == "true" ]]; then
      echo "Repositories that would be converted:"
    else
      echo "Successfully converted repositories:"
    fi
    for repository in "${converted_repositories[@]}"; do
      echo "  ✓ $repository"
    done
  fi

  # List failed repositories
  if [[ ${#failed_repositories[@]} -gt 0 ]]; then
    echo ""
    echo "Failed to convert repositories:"
    for repository in "${failed_repositories[@]}"; do
      echo "  ✗ $repository"
    done
    return 1
  fi

  return 0
}' # Convert HTTPS GitHub URLs to SSH format recursively




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
  echo "  gtag              - Create and push tag"
  echo "  gltags            - List all tags"
  echo "  grmtag            - Remove local and remote tag"
  echo "  grmalltags        - Remove all local and remote tags"
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
  echo "  gh-dl-branch         - Download GitHub repository branch"
  echo "  gh-dl-tag            - Download GitHub repository tag"
  echo "  gh-dl-release        - Download GitHub project release assets"
  echo "  gh-to-ssh         - Convert HTTPS GitHub URLs to SSH format recursively"
  echo ""
  echo "  git-help          - Display this help message"
}' # Display help for Git management aliases
