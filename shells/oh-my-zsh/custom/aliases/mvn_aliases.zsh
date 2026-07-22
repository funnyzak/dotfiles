# Description: Maven related aliases for common build, test, dependency management and project operations.

# Helper functions
# ---------------

# Helper function to check if mvn is installed
_mvn_check_installed() {
  if ! command -v mvn >/dev/null 2>&1; then
    echo >&2 "Error: Maven is not installed. Please install it first."
    return 1
  fi
  return 0
}

# Helper function to display error message
_mvn_error() {
  echo >&2 "Error: $1"
  return 1
}

# Basic Build Commands
# -------------------

alias mvn-clean='() {
  echo "Clean the Maven project."
  echo "Usage: mvn-clean [directory_path:.]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Cleaning Maven project in $mvn_dir..."
  (cd "$mvn_dir" && mvn clean)
}' # Clean the Maven project

alias mvn-compile='() {
  echo "Compile the Maven project."
  echo "Usage: mvn-compile [directory_path:.]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Compiling Maven project in $mvn_dir..."
  (cd "$mvn_dir" && mvn compile)
}' # Compile the Maven project

alias mvn-package='() {
  echo "Package the Maven project."
  echo "Usage: mvn-package [directory_path:.] [skip_tests:false]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"
  local skip_tests="${2:-false}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Packaging Maven project in $mvn_dir..."
  if [ "$skip_tests" = "true" ]; then
    echo "Skipping tests..."
    (cd "$mvn_dir" && mvn package -DskipTests)
  else
    (cd "$mvn_dir" && mvn package)
  fi
}' # Package the Maven project

alias mvn-install='() {
  echo "Install the Maven project to local repository."
  echo "Usage: mvn-install [directory_path:.] [skip_tests:false]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"
  local skip_tests="${2:-false}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Installing Maven project in $mvn_dir to local repository..."
  if [ "$skip_tests" = "true" ]; then
    echo "Skipping tests..."
    (cd "$mvn_dir" && mvn install -DskipTests)
  else
    (cd "$mvn_dir" && mvn install)
  fi
}' # Install the Maven project to local repository

alias mvn-deploy='() {
  echo "Deploy the Maven project to remote repository."
  echo "Usage: mvn-deploy [directory_path:.] [skip_tests:false]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"
  local skip_tests="${2:-false}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Deploying Maven project in $mvn_dir to remote repository..."
  if [ "$skip_tests" = "true" ]; then
    echo "Skipping tests..."
    (cd "$mvn_dir" && mvn deploy -DskipTests)
  else
    (cd "$mvn_dir" && mvn deploy)
  fi
}' # Deploy the Maven project to remote repository

# Lifecycle Commands
# -----------------

alias mvn-clean-install='() {
  echo "Clean and install the Maven project."
  echo "Usage: mvn-clean-install [directory_path:.] [skip_tests:false]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"
  local skip_tests="${2:-false}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Clean and installing Maven project in $mvn_dir..."
  if [ "$skip_tests" = "true" ]; then
    echo "Skipping tests..."
    (cd "$mvn_dir" && mvn clean install -DskipTests)
  else
    (cd "$mvn_dir" && mvn clean install)
  fi
}' # Clean and install the Maven project

alias mvn-clean-package='() {
  echo "Clean and package the Maven project."
  echo "Usage: mvn-clean-package [directory_path:.] [skip_tests:false]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"
  local skip_tests="${2:-false}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Clean and packaging Maven project in $mvn_dir..."
  if [ "$skip_tests" = "true" ]; then
    echo "Skipping tests..."
    (cd "$mvn_dir" && mvn clean package -DskipTests)
  else
    (cd "$mvn_dir" && mvn clean package)
  fi
}' # Clean and package the Maven project

# Test Commands
# ------------

alias mvn-test='() {
  echo "Run tests for the Maven project."
  echo "Usage: mvn-test [directory_path:.] [test_name]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"
  local test_name="$2"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Running tests for Maven project in $mvn_dir..."
  if [ -n "$test_name" ]; then
    echo "Running specific test: $test_name"
    (cd "$mvn_dir" && mvn test -Dtest="$test_name")
  else
    (cd "$mvn_dir" && mvn test)
  fi
}' # Run tests for the Maven project

alias mvn-verify='() {
  echo "Verify the Maven project."
  echo "Usage: mvn-verify [directory_path:.]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Verifying Maven project in $mvn_dir..."
  (cd "$mvn_dir" && mvn verify)
}' # Verify the Maven project

# Dependency Commands
# -----------------

alias mvn-deps='() {
  echo "List dependencies of the Maven project."
  echo "Usage: mvn-deps [directory_path:.]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Listing dependencies for Maven project in $mvn_dir..."
  (cd "$mvn_dir" && mvn dependency:tree)
}' # List dependencies of the Maven project

alias mvn-deps-analyze='() {
  echo "Analyze dependencies of the Maven project."
  echo "Usage: mvn-deps-analyze [directory_path:.]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Analyzing dependencies for Maven project in $mvn_dir..."
  (cd "$mvn_dir" && mvn dependency:analyze)
}' # Analyze dependencies of the Maven project

alias mvn-deps-resolve='() {
  echo "Resolve dependencies of the Maven project."
  echo "Usage: mvn-deps-resolve [directory_path:.]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Resolving dependencies for Maven project in $mvn_dir..."
  (cd "$mvn_dir" && mvn dependency:resolve)
}' # Resolve dependencies of the Maven project

alias mvn-deps-purge='() {
  echo "Purge local repository from dependencies of the Maven project."
  echo "Usage: mvn-deps-purge [directory_path:.]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Purging local repository from dependencies for Maven project in $mvn_dir..."
  (cd "$mvn_dir" && mvn dependency:purge-local-repository)
}' # Purge local repository from dependencies of the Maven project

# Project Commands
# --------------

alias mvn-create='() {
  echo "Create a new Maven project."
  echo "Usage: mvn-create <group_id> <artifact_id> [version:1.0-SNAPSHOT] [template:maven-archetype-quickstart]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _mvn_error "Insufficient parameters. Please provide group_id and artifact_id."
    return 1
  fi

  local group_id="$1"
  local artifact_id="$2"
  local version="${3:-1.0-SNAPSHOT}"
  local template="${4:-maven-archetype-quickstart}"

  echo "Creating new Maven project..."
  echo "Group ID: $group_id"
  echo "Artifact ID: $artifact_id"
  echo "Version: $version"
  echo "Template: $template"

  mvn archetype:generate \
    -DgroupId="$group_id" \
    -DartifactId="$artifact_id" \
    -Dversion="$version" \
    -DarchetypeArtifactId="$template" \
    -DinteractiveMode=false

  if [ $? -eq 0 ]; then
    echo "Maven project created successfully: $artifact_id"
  else
    _mvn_error "Failed to create Maven project."
    return 1
  fi
}' # Create a new Maven project

alias mvn-create-web='() {
  echo "Create a new Maven web project."
  echo "Usage: mvn-create-web <group_id> <artifact_id> [version:1.0-SNAPSHOT]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Verify parameters
  if [ $# -lt 2 ]; then
    _mvn_error "Insufficient parameters. Please provide group_id and artifact_id."
    return 1
  fi

  local group_id="$1"
  local artifact_id="$2"
  local version="${3:-1.0-SNAPSHOT}"

  echo "Creating new Maven web project..."
  echo "Group ID: $group_id"
  echo "Artifact ID: $artifact_id"
  echo "Version: $version"

  mvn archetype:generate \
    -DgroupId="$group_id" \
    -DartifactId="$artifact_id" \
    -Dversion="$version" \
    -DarchetypeArtifactId="maven-archetype-webapp" \
    -DinteractiveMode=false

  if [ $? -eq 0 ]; then
    echo "Maven web project created successfully: $artifact_id"
  else
    _mvn_error "Failed to create Maven web project."
    return 1
  fi
}' # Create a new Maven web project

# Utility Commands
# --------------

alias mvn-version='() {
  echo "Display Maven version."
  echo "Usage: mvn-version"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  echo "Maven version:"
  mvn --version
}' # Display Maven version

alias mvn-effective-pom='() {
  echo "Display effective POM for the Maven project."
  echo "Usage: mvn-effective-pom [directory_path:.]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Displaying effective POM for Maven project in $mvn_dir..."
  (cd "$mvn_dir" && mvn help:effective-pom)
}' # Display effective POM for the Maven project

alias mvn-effective-settings='() {
  echo "Display effective settings for Maven."
  echo "Usage: mvn-effective-settings"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  echo "Displaying effective settings for Maven..."
  mvn help:effective-settings
}' # Display effective settings for Maven

alias mvn-clear-cache='() {
  echo "Clear Maven local repository cache."
  echo "Usage: mvn-clear-cache"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  echo "Clearing Maven local repository cache..."
  mvn dependency:purge-local-repository
}' # Clear Maven local repository cache

# Spring Boot Commands
# ------------------

alias mvn-spring-run='() {
  echo "Run Spring Boot application."
  echo "Usage: mvn-spring-run [directory_path:.] [profile:default]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"
  local profile="$2"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Running Spring Boot application in $mvn_dir..."
  if [ -n "$profile" ]; then
    echo "Using profile: $profile"
    (cd "$mvn_dir" && mvn spring-boot:run -Dspring-boot.run.profiles="$profile")
  else
    (cd "$mvn_dir" && mvn spring-boot:run)
  fi
}' # Run Spring Boot application

alias mvn-spring-package='() {
  echo "Package Spring Boot application as executable jar."
  echo "Usage: mvn-spring-package [directory_path:.] [skip_tests:false]"

  # Check if Maven is installed
  _mvn_check_installed || return 1

  # Set directory path
  local mvn_dir="${1:-.}"
  local skip_tests="${2:-false}"

  # Check if directory exists
  if [ ! -d "$mvn_dir" ]; then
    _mvn_error "Directory does not exist: $mvn_dir"
    return 1
  fi

  # Check if pom.xml exists
  if [ ! -f "$mvn_dir/pom.xml" ]; then
    _mvn_error "No pom.xml found in directory: $mvn_dir"
    return 1
  fi

  echo "Packaging Spring Boot application in $mvn_dir as executable jar..."
  if [ "$skip_tests" = "true" ]; then
    echo "Skipping tests..."
    (cd "$mvn_dir" && mvn clean package spring-boot:repackage -DskipTests)
  else
    (cd "$mvn_dir" && mvn clean package spring-boot:repackage)
  fi
}' # Package Spring Boot application as executable jar

# Help Command
# -----------

alias mvn-help='() {
  echo "Maven aliases help guide"
  echo "---------------------"
  echo ""
  echo "Basic Build Commands:"
  echo "  mvn-clean            - Clean the Maven project"
  echo "  mvn-compile          - Compile the Maven project"
  echo "  mvn-package          - Package the Maven project"
  echo "  mvn-install          - Install the Maven project to local repository"
  echo "  mvn-deploy           - Deploy the Maven project to remote repository"
  echo ""
  echo "Lifecycle Commands:"
  echo "  mvn-clean-install    - Clean and install the Maven project"
  echo "  mvn-clean-package    - Clean and package the Maven project"
  echo ""
  echo "Test Commands:"
  echo "  mvn-test             - Run tests for the Maven project"
  echo "  mvn-verify           - Verify the Maven project"
  echo ""
  echo "Dependency Commands:"
  echo "  mvn-deps             - List dependencies of the Maven project"
  echo "  mvn-deps-analyze     - Analyze dependencies of the Maven project"
  echo "  mvn-deps-resolve     - Resolve dependencies of the Maven project"
  echo "  mvn-deps-purge       - Purge local repository from dependencies"
  echo ""
  echo "Project Commands:"
  echo "  mvn-create           - Create a new Maven project"
  echo "  mvn-create-web       - Create a new Maven web project"
  echo ""
  echo "Utility Commands:"
  echo "  mvn-version          - Display Maven version"
  echo "  mvn-effective-pom    - Display effective POM for the Maven project"
  echo "  mvn-effective-settings - Display effective settings for Maven"
  echo "  mvn-clear-cache      - Clear Maven local repository cache"
  echo ""
  echo "Spring Boot Commands:"
  echo "  mvn-spring-run       - Run Spring Boot application"
  echo "  mvn-spring-package   - Package Spring Boot application as executable jar"
  echo ""
  echo "For more detailed help on each command, run the command without parameters."
}' # Display help information for all Maven aliases