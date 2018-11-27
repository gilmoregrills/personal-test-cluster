provider "google" {
  credentials = "${file("account.json")}"
  project     = "kube-personal"
  region      = "europe-west2"
}

terraform {
  backend "gcs" {
    bucket = "tf-state-personal"
    prefix = "state"
  }
}

data "terraform_remote_state" "network" {
  backend = "gcs"

  config {
    bucket = "tf-state-personal"
    prefix = "state"
  }
}
