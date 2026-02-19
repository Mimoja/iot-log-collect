FROM fluent/fluentd:edge-debian
USER root

# Fluentd plugins
RUN gem install --no-document \
      fluent-plugin-grafana-loki:1.2.20 \
      fluent-plugin-prometheus:2.2.1 \
      fluent-plugin-rewrite-tag-filter:2.4.0 \
      fluent-plugin-multi-format-parser:1.1.0

USER fluent
