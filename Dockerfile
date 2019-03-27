FROM centos:7

LABEL maintainer="igor.znamenskiy@gmail.com"

#This Dockerfile deletes a number of unit files which might cause issues. From here, you are ready to build your base image.
ENV container docker

#RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
#systemd-tmpfiles-setup.service ] || rm -f $i; done); \
#rm -f /lib/systemd/system/multi-user.target.wants/*;\
#rm -f /etc/systemd/system/*.wants/*;\
#rm -f /lib/systemd/system/local-fs.target.wants/*; \
#rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
#rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
#rm -f /lib/systemd/system/basic.target.wants/*;\
#rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN rm -f /var/run/nologin

VOLUME [ "/sys/fs/cgroup" ]

RUN yum -y update; yum clean all
RUN yum -y install openssh-server openssh-clients sudo nano epel-release;
RUN yum clean all;
RUN systemctl enable sshd.service
RUN systemctl enable systemd-user-sessions.service
RUN mkdir /var/run/sshd

COPY sshd_config /etc/ssh/sshd_config

RUN rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -q -N '' -t rsa
RUN ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -q -N '' -t ecdsa
RUN ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -q -N '' -t ed25519

RUN echo 'root:password' | chpasswd

# SMB shares for test
#RUN mkdir -p /mnt/lab5_managed
#RUN mkdir -p /mnt/packages_local

#########################################################################
#########################################################################

# Install Python3 and necessary
RUN yum update -y
RUN yum -y install yum-utils
RUN yum -y install epel-release
RUN yum -y install python36
RUN yum -y install https://centos7.iuscommunity.org/ius-release.rpm
RUN yum -y install python36u-pip
RUN pip3.6 install --upgrade pip
RUN yum -y install curl vim s3cmd unzip zip mediainfo xvfb ncftp bzip2 ftp
RUN yum -y install gcc git make build-essential libssl-dev libffi-dev python-dev libxml2-dev

RUN pip install --upgrade pip
RUN pip install python-dateutil pytz fpdf lxml boto requests robotframework robotframework-requests robotframework-sshlibrary robotframework-selenium2library robotframework-ftplibrary robotframework-pabot  robotframework-imaplibrary robotframework-scplibrary allure-robotframework numpy PyJWT pyyaml Pillow locustio
RUN pip install --upgrade paramiko==2.0.2
RUN pip install git+https://github.com/reportportal/agent-Python-RobotFramework.git
RUN pip install git+https://github.com/petr0ff/robotframework-reportportal-ng.git


# Install java8
ENV JAVA_VERSION 8u31
ENV BUILD_VERSION b13

# Upgrading system
RUN yum -y install wget

RUN yum -y install java-1.8.0-openjdk
RUN yum -y install java-1.8.0-openjdk-devel

RUN java_dir=$(find /usr/lib/jvm -name java-1.8.0-openjdk-1.8.* -type d)
RUN alternatives --install /usr/bin/java java /usr/lib/jvm/$java_dir/jre/bin/java 2
RUN alternatives --install /usr/bin/jar jar /usr/lib/jvm/$java_dir/jre/bin/jar 3
RUN alternatives --install /usr/bin/javac javac /usr/lib/jvm/$java_dir/jre/bin/javac 4

ENV JAVA_HOME /usr/lib/jvm/$java_dir/jre/bin/java
RUN ls -la $JAVA_HOME
RUN java -version

# PhantomJS
ENV PHANTOMJS_VERSION 1.9.8
RUN wget --no-check-certificate -q -O - https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2 | tar xjC /opt
RUN ln -s /opt/phantomjs-$PHANTOMJS_VERSION-linux-x86_64/bin/phantomjs /usr/bin/phantomjs

# FTP client
RUN mkdir -p /usr/src/ftp

# Chrome for Selenium
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
RUN yum -y localinstall google-chrome-stable_current_x86_64.rpm

# Chromedriver
RUN CHROMEDRIVER_VERSION=`wget --no-verbose --output-document - https://chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
    wget --no-verbose --output-document /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip && \
    unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver && \
    chmod +x /opt/chromedriver/chromedriver && \
    ln -fs /opt/chromedriver/chromedriver /usr/local/bin/chromedriver

# Geckodriver (firefox)
RUN GECKODRIVER_VERSION=`wget --no-verbose --output-document - https://api.github.com/repos/mozilla/geckodriver/releases/latest | grep tag_name | cut -d '"' -f 4` && \
    wget --no-verbose --output-document /tmp/geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/$GECKODRIVER_VERSION/geckodriver-$GECKODRIVER_VERSION-linux64.tar.gz && \
    tar --directory /opt -zxf /tmp/geckodriver.tar.gz && \
    chmod +x /opt/geckodriver && \
    ln -fs /opt/geckodriver /usr/local/bin/geckodriver

# Run Xvfb in the background with a display number
RUN Xvfb :99 -ac &
ENV DISPLAY=:99

# Check and configure python version
RUN alternatives --install /usr/bin/python python /usr/bin/python2 20
RUN alternatives --install /usr/bin/python python /usr/bin/python3.6 30
RUN python -V
RUN pip -V

# For Jenkins
RUN useradd -m jenkins -G wheel
RUN echo 'jenkins:password' | chpasswd
RUN echo -e 'jenkins\t\tALL=(ALL)\tNOPASSWD: ALL\n' >> /etc/sudoers
RUN mkdir -p /home/jenkins/.ssh
RUN touch /home/jenkins/.ssh/known_hosts
WORKDIR /home/jenkins

EXPOSE 22
CMD ["/usr/sbin/init"]
