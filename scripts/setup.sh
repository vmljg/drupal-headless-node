#!/bin/bash

# Drupal Platformatic Next.js Setup Script
# This script automates the initial setup process for the entire stack

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="drupal-platformatic-nextjs-example"
DRUPAL_ADMIN_USER="admin"
DRUPAL_ADMIN_PASS="admin"
DRUPAL_ADMIN_EMAIL="admin@example.com"
DRUPAL_SITE_NAME="Headless Drupal Site"

# Function to print colored output
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

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    local missing_deps=()
    
    # Check for required commands
    if ! command_exists docker; then
        missing_deps+=("docker")
    fi
    
    if ! command_exists docker-compose; then
        missing_deps+=("docker-compose")
    fi
    
    if ! command_exists node; then
        missing_deps+=("node")
    fi
    
    if ! command_exists npm; then
        missing_deps+=("npm")
    fi
    
    if ! command_exists php; then
        missing_deps+=("php")
    fi
    
    if ! command_exists composer; then
        missing_deps+=("composer")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_status "Please install the missing dependencies and run this script again."
        print_status "See docs/setup.md for installation instructions."
        exit 1
    fi
    
    # Check Node.js version
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js version 18 or higher is required. Current version: $(node --version)"
        exit 1
    fi
    
    # Check PHP version
    PHP_VERSION=$(php --version | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    if [ "$(echo "$PHP_VERSION < 8.1" | bc -l)" -eq 1 ]; then
        print_error "PHP version 8.1 or higher is required. Current version: $PHP_VERSION"
        exit 1
    fi
    
    print_success "All system requirements met!"
}

# Function to setup environment variables
setup_environment() {
    print_status "Setting up environment variables..."
    
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
EOF
        print_success "Environment file created with secure random values"
    else
        print_warning "Environment file already exists, skipping..."
    fi
}

# Function to start Docker services
start_docker_services() {
    print_status "Starting Docker services..."
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    docker-compose up -d mysql redis mailhog
    
    print_status "Waiting for MySQL to be ready..."
    sleep 10
    
    # Wait for MySQL to be ready
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec -T mysql mysql -u root -prootpassword -e "SELECT 1" >/dev/null 2>&1; then
            break
        fi
        print_status "Waiting for MySQL... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "MySQL failed to start within expected time"
        exit 1
    fi
    
    print_success "Docker services started successfully"
}

# Function to setup Drupal
setup_drupal() {
    print_status "Setting up Drupal backend..."
    
    cd drupal
    
    # Install Composer dependencies
    print_status "Installing Composer dependencies..."
    composer install --no-dev --optimize-autoloader
    
    # Create required directories
    mkdir -p web/sites/default/files
    mkdir -p private
    chmod 755 web/sites/default/files
    chmod 755 private
    
    # Install Drupal
    print_status "Installing Drupal..."
    cd web
    
    # Check if Drupal is already installed
    if [ ! -f sites/default/settings.php ] || ! php core/scripts/drupal quick-start --help >/dev/null 2>&1; then
        php core/scripts/drupal install standard \
            --db-url=mysql://drupal:drupal@localhost:3306/drupal \
            --site-name="$DRUPAL_SITE_NAME" \
            --account-name="$DRUPAL_ADMIN_USER" \
            --account-pass="$DRUPAL_ADMIN_PASS" \
            --account-mail="$DRUPAL_ADMIN_EMAIL" \
            --no-interaction
    else
        print_warning "Drupal appears to be already installed, skipping installation..."
    fi
    
    # Enable required modules
    print_status "Enabling required modules..."
    ../vendor/bin/drush en jsonapi jsonapi_extras rest restui cors serialization hal basic_auth simple_oauth consumers decoupled_router admin_toolbar devel -y
    
    # Enable custom module
    ../vendor/bin/drush en headless_api -y
    
    # Clear cache
    ../vendor/bin/drush cr
    
    cd ../..
    print_success "Drupal setup completed"
}

# Function to setup Platformatic
setup_platformatic() {
    print_status "Setting up Platformatic PHP-Node bridge..."
    
    cd platformatic
    
    # Install npm dependencies
    print_status "Installing npm dependencies..."
    npm install
    
    # Create .env file for platformatic
    if [ ! -f .env ]; then
        cp ../.env .env
    fi
    
    cd ..
    print_success "Platformatic setup completed"
}

# Function to setup Next.js frontend
setup_frontend() {
    print_status "Setting up Next.js frontend..."
    
    cd frontend
    
    # Install npm dependencies
    print_status "Installing npm dependencies..."
    npm install
    
    # Create .env.local file
    if [ ! -f .env.local ]; then
        cat > .env.local << EOF
API_BASE_URL=http://localhost:3001
DRUPAL_BASE_URL=http://localhost:8080
SITE_NAME=Headless Drupal Site
SITE_URL=http://localhost:3000
EOF
    fi
    
    cd ..
    print_success "Frontend setup completed"
}

# Function to create sample content
create_sample_content() {
    print_status "Creating sample content..."
    
    cd drupal/web
    
    # Create sample articles
    ../vendor/bin/drush generate:content 5 --types=article
    
    # Create sample pages
    ../vendor/bin/drush generate:content 3 --types=page
    
    cd ../..
    print_success "Sample content created"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check if services are running
    local services_ok=true
    
    # Check MySQL
    if ! docker-compose exec -T mysql mysql -u drupal -pdrupal -e "SELECT 1" >/dev/null 2>&1; then
        print_error "MySQL connection failed"
        services_ok=false
    fi
    
    # Check Redis
    if ! docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
        print_error "Redis connection failed"
        services_ok=false
    fi
    
    if [ "$services_ok" = true ]; then
        print_success "All services are running correctly"
    else
        print_error "Some services are not working correctly"
        exit 1
    fi
}

# Function to display next steps
show_next_steps() {
    print_success "Setup completed successfully!"
    echo
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Start the Platformatic server:"
    echo "   cd platformatic && npm run dev"
    echo
    echo "2. In another terminal, start the Next.js frontend:"
    echo "   cd frontend && npm run dev"
    echo
    echo "3. Access your applications:"
    echo "   - Drupal Admin: http://localhost:8080/admin"
    echo "     Username: $DRUPAL_ADMIN_USER"
    echo "     Password: $DRUPAL_ADMIN_PASS"
    echo "   - API Endpoint: http://localhost:3001"
    echo "   - Frontend: http://localhost:3000"
    echo
    echo "4. Check the health endpoints:"
    echo "   - API Health: http://localhost:3001/health"
    echo "   - API Config: http://localhost:3001/api/config"
    echo
    echo -e "${YELLOW}Note:${NC} Make sure to keep the Docker services running with 'docker-compose up -d'"
    echo
    echo "For more information, see the documentation in the docs/ directory."
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Drupal + Platformatic + Next.js Setup${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
    
    check_requirements
    setup_environment
    start_docker_services
    setup_drupal
    setup_platformatic
    setup_frontend
    create_sample_content
    verify_installation
    show_next_steps
}

# Run main function
main "$@"

