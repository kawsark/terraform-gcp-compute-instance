terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "kawsar-org"

    workspaces {
      name = "0822Demo-GCP-compute-instance"
    }
  }
}
