FROM alpine:latest

RUN apk --no-cache add \
		altermime \
		amavis \
        lz4 \
        p7zip \
        patch \
        perl-io-socket-ssl

COPY configure-instance.sh 01-chroot-fix.diff /usr/local/lib/
RUN patch /usr/sbin/amavisd /usr/local/lib/01-chroot-fix.diff
RUN sh /usr/local/lib/configure-instance.sh

EXPOSE 50024
CMD ["sh", "-c", "/usr/sbin/amavisd -c /etc/amavisd.conf foreground"]
