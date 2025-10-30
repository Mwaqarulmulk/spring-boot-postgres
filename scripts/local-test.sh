#!/bin/bash

# Local Testing Script for Spring Boot PostgreSQL Application
# Author: waqarulmulk
# Description: Run local tests and verify application functionality

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
APP_PORT=8080
DB_PORT=5432
PROJECT_DIR="bezkoder-app"

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
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

# Check prerequisites
check_prerequisites() {
    print_header "CHECKING PREREQUISITES"

    # Check Java
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
        print_success "Java installed: $JAVA_VERSION"

        if [[ "$JAVA_VERSION" =~ ^17 ]] || [[ "$JAVA_VERSION" =~ ^1.17 ]]; then
            print_success "Java 17 detected"
        else
            print_warning "Java 17 is recommended, you have: $JAVA_VERSION"
        fi
    else
        print_error "Java is not installed"
        exit 1
    fi

    # Check Maven
    if command -v mvn &> /dev/null; then
        MVN_VERSION=$(mvn -version | head -n 1)
        print_success "Maven installed: $MVN_VERSION"
    else
        print_error "Maven is not installed"
        exit 1
    fi

    # Check Docker
    if command -v docker &> /dev/null; then
        print_success "Docker is installed"
        if ! docker info &> /dev/null; then
            print_warning "Docker daemon is not running"
        else
            print_success "Docker daemon is running"
        fi
    else
        print_warning "Docker is not installed (optional for local testing)"
    fi

    # Check Docker Compose
    if command -v docker-compose &> /dev/null || command -v docker &> /dev/null && docker compose version &> /dev/null; then
        print_success "Docker Compose is available"
    else
        print_warning "Docker Compose is not installed (optional for local testing)"
    fi
}

# Check if PostgreSQL is running
check_postgres() {
    print_header "CHECKING POSTGRESQL DATABASE"

    if docker ps | grep -q postgres-db; then
        print_success "PostgreSQL container is running"
        return 0
    else
        print_warning "PostgreSQL container is not running"
        print_info "Starting PostgreSQL with Docker Compose..."

        if docker-compose up -d db; then
            print_success "PostgreSQL started successfully"
            sleep 10
            return 0
        else
            print_error "Failed to start PostgreSQL"
            return 1
        fi
    fi
}

# Run Maven clean install
maven_build() {
    print_header "BUILDING APPLICATION WITH MAVEN"

    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "Project directory '$PROJECT_DIR' not found"
        exit 1
    fi

    cd "$PROJECT_DIR"

    print_info "Running mvn clean install..."
    if mvn clean install -DskipTests -B; then
        print_success "Build successful"
    else
        print_error "Build failed"
        cd ..
        exit 1
    fi

    cd ..
}

# Run unit tests
run_tests() {
    print_header "RUNNING UNIT TESTS"

    cd "$PROJECT_DIR"

    print_info "Running Maven tests..."
    if mvn test -B; then
        print_success "All tests passed"
    else
        print_warning "Some tests failed (check logs above)"
    fi

    cd ..
}

# Run integration tests with database
run_integration_tests() {
    print_header "RUNNING INTEGRATION TESTS"

    # Ensure PostgreSQL is running
    if ! check_postgres; then
        print_error "Cannot run integration tests without PostgreSQL"
        return 1
    fi

    cd "$PROJECT_DIR"

    print_info "Running integration tests with PostgreSQL..."

    export SPRING_DATASOURCE_URL="jdbc:postgresql://localhost:5432/testdb"
    export SPRING_DATASOURCE_USERNAME="postgres"
    export SPRING_DATASOURCE_PASSWORD="postgres"

    if mvn verify -B; then
        print_success "Integration tests passed"
    else
        print_warning "Integration tests failed (check logs above)"
    fi

    cd ..
}

# Check code quality
check_code_quality() {
    print_header "CHECKING CODE QUALITY"

    cd "$PROJECT_DIR"

    print_info "Running Maven verify..."
    if mvn verify -DskipTests -B; then
        print_success "Code quality checks passed"
    else
        print_warning "Code quality issues detected"
    fi

    cd ..
}

# Test Docker build
test_docker_build() {
    print_header "TESTING DOCKER BUILD"

    if ! command -v docker &> /dev/null; then
        print_warning "Docker not available, skipping Docker build test"
        return 0
    fi

    print_info "Building Docker image locally..."
    if docker build -t springboot-postgres-app:test ./bezkoder-app; then
        print_success "Docker image built successfully"

        print_info "Image details:"
        docker images | grep springboot-postgres-app
    else
        print_error "Docker build failed"
        return 1
    fi
}

# Test with Docker Compose
test_docker_compose() {
    print_header "TESTING WITH DOCKER COMPOSE"

    if ! command -v docker-compose &> /dev/null && ! (command -v docker &> /dev/null && docker compose version &> /dev/null); then
        print_warning "Docker Compose not available, skipping"
        return 0
    fi

    print_info "Starting services with Docker Compose..."
    if docker-compose up -d; then
        print_success "Services started successfully"

        sleep 15

        print_info "Checking running containers..."
        docker ps

        print_info "Testing application endpoint..."
        for i in {1..30}; do
            if curl -s -f http://localhost:${APP_PORT}/ > /dev/null 2>&1 || \
               curl -s -f http://localhost:${APP_PORT}/actuator/health > /dev/null 2>&1; then
                print_success "Application is responding"
                break
            fi
            if [ $i -eq 30 ]; then
                print_warning "Application did not respond in time"
            fi
            sleep 2
        done

        print_info "Application logs (last 15 lines):"
        docker logs --tail 15 springboot-app

    else
        print_error "Failed to start services"
        return 1
    fi
}

# Run security scan (OWASP)
run_security_scan() {
    print_header "RUNNING SECURITY SCAN (OWASP)"

    cd "$PROJECT_DIR"

    print_info "Running OWASP Dependency Check..."
    print_warning "This may take a few minutes on first run..."

    if mvn org.owasp:dependency-check-maven:check -DfailBuildOnCVSS=8 -B; then
        print_success "No critical vulnerabilities found"
    else
        print_warning "Vulnerabilities detected (check reports)"
    fi

    if [ -f "target/dependency-check-report.html" ]; then
        print_info "Security report available at: $PROJECT_DIR/target/dependency-check-report.html"
    fi

    cd ..
}

# Display test summary
display_summary() {
    print_header "TEST SUMMARY"

    echo "✅ Prerequisites checked"
    echo "✅ Application built successfully"
    echo "✅ Tests executed"
    echo ""
    echo "📝 Generated Reports:"
    echo "   - Test Results: $PROJECT_DIR/target/surefire-reports/"
    echo "   - Build Output: $PROJECT_DIR/target/"
    echo ""
    echo "🚀 Next Steps:"
    echo "   - Run application: cd $PROJECT_DIR && mvn spring-boot:run"
    echo "   - Run with Docker: docker-compose up"
    echo "   - View logs: docker logs -f springboot-app"
    echo ""
}

# Cleanup function
cleanup() {
    print_header "CLEANUP"

    read -p "Do you want to stop Docker containers? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose down
        print_success "Containers stopped"
    fi
}

# Main menu
show_menu() {
    print_header "LOCAL TESTING MENU"

    echo "Select test option:"
    echo "  1) Full test suite (recommended)"
    echo "  2) Quick test (build + unit tests)"
    echo "  3) Build only"
    echo "  4) Unit tests only"
    echo "  5) Integration tests"
    echo "  6) Docker build test"
    echo "  7) Docker Compose test"
    echo "  8) Security scan (OWASP)"
    echo "  9) Exit"
    echo ""
    read -p "Enter choice [1-9]: " choice

    case $choice in
        1)
            full_test_suite
            ;;
        2)
            quick_test
            ;;
        3)
            check_prerequisites
            maven_build
            ;;
        4)
            check_prerequisites
            run_tests
            ;;
        5)
            check_prerequisites
            run_integration_tests
            ;;
        6)
            check_prerequisites
            test_docker_build
            ;;
        7)
            check_prerequisites
            test_docker_compose
            ;;
        8)
            check_prerequisites
            run_security_scan
            ;;
        9)
            print_info "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option"
            show_menu
            ;;
    esac
}

# Full test suite
full_test_suite() {
    print_header "🚀 RUNNING FULL TEST SUITE"

    check_prerequisites
    maven_build
    run_tests
    run_integration_tests
    check_code_quality
    test_docker_build
    test_docker_compose
    display_summary

    print_header "✅ FULL TEST SUITE COMPLETED"
}

# Quick test
quick_test() {
    print_header "⚡ RUNNING QUICK TEST"

    check_prerequisites
    maven_build
    run_tests

    print_header "✅ QUICK TEST COMPLETED"
}

# Main execution
main() {
    print_header "🧪 SPRING BOOT POSTGRESQL - LOCAL TESTING"

    # Check if argument provided
    if [ $# -eq 0 ]; then
        show_menu
    else
        case $1 in
            --full)
                full_test_suite
                ;;
            --quick)
                quick_test
                ;;
            --build)
                check_prerequisites
                maven_build
                ;;
            --test)
                check_prerequisites
                run_tests
                ;;
            --docker)
                check_prerequisites
                test_docker_compose
                ;;
            --security)
                check_prerequisites
                run_security_scan
                ;;
            --help)
                echo "Usage: $0 [option]"
                echo ""
                echo "Options:"
                echo "  --full       Run full test suite"
                echo "  --quick      Run quick test (build + unit tests)"
                echo "  --build      Build only"
                echo "  --test       Unit tests only"
                echo "  --docker     Docker Compose test"
                echo "  --security   Run security scan"
                echo "  --help       Show this help message"
                echo ""
                echo "No option: Show interactive menu"
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    fi
}

# Trap errors
trap 'print_error "An error occurred. Exiting..."; exit 1' ERR

# Run main function
main "$@"
