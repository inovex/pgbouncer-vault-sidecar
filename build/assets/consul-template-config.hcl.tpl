reload_signal = "SIGHUP"
kill_signal = "SIGTERM"

vault {

  # This value can also be specified via the environment variable VAULT_NAMESPACE.
  namespace = "{{ env "VAULT_NAMESPACE" }}"

  address = "{{ env "VAULT_ADDR" }}"

  # This token is set by the Vault agent in the entrypoint.sh
  vault_agent_token_file = "/tmp/auth.token"
  unwrap_token = false

  # This option tells Consul Template to automatically renew the Vault token
  # given. If you are unfamiliar with Vault's architecture, Vault requires
  # tokens be renewed at some regular interval or they will be revoked. Consul
  # Template will automatically renew the token at half the lease duration of
  # the token. The default value is true, but this option can be disabled if
  # you want to renew the Vault token using an out-of-band process.
  #
  # Renewing the Vault token is only possible until maxTTL of the token is 
  # reached. Consul Template will not attempt to retrieve a new token.
  #
  #
  # Note that secrets specified in a template (using {{secret}} for example)
  # are always renewed, even if this option is set to false. This option only
  # applies to the top-level Vault token itself.
  renew_token = true

  {{ if (or (env "VAULT_CA_CERT") (env "VAULT_SSL_VERIFY")) -}}
  ssl {
    {{ if (env "VAULT_CA_CERT") -}}
    ca_cert = {{ env "VAULT_CA_CERT" }}
    {{- end }}
    {{ if (env "VAULT_SSL_VERIFY") -}}
    ssl_verify = {{ env "VAULT_SSL_VERIFY" }}
    {{- end }}
  }
  {{- end }}
}

exec {
  command = "pgbouncer -R /tmp/pgbouncer_rendered.ini"

  # TODO make splay configurable
  splay = "5s"

  # Triggers pgbouncer to 
  reload_signal = "SIGHUP"

  # causes a safe shutdown of pgbouncer
  kill_signal = "SIGINT"
  kill_timeout = "5s"
}

template {
  source = "/etc/pgbouncer/pgbouncer_template.ini"
  destination = "/tmp/pgbouncer_rendered.ini"

  create_dest_dirs = true

  # This is the optional command to run when the template is rendered. The
  # command will only run if the resulting template changes. The command must
  # return within 30s (configurable), and it must have a successful exit code.
  # Consul Template is not a replacement for a process monitor or init system.
  # command = "restart service foo"

  # 
  perms = 0600

  backup = false

  wait {
    min = "2s"
    max = "10s"
  }
}
