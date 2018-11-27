resource "google_container_cluster" "primary" {
  name               = "cluster"
  zone               = "europe-west2-b"
  additional_zones = [
    "europe-west2-c"
  ]
  initial_node_count = 1
  project            = "kube-personal"

  master_auth {
    username = "${var.username}"
    password = "${var.password}"
  }

  node_config {
    machine_type = "g1-small"
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels {
      project = "robinyonge.com"
    }

    tags = ["project", "kube-personal"]
  }
}

output "endpoint" {
  value = "${google_container_cluster.primary.endpoint}"
}

output "client_certificate" {
  value = "${google_container_cluster.primary.master_auth.0.client_certificate}"
}

output "client_key" {
  value = "${google_container_cluster.primary.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}"
}