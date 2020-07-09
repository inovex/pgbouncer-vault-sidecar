exit_after_auth = true
auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes"
        config = {
            role = "__ROLE__"
        }
    }

    sink "file" {
        config = {
            path = "/tmp/auth.token"
        }
    }
}
