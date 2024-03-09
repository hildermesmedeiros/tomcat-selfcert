FROM ubuntu/apache2

# Set working directory to Apache's directory
WORKDIR /etc/apache2

RUN useradd -m -d /opt/tomcat -U -s /bin/false tomcat
# Install OpenSSL and Tomcat using cache mount for apt cache
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
    apt-get install -y \
    openssl \
    default-jdk \
    wget \
    gosu \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*
   
RUN /bin/sh -c set -eux; apt-get update; DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl wget fontconfig ca-certificates p11-kit binutils tzdata locales ; echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen; locale-gen en_US.UTF-8; rm -rf /var/lib/apt/lists/*

COPY ./apache-tomcat-*.tar.gz .
RUN mkdir /usr/local/tomcat
RUN tar -xvzf /etc/apache2/apache-tomcat-*.tar.gz -C /usr/local/tomcat --strip-components=1

RUN chown -R tomcat:tomcat /usr/local/tomcat
RUN chmod -R u+x /usr/local/tomcat/bin

ENV JAVA_VERSION=jdk-21.0.2+13
ENV JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64
ENV JAVA_OPTS=-Djava.security.egd=file:///dev/urandom
ENV CATALINA_BASE=/usr/local/tomcat
ENV CATALINA_HOME=/usr/local/tomcat
ENV CATALINA_PID=/usr/local/tomcat/temp/tomcat.pid
ENV CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
ENV TOMCAT_MAJOR=10
ENV TOMCAT_VERSION=10.1.19

# Generate en_US.UTF-8
RUN locale-gen en_US.UTF-8

# Set the locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


RUN /bin/sh -c set -eux; echo "Verifying install ..."; fileEncoding="$(echo 'System.out.println(System.getProperty("file.encoding"))' | jshell -s -)"; [ "$fileEncoding" = 'UTF-8' ]; rm -rf ~/.java; echo "javac --version"; javac --version; echo "java --version"; java --version; echo "Complete."

# Enable necessary Apache modules for proxying
RUN a2enmod proxy proxy_http ssl rewrite proxy_ajp

# Add a new Apache site configuration for reverse proxying
COPY my-apache-site.conf /etc/apache2/my-apache-site.conf

# Overwrite the context.xml for the manager application
RUN echo '<Context antiResourceLocking="false" privileged="true" >'\
'  <!--'\
'    <Valve className="org.apache.catalina.valves.RemoteAddrValve"'\
'         allow="127\\.\d+\\.\d+\\.\d+|::1|0:0:0:0:0:0:0:1" />'\
'  -->'\
'  <Manager sessionAttributeValueClassNameFilter="java\\.lang\\.(?:Boolean|Integer|Long|Number|String)|org\\.apache\\.catalina\\.filters\\.CsrfPreventionFilter\\$LruCache(?:\\$1)?|java\\.util\\.(?:Linked)?HashMap"/>'\
'</Context>' > /usr/local/tomcat/webapps/manager/META-INF/context.xml

COPY server.xml /usr/local/tomcat/conf/server.xml

COPY ./start.sh /etc/apache2/start.sh
RUN chmod +x /etc/apache2/start.sh
# Expose ports for HTTP and HTTPS
EXPOSE 80 443

# Start Apache
CMD ["/etc/apache2/start.sh"]
