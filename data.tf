# Copyright 2024 METRO Digital GmbH
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

data "google_iam_policy" "bucket" {
  #######
  #
  # Storage Legacy roles
  #
  #######
  # https://cloud.google.com/iam/docs/understanding-roles#cloud-storage-legacy-roles

  binding {
    role = "roles/storage.legacyBucketOwner"
    members = compact(concat(
      var.additional_legacy_bucket_owners,
      var.purge_legacy_roles ? [] : local.iam_legacy_owner
    ))
  }

  binding {
    role = "roles/storage.legacyBucketReader"
    members = compact(concat(
      var.additional_legacy_bucket_readers,
      var.purge_legacy_roles ? [] : local.iam_legacy_reader
    ))
  }

  binding {
    role    = "roles/storage.legacyBucketWriter"
    members = var.additional_legacy_bucket_writers
  }


  binding {
    role = "roles/storage.legacyObjectOwner"
    members = compact(concat(
      var.additional_legacy_object_owners,
      var.purge_legacy_roles ? [] : local.iam_legacy_owner
    ))
  }

  binding {
    role = "roles/storage.legacyObjectReader"
    members = compact(concat(
      var.additional_legacy_object_readers,
      var.purge_legacy_roles ? [] : local.iam_legacy_reader
    ))
  }

  #######
  #
  # Storage roles
  #
  #######
  # https://cloud.google.com/iam/docs/understanding-roles#storage-roles

  binding {
    role    = "roles/storage.admin"
    members = compact(var.storage_admins)
  }

  binding {
    role    = "roles/storage.objectAdmin"
    members = compact(var.storage_object_admins)
  }

  binding {
    role    = "roles/storage.objectCreator"
    members = compact(var.storage_object_creators)
  }

  binding {
    role    = "roles/storage.objectViewer"
    members = compact(var.storage_object_viewers)
  }
}
