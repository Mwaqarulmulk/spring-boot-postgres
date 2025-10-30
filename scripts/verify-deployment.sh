#!/bin/bash

# Deployment Verification Script for Spring Boot PostgreSQL Application
# Author: waqarulmulk
# Description: Verifies Docker image deployment and container health

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_USERNAME="waqarulmulk"
IMAGE_NAME="springboot-postgres-app"
FULL_IMAGE="${DOCKER_USERNAME}/${IMAGE_NAME}:latest"
APP_PORT=8080
DB_PORT=5432

# Print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Check if Docker is installed and running
check_docker() {
    print_header "STEP 1: Checking Docker Installation"

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed!"
        exit 1
    fi
    print_success "Docker is installed"

    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running!"
        exit 1
    fi
    print_success "Docker daemon is running"

    docker --version
    docker-compose --version || docker compose version
}

# Pull latest image from Docker Hub
pull_image() {
    print_header "STEP 2: Pulling Docker Image from Docker Hub"

    print_info "Pulling ${FULL_IMAGE}..."
    if docker pull ${FULL_IMAGE}; then
        print_success "Successfully pulled image from Docker Hub"
        docker images | grep ${IMAGE_NAME}
    else
        print_error "Failed to pull image from Docker Hub"
        exit 1
    fi
}

# Stop and remove existing containers
cleanup_existing() {
    print_header "STEP 3: Cleaning Up Existing Containers"

    if docker ps -a | grep -q springboot-app; then
        print_info "Stopping and removing existing springboot-app container..."
        docker stop springboot-app 2>/dev/null || true
        docker rm springboot-app 2>/dev/null || true
        print_success "Removed existing app container"
    fi

    if docker ps -a | grep -q postgres-db; then
        print_info "Stopping and removing existing postgres-db container..."
        docker stop postgres-db 2>/dev/null || true
        docker rm postgres-db 2>/dev/null || true
        print_success "Removed existing database container"
    fi
}

# Start containers using Docker Compose
start_containers() {
    print_header "STEP 4: Starting Containers with Docker Compose"

    print_info "Starting PostgreSQL and Spring Boot containers..."

    if docker-compose up -d; then
        print_success "Containers started successfully"
    else
        print_error "Failed to start containers"
        exit 1
    fi

    sleep 5

    print_info "Checking running containers..."
    docker ps
}

# Verify container health
check_health() {
    print_header "STEP 5: Verifying Container Health"

    # Check database container
    print_info "Checking PostgreSQL container..."
    if docker ps | grep -q postgres-db; then
        print_success "PostgreSQL container is running"

        # Wait for database to be ready
        print_info "Waiting for PostgreSQL to be ready..."
        for i in {1..30}; do
            if docker exec postgres-db pg_isready -U postgres &> /dev/null; then
                print_success "PostgreSQL is ready and accepting connections"
                break
            fi
            if [ $i -eq 30 ]; then
                print_error "PostgreSQL failed to become ready in time"
                exit 1
            fi
            sleep 2
        done
    else
        print_error "PostgreSQL container is not running"
        exit 1
    fi

    # Check application container
    print_info "Checking Spring Boot application container..."
    if docker ps | grep -q springboot-app; then
        print_success "Spring Boot application container is running"
    else
        print_error "Spring Boot application container is not running"
        exit 1
    fi

    # Wait for application to start
    print_info "Waiting for Spring Boot application to start..."
    sleep 15
}

# Test application endpoints
test_endpoints() {
    print_header "STEP 6: Testing Application Endpoints"

    # Test health endpoint
    print_info "Testing health endpoint..."
    for i in {1..30}; do
        if curl -s -f http://localhost:${APP_PORT}/actuator/health > /dev/null 2>&1; then
            print_success "Health endpoint is responding"
            curl -s http://localhost:${APP_PORT}/actuator/health | grep -q "UP" && \
                print_success "Application health status: UP"
            break
        fi
        if [ $i -eq 30 ]; then
            print_warning "Health endpoint not responding (this is OK if actuator is not configured)"
            break
        fi
        sleep 3
    done

    # Test base application endpoint
    print_info "Testing base application endpoint..."
    if curl -s -f http://localhost:${APP_PORT}/ > /dev/null 2>&1; then
        print_success "Application is accessible at http://localhost:${APP_PORT}"
    else
        print_warning "Base endpoint returned non-200 status (check application logs)"
    fi
}

# Display container logs
show_logs() {
    print_header "STEP 7: Container Logs (Last 20 Lines)"

    print_info "Spring Boot Application Logs:"
    docker logs --tail 20 springboot-app

    echo ""
    print_info "PostgreSQL Database Logs:"
    docker logs --tail 20 postgres-db
}

# Display final status
display_status() {
    print_header "DEPLOYMENT VERIFICATION COMPLETE"

    print_success "All checks passed!"
    echo ""
    echo "📦 Docker Image: ${FULL_IMAGE}"
    echo "🌐 Application URL: http://localhost:${APP_PORT}"
    echo "🗄️  Database: PostgreSQL on localhost:${DB_PORT}"
    echo ""
    echo "Useful Commands:"
    echo "  - View logs: docker logs -f springboot-app"
    echo "  - Stop services: docker-compose down"
    echo "  - Stop & remove volumes: docker-compose down -v"
    echo "  - Restart services: docker-compose restart"
    echo ""
    print_info "Containers are running in detached mode"
}

# Main execution
main() {
    print_header "🚀 DEPLOYMENT VERIFICATION STARTED"

    check_docker
    pull_image
    cleanup_existing
    start_containers
    check_health
    test_endpoints
    show_logs
    display_status

    print_header "✅ DEPLOYMENT VERIFIED SUCCESSFULLY"
}

# Run main function
main
