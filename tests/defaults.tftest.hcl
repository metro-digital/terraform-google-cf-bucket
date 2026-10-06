# Copyright 2026 METRO Digital GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

mock_provider "google" {
  source = "./tests/mocks"
}

variables {
  name       = "cf-unit-test-bucket"
  project_id = "cf-unit-test"
}

run "bucket_defaults" {
  command = plan

  assert {
    condition     = output.name == "cf-unit-test-bucket" && output.project == "cf-unit-test" && output.location == "EU" && output.storage_class == "REGIONAL"
    error_message = "The existing identity, location and storage-class defaults must remain stable."
  }

  assert {
    condition     = google_storage_bucket.bucket.uniform_bucket_level_access && !one(output.versioning).enabled
    error_message = "Uniform access must default to enabled and versioning to disabled."
  }

  assert {
    condition     = google_storage_bucket.bucket.public_access_prevention == "inherited" && one(google_storage_bucket.bucket.soft_delete_policy).retention_duration_seconds == 604800
    error_message = "Public access and soft-delete defaults must remain stable."
  }

  assert {
    condition     = length(google_storage_bucket.bucket.lifecycle_rule) == 0 && length(google_storage_bucket.bucket.logging) == 0 && length(google_storage_bucket.bucket.encryption) == 0
    error_message = "Optional bucket configuration must be absent by default."
  }

  assert {
    condition     = length(local.labels) == 0
    error_message = "No exemption label should be injected with uniform access enabled."
  }
}

run "custom_identity_and_outputs" {
  command = plan
  variables {
    name          = "cf-custom-bucket"
    project_id    = "cf-other-project"
    location      = "europe-west1"
    storage_class = "STANDARD"
    versioning    = true
    labels        = { owner = "platform" }
  }

  assert {
    condition     = output.name == "cf-custom-bucket" && output.project == "cf-other-project" && output.location == "europe-west1" && output.storage_class == "STANDARD" && one(output.versioning).enabled
    error_message = "Outputs must reflect caller configuration."
  }

  assert {
    condition     = google_storage_bucket.bucket.labels["owner"] == "platform" && !contains(keys(google_storage_bucket.bucket.labels), "cf_no_require_bucket_policy_only")
    error_message = "Caller labels must reach the bucket without an exemption label."
  }
}

run "uniform_access_exemption" {
  command = plan
  variables {
    uniform_access = false
    labels         = { owner = "platform", cf_no_require_bucket_policy_only = "false" }
  }

  assert {
    condition     = !google_storage_bucket.bucket.uniform_bucket_level_access && google_storage_bucket.bucket.labels["owner"] == "platform" && google_storage_bucket.bucket.labels["cf_no_require_bucket_policy_only"] == "true"
    error_message = "Disabling uniform access must enforce the exemption label and preserve caller labels."
  }
}
