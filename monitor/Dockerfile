FROM alpine:3

RUN apk add --no-cache bash parallel postgresql-client speedtest-cli xsv

COPY . /opt/monitoring
WORKDIR /opt/monitoring

RUN /usr/bin/crontab /opt/monitoring/crontab.txt

CMD ["/opt/monitoring/entrypoint.sh"]
