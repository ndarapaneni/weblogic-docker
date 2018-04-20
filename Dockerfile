FROM oraclelinux:7-slim

MAINTAINER Neeraja Darapaneni ndarapaneni46@gmail.com

ENV JAVA_PKG=server-jre-8u*-linux-x64.tar.gz \
    JAVA_HOME=/usr/java/default
    ADD $JAVA_PKG /usr/java/

 RUN export JAVA_DIR=$(ls -1 -d /usr/java/*) && \
    ln -s $JAVA_DIR /usr/java/latest && \
    ln -s $JAVA_DIR /usr/java/default && \
    alternatives --install /usr/bin/java java $JAVA_DIR/bin/java 20000 && \
    alternatives --install /usr/bin/javac javac $JAVA_DIR/bin/javac 20000 && \
    alternatives --install /usr/bin/jar jar $JAVA_DIR/bin/jar 20000


ENV ORACLE_HOME=/u01/oracle \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    SCRIPT_FILE=/u01/oracle/createAndStartEmptyDomain.sh \
    PATH=$PATH:/usr/java/default/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin

RUN mkdir -p /u01 && \
    chmod a+xr /u01 && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash oracle


COPY container-scripts/createAndStartEmptyDomain.sh container-scripts/create-wls-domain.py /u01/oracle/

# Domain and Server environment variables
# ----------------------------------------------------------
ENV DOMAIN_NAME="${DOMAIN_NAME:-base_domain}" \
    DOMAIN_HOME=/u01/oracle/user_projects/domains/${DOMAIN_NAME:-base_domain} \
    ADMIN_PORT="${ADMIN_PORT:-7001}"  \
    ADMIN_USERNAME="${ADMIN_USERNAME:-weblogic}" \
    ADMIN_NAME="${ADMIN_NAME:-AdminServer}" \
    ADMIN_PASSWORD="${ADMIN_PASSWORD:-""}" \
    DEBUG_FLAG=true \
    PRODUCTION_MODE=dev

# Environment variables required for this build
# -----------------------------------------------
ENV FMW_PKG=fmw_12.2.1.3.0_wls_quick_Disk1_1of1.zip \
    FMW_JAR=fmw_12.2.1.3.0_wls_quick.jar

# Copy packages
# -------------
COPY $FMW_PKG install.file oraInst.loc /u01/
RUN  chown oracle:oracle -R /u01  && \
     chmod +xr $SCRIPT_FILE

# Install
# ------------------------------------------------------------
USER oracle
RUN cd /u01 && $JAVA_HOME/bin/jar xf /u01/$FMW_PKG && cd - && \
    $JAVA_HOME/bin/java -jar /u01/$FMW_JAR -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME && \
    rm /u01/$FMW_JAR /u01/$FMW_PKG /u01/oraInst.loc /u01/install.file

WORKDIR ${ORACLE_HOME}

# Define default command to start script.
CMD ["/u01/oracle/createAndStartEmptyDomain.sh"]
