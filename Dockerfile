FROM almalinux:9.7-minimal-20260104 AS base

LABEL org.opencontainers.image.authors="Shane Mc Cormack <dataforce@dataforce.org.uk>"
LABEL org.opencontainers.image.description="Duo Auth Proxy in Docker."
LABEL org.opencontainers.image.url="https://github.com/ShaneMcC/docker-duoauthproxy"

# Do overall system update, then install base requirements for duoproxy.
RUN sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/almalinux-crb.repo && \
    ln -s /usr/bin/microdnf /usr/bin/dnf && \
    ln -s /usr/bin/microdnf /usr/bin/yum && \
    dnf update -y && \
    dnf install -y python openssl && \
    useradd -s /sbin/nologin duo

FROM base AS build

# Install tools required to build proxy
RUN dnf install -y gcc make libffi-devel zlib-devel diffutils \
        tar python-devel procps

# Build proxy
ADD https://dl.duosecurity.com/duoauthproxy-6.6.0-src.tgz /tmp/duoauthproxy-1fb6d07f8266fa1ab1b3fa3b6e862323.tgz
RUN cd /tmp && tar -zxvf /tmp/duoauthproxy-1fb6d07f8266fa1ab1b3fa3b6e862323.tgz && mv /tmp/duoauthproxy*/ /tmp/duoauthproxy
RUN cd /tmp/duoauthproxy && make

# Install Proxy
RUN cd /tmp/duoauthproxy/duoauthproxy-build && ./install --install-dir=/opt/duoauthproxy --service-user=duo --log-group=duo --create-init-script=yes


FROM base AS run
RUN dnf clean all

COPY --from=build /opt/duoauthproxy /opt/duoauthproxy

# Harden Image
# Based on https://github.com/jumanjihouse/docker-duoauthproxy/blob/master/runtime/harden
RUN rm -rf /var/spool/cron /etc/crontabs /etc/periodic /etc/init.d /lib/rc /etc/conf.d /etc/inittab /etc/runlevels /etc/rc.conf /etc/sysctl* /etc/modprobe.d /etc/modules /etc/mdev.conf /etc/acpi /etc/fstab /root && \
    find /usr/sbin ! -type d -a ! -name nologin -delete && \
    find /bin /etc /lib /opt /usr -xdev -type d -perm /0002 -exec chmod o-w {} + && \
    find /bin /etc /lib /opt /usr -xdev -type f -regex '.*-$' -exec rm -f {} + && \
    find /bin /etc /lib /opt /usr -xdev -type d -exec chown root:root {} \; -exec chmod 0755 {} \; && \
    find /bin /etc /lib /opt /usr -xdev -type f -a -perm /4000 -delete && \
    find /bin /etc /lib /opt /usr -xdev -type l -exec test ! -e {} \; -delete && \
    sed -i -r '/^(duo)/!d' /etc/group && sed -i -r '/^(duo)/!d' /etc/passwd && \
    sed -i -r '/^duo:/! s#^(.*):[^:]*$#\1:/usr/sbin/nologin#' /etc/passwd

# Prepare files needed for running duoproxy
RUN mkdir -p /opt/duoauthproxy/log /opt/duoauthproxy/conf /etc/duoauthproxy && \
    chown -R duo:duo /opt/duoauthproxy/conf /opt/duoauthproxy/log /etc/duoauthproxy

VOLUME /opt/duoauthproxy/log
VOLUME /opt/duoauthproxy/conf

USER duo
ENTRYPOINT ["/opt/duoauthproxy/bin/authproxy"]
