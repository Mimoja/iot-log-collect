FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends systemd-journal-remote && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/log/journal/remote

EXPOSE 19532

ENTRYPOINT ["/usr/lib/systemd/systemd-journal-remote", \
    "--listen-http=0.0.0.0:19532", \
    "--output=/var/log/journal/remote/", \
    "--split-mode=host"]
