#!/bin/bash

# Development Server Startup Script
# This script starts all development servers in the correct order

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

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" >/dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        sleep 2
        ((attempt++))
    done
    
    print_error "$service_name failed to start within expected time"
    return 1
}

# Function to start Docker services
start_docker_services() {
    print_status "Starting Docker services..."
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    docker-compose up -d
    
    # Wait for MySQL
    print_status "Waiting for MySQL to be ready..."
    sleep 10
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec -T mysql mysql -u root -prootpassword -e "SELECT 1" >/dev/null 2>&1; then
            print_success "MySQL is ready!"
            break
        fi
        sleep 2
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "MySQL failed to start"
        exit 1
    fi
}

# Function to start Platformatic server
start_platformatic() {
    print_status "Starting Platformatic PHP-Node bridge..."
    
    cd platformatic
    
    # Check if already running
    if check_port 3001; then
        print_warning "Port 3001 is already in use. Platformatic might already be running."
        cd ..
        return 0
    fi
    
    # Start in background
    npm run dev > ../logs/platformatic.log 2>&1 &
    local platformatic_pid=$!
    echo $platformatic_pid > ../logs/platformatic.pid
    
    cd ..
    
    # Wait for service to be ready
    if wait_for_service "http://localhost:3001/health" "Platformatic"; then
        print_success "Platformatic started successfully (PID: $platformatic_pid)"
    else
        print_error "Failed to start Platformatic"
        exit 1
    fi
}

# Function to start Next.js frontend
start_frontend() {
    print_status "Starting Next.js frontend..."
    
    cd frontend
    
    # Check if already running
    if check_port 3000; then
        print_warning "Port 3000 is already in use. Frontend might already be running."
        cd ..
        return 0
    fi
    
    # Start in background
    npm run dev > ../logs/frontend.log 2>&1 &
    local frontend_pid=$!
    echo $frontend_pid > ../logs/frontend.pid
    
    cd ..
    
    # Wait for service to be ready
    if wait_for_service "http://localhost:3000" "Next.js Frontend"; then
        print_success "Frontend started successfully (PID: $frontend_pid)"
    else
        print_error "Failed to start Frontend"
        exit 1
    fi
}

# Function to show running services
show_services() {
    echo
    print_success "All services are now running!"
    echo
    echo -e "${GREEN}Available Services:${NC}"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│ Service          │ URL                    │ Status          │"
    echo "├─────────────────────────────────────────────────────────────┤"
    
    # Check Drupal
    if check_port 8080; then
        echo "│ Drupal Admin     │ http://localhost:8080  │ ✅ Running      │"
    else
        echo "│ Drupal Admin     │ http://localhost:8080  │ ❌ Not Running  │"
    fi
    
    # Check Platformatic
    if check_port 3001; then
        echo "│ Platformatic API │ http://localhost:3001  │ ✅ Running      │"
    else
        echo "│ Platformatic API │ http://localhost:3001  │ ❌ Not Running  │"
    fi
    
    # Check Frontend
    if check_port 3000; then
        echo "│ Next.js Frontend │ http://localhost:3000  │ ✅ Running      │"
    else
        echo "│ Next.js Frontend │ http://localhost:3000  │ ❌ Not Running  │"
    fi
    
    # Check MailHog
    if check_port 8025; then
        echo "│ MailHog          │ http://localhost:8025  │ ✅ Running      │"
    else
        echo "│ MailHog          │ http://localhost:8025  │ ❌ Not Running  │"
    fi
    
    echo "└─────────────────────────────────────────────────────────────┘"
    echo
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo "• Stop all services: ./scripts/stop.sh"
    echo "• View logs: ./scripts/logs.sh"
    echo "• Restart services: ./scripts/restart.sh"
    echo
    echo -e "${YELLOW}Default Credentials:${NC}"
    echo "• Drupal Admin: admin / admin"
    echo
    echo -e "${YELLOW}API Endpoints:${NC}"
    echo "• Health Check: http://localhost:3001/health"
    echo "• Site Config: http://localhost:3001/api/config"
    echo "• Featured Content: http://localhost:3001/api/content/featured"
    echo "• JSON:API: http://localhost:3001/jsonapi/node/article"
}

# Function to create logs directory
setup_logging() {
    mkdir -p logs
    touch logs/platformatic.log logs/frontend.log
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Starting Development Environment     ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
    
    setup_logging
    start_docker_services
    start_platformatic
    start_frontend
    show_services
    
    echo -e "${GREEN}Development environment is ready!${NC}"
    echo "Press Ctrl+C to stop all services, or run './scripts/stop.sh' from another terminal."
    
    # Keep script running and handle Ctrl+C
    trap 'echo; print_status "Stopping services..."; ./scripts/stop.sh; exit 0' INT
    
    # Monitor services
    while true; do
        sleep 5
        
        # Check if services are still running
        if [ -f logs/platformatic.pid ]; then
            local platformatic_pid=$(cat logs/platformatic.pid)
            if ! kill -0 $platformatic_pid 2>/dev/null; then
                print_error "Platformatic service stopped unexpectedly"
                break
            fi
        fi
        
        if [ -f logs/frontend.pid ]; then
            local frontend_pid=$(cat logs/frontend.pid)
            if ! kill -0 $frontend_pid 2>/dev/null; then
                print_error "Frontend service stopped unexpectedly"
                break
            fi
        fi
    done
}

# Run main function
main "$@"

