# Cloud Foundation GCS bucket module
[FAQ] | [CONTRIBUTING]

This module allows you to create and manage a Google Cloud Storage bucket.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Table of Contents

- [Compatibility](#compatibility)
- [Usage](#usage)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Compatibility

This module requires [terraform] version >=1.3.

## Usage

```hcl
module "tf-state-bucket" {
  source         = "metro-digital/cf-bucket/google"
  project_id     = "metro-cf-example-ex1-e8v"
  name           = "tf-state-metro-cf-example-ex1-e8v"
  location       = "EU"
  storage_class  = "MULTI_REGIONAL"
  uniform_access = true
  versioning     = true

  lifecycle_rules = [
    {
      action = {
        type          = "Delete"
      },
      condition = {
        num_newer_versions = 30
      }
    }
  ]

}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Bucket name | `string` | n/a | yes |
| project_id | GCP project ID | `string` | n/a | yes |
| additional_legacy_bucket_owners | List of additional users/groups/service accounts with role roles/storage.legacyBucketOwner on bucket level<br><br>If `purge_legacy_roles` is set to true, this list becomes authoritative.<br>Otherwise the default permissions will be added automatically. | `list(string)` | `[]` | no |
| additional_legacy_bucket_readers | List of additional users/groups/service accounts with role roles/storage.legacyBucketReader on bucket level<br><br>If `purge_legacy_roles` is set to true, this list becomes authoritative.<br>Otherwise the default permissions will be added automatically. | `list(string)` | `[]` | no |
| additional_legacy_bucket_writers | List of additional users/groups/service accounts with role roles/storage.legacyBucketWriter on bucket level<br><br>If `purge_legacy_roles` is set to true, this list becomes authoritative.<br>Otherwise the default permissions will be added automatically. | `list(string)` | `[]` | no |
| additional_legacy_object_owners | List of additional users/groups/service accounts with role roles/storage.legacyObjectOwner on bucket level<br><br>If `purge_legacy_roles` is set to true, this list becomes authoritative.<br>Otherwise the default permissions will be added automatically. | `list(string)` | `[]` | no |
| additional_legacy_object_readers | List of additional users/groups/service accounts with role roles/storage.legacyObjectReader on bucket level<br><br>If `purge_legacy_roles` is set to true, this list becomes authoritative.<br>Otherwise the default permissions will be added automatically. | `list(string)` | `[]` | no |
| encryption | Bucket's encryption configuration. Please provide the id of a Cloud KMS key that will be used to encrypt objects inserted into this bucket, if no encryption method is specified. You must pay attention to whether the crypto key is available in the location that this bucket is created in | `list(string)` | `[]` | no |
| labels | A set of key/value label pairs to assign to the bucket | `map(string)` | `{}` | no |
| lifecycle_rules | List of lifecycle rules to configure. Format is the same as described in provider documentation https://www.terraform.io/docs/providers/google/r/storage_bucket.html#lifecycle_rule except condition.matches_storage_class should be a comma delimited string.<br><br>Set of objects:<br>  action:<br>    map<br>      * type - The type of the action of this Lifecycle Rule. Supported values: Delete and SetStorageClass.<br>      * storage_class - (Required if action type is SetStorageClass) The target Storage Class of objects affected by this Lifecycle Rule.<br><br>  condition:<br>    map:<br>      * age - (Optional) Minimum age of an object in days to satisfy this condition.<br>      * created_before - (Optional) Creation date of an object in RFC 3339 (e.g. 2017-06-13) to satisfy this condition.<br>      * with_state - (Optional) Match to live and/or archived objects. Supported values include: "LIVE", "ARCHIVED", "ANY".<br>      * matches_storage_class - (Optional) Comma delimited string for storage class of objects to satisfy this condition. Supported values include: MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, STANDARD, DURABLE_REDUCED_AVAILABILITY.<br>      * num_newer_versions - (Optional) Relevant only for versioned objects. The number of newer versions of an object to satisfy this condition.<br><br>Examples:<pre>lifecycle_rules = [<br>  {<br>    action = {<br>      type          = "SetStorageClass"<br>      storage_class = "NEARLINE"<br>    },<br>    condition = {<br>      age                   = "7"<br>      matches_storage_class = "REGIONAL"<br>    }<br>  },<br>  {<br>    action = {<br>      type          = "SetStorageClass"<br>      storage_class = "COLDLINE"<br>    },<br>    condition = {<br>      age                   = "30"<br>      matches_storage_class = "NEARLINE"<br>    }<br>  },<br>]</pre> | <pre>set(object({<br>    action    = map(string)<br>    condition = map(string)<br>  }))</pre> | `[]` | no |
| location | The GCS location - see https://cloud.google.com/storage/docs/bucket-locations | `string` | `"EU"` | no |
| logging | Bucket's Access & Storage Logs configuration<br><br>The logging block supports:<br>  * log_bucket - (Required) The bucket that will receive log objects.<br>  * log_object_prefix - (Optional, Computed) The object prefix for log objects. If it's not provided, by default GCS sets this to this bucket's name.<br><br>Example:<pre>logging = [{<br>  log_bucket        = "some-bucket-to-log-into"<br>  log_object_prefix = "my-prefix"<br>}]</pre> | <pre>set(object({<br>    log_bucket        = string<br>    log_object_prefix = optional(string)<br>  }))</pre> | `[]` | no |
| purge_legacy_roles | If enabled the module will purge the default users from roles/storage.legacy* roles | `bool` | `false` | no |
| soft_delete_retention_duration_seconds | Duration in seconds controlling the soft delete retention of storage object. The value must be in between 604800 seconds (7 days) and 7776000 (90 days). To disable the feature, set the value to 0. | `number` | `604800` | no |
| storage_admins | list of users with role roles/storage.admin on bucket level (authoritative) | `list(string)` | `[]` | no |
| storage_class | Bucket's Storage Class | `string` | `"REGIONAL"` | no |
| storage_object_admins | list of users with role roles/storage.objectAdmin on bucket level (authoritative) | `list(string)` | `[]` | no |
| storage_object_creators | list of users with role roles/storage.objectCreator on bucket level (authoritative) | `list(string)` | `[]` | no |
| storage_object_viewers | list of users with role roles/storage.objectViewer on bucket level (authoritative) | `list(string)` | `[]` | no |
| uniform_access | Enables Uniform bucket-level access to a bucket | `bool` | `true` | no |
| versioning | Enable Versioning | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| location | Bucket location |
| name | Bucket name |
| project | Bucket Project ID |
| storage_class | Bucket's Storage Class |
| versioning | Versioning configuration |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## License

This project is licensed under the terms of the [Apache License 2.0](LICENSE)

This [terraform] module depends on providers from HashiCorp, Inc. which are licensed under MPL-2.0. You can obtain the respective source code for these provider here:
  * [`hashicorp/google`](https://github.com/hashicorp/terraform-provider-google)

[terraform]: https://terraform.io/
[FAQ]: ./docs/FAQ.md
[CONTRIBUTING]: docs/CONTRIBUTING.md
