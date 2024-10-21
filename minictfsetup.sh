#!/bin/bash

# Function to check if a command exists
function check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "$1 could not be found, installing..."
        sudo apt-get install -y $1
    else
        echo "$1 is already installed."
    fi
}

echo "Starting CTF setup..."

# 1. Update the system and install dependencies
echo "Updating system..."
sudo apt-get update -y
sudo apt-get upgrade -y

# 2. Install Apache, MySQL, PHP
echo "Installing Apache, MySQL, and PHP..."

check_command apache2
check_command mysql-server
check_command php
check_command libapache2-mod-php
check_command php-mysql
check_command unzip  # Needed for RockYou file

# 3. Start Apache and MySQL services
echo "Starting Apache and MySQL services..."
sudo systemctl start apache2
sudo systemctl start mysql
sudo systemctl enable apache2
sudo systemctl enable mysql

# 4. Download and setup the RockYou password list
echo "Downloading RockYou password list..."
wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt -P /var/www/html/

# 5. Create MySQL database and user table
echo "Setting up MySQL database and user credentials..."

# Secure MySQL Installation (Optional)
sudo mysql_secure_installation

# MySQL commands to create database and user
sudo mysql -u root <<EOF
CREATE DATABASE ctf_db;
USE ctf_db;
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL
);
INSERT INTO users (username, password) VALUES ('admin', 'password123');
EOF

# 6. Create the PHP login page
echo "Creating the PHP login page..."
cat <<EOL | sudo tee /var/www/html/login.php
<?php
\$servername = "localhost";
\$username = "root";
\$password = "";
\$dbname = "ctf_db";

\$conn = new mysqli(\$servername, \$username, \$password, \$dbname);

if (\$conn->connect_error) {
    die("Connection failed: " . \$conn->connect_error);
}

if (\$_SERVER['REQUEST_METHOD'] == 'POST') {
    \$input_user = \$_POST['username'];
    \$input_pass = \$_POST['password'];
    
    \$sql = "SELECT * FROM users WHERE username='\$input_user' AND password='\$input_pass'";
    \$result = \$conn->query(\$sql);

    if (\$result->num_rows > 0) {
        echo "Login Successful! Here's your flag: FLAG{successful_login}";
    } else {
        echo "Login Failed!";
    }
}
?>
<html>
<head><title>Login Page</title></head>
<body>
<form action="login.php" method="post">
    Username: <input type="text" name="username"><br>
    Password: <input type="password" name="password"><br>
    <input type="submit" value="Login">
</form>
</body>
</html>
EOL

# 7. Set correct permissions for the web directory
echo "Setting up permissions..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# 8. Restart Apache to apply changes
echo "Restarting Apache..."
sudo systemctl restart apache2

echo "CTF setup is complete. Visit http://localhost/login.php to start the challenge!"

