#!/bin/bash

# Stop Development Services Script
# This script stops all running development services

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

# Function to stop process by PID file
stop_service() {
    local service_name=$1
    local pid_file=$2
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_status "Stopping $service_name (PID: $pid)..."
            kill "$pid"
            
            # Wait for process to stop
            local attempts=0
            while kill -0 "$pid" 2>/dev/null && [ $attempts -lt 10 ]; do
                sleep 1
                ((attempts++))
            done
            
            if kill -0 "$pid" 2>/dev/null; then
                print_warning "Force killing $service_name..."
                kill -9 "$pid"
            fi
            
            print_success "$service_name stopped"
        else
            print_warning "$service_name was not running"
        fi
        rm -f "$pid_file"
    else
        print_warning "No PID file found for $service_name"
    fi
}

# Function to stop Docker services
stop_docker_services() {
    print_status "Stopping Docker services..."
    
    if docker-compose ps -q | grep -q .; then
        docker-compose down
        print_success "Docker services stopped"
    else
        print_warning "No Docker services were running"
    fi
}

# Function to kill processes by port
kill_by_port() {
    local port=$1
    local service_name=$2
    
    local pid=$(lsof -ti:$port 2>/dev/null || true)
    if [ -n "$pid" ]; then
        print_status "Killing $service_name on port $port (PID: $pid)..."
        kill "$pid" 2>/dev/null || true
        sleep 2
        
        # Force kill if still running
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
        print_success "$service_name stopped"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Stopping Development Environment     ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Stop services by PID files
    if [ -d "logs" ]; then
        stop_service "Platformatic" "logs/platformatic.pid"
        stop_service "Frontend" "logs/frontend.pid"
    fi
    
    # Stop services by port (fallback)
    kill_by_port 3001 "Platformatic API"
    kill_by_port 3000 "Next.js Frontend"
    
    # Stop Docker services
    stop_docker_services
    
    # Clean up log files
    if [ -d "logs" ]; then
        rm -f logs/*.pid
        print_status "Cleaned up PID files"
    fi
    
    print_success "All services stopped successfully!"
    echo
    echo "To start the development environment again, run:"
    echo "  ./scripts/dev.sh"
}

# Run main function
main "$@"

