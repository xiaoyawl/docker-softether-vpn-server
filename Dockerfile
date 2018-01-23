FROM benyoo/alpine:3.7.20180123
MAINTAINER from www.dwhd.org by lookback (mondeolove@gmail.com)

### SET ENVIRONNEMENT
ARG SOFTETHER_VERSION=${SOFTETHER_VERSION:-v4.24-9651-beta}
ENV LANG="en_US.UTF-8" \
	DOWN_URL=https://github.com/SoftEtherVPN/SoftEtherVPN/archive/${SOFTETHER_VERSION}.tar.gz

### SETUP
COPY assets /assets
RUN set -ex && \
	addgroup -S softether && \
	adduser -D -H softether -g softether -G softether -s /sbin/nologin && \
	apk add --no-cache --virtual .build-deps gcc make musl-dev ncurses-dev openssl-dev readline-dev wget && \
	mv /assets/entrypoint.sh / && \
	cd /tmp && \
	chmod +x /entrypoint.sh && \
	# Fetch sources
	#wget --no-check-certificate -O - https://github.com/SoftEtherVPN/SoftEtherVPN/archive/${SOFTETHER_VERSION}.tar.gz | tar xzf - ; \
	curl -Lk ${DOWN_URL} | tar xzf - && \
	cd SoftEtherVPN-${SOFTETHER_VERSION:1} && \
	# Patching sources
	for file in /assets/patchs/*.sh; do /bin/bash "$file"; done && \
	# Compile and Install
	cp src/makefiles/linux_64bit.mak Makefile && \
	make -j$(getconf _NPROCESSORS_ONLN) && \
	make install && \
	make clean && \
	# Striping vpnserver
	strip /usr/vpnserver/vpnserver && \
	mkdir -p /etc/vpnserver /var/log/vpnserver && \
	ln -s /etc/vpnserver/vpn_server.config /usr/vpnserver/vpn_server.config && \
	# Cleanning
	apk del .build-deps && \
	# Reintroduce necessary libraries
	apk add --no-cache --virtual .run-deps libcap libcrypto1.0 libssl1.0 ncurses-libs readline su-exec && \
	# Removing vpnbridge, vpnclient, vpncmd and build files
	cd .. && \
	rm -rf /usr/vpnbridge \
		/usr/bin/vpnbridge \
		/usr/vpnclient \
		/usr/bin/vpnclient \
		/usr/vpncmd \
		/usr/bin/vpncmd \
		/usr/bin/vpnserver \
		/assets \
		/tmp/SoftEtherVPN-${SOFTETHER_VERSION:1} ;

EXPOSE 443/tcp 992/tcp 1194/udp 5555/tcp

VOLUME ["/etc/vpnserver", "/var/log/vpnserver"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/vpnserver/vpnserver", "execsvc"]
