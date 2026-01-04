#!/bin/bash
# ----------------------------------------------------
# EC2 UserData: OpenJDK 17 + Maven + Tomcat 9 (8081) + Jenkins (8082)
# ----------------------------------------------------

set -e

echo "Updating system..."
apt update -y

# ----------------------------------------------------
# Install Java 17, Maven, utilities
# ----------------------------------------------------
echo "Installing OpenJDK 17, Maven, and utilities..."
apt install -y \
  openjdk-17-jdk \
  maven \
  wget \
  curl \
  gnupg \
  tar

java -version
mvn -version

# ----------------------------------------------------
# Install Jenkins
# ----------------------------------------------------
echo "Installing Jenkins..."

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt update -y
apt install -y jenkins

# ----------------------------------------------------
# Create Tomcat user
# ----------------------------------------------------
echo "Creating tomcat user..."
useradd -r -m -U -d /opt/apache-tomcat-9.0.96 -s /bin/false tomcat || true

# ----------------------------------------------------
# Install Tomcat 9
# ----------------------------------------------------
echo "Downloading Tomcat 9.0.96..."
cd /tmp
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.96/bin/apache-tomcat-9.0.96.tar.gz

echo "Extracting Tomcat..."
tar xf apache-tomcat-9.0.96.tar.gz -C /opt/

chown -R tomcat:tomcat /opt/apache-tomcat-9.0.96
chmod +x /opt/apache-tomcat-9.0.96/bin/*.sh

# ----------------------------------------------------
# Change Tomcat port from 8080 → 8081
# ----------------------------------------------------
echo "Configuring Tomcat to run on port 8081..."
sed -i 's/port="8080"/port="8081"/' /opt/apache-tomcat-9.0.96/conf/server.xml

# ----------------------------------------------------
# Create Tomcat systemd service
# ----------------------------------------------------
echo "Creating Tomcat systemd service..."
cat <<EOF > /etc/systemd/system/tomcat9.service
[Unit]
Description=Apache Tomcat 9
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
Environment="CATALINA_HOME=/opt/apache-tomcat-9.0.96"
Environment="CATALINA_BASE=/opt/apache-tomcat-9.0.96"
Environment="CATALINA_PID=/opt/apache-tomcat-9.0.96/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server"

ExecStart=/opt/apache-tomcat-9.0.96/bin/startup.sh
ExecStop=/opt/apache-tomcat-9.0.96/bin/shutdown.sh

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# ----------------------------------------------------
# Enable and start Tomcat
# ----------------------------------------------------
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable tomcat9
systemctl start tomcat9

echo "----------------------------------------------------"
echo "Setup complete:"
echo " - Java 17 installed"
echo " - Maven installed"
echo " - Tomcat running on port 8081"
echo " - Jenkins running on port 8082"
echo "----------------------------------------------------"
