FROM fluent/fluentd:edge-debian
USER root

# Install build dependencies for native extensions (systemd journal plugin)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libsystemd-dev \
    && rm -rf /var/lib/apt/lists/*

# Elasticsearch 8.x Ruby client
# Ref. https://github.com/elastic/elasticsearch-ruby/blob/main/README.md#compatibility
RUN gem install --no-document elasticsearch --version 8.19.0

# Fluentd plugins
RUN gem install --no-document \
      fluent-plugin-elasticsearch:5.4.3 \
      fluent-plugin-systemd:1.1.0 \
      fluent-plugin-rewrite-tag-filter:2.4.0 \
      fluent-plugin-multi-format-parser:1.1.0

USER fluent
