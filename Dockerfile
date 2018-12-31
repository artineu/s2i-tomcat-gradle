FROM  centos/s2i-base-centos7

# TODO: Put the maintainer name in the image metadata
LABEL maintainer="Martin Handl <mhandl@artin.io>"
ENV LANG en_US.UTF-8

# Install bzip2, epel-release
#RUN INSTALL_PKGS="bzip2 epel-release" && \
#    yum install -y $INSTALL_PKGS && \
#    yum install -y nodejs && \
#    rpm -V $INSTALL_PKGS && \
#    yum clean all -y
    
# Install  Java
RUN wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3a%2F%2Fwww.oracle.com%2Ftechnetwork%2Fjava%2Fjavase%2Fdownloads%2Fjdk8-downloads-2133151.html; oraclelicense=accept-securebackup-cookie;" "https://download.oracle.com/otn-pub/java/jdk/8u191-b12/2787e4a523244c269598db4e85c51e0c/jdk-8u191-linux-x64.rpm" -O /tmp/jdk-8-linux-x64.rpm \
 && yum -y install /tmp/jdk-8-linux-x64.rpm \
 && alternatives --install /usr/bin/java jar /usr/java/latest/bin/java 200000 \
 && alternatives --install /usr/bin/javaws javaws /usr/java/latest/bin/javaws 200000 \
 && alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 200000 \
 && yum -y clean all \
 && rm /tmp/jdk-8-linux-x64.rpm

ENV JAVA_HOME /usr/java/latest
ENV JRE_HOME ${JAVA_HOME}/jre
ENV CLASSPATH .:${JAVA_HOME}/lib:${JRE_HOME}/lib
ENV PATH ${JAVA_HOME}/bin:$PATH

# Install Gradle
ENV GRADLE_VERSION 4.2.1
RUN curl -fSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o gradle-${GRADLE_VERSION}-bin.zip && \
  mkdir /opt/gradle && \
  unzip -d /opt/gradle gradle-${GRADLE_VERSION}-bin.zip && \
  rm gradle-${GRADLE_VERSION}-bin.zip && \
  ln -s /opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle /usr/local/bin/gradle

# Install tomcat
ENV CATALINA_HOME /opt/app-root
ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.37
ENV TOMCAT_TGZ_URL https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz
ENV MYSQL_JDBC_DRIVER_DOWNLOAD_URL https://downloads.mariadb.com/Connectors/java/connector-java-2.3.0/mariadb-java-client-2.3.0.jar
ENV PGSQL_JDBC_DRIVER_DOWNLOAD_URL https://jdbc.postgresql.org/download/postgresql-42.2.5.jar
ENV MSSQL_JDBC_DRIVER_DOWNLOAD_URL https://github.com/Microsoft/mssql-jdbc/releases/download/v7.0.0/mssql-jdbc-7.0.0.jre10.jar

RUN  curl -fSL "${TOMCAT_TGZ_URL}" -o /tmp/tomcat.tar.gz \
  && tar -xvf /tmp/tomcat.tar.gz -C${CATALINA_HOME} --strip-components=1  \
  && rm ${CATALINA_HOME}/bin/*.bat  \
	&& rm /tmp/tomcat.tar.gz \
  && chmod +x ${CATALINA_HOME}/bin/*.sh  \
  && rm -rf ${CATALINA_HOME}/webapps/* \
  && curl -fsL "${MYSQL_JDBC_DRIVER_DOWNLOAD_URL}" -o ${CATALINA_HOME}/lib/mariadb-java-client-2.3.0.jar \
  && curl -fsL "${PGSQL_JDBC_DRIVER_DOWNLOAD_URL}" -o ${CATALINA_HOME}/lib/postgresql-42.2.5.jar \
  && curl -fsL "${MSSQL_JDBC_DRIVER_DOWNLOAD_URL}" -o ${CATALINA_HOME}/lib/mssql-jdbc-7.0.0.jre10.jar \
  && echo "Tomcat install successful!"


# install nodej & npm
ENV NODEJS_VERSION=8 \
    NPM_RUN=start \
    NS_NAME=nodejs \
    NPM_CONFIG_PREFIX=$HOME/.npm-global \
    PATH=$HOME/node_modules/.bin/:$HOME/.npm-global/bin/:/opt/rh/rh-nodejs8/root/usr/bin:$PATH

RUN yum install -y centos-release-scl-rh && \
    ( [ "rh-${NS_NAME}${NODEJS_VERSION}" != "${NODEJS_SCL}" ] && yum remove -y ${NODEJS_SCL}\* || : ) && \
    INSTALL_PKGS="rh-nodejs8 rh-nodejs8-npm rh-nodejs8-nodejs-nodemon nss_wrapper" && \
    ln -s /usr/lib/node_modules/nodemon/bin/nodemon.js /usr/bin/nodemon && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all -y
   


# TODO: Set labels used in OpenShift to describe the builder image
ENV BUILDER_VERSION 1.0
LABEL io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" \
      io.s2i.scripts-url="image:///usr/libexec/s2i" \
      io.k8s.display-name="s2i-tomcat-gradle ${BUILDER_VERSION}" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="java,builder,tomcat,gradle" \
      name="artineu/s2i-tomcat-gradle ${BUILDER_VERSION}" \
      version="${BUILDER_VERSION}"  \
      maintainer="Martin Handl <mhandl@artin.io>" \
      usage="s2i build <SOURCE-REPOSITORY> artineu/s2i-tomcat-gradle:latest <APP-NAME>"

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy extra files to the image, including help file.
COPY ./root/ /

# Drop the root user and make the content of /opt/app-root owned by user 1001
RUN chown -R 1001:0 ${APP_ROOT} && chmod -R ug+rwx ${APP_ROOT} && \
    rpm-file-permissions

#RUN chmod -R u+x /opt/app-root/bin && \
#    chgrp -R 0 /opt/app-root && \
#    chmod -R g=u /opt/app-root /etc/passwd && \
#    chown -R 1001:0 /opt/app-root && \
#    chmod -R g+w /opt/app-root

EXPOSE 8080

USER 1001

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usage