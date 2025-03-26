# Description: Git related aliases for common git commands and workflows.

# Basic operations
alias gad='echo "Adding files to staging area" && git add'  # Add specified files to staging area
alias gss='echo "Checking Git status" && git status'  # Check repository status
alias gct='echo "Committing changes" && git commit'   # Commit changes
alias gp='echo "Pushing changes to remote" && git push'  # Push to remote repository

# Branch operations
alias gcob='echo "Creating and switching to new branch" && git checkout -b'  # Create and switch to new branch
alias gcobo='() {
  if [ $# -eq 0 ]; then
    echo "Create and switch to a new orphan branch.\nUsage:\n gcobo <branch_name>"
    return 1
  fi
  echo "Creating and switching to a new orphan branch"
  git checkout --orphan $@
}'  # Create a branch with no history

alias gco='echo "Switching branch" && git checkout'  # Switch to specified branch
alias gcom='echo "Switching to main branch" && git checkout main'  # Switch to main branch
alias gcod='echo "Switching to dev branch" && git checkout dev'  # Switch to dev branch

# Push operations
alias gpb='() {
  if [ $# -eq 0 ]; then
    echo "Push branch to remote.\nUsage:\n gpb [branch:current] [remote:origin]"
  fi
  remote=${2:-origin}
  branch=${1:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")}
  echo "Pushing branch ${branch} to ${remote}"
  git push ${remote} ${branch}
}'  # Push current or specified branch to remote

alias gsettrack='() {
  echo "Setting upstream tracking branch"
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  git branch --set-upstream-to=origin/$current_branch $current_branch
}'  # Set current branch to track remote

alias gpall='echo "Pushing all branches to remote" && git push --all'  # Push all branches to remote
alias gptags='echo "Pushing all tags to remote" && git push --tags'  # Push all tags to remote
alias gptagsf='echo "Force pushing all tags to remote" && git push --tags --force'  # Force push all tags
alias gpallr='() {
  echo "Pushing current branch to all remotes"
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  if ! git remote | grep -q .; then
    echo "No remote repositories found."
    return 1
  fi
  git remote | while read -r remote; do
    echo "Pushing branch ${current_branch} to ${remote}"
    git push "${remote}" "${current_branch}"
  done
}'  # Push current branch to all remote repositories

# Pull operations
alias gpl='() {
  if [ $# -eq 0 ]; then
    echo "Pull changes from remote.\nUsage:\n gpl [remote:origin]"
  fi
  remote=${1:-origin}
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  echo "Pulling changes from remote ${remote} for branch ${branch}"
  git pull ${remote} ${branch}
}'  # Pull updates from remote for current branch

alias glom='echo "Pulling main branch from origin" && git pull origin main'  # Pull main branch
alias glod='echo "Pulling dev branch from origin" && git pull origin dev'  # Pull dev branch

# Merge operations
alias gmge='() {
  if [ $# -eq 0 ]; then
    echo "Merge target branch into current branch.\nUsage:\n gmge <target_branch>"
    return 1
  else
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    echo "Merging $1 into $current_branch"
    git merge $1
  fi
}'  # Merge specified branch into current branch

alias gmgep='() {
  if [ $# -eq 0 ]; then
    echo "Merge target branch into current branch and push.\nUsage:\n gmgep <target_branch>"
    return 1
  else
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    echo "Merging $1 into $current_branch and pushing"
    git merge $1 && git push
  fi
}'  # Merge and push in one command

# Reset operations
alias grom='echo "Resetting to origin/main" && git reset --hard origin/main'  # Reset to remote main branch
alias grod='echo "Resetting to origin/dev" && git reset --hard origin/dev'  # Reset to remote dev branch

alias grc='() {
  if [ $# -eq 0 ]; then
    echo "Reset current branch to specific commit.\nUsage:\n grc <commit_id>"
    return 1
  else
    commit_id=$1
    echo "Resetting current branch to commit ${commit_id}"
    git reset --hard ${commit_id}
  fi
}'  # Reset current branch to specified commit

alias grcgpf='() {
  if [ $# -eq 0 ]; then
    echo "Reset current branch to commit and force push.\nUsage:\n grcgpf <commit_id> [remote:origin]"
    return 1
  else
    commit_id=$1
    remote_name=${2:-origin}
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    echo "Resetting current branch to commit ${commit_id} and force pushing to ${remote_name}/${current_branch}"
    git reset --hard ${commit_id} && git push ${remote_name} --force
  fi
}'  # Reset and force push

# Quick combined operations
alias gam='() {
  msg="${1:-chore:update}"
  echo "Adding and committing changes with message: ${msg}"
  git add .
  git commit -m "${msg}"
}'  # Add all and commit

alias gamp='() {
  msg="${1:-chore:update}"
  echo "Adding, committing and pushing changes with message: ${msg}"
  git add .
  git commit -m "${msg}" &&
  git push
}'  # Add all, commit and push

alias gmp='() {
  msg="${1:-chore:update}"
  echo "Committing and pushing changes with message: ${msg}"
  git commit -m "${msg}" &&
  git push
}'  # Commit and push

# Rebase operations
alias gmr='() {
  if [ $# -eq 0 ]; then
    echo "Rebase current branch onto target branch.\nUsage:\n gmr <target_branch> [start_commit] [end_commit]"
    return 1
  else
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    echo "Rebasing $current_branch onto $1"
    git rebase $1 ${2:-HEAD}~${3:-1}
  fi
}'  # Rebase operation

# Branch renaming
alias grename='() {
  if [ $# -eq 0 ]; then
    echo "Rename current branch.\nUsage:\n grename <new_name>"
    return 1
  else
    current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    echo "Renaming branch from $current to $1"
    git branch -m $1
  fi
}'  # Rename current branch

alias grname_and_track='() {
  if [ $# -eq 0 ]; then
    echo "Rename current branch and set remote tracking.\nUsage:\n grname_and_track <new_name>"
    return 1
  else
    current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    echo "Renaming branch from $current to $1 and setting remote tracking"
    git branch -m $1 &&
    git fetch origin &&
    git branch -u origin/$1 $1 &&
    git remote set-head origin -a
  fi
}'  # Rename and set remote tracking

# Remote repository operations
alias grso='echo "Setting remote origin URL" && git remote set-url origin'  # Set remote repository URL
alias grmo='() {
  echo "Removing remote origin"
  git remote rm origin
}'  # Remove remote repository

# Clone operations
alias gcl='() {
  if [ $# -eq 0 ]; then
    echo "Clone repository.\nUsage:\n gcl <repo_url> [folder:auto-name]"
    return 1
  else
    repo_url=$1
    folder=${2:-$(basename $1 .git)}
    git clone $repo_url $folder &&
    cd $folder && echo "Clone completed, changed directory to $folder"
  fi
}'  # Clone and switch to specified branch

# Staging operations
alias gsu='echo "Unstaging all staged changes" && git restore --staged .'  # Unstage all files
alias grs='echo "Restoring changes in working directory" && git restore'  # Restore working directory changes

# Tag operations
alias gtag='() {
  if [ $# -eq 0 ]; then
    echo "Create Git tag.\nUsage:\n gtag <tag_name>"
    return 1
  else
    echo "Creating tag $1"
    git tag $1 -m "bump v${1}" &&
    git push --tags
  fi
}'  # Create and push tag

alias gtags='echo "Listing all Git tags" && git tag -l | xargs -n 1 -I {} echo {}'  # List all tags

alias grtag='() {
  if [ $# -eq 0 ]; then
    echo "Remove Git tag.\nUsage:\n grtag <tag_name>"
    return 1
  else
    echo "Removing tag $1"
    git tag -d $1 &&
    git push origin :refs/tags/$1
  fi
}'  # Delete local and remote tag

alias grtags='echo "Removing all Git tags" && git tag -l | xargs git tag -d'  # Remove all local tags

# Logs and diffs
alias githash='echo "Getting latest commit hash" && git rev-parse HEAD'  # Get latest commit hash
alias gitdate='echo "Getting latest commit date" && git log -1 --format=%cd'  # Get latest commit date
alias gitlog='echo "Viewing Git log with graph" && git log --oneline --decorate --graph'  # View log with graph

# Archive
alias gitarchive='() {
  echo "Creating Git archive"
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  output_file="../$(basename $(pwd))_${current_branch}_$(date +%Y%m%d%H%M%S).zip"
  git archive -o $output_file $current_branch -0 &&
  echo "Archive created, exported to $output_file"
}'  # Create archive of current repository

# GitHub operations
alias gh_repo_create='() {
  if [ $# -eq 0 ]; then
    echo "Create GitHub repository.\nUsage:\n gh_repo_create <repo_name> [repo_description]"
    return 1
  else
    repo_name=${1}
    repo_desc=${2:-"A new repository"}
    gh repo create $repo_name -y -d "$repo_desc"
    echo "GitHub repository $repo_name created successfully"
  fi
}'  # Create GitHub repository using GitHub CLI

alias gitinit='() {
  if [ $# -eq 0 ]; then
    echo "Initialize Git repository.\nUsage:\n gitinit <repo_name>"
    return 1
  else
    repo_name=${1}
    mkdir -p $repo_name
    cd $repo_name
    git init -b main
    echo "# $repo_name" > README.md
    git add .
    git commit -m "chore: init"
    echo "Git repository initialized"
  fi
}'  # Initialize a new Git repository

# GitHub downloads
alias gh_dl_b='() {
  if [ $# -eq 0 ]; then
    echo "Download GitHub project branch.\nUsage:\n gh_dl_b <repository> [branch:main]"
    return 1
  else
    repo=$1
    branch=${2:-main}
    output="$(basename $repo)_${branch}.tar.gz"
    wget -O $output --no-check-certificate --progress=bar:force https://github.com/$repo/archive/refs/heads/${branch}.tar.gz &&
    echo "Download complete, saved to $output"
  fi
}'  # Download GitHub repository branch

alias gh_dl_t='() {
  if [ $# -eq 0 ]; then
    echo "Download GitHub project tag.\nUsage:\n gh_dl_t <repository> [tag:v1.0.0]"
    return 1
  else
    repo=$1
    tag=${2:-v1.0.0}
    output="$(basename $repo)_${tag}.zip"
    wget -O $output --no-check-certificate --progress=bar:force https://github.com/$repo/archive/refs/tags/${tag}.zip &&
    echo "Download complete, saved to $output"
  fi
}'  # Download GitHub repository tag

alias gh_dl_r='() {
  if [ $# -lt 1 ]; then
    echo "Download GitHub project release assets.\nUsage:\n gh_dl_r <repository> [version:latest] [save_path]"
    return 1
  else
    repo=$1
    version=${2:-latest}
    save_path="${3:-$1}"

    if [ "$save_path" = "$1" ]; then
      save_path="$save_path/$version"
    fi

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
  fi
}'  # Download GitHub repository release assets
