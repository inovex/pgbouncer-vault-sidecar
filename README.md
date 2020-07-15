# Pgbouncer Vault Sidecar

This sidecar provides a proxy ([pgbouncer]()) to a Postgres database and takes care of authentication by obtaining credentials from [Vault](). The main container connects to `localhost`, the sidecar takes care of the rest!

Why?

Features
- Vault integration without changing the application
- Database connection pooling
- Auto renewal of database credentials
- Authentication with Kubernetes service account

## Usage

Releases are available on [Docker Hub](). Check the [examples](examples/) folder.

The sidecar is configured via environment variables:

- **DB_HOST**: *Required* The hostname of the Postgres server.
- **DB_PORT**: The port of the Postgres server. Default is `5432`.
- **DB_NAME**: *Required* The name of the database. 
- **SSL_MODE**: The mode that is used to connect to Postgres. See [the Postgres docs](https://www.postgresql.org/docs/current/libpq-connect.html) for possible values. Default is `require`.
- **VAULT_PATH**: *Required* The path of the database credentials in Vault.
- **VAULT_ADDR**: *Required* The address of Vault. The protocol (http(s)) portion of the address is required.
- **VAULT_CA_CERT**: Path to a CA certificate to connect to Vault.
- **VAULT_KUBERNETES_ROLE**: Which [role](https://www.vaultproject.io/docs/auth/kubernetes#via-the-api) to request during token retrieval. Default is `default`.
- **LISTEN_PORT**: Which port to listen on for incoming database connections.

The sidecar authenticates against Vault with the [Kubernetes auth method](https://www.vaultproject.io/docs/auth/kubernetes). The service account that is associated with the pod must have access to the database credentials.

use service account projections

The main application can connect to the database using `localhost`, the configured database name (`$DB_NAME`) and the configured port (`$LISTEN_PORT`). Any username and password will do.

The sidecar comes with `psql` to define a liveness probe.

```yaml
    livenessProbe:
      exec:
        command: ["psql", "-d", "my-database", "-c", "SELECT 1"]
```

## Metrics

To get metrics for pgbouncer add the [prometheus-pgbouncer-exporter](https://github.com/spreaker/prometheus-pgbouncer-exporter) as an extra sidecar.

## Sidecar injection

The sidecar doesn't come with an injector but you can use any generic injector, for example [tumblr/k8s-sidecar-injector](https://github.com/tumblr/k8s-sidecar-injector). You can use [environment variable substitution in environment variables](https://stackoverflow.com/a/49583616/1863595) to generalize the configuration. See example [here](examples/sidecar-injection). 

## Limitations

- Consul template renews the Vault token that it initially obtained by Vault. If `maxTTL` is configured on that token or Vault is unavailable for a longer time, then consul template will not attempt to obtain a new token. Use a liveness probe to reduce the risk.
- There is currently no good way to [run a sidecar in jobs](https://github.com/kubernetes/kubernetes/issues/25908).
- The sidecar supports a single database. If you need multiple databases, run multiple sidecars and ensure that the ports are and colliding.

## Build instructions

`docker build -t inovex/pgbouncer-vault build`

## Contribution

Contributions are highly appreciated :)

## Acknowledgement



## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](./LICENSE) file for details.