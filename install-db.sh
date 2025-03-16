#!/bin/bash

# Exit script on error
set -e

# Function to display usage information
usage() {
    echo "Usage: $0 [ROOT_PASSWORD] [NEW_USER] [NEW_USER_PASSWORD] [DB_PORT]"
    echo "Defaults will be used if arguments are not provided."
    echo "\nExamples:"
    echo "  $0 myRootPass myUser myUserPass 3306"
    echo "  ROOT_PASSWORD=myRootPass NEW_USER=myUser NEW_USER_PASSWORD=myUserPass DB_PORT=3306 $0"
    exit 1
}

# Define variables from arguments or environment with default values
ROOT_PASSWORD=${1:-${MariaDB_ROOT_PASSWORD:-'superpwd123'}}
NEW_USER=${2:-${MariaDB_NEW_USER:-'gti778'}}
NEW_USER_PASSWORD=${3:-${MariaDB_NEW_USER_PASSWORD:-'gti778psw'}}
DB_PORT=${4:-${MariaDB_DB_PORT:-'3360'}}    

# Show usage if help flag is passed
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    usage
fi

# Update system packages
echo "Updating system packages..."
sudo dnf update -y

# Install MariaDB server
echo "Installing MariaDB server..."
sudo dnf install -y mariadb105-server

# Configure MariaDB to use custom port
echo "Configuring MariaDB to use port $DB_PORT..."
echo -e "[mysqld]\nport=$DB_PORT" | sudo tee /etc/my.cnf.d/mariadb-server-custom.cnf

# Enable and start MariaDB service
echo "Enabling and starting MariaDB service..."
sudo systemctl enable mariadb
sudo systemctl restart mariadb

# Checking status of MariaDB service
echo "Checking status of MariaDB service..."
sudo systemctl status mariadb

# Retrieve current root password if exists
CURRENT_ROOT_PASSWORD=$(sudo grep 'password' /var/log/mysqld.log | awk '{print $NF}' || echo "")
if [[ -n "$CURRENT_ROOT_PASSWORD" ]]; then
    ROOT_PASSWORD="$CURRENT_ROOT_PASSWORD"
fi

echo "Securing MariaDB installation..."
sudo mysql -u root -p"$ROOT_PASSWORD" -e "USE mysql; ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASSWORD';"
sudo mysql -u root -p"$ROOT_PASSWORD" -e "USE mysql; DELETE FROM mysql.user WHERE User='';"
sudo mysql -u root -p"$ROOT_PASSWORD" -e "USE mysql; DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost');"
sudo mysql -u root -p"$ROOT_PASSWORD" -e "USE mysql; DROP DATABASE IF EXISTS test;"
sudo mysql -u root -p"$ROOT_PASSWORD" -e "USE mysql; DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -u root -p"$ROOT_PASSWORD" -e "USE mysql; FLUSH PRIVILEGES;"

# Create a new user
echo "Creating new user: $NEW_USER..."
sudo mysql -u root -p"$ROOT_PASSWORD" -e "USE mysql; CREATE USER '$NEW_USER'@'%' IDENTIFIED BY '$NEW_USER_PASSWORD';"
sudo mysql -u root -p"$ROOT_PASSWORD" -e "USE mysql; GRANT ALL PRIVILEGES ON *.* TO '$NEW_USER'@'%' WITH GRANT OPTION;"
sudo mysql -u root -p"$ROOT_PASSWORD" -e "USE mysql; FLUSH PRIVILEGES;"

# Verify installation
echo "Checking MariaDB status..."
sudo systemctl status mariadb --no-pager

echo "MariaDB installation and setup complete."
