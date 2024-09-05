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

output "name" {
  description = "Bucket name"
  value       = google_storage_bucket.bucket.name
}

output "project" {
  description = "Bucket Project ID"
  value       = google_storage_bucket.bucket.project
}

output "location" {
  description = "Bucket location"
  value       = google_storage_bucket.bucket.location
}

output "storage_class" {
  description = "Bucket's Storage Class"
  value       = google_storage_bucket.bucket.storage_class
}

output "versioning" {
  description = "Versioning configuration"
  value       = google_storage_bucket.bucket.versioning
}

