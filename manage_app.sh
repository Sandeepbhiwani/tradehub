#!/bin/bash

# TradeHub Management Script
# Use this script to manage your TradeHub application on VPS

set -e

PROJECT_DIR="/var/www/tradehub"
VENV="$PROJECT_DIR/venv"
LOG_DIR="/var/log/tradehub"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Function to show menu
show_menu() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  TradeHub Application Management"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo -e "${YELLOW}Application Management:${NC}"
    echo "  1. Start application"
    echo "  2. Stop application"
    echo "  3. Restart application"
    echo "  4. Check status"
    echo ""
    echo -e "${YELLOW}Maintenance:${NC}"
    echo "  5. Update application (git pull + migrate)"
    echo "  6. Backup database"
    echo "  7. Restore database"
    echo "  8. Collect static files"
    echo "  9. Clear cache"
    echo ""
    echo -e "${YELLOW}Logs & Monitoring:${NC}"
    echo "  10. View error logs (follow)"
    echo "  11. View access logs (follow)"
    echo "  12. View Django logs"
    echo "  13. Check system resources"
    echo ""
    echo -e "${YELLOW}Database:${NC}"
    echo "  14. Django shell"
    echo "  15. Run Django commands"
    echo "  16. Reset database (DANGER!)"
    echo ""
    echo -e "${YELLOW}Services:${NC}"
    echo "  17. Restart Nginx"
    echo "  18. Restart PostgreSQL"
    echo "  19. Restart all services"
    echo ""
    echo "  20. Exit"
    echo ""
}

# Function implementations
start_app() {
    log_info "Starting TradeHub application..."
    systemctl start tradehub
    log_success "Application started"
    sleep 1
    systemctl status tradehub --no-pager
}

stop_app() {
    log_info "Stopping TradeHub application..."
    systemctl stop tradehub
    log_success "Application stopped"
}

restart_app() {
    log_info "Restarting TradeHub application..."
    systemctl restart tradehub
    log_success "Application restarted"
    sleep 1
    systemctl status tradehub --no-pager
}

check_status() {
    echo ""
    log_info "Application Status:"
    systemctl status tradehub --no-pager || true
    echo ""
    log_info "Nginx Status:"
    systemctl status nginx --no-pager || true
    echo ""
    log_info "PostgreSQL Status:"
    systemctl status postgresql --no-pager || true
    echo ""
}

update_app() {
    log_info "Updating application..."
    cd $PROJECT_DIR
    
    log_info "Pulling latest code..."
    git pull origin main || log_warning "Git pull failed"
    
    log_info "Installing dependencies..."
    source $VENV/bin/activate
    pip install -r requirements.txt --upgrade
    
    log_info "Running migrations..."
    export DJANGO_SETTINGS_MODULE=tradehub.settings_production
    python manage.py migrate
    
    log_info "Collecting static files..."
    python manage.py collectstatic --noinput
    
    log_info "Restarting application..."
    systemctl restart tradehub
    
    log_success "Application updated successfully"
}

backup_database() {
    BACKUP_FILE="$PROJECT_DIR/backups/backup_$(date +%Y%m%d_%H%M%S).json"
    mkdir -p "$PROJECT_DIR/backups"
    
    log_info "Backing up database to $BACKUP_FILE..."
    cd $PROJECT_DIR
    source $VENV/bin/activate
    export DJANGO_SETTINGS_MODULE=tradehub.settings_production
    python manage.py dumpdata > "$BACKUP_FILE"
    
    log_success "Database backed up: $BACKUP_FILE"
    ls -lh "$BACKUP_FILE"
}

restore_database() {
    echo ""
    log_warning "This will RESTORE a previous database backup"
    echo "Available backups:"
    ls -1 $PROJECT_DIR/backups/ 2>/dev/null || log_error "No backups found"
    echo ""
    read -p "Enter backup filename to restore: " backup_file
    
    if [ ! -f "$PROJECT_DIR/backups/$backup_file" ]; then
        log_error "Backup file not found"
        return
    fi
    
    read -p "Are you sure? This will overwrite current data (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        log_warning "Restore cancelled"
        return
    fi
    
    log_info "Restoring database from $backup_file..."
    cd $PROJECT_DIR
    source $VENV/bin/activate
    export DJANGO_SETTINGS_MODULE=tradehub.settings_production
    python manage.py loaddata "$PROJECT_DIR/backups/$backup_file"
    
    log_success "Database restored"
}

collect_static() {
    log_info "Collecting static files..."
    cd $PROJECT_DIR
    source $VENV/bin/activate
    export DJANGO_SETTINGS_MODULE=tradehub.settings_production
    python manage.py collectstatic --noinput
    log_success "Static files collected"
}

clear_cache() {
    log_info "Clearing cache..."
    cd $PROJECT_DIR
    source $VENV/bin/activate
    export DJANGO_SETTINGS_MODULE=tradehub.settings_production
    python manage.py clear_cache 2>/dev/null || log_warning "Clear cache command not available"
    log_success "Cache cleared (if Redis configured)"
}

view_error_logs() {
    log_info "Showing error logs (Ctrl+C to stop)..."
    tail -f $LOG_DIR/error.log
}

view_access_logs() {
    log_info "Showing access logs (Ctrl+C to stop)..."
    tail -f $LOG_DIR/access.log
}

view_django_logs() {
    log_info "Showing Django logs (last 50 lines)..."
    journalctl -u tradehub -n 50 --no-pager
}

check_resources() {
    echo ""
    log_info "Memory Usage:"
    free -h
    echo ""
    log_info "Disk Usage:"
    df -h
    echo ""
    log_info "Top Processes:"
    ps aux --sort=-%mem | head -10
    echo ""
    log_info "Network Connections:"
    netstat -tulpn | grep -E ':(80|443|8000|5432)' || echo "No connections on monitored ports"
    echo ""
}

django_shell() {
    log_info "Starting Django shell..."
    cd $PROJECT_DIR
    source $VENV/bin/activate
    export DJANGO_SETTINGS_MODULE=tradehub.settings_production
    python manage.py shell
}

run_django_command() {
    read -p "Enter Django command (e.g., 'createsuperuser'): " command
    
    log_info "Running: python manage.py $command"
    cd $PROJECT_DIR
    source $VENV/bin/activate
    export DJANGO_SETTINGS_MODULE=tradehub.settings_production
    python manage.py $command
}

reset_database() {
    log_warning "=== DATABASE RESET - THIS IS DANGEROUS ==="
    log_error "This will DELETE all data in the database!"
    echo ""
    read -p "Type 'YES' to confirm: " confirm
    
    if [ "$confirm" != "YES" ]; then
        log_warning "Reset cancelled"
        return
    fi
    
    log_info "Resetting database..."
    cd $PROJECT_DIR
    source $VENV/bin/activate
    export DJANGO_SETTINGS_MODULE=tradehub.settings_production
    python manage.py flush --noinput
    python manage.py migrate
    
    log_success "Database reset complete"
    
    read -p "Create new superuser? (y/n): " create_super
    if [ "$create_super" = "y" ]; then
        python manage.py createsuperuser
    fi
}

restart_nginx() {
    log_info "Restarting Nginx..."
    systemctl restart nginx
    log_success "Nginx restarted"
    sleep 1
    systemctl status nginx --no-pager
}

restart_postgresql() {
    log_info "Restarting PostgreSQL..."
    systemctl restart postgresql
    log_success "PostgreSQL restarted"
    sleep 1
    systemctl status postgresql --no-pager
}

restart_all_services() {
    log_info "Restarting all services..."
    systemctl restart tradehub postgresql nginx
    log_success "All services restarted"
    sleep 2
    check_status
}

# Main menu loop
main() {
    check_root
    
    while true; do
        show_menu
        read -p "Enter your choice: " choice
        
        case $choice in
            1) start_app ;;
            2) stop_app ;;
            3) restart_app ;;
            4) check_status ;;
            5) update_app ;;
            6) backup_database ;;
            7) restore_database ;;
            8) collect_static ;;
            9) clear_cache ;;
            10) view_error_logs ;;
            11) view_access_logs ;;
            12) view_django_logs ;;
            13) check_resources ;;
            14) django_shell ;;
            15) run_django_command ;;
            16) reset_database ;;
            17) restart_nginx ;;
            18) restart_postgresql ;;
            19) restart_all_services ;;
            20) log_success "Goodbye!"; exit 0 ;;
            *) log_error "Invalid choice. Please try again." ;;
        esac
        
        read -p "Press Enter to continue..."
    done
}

# Run main function
main
