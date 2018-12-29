FROM openshift/base-centos7

# TODO: Put the maintainer name in the image metadata
LABEL maintainer="Martin Handl <mhandl@artin.io>"
ENV LANG en_US.UTF-8

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

# TODO: Set labels used in OpenShift to describe the builder image
ENV BUILDER_VERSION 1.0
LABEL io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" \
      io.k8s.display-name="s2i-tomcat-gradle ${BUILDER_VERSION}" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="java,builder,tomcat,gradle" \
      name="s2i-tomcat-gradle ${BUILDER_VERSION}" \
      version="${BUILDER_VERSION}" 

# TODO: Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way, or update that label
COPY ./s2i/bin/ /usr/libexec/s2i

ENV JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8

WORKDIR ${HOME}
USER 1001

