FROM oryxprod/node-10.1:20181025.5
LABEL maintainer="Azure App Services Container Images <appsvc-images@microsoft.com>"

RUN echo "ipv6" >> /etc/modules

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.6/community" >> /etc/apk/repositories; \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.6/main" >> /etc/apk/repositories;

RUN npm install -g pm2 \
     && mkdir -p /home/LogFiles /opt/startup \
     && echo "root:Docker!" | chpasswd \
     && echo "cd /home" >> /etc/bash.bashrc \
     && apk update --no-cache \
     && apk add openssh \
     && apk add openrc \
     && apk add vim \
     && apk add curl \
     && apk add wget \
     && apk add tcptraceroute \
     && apk add bash 

# https://github.com/dockage/alpine/blob/master/3.8/openrc/Dockerfile
RUN sed -i 's/^\(tty\d\:\:\)/#\1/g' /etc/inittab \
    && sed -i \
        -e 's/#rc_sys=".*"/rc_sys="docker"/g' \
        -e 's/#rc_env_allow=".*"/rc_env_allow="\*"/g' \
        -e 's/#rc_crashed_stop=.*/rc_crashed_stop=NO/g' \
        -e 's/#rc_crashed_start=.*/rc_crashed_start=YES/g' \
        -e 's/#rc_provide=".*"/rc_provide="loopback net"/g' \
        /etc/rc.conf \
    # Remove unnecessary services
    && rm -f /etc/init.d/hwdrivers \
            /etc/init.d/hwclock \
            /etc/init.d/hwdrivers \
            /etc/init.d/modules \
            /etc/init.d/modules-load \
            /etc/init.d/modloop \
    # Can't do cgroups
    && sed -i 's/cgroup_add_service /# cgroup_add_service /g' /lib/rc/sh/openrc-run.sh \
    && sed -i 's/VSERVER/DOCKER/Ig' /lib/rc/sh/init.sh

# setup default site
COPY startup /opt/startup
COPY server.js /home/site/wwwroot/
COPY package.json /home/site/wwwroot/

# configure startup
COPY sshd_config /etc/ssh/
COPY ssh_setup.sh /tmp
RUN echo $(ls -1 /tmp/ssh_setup.sh)
RUN chmod -R +x /opt/startup \
   && chmod -R +x /tmp/ssh_setup.sh \
   && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null) \
   && rm -rf /tmp/* \
   && cd /opt/startup \
   && npm install 


EXPOSE 2222 8080

ENV PM2HOME /pm2home

ENV PORT 8080
ENV WEBSITE_ROLE_INSTANCE_ID localRoleInstance
ENV WEBSITE_INSTANCE_ID localInstance
ENV PATH ${PATH}:/home/site/wwwroot

WORKDIR /home/site/wwwroot
RUN npm install

ENTRYPOINT ["/opt/startup/init_container.sh"]