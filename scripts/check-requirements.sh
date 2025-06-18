#!/bin/bash

# System Requirements Check Script
# This script checks if all required dependencies are installed

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

# Function to get version
get_version() {
    local cmd=$1
    local version_flag=${2:---version}
    
    if command_exists "$cmd"; then
        $cmd $version_flag 2>/dev/null | head -n1 || echo "Unknown"
    else
        echo "Not installed"
    fi
}

# Function to check version requirement
check_version() {
    local current=$1
    local required=$2
    local name=$3
    
    if [ "$current" = "Not installed" ]; then
        print_error "$name is not installed"
        return 1
    fi
    
    # Extract version numbers for comparison
    local current_major=$(echo "$current" | grep -oE '[0-9]+' | head -n1)
    local current_minor=$(echo "$current" | grep -oE '[0-9]+' | sed -n '2p')
    local required_major=$(echo "$required" | cut -d'.' -f1)
    local required_minor=$(echo "$required" | cut -d'.' -f2)
    
    if [ -z "$current_major" ]; then
        print_warning "$name version could not be determined"
        return 0
    fi
    
    if [ "$current_major" -gt "$required_major" ] || 
       ([ "$current_major" -eq "$required_major" ] && [ "${current_minor:-0}" -ge "${required_minor:-0}" ]); then
        print_success "$name version $current (>= $required required)"
        return 0
    else
        print_error "$name version $current is too old (>= $required required)"
        return 1
    fi
}

# Function to check system requirements
check_system_requirements() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  System Requirements Check            ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    local all_good=true
    
    # Check operating system
    print_status "Operating System: $(uname -s) $(uname -r)"
    
    # Check architecture
    print_status "Architecture: $(uname -m)"
    
    echo
    print_status "Checking required software..."
    echo
    
    # Check Docker
    local docker_version=$(get_version docker --version)
    if command_exists docker; then
        print_success "Docker: $docker_version"
        
        # Check if Docker is running
        if docker info >/dev/null 2>&1; then
            print_success "Docker daemon is running"
        else
            print_warning "Docker daemon is not running"
        fi
    else
        print_error "Docker: Not installed"
        all_good=false
    fi
    
    # Check Docker Compose
    local compose_version=$(get_version docker-compose --version)
    if command_exists docker-compose; then
        print_success "Docker Compose: $compose_version"
    else
        print_error "Docker Compose: Not installed"
        all_good=false
    fi
    
    # Check Node.js
    local node_version=$(get_version node --version)
    if ! check_version "$node_version" "18.0" "Node.js"; then
        all_good=false
    fi
    
    # Check npm
    local npm_version=$(get_version npm --version)
    if command_exists npm; then
        print_success "npm: $npm_version"
    else
        print_error "npm: Not installed"
        all_good=false
    fi
    
    # Check PHP
    local php_version=$(get_version php --version)
    if ! check_version "$php_version" "8.1" "PHP"; then
        all_good=false
    fi
    
    # Check PHP extensions
    if command_exists php; then
        echo
        print_status "Checking PHP extensions..."
        
        local required_extensions=("curl" "xml" "mbstring" "zip" "gd" "mysql" "json")
        local missing_extensions=()
        
        for ext in "${required_extensions[@]}"; do
            if php -m | grep -q "^$ext$"; then
                print_success "PHP extension: $ext"
            else
                print_error "PHP extension missing: $ext"
                missing_extensions+=("$ext")
                all_good=false
            fi
        done
        
        if [ ${#missing_extensions[@]} -gt 0 ]; then
            echo
            print_error "Missing PHP extensions: ${missing_extensions[*]}"
            print_status "Install them with: sudo apt-get install $(printf 'php-%%s ' "${missing_extensions[@]}")"
        fi
    fi
    
    # Check Composer
    local composer_version=$(get_version composer --version)
    if command_exists composer; then
        print_success "Composer: $composer_version"
    else
        print_error "Composer: Not installed"
        all_good=false
    fi
    
    # Check Git
    local git_version=$(get_version git --version)
    if command_exists git; then
        print_success "Git: $git_version"
    else
        print_warning "Git: Not installed (recommended for version control)"
    fi
    
    # Check system resources
    echo
    print_status "Checking system resources..."
    
    # Check available memory
    if command_exists free; then
        local total_mem=$(free -m | awk 'NR==2{printf "%.1f", $2/1024}')
        if (( $(echo "$total_mem >= 4.0" | bc -l) )); then
            print_success "Memory: ${total_mem}GB (>= 4GB recommended)"
        else
            print_warning "Memory: ${total_mem}GB (4GB+ recommended for optimal performance)"
        fi
    fi
    
    # Check available disk space
    if command_exists df; then
        local available_space=$(df -h . | awk 'NR==2 {print $4}')
        print_status "Available disk space: $available_space"
    fi
    
    # Check network connectivity
    echo
    print_status "Checking network connectivity..."
    
    if ping -c 1 google.com >/dev/null 2>&1; then
        print_success "Internet connectivity: Available"
    else
        print_warning "Internet connectivity: Limited (may affect package downloads)"
    fi
    
    # Summary
    echo
    echo -e "${BLUE}========================================${NC}"
    if [ "$all_good" = true ]; then
        print_success "All requirements met! You can proceed with the setup."
        echo
        echo "Next steps:"
        echo "1. Run './scripts/setup.sh' to set up the project"
        echo "2. Run './scripts/dev.sh' to start the development environment"
    else
        print_error "Some requirements are missing. Please install the missing dependencies."
        echo
        echo "Installation guides:"
        echo "• Docker: https://docs.docker.com/get-docker/"
        echo "• Node.js: https://nodejs.org/en/download/"
        echo "• PHP: https://www.php.net/manual/en/install.php"
        echo "• Composer: https://getcomposer.org/download/"
        echo
        echo "For detailed instructions, see docs/setup.md"
    fi
    echo -e "${BLUE}========================================${NC}"
    
    return $([ "$all_good" = true ] && echo 0 || echo 1)
}

# Main execution
main() {
    check_system_requirements
}

# Run main function
main "$@"

