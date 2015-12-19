FROM jenkins:1.625.3

# The following sample Dockerfile uses this option to force use of HTTPS with a certificate included in the image
# COPY https.pem /var/lib/jenkins/cert
# COPY https.key /var/lib/jenkins/pk
# ENV JENKINS_OPTS --httpPort=-1 --httpsPort=8083 --httpsCertificate=/var/lib/jenkins/cert --httpsPrivateKey=/var/lib/jenkins/pk
# EXPOSE 8083

USER root
RUN apt-get update && apt-get install -y ruby vim maven xvfb ssmtp file

ADD plugins.txt /usr/share/jenkins/ref/

RUN git config --global user.name "Jenkins"
RUN git config --global user.email "Jenkins@`hostname -f`"

ADD plugins.sh /usr/local/bin/plugins.sh
RUN /usr/local/bin/plugins.sh      /usr/share/jenkins/ref/plugins.txt
RUN ln -s /var/jenkins_home /home/jenkins

# drop back to the regular jenkins user - good practice
USER jenkins
# s.a. https://jenkins.elexis.info/jenkins/systemInfo für plugins-versionen

