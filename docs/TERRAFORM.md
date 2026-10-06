# Terraform Inputs and Outputs

[Back to the module](../README.md)

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| name | Bucket name. Existing buckets must retain their current name. | `string` | n/a | yes |
| project_id | GCP project ID. | `string` | n/a | yes |
| encryption | Optional bucket encryption configuration. Null uses Google-managed encryption by default. Enforcement controls encryption types for new objects; KMS keys require compatible location and storage service-agent access. | <pre>object({<br/>    default_kms_key_name = optional(string)<br/>    google_managed_encryption_enforcement_config = optional(object({<br/>      restriction_mode = string<br/>    }))<br/>    customer_managed_encryption_enforcement_config = optional(object({<br/>      restriction_mode = string<br/>    }))<br/>    customer_supplied_encryption_enforcement_config = optional(object({<br/>      restriction_mode = string<br/>    }))<br/>  })</pre> | `null` | no |
| iam_bindings | Authoritative bucket IAM bindings, keyed by role, with sets of members. The module replaces the entire bucket policy. Default legacy principals are added unless purge_legacy_roles is true. | `map(set(string))` | `{}` | no |
| labels | Key/value labels assigned to the bucket. | `map(string)` | `{}` | no |
| lifecycle_rules | Lifecycle rules with typed actions and conditions. Numbers are expressed in days or version counts; matches_storage_class is a set of class names. | <pre>set(object({<br/>    action = object({<br/>      type          = string<br/>      storage_class = optional(string)<br/>    })<br/>    condition = object({<br/>      age                   = optional(number)<br/>      created_before        = optional(string)<br/>      with_state            = optional(string)<br/>      matches_storage_class = optional(set(string))<br/>      num_newer_versions    = optional(number)<br/>    })<br/>  }))</pre> | `[]` | no |
| location | GCS location. Changing an existing bucket's location requires replacement. | `string` | `"EU"` | no |
| logging | Optional access and storage logging destination. Set null to omit logging; log_object_prefix is optional. | <pre>object({<br/>    log_bucket        = string<br/>    log_object_prefix = optional(string)<br/>  })</pre> | `null` | no |
| public_access_prevention | Public access prevention: inherited follows organization policy; enforced prevents public access on this bucket. | `string` | `"inherited"` | no |
| purge_legacy_roles | Remove default project owner/editor/viewer principals from legacy roles. Explicit iam_bindings are retained. | `bool` | `false` | no |
| soft_delete_retention_duration_seconds | Whole seconds of soft-delete retention: 604800 (7 days) through 7776000 (90 days), or 0 to disable. | `number` | `604800` | no |
| storage_class | Bucket storage class. Specify the previous value explicitly when upgrading an existing bucket. | `string` | `"STANDARD"` | no |
| uniform_access | Enable uniform bucket-level access. Disabling it adds the Cloud Foundation exemption label. | `bool` | `true` | no |
| versioning | Enable object versioning. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| location | Bucket location |
| name | Bucket name |
| project | Bucket Project ID |
| storage_class | Bucket's Storage Class |
| versioning | Versioning configuration |
<!-- END_TF_DOCS -->
