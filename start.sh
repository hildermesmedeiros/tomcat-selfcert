#!/bin/bash

# Check if the Apache2 server has already been configured
if [ ! -f "/etc/apache2/server-created.flag" ]; then
    echo "Creating the Apache2-tomcat Server site..."

    export LOWERCASE_HOSTNAME=$(echo ${HOSTNAME} | tr '[:upper:]' '[:lower:]')
    export UPPERCASE_HOSTNAME=$(echo ${HOSTNAME} | tr '[:lower:]' '[:upper:]')
    # Apache2 confs
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/apache-selfsigned.key \
    -out /etc/ssl/certs/apache-selfsigned.crt \
    -subj "/OU=Self Signed Certificate/CN=${HOSTNAME}" \
    -addext "subjectAltName = DNS:${LOWERCASE_HOSTNAME},DNS:${UPPERCASE_HOSTNAME}"
    
    # Check if custom site configuration exists and move it
    if [ -f "/etc/apache2/my-apache-site.conf" ]; then
        mv /etc/apache2/my-apache-site.conf /etc/apache2/sites-available/${HOSTNAME}.conf
        a2ensite ${HOSTNAME}.conf
    else
        echo "/etc/apache2/my-apache-site.conf does not exist."
        exit 1
    fi

    # Disable default site and enable necessary modules
    a2dissite 000-default.conf
    a2enmod ssl
    a2enmod headers
    a2enmod socache_shmcb
    a2enmod rewrite
    a2enmod proxy proxy_http proxy_ajp proxy_connect
    # Add ServerName to apache2.conf
    echo "ServerName ${HOSTNAME}" | tee -a /etc/apache2/apache2.conf
    # Check the configuration for errors
    apache2ctl configtest
    service apache2 stop
    # Tomcat confs
    # Generate a keystore for Tomcat
    keytool -genkeypair \
        -alias "${TOMCAT_KEY_ALIAS}" \
        -keyalg RSA \
        -keysize 2048 \
        -keystore "/usr/local/tomcat/conf/keystore.p12" \
        -validity 3650 \
        -storepass "${TOMCAT_KEY_PASSWORD}" \
        -keypass "${TOMCAT_KEY_PASSWORD}" \
        -dname "CN=${HOSTNAME}, OU=Self Signed Certificate" \
        -ext "SAN=dns:${LOWERCASE_HOSTNAME},dns:${UPPERCASE_HOSTNAME}"
    # Create tomcat-users.xml
    cat << EOF > /usr/local/tomcat/conf/tomcat-users.xml
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
    <role rolename="manager-gui"/>
    <role rolename="manager-script"/>
    <user username="${TOMCAT_USERNAME}" password="${TOMCAT_PASSWORD}" roles="manager-gui,manager-script"/>
</tomcat-users>
EOF
    sed -i "s/\${KEYSTORE_PLACEHOLDER}/${TOMCAT_KEY_PASSWORD}/g" /usr/local/tomcat/conf/server.xml
    sed -i "s/\${ALIAS_PLACEHOLDER}/${TOMCAT_KEY_ALIAS}/g" /usr/local/tomcat/conf/server.xml
    echo "Apache2-tomcat server setup completed on $(date)" > "/etc/apache2/server-created.flag"

else
    echo "Apache2-tomcat site already created. Starting Server"
fi

# Start Apache in the foreground
gosu tomcat /usr/local/tomcat/bin/catalina.sh run &
exec apachectl -DFOREGROUND
