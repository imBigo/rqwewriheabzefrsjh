#!/bin/bash
# Modified install-bd.sh for Amazon Linux 2023
# Usage: install-db.sh root_password user_password db_user db_port [stack_name resource_name region]

# Récupération des paramètres CloudFormation (passés comme arguments supplémentaires)
STACK_NAME=${5:-""}
RESOURCE_NAME=${6:-""}
REGION=${7:-"us-east-1"}

# Add verbose logging to debug
exec > >(tee /var/log/db-install.log) 2>&1
echo "Starting database installation at $(date)"

# Exit on error but with logging
set -e

# Define variables from arguments with default values
ROOT_PASSWORD=${1:-'superpwd123'}
NEW_USER=${2:-'gti778'}
NEW_USER_PASSWORD=${3:-'gti778psw'}
DB_PORT=${4:-'3360'}

echo "Using DB_PORT: $DB_PORT"

# Update system packages
echo "Updating system packages..."
sudo yum update -y

# Install MariaDB server and aws-cfn-bootstrap
echo "Installing MariaDB server and aws-cfn-bootstrap..."
sudo yum install -y mariadb105-server aws-cfn-bootstrap

# Create config directories
echo "Creating configuration..."
sudo mkdir -p /etc/my.cnf.d/
# Configure MariaDB more safely
sudo bash -c "cat > /etc/my.cnf.d/custom.cnf << EOF
[mysqld]
port=$DB_PORT
innodb_buffer_pool_size=128M
max_connections=50
EOF"

# Enable and start MariaDB service
echo "Starting MariaDB service..."
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Wait for service to fully start
echo "Waiting for MariaDB to initialize..."
sleep 10

# Use mysqladmin to set root password (more reliable)
echo "Setting root password..."
sudo mysqladmin -u root password "$ROOT_PASSWORD" || echo "Root password already set or error occurred"

# Create user and grant privileges
echo "Creating new user: $NEW_USER..."
mysql -u root -p"$ROOT_PASSWORD" <<EOF || echo "User creation failed, may already exist"
CREATE USER IF NOT EXISTS '$NEW_USER'@'%' IDENTIFIED BY '$NEW_USER_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO '$NEW_USER'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Verify MariaDB is running
echo "Checking MariaDB status..."
if sudo systemctl status mariadb --no-pager; then
    echo "MariaDB installation complete at $(date)"
    # Signaler le succès à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
        /opt/aws/bin/cfn-signal -e 0 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
else
    echo "Erreur: MariaDB n'a pas démarré correctement"
    # Signaler l'échec à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
        /opt/aws/bin/cfn-signal -e 1 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
    exit 1
fi

echo "Testing database connection..."
if mysqladmin -u root -p"$ROOT_PASSWORD" ping; then
    echo "Database connection successful"
else
    echo "Database ping failed"
    # Signaler l'échec à CloudFormation si les paramètres sont fournis
    if [ -n "$STACK_NAME" ] && [ -n "$RESOURCE_NAME" ]; then
        /opt/aws/bin/cfn-signal -e 1 --stack "$STACK_NAME" --resource "$RESOURCE_NAME" --region "$REGION"
    fi
    exit 1
fi
