#!/bin/bash

# Check if the Tomcat server has already been created
if [ ! -f "/usr/local/tomcat/server-created.flag" ]; then
    echo "Creating the Tomcat Server site..."
    # Ensure HOSTNAME is provided
    if [ -z "$HOSTNAME" ]; then
        echo "HOSTNAME environment variable is not set."
        exit 1
    fi

    # Convert the hostname to lowercase and uppercase
    export LOWERCASE_HOSTNAME=$(echo ${HOSTNAME} | tr '[:upper:]' '[:lower:]')
    export UPPERCASE_HOSTNAME=$(echo ${HOSTNAME} | tr '[:lower:]' '[:upper:]')

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
    # Mark the server as created by creating the flag file
    echo "Tomcat server setup completed on $(date)" > "/usr/local/tomcat/server-created.flag"
else
    echo "Tomcat site already created. Starting Server"
fi

# Execute the main container command
exec /usr/local/tomcat/bin/catalina.sh run
