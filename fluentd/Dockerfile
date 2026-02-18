FROM fluent/fluentd:edge-debian
USER root

# Elasticsearch 8.x Ruby client
RUN gem install --no-document elasticsearch --version 8.19.0

# Fluentd plugins
RUN gem install --no-document \
      fluent-plugin-elasticsearch:5.4.3 \
      fluent-plugin-grafana-loki:1.2.20 \
      fluent-plugin-prometheus:2.2.1 \
      fluent-plugin-rewrite-tag-filter:2.4.0 \
      fluent-plugin-multi-format-parser:1.1.0

USER fluent
