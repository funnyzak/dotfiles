# Description: Utilities for managing virtual environments and development environments

# Helper functions for error handling and feedback
_show_error_environment_aliases() {
  local error_message="$1"
  echo "ERROR: $error_message" >&2
  return 1
}

_show_info_environment_aliases() {
  local message="$1"
  echo "$message"
}

# Python Virtual Environment utilities
# -----------------------------------

alias venv-create='() {
  echo -e "Create or activate a Python virtual environment.\nUsage:\n  venv-create [env_dir:venv]"

  local env_dir="${1:-venv}"
  if [ -d "$env_dir" ]; then
    _show_info_environment_aliases "Activating virtual environment: $env_dir"
    if ! source "$env_dir/bin/activate"; then
      _show_error_environment_aliases "Failed to activate virtual environment: $env_dir"
      return 1
    fi
    _show_info_environment_aliases "Virtual environment activated successfully"
  else
    _show_info_environment_aliases "Creating virtual environment: $env_dir"
    if ! python3 -m venv "$env_dir"; then
      _show_error_environment_aliases "Failed to create virtual environment: $env_dir"
      return 1
    fi
    if ! source "$env_dir/bin/activate"; then
      _show_error_environment_aliases "Failed to activate new virtual environment"
      return 1
    fi
    _show_info_environment_aliases "Virtual environment created and activated successfully"
  fi
}' # Create or activate a Python virtual environment

# Deactivate current Python virtual environment
alias venv-exit='() {
  echo -e "Deactivate the current Python virtual environment.\nUsage:\n  venv-exit"

  if [ -z "$VIRTUAL_ENV" ]; then
    _show_info_environment_aliases "No virtual environment is currently activated."
  else
    _show_info_environment_aliases "Deactivating virtual environment: $VIRTUAL_ENV"
    deactivate
    _show_info_environment_aliases "Virtual environment deactivated successfully"
  fi
}' # Deactivate current Python virtual environment

# Delete a Python virtual environment
alias venv-delete='() {
  echo -e "Delete a Python virtual environment.\nUsage:\n  venv-delete [env_dir:venv]"

  local env_dir="${1:-venv}"
  if [ -d "$env_dir" ]; then
    # Check if the environment is currently active
    if [ -n "$VIRTUAL_ENV" ] && [[ "$VIRTUAL_ENV" == *"$env_dir"* ]]; then
      _show_info_environment_aliases "Deactivating active virtual environment before deletion"
      deactivate
    fi

    _show_info_environment_aliases "Removing virtual environment: $env_dir"
    if ! rm -rf "$env_dir"; then
      _show_error_environment_aliases "Failed to remove virtual environment: $env_dir"
      return 1
    fi
    _show_info_environment_aliases "Virtual environment deleted successfully"
  else
    _show_error_environment_aliases "Virtual environment not found: $env_dir"
    return 1
  fi
}' # Delete a Python virtual environment

# Display information about the current Python virtual environment
alias venv-info='() {
  echo -e "Display information about the current Python virtual environment.\nUsage:\n  venv-info"

  if [ -z "$VIRTUAL_ENV" ]; then
    _show_info_environment_aliases "No virtual environment is currently activated."
  else
    _show_info_environment_aliases "Virtual environment: $VIRTUAL_ENV"
    _show_info_environment_aliases "Python version: $(python --version 2>&1)"
    _show_info_environment_aliases "Pip version: $(pip --version 2>&1)"

    # Show installed packages
    _show_info_environment_aliases "\nInstalled packages:"
    pip list
  fi
}' # Display information about the current Python virtual environment

# Python uv package manager utilities
# ----------------------------------

# Check if uv is installed
_check_uv_installed() {
  if ! command -v uv &> /dev/null; then
    _show_error_environment_aliases "uv is not installed. Install it with 'pip install uv'"
    return 1
  fi
  return 0
} # Check if uv is installed

# Create or activate a Python virtual environment using uv
alias uv-venv='() {
  echo -e "Create or activate a Python virtual environment using uv.\nUsage:\n  uv-venv [env_dir:venv]"

  if ! _check_uv_installed; then
    return 1
  fi

  local env_dir="${1:-venv}"
  if [ -d "$env_dir" ]; then
    _show_info_environment_aliases "Activating virtual environment: $env_dir"
    if ! source "$env_dir/bin/activate"; then
      _show_error_environment_aliases "Failed to activate virtual environment: $env_dir"
      return 1
    fi
  else
    _show_info_environment_aliases "Creating virtual environment using uv: $env_dir"
    if ! uv venv "$env_dir"; then
      _show_error_environment_aliases "Failed to create virtual environment using uv: $env_dir"
      return 1
    fi
    if ! source "$env_dir/bin/activate"; then
      _show_error_environment_aliases "Failed to activate new virtual environment"
      return 1
    fi
  fi
  _show_info_environment_aliases "Virtual environment activated successfully"
}' # Create or activate a Python virtual environment using uv

# Install packages using uv
alias uv-install='() {
  echo -e "Install Python packages using uv.\nUsage:\n  uv-install <package_name> [package_name...]"

  if ! _check_uv_installed; then
    return 1
  fi

  if [ "$#" -eq 0 ]; then
    _show_error_environment_aliases "Please specify at least one package to install"
    return 1
  fi

  _show_info_environment_aliases "Installing packages using uv: $@"
  if ! uv pip install "$@"; then
    _show_error_environment_aliases "Failed to install packages: $@"
    return 1
  fi
  _show_info_environment_aliases "Packages installed successfully"
}' # Install packages using uv

# Update packages using uv
alias uv-update='() {
  echo -e "Update Python packages using uv.\nUsage:\n  uv-update [package_name] [package_name...]"

  if ! _check_uv_installed; then
    return 1
  fi

  if [ "$#" -eq 0 ]; then
    _show_info_environment_aliases "Updating all packages using uv"
    if ! uv pip install --upgrade $(pip list --outdated --format=freeze | cut -d = -f 1); then
      _show_error_environment_aliases "Failed to update all packages"
      return 1
    fi
  else
    _show_info_environment_aliases "Updating specified packages using uv: $@"
    if ! uv pip install --upgrade "$@"; then
      _show_error_environment_aliases "Failed to update packages: $@"
      return 1
    fi
  fi
  _show_info_environment_aliases "Packages updated successfully"
}' # Update packages using uv

# Install packages from requirements.txt using uv
alias uv-req='() {
  echo -e "Install packages from requirements file using uv.\nUsage:\n  uv-req [requirements_file:requirements.txt]"

  if ! _check_uv_installed; then
    return 1
  fi

  local req_file="${1:-requirements.txt}"
  if [ ! -f "$req_file" ]; then
    _show_error_environment_aliases "Requirements file not found: $req_file"
    return 1
  fi

  _show_info_environment_aliases "Installing packages from $req_file using uv"
  if ! uv pip install -r "$req_file"; then
    _show_error_environment_aliases "Failed to install packages from $req_file"
    return 1
  fi
  _show_info_environment_aliases "Packages installed successfully from $req_file"
}' # Install packages from requirements.txt using uv
