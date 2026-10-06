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

# Assert documented migration examples against explicit expected configuration.
# These mocked plans do not verify a live state upgrade.
mock_provider "google" { source = "./tests/mocks" }
variables {
  name       = "cf-unit-test-bucket"
  project_id = "cf-unit-test"
}

run "migrated_defaults" {
  command = plan
  variables {
    purge_legacy_roles                     = false
    storage_class                          = "REGIONAL"
    uniform_access                         = false
    versioning                             = true
    labels                                 = { owner = "platform" }
    public_access_prevention               = "enforced"
    soft_delete_retention_duration_seconds = 7776000
    logging                                = { log_bucket = "cf-logs", log_object_prefix = "audit/" }
    encryption                             = { default_kms_key_name = "projects/cf-unit-test/locations/eu/keyRings/test/cryptoKeys/bucket" }
    lifecycle_rules = [{
      action    = { type = "SetStorageClass", storage_class = "NEARLINE" }
      condition = { age = 7, matches_storage_class = ["REGIONAL", "STANDARD"] }
    }]
    iam_bindings = {
      "roles/storage.legacyBucketOwner"  = ["group:owners@example.com"]
      "roles/storage.legacyBucketReader" = ["group:readers@example.com"]
      "roles/storage.legacyBucketWriter" = ["group:writers@example.com"]
      "roles/storage.legacyObjectOwner"  = ["group:object-owners@example.com"]
      "roles/storage.legacyObjectReader" = ["group:object-readers@example.com"]
      "roles/storage.admin"              = ["group:admins@example.com"]
      "roles/storage.objectAdmin"        = ["group:object-admins@example.com"]
      "roles/storage.objectCreator"      = ["group:creators@example.com"]
      "roles/storage.objectViewer"       = ["group:viewers@example.com"]
    }
  }
  assert {
    condition = (
      output.name == "cf-unit-test-bucket" && output.project == "cf-unit-test" &&
      output.location == "EU" && output.storage_class == "REGIONAL" &&
      !google_storage_bucket.bucket.uniform_bucket_level_access &&
      one(output.versioning).enabled &&
      google_storage_bucket.bucket.labels == tomap({ owner = "platform", cf_no_require_bucket_policy_only = "true" })
    )
    error_message = "Migrated inputs must retain bucket identity, class, labels, access mode and versioning."
  }
  assert {
    condition = (
      google_storage_bucket.bucket.public_access_prevention == "enforced" &&
      one(google_storage_bucket.bucket.soft_delete_policy).retention_duration_seconds == 7776000 &&
      one(google_storage_bucket.bucket.logging).log_bucket == "cf-logs" &&
      one(google_storage_bucket.bucket.logging).log_object_prefix == "audit/" &&
      one(google_storage_bucket.bucket.encryption).default_kms_key_name == "projects/cf-unit-test/locations/eu/keyRings/test/cryptoKeys/bucket"
    )
    error_message = "Migrated inputs must retain protection, logging and encryption settings."
  }
  assert {
    condition = (
      length(google_storage_bucket.bucket.lifecycle_rule) == 1 &&
      one(one(google_storage_bucket.bucket.lifecycle_rule).action).type == "SetStorageClass" &&
      one(one(google_storage_bucket.bucket.lifecycle_rule).action).storage_class == "NEARLINE" &&
      one(one(google_storage_bucket.bucket.lifecycle_rule).condition).age == 7 &&
      one(one(google_storage_bucket.bucket.lifecycle_rule).condition).created_before == null &&
      one(one(google_storage_bucket.bucket.lifecycle_rule).condition).num_newer_versions == null &&
      toset(one(one(google_storage_bucket.bucket.lifecycle_rule).condition).matches_storage_class) == toset(["REGIONAL", "STANDARD"])
    )
    error_message = "The migrated lifecycle rule must preserve its action, age and matching storage classes."
  }
  assert {
    condition = tomap({ for binding in data.google_iam_policy.bucket.binding : binding.role => toset(binding.members) }) == tomap({
      "roles/storage.legacyBucketOwner"  = toset(["group:owners@example.com", "projectEditor:cf-unit-test", "projectOwner:cf-unit-test"])
      "roles/storage.legacyBucketReader" = toset(["group:readers@example.com", "projectViewer:cf-unit-test"])
      "roles/storage.legacyBucketWriter" = toset(["group:writers@example.com"])
      "roles/storage.legacyObjectOwner"  = toset(["group:object-owners@example.com", "projectEditor:cf-unit-test", "projectOwner:cf-unit-test"])
      "roles/storage.legacyObjectReader" = toset(["group:object-readers@example.com", "projectViewer:cf-unit-test"])
      "roles/storage.admin"              = toset(["group:admins@example.com"])
      "roles/storage.objectAdmin"        = toset(["group:object-admins@example.com"])
      "roles/storage.objectCreator"      = toset(["group:creators@example.com"])
      "roles/storage.objectViewer"       = toset(["group:viewers@example.com"])
    })
    error_message = "Migrated role inputs must retain exactly the expected explicit and legacy principals."
  }
}

run "migrated_purged" {
  command = plan
  variables {
    purge_legacy_roles                     = true
    storage_class                          = "REGIONAL"
    uniform_access                         = false
    versioning                             = true
    labels                                 = { owner = "platform" }
    public_access_prevention               = "enforced"
    soft_delete_retention_duration_seconds = 7776000
    logging                                = { log_bucket = "cf-logs", log_object_prefix = "audit/" }
    encryption                             = { default_kms_key_name = "projects/cf-unit-test/locations/eu/keyRings/test/cryptoKeys/bucket" }
    lifecycle_rules = [{
      action    = { type = "SetStorageClass", storage_class = "NEARLINE" }
      condition = { age = 7, matches_storage_class = ["REGIONAL", "STANDARD"] }
    }]
    iam_bindings = {
      "roles/storage.legacyBucketOwner"  = ["group:owners@example.com"]
      "roles/storage.legacyBucketReader" = ["group:readers@example.com"]
      "roles/storage.legacyBucketWriter" = ["group:writers@example.com"]
      "roles/storage.legacyObjectOwner"  = ["group:object-owners@example.com"]
      "roles/storage.legacyObjectReader" = ["group:object-readers@example.com"]
      "roles/storage.admin"              = ["group:admins@example.com"]
      "roles/storage.objectAdmin"        = ["group:object-admins@example.com"]
      "roles/storage.objectCreator"      = ["group:creators@example.com"]
      "roles/storage.objectViewer"       = ["group:viewers@example.com"]
    }
  }
  assert {
    condition = (
      output.name == "cf-unit-test-bucket" && output.project == "cf-unit-test" &&
      output.location == "EU" && output.storage_class == "REGIONAL" &&
      !google_storage_bucket.bucket.uniform_bucket_level_access &&
      one(output.versioning).enabled &&
      google_storage_bucket.bucket.labels == tomap({ owner = "platform", cf_no_require_bucket_policy_only = "true" })
    )
    error_message = "Migrated inputs must retain bucket identity, class, labels, access mode and versioning."
  }
  assert {
    condition = (
      google_storage_bucket.bucket.public_access_prevention == "enforced" &&
      one(google_storage_bucket.bucket.soft_delete_policy).retention_duration_seconds == 7776000 &&
      one(google_storage_bucket.bucket.logging).log_bucket == "cf-logs" &&
      one(google_storage_bucket.bucket.logging).log_object_prefix == "audit/" &&
      one(google_storage_bucket.bucket.encryption).default_kms_key_name == "projects/cf-unit-test/locations/eu/keyRings/test/cryptoKeys/bucket"
    )
    error_message = "Migrated inputs must retain protection, logging and encryption settings."
  }
  assert {
    condition = (
      length(google_storage_bucket.bucket.lifecycle_rule) == 1 &&
      one(one(google_storage_bucket.bucket.lifecycle_rule).action).type == "SetStorageClass" &&
      one(one(google_storage_bucket.bucket.lifecycle_rule).action).storage_class == "NEARLINE" &&
      one(one(google_storage_bucket.bucket.lifecycle_rule).condition).age == 7 &&
      one(one(google_storage_bucket.bucket.lifecycle_rule).condition).created_before == null &&
      one(one(google_storage_bucket.bucket.lifecycle_rule).condition).num_newer_versions == null &&
      toset(one(one(google_storage_bucket.bucket.lifecycle_rule).condition).matches_storage_class) == toset(["REGIONAL", "STANDARD"])
    )
    error_message = "The migrated lifecycle rule must preserve its action, age and matching storage classes."
  }
  assert {
    condition = tomap({ for binding in data.google_iam_policy.bucket.binding : binding.role => toset(binding.members) }) == tomap({
      "roles/storage.legacyBucketOwner"  = toset(["group:owners@example.com"])
      "roles/storage.legacyBucketReader" = toset(["group:readers@example.com"])
      "roles/storage.legacyBucketWriter" = toset(["group:writers@example.com"])
      "roles/storage.legacyObjectOwner"  = toset(["group:object-owners@example.com"])
      "roles/storage.legacyObjectReader" = toset(["group:object-readers@example.com"])
      "roles/storage.admin"              = toset(["group:admins@example.com"])
      "roles/storage.objectAdmin"        = toset(["group:object-admins@example.com"])
      "roles/storage.objectCreator"      = toset(["group:creators@example.com"])
      "roles/storage.objectViewer"       = toset(["group:viewers@example.com"])
    })
    error_message = "Migrated role inputs must retain exactly the expected explicit and legacy principals."
  }
}
