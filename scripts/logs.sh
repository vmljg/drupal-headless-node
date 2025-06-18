#!/bin/bash

# Log Viewer Script
# This script displays logs from all services

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
    echo "Usage: $0 [OPTIONS] [SERVICE]"
    echo
    echo "Options:"
    echo "  -f, --follow     Follow log output (like tail -f)"
    echo "  -n, --lines N    Show last N lines (default: 50)"
    echo "  -h, --help       Show this help message"
    echo
    echo "Services:"
    echo "  platformatic     Show Platformatic API logs"
    echo "  frontend         Show Next.js frontend logs"
    echo "  docker           Show Docker Compose logs"
    echo "  all              Show all logs (default)"
    echo
    echo "Examples:"
    echo "  $0                          # Show last 50 lines of all logs"
    echo "  $0 -f platformatic          # Follow Platformatic logs"
    echo "  $0 -n 100 frontend          # Show last 100 lines of frontend logs"
    echo "  $0 --follow docker          # Follow Docker logs"
}

# Function to show platformatic logs
show_platformatic_logs() {
    local lines=$1
    local follow=$2
    
    if [ -f "logs/platformatic.log" ]; then
        echo -e "${GREEN}=== Platformatic API Logs ===${NC}"
        if [ "$follow" = true ]; then
            tail -f -n "$lines" logs/platformatic.log
        else
            tail -n "$lines" logs/platformatic.log
        fi
    else
        print_warning "Platformatic log file not found"
    fi
}

# Function to show frontend logs
show_frontend_logs() {
    local lines=$1
    local follow=$2
    
    if [ -f "logs/frontend.log" ]; then
        echo -e "${GREEN}=== Next.js Frontend Logs ===${NC}"
        if [ "$follow" = true ]; then
            tail -f -n "$lines" logs/frontend.log
        else
            tail -n "$lines" logs/frontend.log
        fi
    else
        print_warning "Frontend log file not found"
    fi
}

# Function to show docker logs
show_docker_logs() {
    local lines=$1
    local follow=$2
    
    echo -e "${GREEN}=== Docker Compose Logs ===${NC}"
    if [ "$follow" = true ]; then
        docker-compose logs -f --tail="$lines"
    else
        docker-compose logs --tail="$lines"
    fi
}

# Function to show all logs
show_all_logs() {
    local lines=$1
    local follow=$2
    
    if [ "$follow" = true ]; then
        print_status "Following all logs (press Ctrl+C to stop)..."
        echo
        
        # Start background processes for each log
        if [ -f "logs/platformatic.log" ]; then
            (echo -e "${GREEN}=== Platformatic API Logs ===${NC}"; tail -f logs/platformatic.log | sed 's/^/[PLATFORMATIC] /') &
        fi
        
        if [ -f "logs/frontend.log" ]; then
            (echo -e "${GREEN}=== Next.js Frontend Logs ===${NC}"; tail -f logs/frontend.log | sed 's/^/[FRONTEND] /') &
        fi
        
        (echo -e "${GREEN}=== Docker Compose Logs ===${NC}"; docker-compose logs -f 2>/dev/null | sed 's/^/[DOCKER] /') &
        
        # Wait for all background processes
        wait
    else
        show_platformatic_logs "$lines" false
        echo
        show_frontend_logs "$lines" false
        echo
        show_docker_logs "$lines" false
    fi
}

# Function to show service status
show_service_status() {
    echo -e "${BLUE}=== Service Status ===${NC}"
    
    # Check if services are running
    if [ -f "logs/platformatic.pid" ]; then
        local platformatic_pid=$(cat logs/platformatic.pid)
        if kill -0 "$platformatic_pid" 2>/dev/null; then
            print_success "Platformatic API: Running (PID: $platformatic_pid)"
        else
            print_error "Platformatic API: Not running"
        fi
    else
        print_warning "Platformatic API: No PID file found"
    fi
    
    if [ -f "logs/frontend.pid" ]; then
        local frontend_pid=$(cat logs/frontend.pid)
        if kill -0 "$frontend_pid" 2>/dev/null; then
            print_success "Next.js Frontend: Running (PID: $frontend_pid)"
        else
            print_error "Next.js Frontend: Not running"
        fi
    else
        print_warning "Next.js Frontend: No PID file found"
    fi
    
    # Check Docker services
    local docker_services=$(docker-compose ps -q 2>/dev/null | wc -l)
    if [ "$docker_services" -gt 0 ]; then
        print_success "Docker Services: $docker_services containers running"
    else
        print_warning "Docker Services: No containers running"
    fi
    
    echo
}

# Main execution
main() {
    local lines=50
    local follow=false
    local service="all"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--follow)
                follow=true
                shift
                ;;
            -n|--lines)
                lines="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            platformatic|frontend|docker|all)
                service="$1"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Show service status first
    show_service_status
    
    # Show logs based on service selection
    case $service in
        platformatic)
            show_platformatic_logs "$lines" "$follow"
            ;;
        frontend)
            show_frontend_logs "$lines" "$follow"
            ;;
        docker)
            show_docker_logs "$lines" "$follow"
            ;;
        all)
            show_all_logs "$lines" "$follow"
            ;;
    esac
}

# Handle Ctrl+C gracefully
trap 'echo; print_status "Stopping log viewer..."; exit 0' INT

# Run main function
main "$@"

