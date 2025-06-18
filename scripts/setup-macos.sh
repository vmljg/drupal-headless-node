#!/bin/bash

# macOS Setup Script for Drupal Platformatic Next.js Example
# This script provides macOS-specific setup with Homebrew integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Homebrew if not present
install_homebrew() {
    if ! command_exists brew; then
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        print_success "Homebrew installed successfully"
    else
        print_success "Homebrew is already installed"
        brew update
    fi
}

# Function to install required software via Homebrew
install_dependencies() {
    print_status "Installing required dependencies via Homebrew..."
    
    local packages=()
    
    # Check and add missing packages
    if ! command_exists docker; then
        packages+=("docker")
    fi
    
    if ! command_exists node; then
        packages+=("node")
    fi
    
    if ! command_exists php; then
        packages+=("php")
    fi
    
    if ! command_exists composer; then
        packages+=("composer")
    fi
    
    # Install required system libraries for @platformatic/php-node
    packages+=("openssl@3" "curl" "sqlite" "libxml2" "oniguruma")
    
    if [ ${#packages[@]} -gt 0 ]; then
        print_status "Installing packages: ${packages[*]}"
        brew install "${packages[@]}"
        print_success "Dependencies installed successfully"
    else
        print_success "All dependencies are already installed"
    fi
    
    # Install Docker Desktop if docker command is not available
    if ! command_exists docker; then
        print_status "Installing Docker Desktop..."
        brew install --cask docker
        print_warning "Please start Docker Desktop manually and run this script again"
        exit 1
    fi
}

# Function to setup PHP extensions
setup_php_extensions() {
    print_status "Checking PHP extensions..."
    
    local php_ini_path=$(php --ini | grep "Loaded Configuration File" | cut -d: -f2 | xargs)
    
    if [ -z "$php_ini_path" ] || [ "$php_ini_path" = "(none)" ]; then
        print_warning "No php.ini file found. Creating one..."
        php_ini_path="/opt/homebrew/etc/php/$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')/php.ini"
        cp "/opt/homebrew/etc/php/$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')/php.ini-development" "$php_ini_path"
    fi
    
    # Check required extensions
    local required_extensions=("curl" "xml" "mbstring" "zip" "gd" "mysql" "json")
    local missing_extensions=()
    
    for ext in "${required_extensions[@]}"; do
        if ! php -m | grep -q "^$ext$"; then
            missing_extensions+=("$ext")
        fi
    done
    
    if [ ${#missing_extensions[@]} -gt 0 ]; then
        print_warning "Some PHP extensions may need to be enabled: ${missing_extensions[*]}"
        print_status "Most extensions should be available by default with Homebrew PHP"
    else
        print_success "All required PHP extensions are available"
    fi
}

# Function to setup environment with macOS-specific paths
setup_macos_environment() {
    print_status "Setting up macOS-specific environment..."
    
    # Create .env file with macOS-specific settings
    if [ ! -f .env ]; then
        cat > .env << EOF
# Database Configuration
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=drupal
MYSQL_USER=drupal
MYSQL_PASSWORD=drupal

# Drupal Configuration
DRUPAL_DATABASE_HOST=localhost
DRUPAL_DATABASE_PORT=3306
DRUPAL_DATABASE_NAME=drupal
DRUPAL_DATABASE_USERNAME=drupal
DRUPAL_DATABASE_PASSWORD=drupal
DRUPAL_HASH_SALT=$(openssl rand -base64 32)
DRUPAL_ENV=development

# API Configuration
API_BASE_URL=http://localhost:3001
DRUPAL_BASE_URL=http://localhost:8080
FRONTEND_URL=http://localhost:3000

# Security Configuration
JWT_SECRET=$(openssl rand -base64 32)
API_KEY=$(openssl rand -hex 16)

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# macOS-specific paths
OPENSSL_ROOT_DIR=/opt/homebrew/opt/openssl@3
PKG_CONFIG_PATH=/opt/homebrew/opt/libxml2/lib/pkgconfig:/opt/homebrew/opt/oniguruma/lib/pkgconfig
EOF
        print_success "Environment file created with macOS-specific settings"
    else
        print_warning "Environment file already exists, skipping..."
    fi
}

# Function to create macOS-specific helper scripts
create_macos_helpers() {
    print_status "Creating macOS helper scripts..."
    
    # Create a launch script for development
    cat > start-dev-macos.sh << 'EOF'
#!/bin/bash

# macOS Development Environment Launcher
# This script starts all services and opens them in the default browser

set -e

echo "Starting development environment..."

# Start Docker services
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Start Platformatic in background
cd platformatic
npm run dev > ../logs/platformatic.log 2>&1 &
echo $! > ../logs/platformatic.pid
cd ..

# Start Frontend in background
cd frontend
npm run dev > ../logs/frontend.log 2>&1 &
echo $! > ../logs/frontend.pid
cd ..

# Wait for services to be ready
echo "Waiting for applications to start..."
sleep 15

# Open applications in default browser
echo "Opening applications in browser..."
open http://localhost:3000
open http://localhost:3001/health
open http://localhost:8080

echo "Development environment started!"
echo "Press Ctrl+C to stop all services"

# Monitor services
trap './scripts/stop.sh; exit 0' INT

while true; do
    sleep 5
done
EOF

    chmod +x start-dev-macos.sh
    
    # Create a Finder integration script
    cat > open-in-vscode.sh << 'EOF'
#!/bin/bash

# Open project in Visual Studio Code
if command -v code >/dev/null 2>&1; then
    code .
    echo "Project opened in Visual Studio Code"
else
    echo "Visual Studio Code not found. Opening in default editor..."
    open .
fi
EOF

    chmod +x open-in-vscode.sh
    
    print_success "macOS helper scripts created"
}

# Function to setup Xcode Command Line Tools if needed
setup_xcode_tools() {
    if ! xcode-select -p >/dev/null 2>&1; then
        print_status "Installing Xcode Command Line Tools..."
        xcode-select --install
        print_warning "Please complete the Xcode Command Line Tools installation and run this script again"
        exit 1
    else
        print_success "Xcode Command Line Tools are installed"
    fi
}

# Function to optimize for Apple Silicon
optimize_for_apple_silicon() {
    if [[ $(uname -m) == "arm64" ]]; then
        print_status "Optimizing for Apple Silicon (M1/M2)..."
        
        # Set environment variables for native compilation
        export ARCHFLAGS="-arch arm64"
        
        # Add to shell profile for persistence
        local shell_profile=""
        if [[ $SHELL == *"zsh"* ]]; then
            shell_profile="$HOME/.zshrc"
        elif [[ $SHELL == *"bash"* ]]; then
            shell_profile="$HOME/.bash_profile"
        fi
        
        if [ -n "$shell_profile" ]; then
            if ! grep -q "ARCHFLAGS" "$shell_profile"; then
                echo 'export ARCHFLAGS="-arch arm64"' >> "$shell_profile"
                print_status "Added ARCHFLAGS to $shell_profile"
            fi
        fi
        
        print_success "Apple Silicon optimizations applied"
    else
        print_status "Running on Intel Mac - no specific optimizations needed"
    fi
}

# Main execution function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  macOS Setup for Drupal + Platformatic${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
    
    print_status "Detected macOS $(sw_vers -productVersion) on $(uname -m)"
    echo
    
    setup_xcode_tools
    optimize_for_apple_silicon
    install_homebrew
    install_dependencies
    setup_php_extensions
    setup_macos_environment
    create_macos_helpers
    
    # Run the main setup script
    print_status "Running main setup script..."
    ./scripts/setup.sh
    
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  macOS Setup Complete!                ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo "macOS-specific features:"
    echo "• Run './start-dev-macos.sh' to start and open all services"
    echo "• Run './open-in-vscode.sh' to open project in VS Code"
    echo "• All services will open automatically in your default browser"
    echo
    echo "Next steps:"
    echo "1. Run './start-dev-macos.sh' to start the development environment"
    echo "2. Complete Drupal setup at http://localhost:8080"
    echo "3. Explore the API at http://localhost:3001"
    echo "4. View the frontend at http://localhost:3000"
    echo
}

# Run main function
main "$@"

