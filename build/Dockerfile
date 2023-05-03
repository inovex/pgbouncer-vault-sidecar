# Use consul-template upstream image
FROM hashicorp/consul-template:0.25.2-alpine

# Switch to root for setup
USER root

# Install pgbouncer
# TODO pin version
RUN sed -i -e 's/http:/https:/' /etc/apk/repositories && \
    apk update && \
    apk add 'pgbouncer' 'jq' 'postgresql-client' 'tini' --no-cache

RUN mkdir /var/secrets/ -p
RUN cd /bin/ && \
    wget -qO- https://releases.hashicorp.com/vault/1.3.1/vault_1.3.1_linux_amd64.zip | unzip - && \
    chmod +x /bin/vault


# Copy pgbouncer config and credentials into container
COPY assets/pgbouncer_template.ini /etc/pgbouncer/pgbouncer_template.ini
RUN ls -l /etc/pgbouncer
COPY assets/consul-template-config.hcl /etc/consul-template-config.hcl
COPY assets/vault-agent-config.hcl /etc/vault-agent-config.hcl
COPY assets/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chown consul-template /var/log/pgbouncer -R

# Switch to consul-template user from base image
USER consul-template

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]