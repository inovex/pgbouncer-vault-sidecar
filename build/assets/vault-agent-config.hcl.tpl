exit_after_auth = true
auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes"
        config = {
            role = "{{ env "VAULT_KUBERNETES_ROLE" }}"
            {{ if (env "VAULT_KUBERNETES_TOKEN_PATH") }}
            token_path = "{{ env "VAULT_KUBERNETES_TOKEN_PATH" }}"
            {{ end }}
        }
    }

    sink "file" {
        config = {
            path = "/tmp/auth.token"
        }
    }
}
