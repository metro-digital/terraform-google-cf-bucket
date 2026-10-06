# Public Registry example for the forthcoming v2 module.
terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.6"
    }
  }
}

module "bucket" {
  source  = "metro-digital/cf-bucket/google"
  version = "~> 2.0" # x-release-please-major
  providers = {
    google = google
  }

  name          = var.bucket_name
  project_id    = var.project_id
  location      = "EU"
  storage_class = "STANDARD"
  versioning    = true

  lifecycle_rules = [{
    action    = { type = "Delete" }
    condition = { num_newer_versions = 30 }
  }]

  iam_bindings = {
    "roles/storage.objectViewer" = ["group:readers@example.com"]
  }
}
