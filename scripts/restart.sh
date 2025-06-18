#!/bin/bash

# Restart Services Script
# This script restarts all or specific services

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [SERVICE]"
    echo
    echo "Services:"
    echo "  platformatic     Restart Platformatic API only"
    echo "  frontend         Restart Next.js frontend only"
    echo "  docker           Restart Docker services only"
    echo "  all              Restart all services (default)"
    echo
    echo "Examples:"
    echo "  $0                    # Restart all services"
    echo "  $0 platformatic       # Restart only Platformatic API"
    echo "  $0 frontend           # Restart only Next.js frontend"
    echo "  $0 docker             # Restart only Docker services"
}

# Function to restart Platformatic
restart_platformatic() {
    print_status "Restarting Platformatic API..."
    
    # Stop if running
    if [ -f "logs/platformatic.pid" ]; then
        local pid=$(cat logs/platformatic.pid)
        if kill -0 "$pid" 2>/dev/null; then
            print_status "Stopping Platformatic (PID: $pid)..."
            kill "$pid"
            sleep 2
            
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid"
            fi
        fi
        rm -f logs/platformatic.pid
    fi
    
    # Start Platformatic
    cd platformatic
    npm run dev > ../logs/platformatic.log 2>&1 &
    local new_pid=$!
    echo $new_pid > ../logs/platformatic.pid
    cd ..
    
    # Wait for service to be ready
    sleep 5
    if curl -s http://localhost:3001/health >/dev/null 2>&1; then
        print_success "Platformatic restarted successfully (PID: $new_pid)"
    else
        print_error "Failed to restart Platformatic"
        return 1
    fi
}

# Function to restart Frontend
restart_frontend() {
    print_status "Restarting Next.js Frontend..."
    
    # Stop if running
    if [ -f "logs/frontend.pid" ]; then
        local pid=$(cat logs/frontend.pid)
        if kill -0 "$pid" 2>/dev/null; then
            print_status "Stopping Frontend (PID: $pid)..."
            kill "$pid"
            sleep 2
            
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid"
            fi
        fi
        rm -f logs/frontend.pid
    fi
    
    # Start Frontend
    cd frontend
    npm run dev > ../logs/frontend.log 2>&1 &
    local new_pid=$!
    echo $new_pid > ../logs/frontend.pid
    cd ..
    
    # Wait for service to be ready
    sleep 5
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        print_success "Frontend restarted successfully (PID: $new_pid)"
    else
        print_error "Failed to restart Frontend"
        return 1
    fi
}

# Function to restart Docker services
restart_docker() {
    print_status "Restarting Docker services..."
    
    docker-compose restart
    
    # Wait for MySQL to be ready
    print_status "Waiting for MySQL to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec -T mysql mysql -u root -prootpassword -e "SELECT 1" >/dev/null 2>&1; then
            print_success "Docker services restarted successfully"
            return 0
        fi
        sleep 2
        ((attempt++))
    done
    
    print_error "MySQL failed to start after restart"
    return 1
}

# Function to restart all services
restart_all() {
    print_status "Restarting all services..."
    
    # Create logs directory if it doesn't exist
    mkdir -p logs
    
    # Restart in order: Docker first, then application services
    restart_docker
    restart_platformatic
    restart_frontend
    
    print_success "All services restarted successfully!"
}

# Function to show service status after restart
show_status() {
    echo
    print_status "Service Status:"
    
    # Check Platformatic
    if [ -f "logs/platformatic.pid" ]; then
        local platformatic_pid=$(cat logs/platformatic.pid)
        if kill -0 "$platformatic_pid" 2>/dev/null; then
            print_success "Platformatic API: Running (PID: $platformatic_pid)"
        else
            print_error "Platformatic API: Not running"
        fi
    fi
    
    # Check Frontend
    if [ -f "logs/frontend.pid" ]; then
        local frontend_pid=$(cat logs/frontend.pid)
        if kill -0 "$frontend_pid" 2>/dev/null; then
            print_success "Next.js Frontend: Running (PID: $frontend_pid)"
        else
            print_error "Next.js Frontend: Not running"
        fi
    fi
    
    # Check Docker
    local docker_services=$(docker-compose ps -q 2>/dev/null | wc -l)
    if [ "$docker_services" -gt 0 ]; then
        print_success "Docker Services: $docker_services containers running"
    else
        print_warning "Docker Services: No containers running"
    fi
    
    echo
    echo "Available at:"
    echo "• Frontend: http://localhost:3000"
    echo "• API: http://localhost:3001"
    echo "• Drupal: http://localhost:8080"
}

# Main execution
main() {
    local service="all"
    
    # Parse command line arguments
    case ${1:-all} in
        platformatic)
            service="platformatic"
            ;;
        frontend)
            service="frontend"
            ;;
        docker)
            service="docker"
            ;;
        all)
            service="all"
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown service: $1"
            show_usage
            exit 1
            ;;
    esac
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Restarting Services                   ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # Restart based on service selection
    case $service in
        platformatic)
            restart_platformatic
            ;;
        frontend)
            restart_frontend
            ;;
        docker)
            restart_docker
            ;;
        all)
            restart_all
            ;;
    esac
    
    show_status
}

# Run main function
main "$@"

