FROM apache2-tomcat:latest

# Set working directory to Apache's directory
WORKDIR /etc/apache2

# Copy the custom server.xml to the container
COPY server.xml /usr/local/tomcat/conf/server.xml

# Enable necessary Apache modules for proxying
RUN a2enmod proxy proxy_http ssl rewrite proxy_ajp

# Generate a keystore and self-signed certificate for Tomcat
RUN keytool -genkeypair \
  -alias tomcat.${HOSTNAME} \
  -keyalg RSA -keysize 2048 \
  -keystore /usr/local/tomcat/conf/keystore.p12 -validity 3650 \
  -storepass ARCgis22 -keypass ARCgis22 \
  -dname "CN=${HOSTNAME}, OU=Self Signed Certificate" \
  -ext SAN=dns:${HOSTNAME},dns:${HOSTNAME^^}

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
 -keyout /etc/ssl/private/apache-selfsigned.key \
 -out /etc/ssl/certs/apache-selfsigned.crt \
 -subj "/OU=Self Signed Certificate/CN=${HOSTNAME}" \
 -addext "subjectAltName = DNS:${HOSTNAME},DNS:${HOSTNAME^^}"

RUN cp /etc/ssl/certs/apache-selfsigned.crt /usr/local/share/ca-certificates/apache-selfsigned.crt

RUN update-ca-certificates
RUN mv /usr/local/tomcat/webapps.dist/* /usr/local/tomcat/webapps

# Add a new Apache site configuration for reverse proxying
COPY my-apache-site.conf /etc/apache2/sites-available/${HOSTNAME}.conf

RUN a2ensite ${HOSTNAME}.conf
RUN a2dissite 000-default.conf
RUN a2enmod ssl
RUN a2enmod headers
RUN a2enmod socache_shmcb
RUN a2enmod rewrite
RUN a2enmod proxy proxy_http proxy_ajp proxy_connect
RUN apache2ctl configtest
RUN echo "ServerName ${HOSTNAME}" | tee -a /etc/apache2/apache2.conf
RUN service apache2 stop && service apache2 start &

# Add user for Tomcat manager
RUN echo '<?xml version="1.0" encoding="UTF-8"?>\
<tomcat-users xmlns="http://tomcat.apache.org/xml" \
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd" \
              version="1.0">\
  <role rolename="manager-gui"/>\
  <role rolename="manager-script"/>\
  <user username="${TOMCAT_USERNAME}" password="${TOMCAT_PASSWORD}" roles="manager-gui,manager-script"/>\
</tomcat-users>' > /usr/local/tomcat/conf/tomcat-users.xml

# Overwrite the context.xml for the manager application
RUN echo '<Context antiResourceLocking="false" privileged="true" >'\
'  <!--'\
'    <Valve className="org.apache.catalina.valves.RemoteAddrValve"'\
'         allow="127\\.\d+\\.\d+\\.\d+|::1|0:0:0:0:0:0:0:1" />'\
'  -->'\
'  <Manager sessionAttributeValueClassNameFilter="java\\.lang\\.(?:Boolean|Integer|Long|Number|String)|org\\.apache\\.catalina\\.filters\\.CsrfPreventionFilter\\$LruCache(?:\\$1)?|java\\.util\\.(?:Linked)?HashMap"/>'\
'</Context>' > /usr/local/tomcat/webapps/manager/META-INF/context.xml

# Expose ports for HTTP and HTTPS
EXPOSE 80 443

# Start Apache
CMD ["apache2ctl", "-D", "FOREGROUND"]
