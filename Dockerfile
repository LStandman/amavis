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

EXPOSE 50024
CMD ["sh", "-c", "sh /usr/local/lib/configure-instance.sh && /usr/sbin/amavisd -c /etc/amavisd.conf foreground"]
