# Module safeguards and possible extensions

[Back to the module](../README.md)

The module deliberately exposes a subset of `google_storage_bucket`. Its value is in documented
defaults, typed interfaces and checks on configuration combinations, rather than exposing every
provider argument. This page distinguishes existing behavior from recommendations for future
changes; it adds no module inputs.

## Safeguards already present in v2

| Topic         | Current module behavior                                                                           | Remaining responsibility                                                           |
| ------------- | ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Encryption    | Typed optional object; validates modes, key-name format and conflicting restrictions              | KMS availability, IAM, location and compliant uploads                              |
| Lifecycle     | Validates action/class combinations, dates, states, counts and nonempty conditions                | Workload retention, safe scope, rule overlaps and supported transitions            |
| Soft deletion | Seven-day default; whole seconds in the supported range, with explicit zero to disable            | Cost, suitable recovery window and tested restoration                              |
| IAM           | One authoritative policy; merges legacy defaults, removes empty bindings and deduplicates members | Include every intended grant and assess inherited project/organization permissions |
| Access        | Uniform access enabled by default; validates public-access prevention mode                        | Ensure organization policy and any public access exceptions match the workload     |

Encryption checks apply to the supplied configuration. They are not an organization-wide enforcement
boundary: a caller can choose different module settings, and another principal with sufficient
permission can change the bucket.

The module's whole-policy IAM ownership is already more opinionated than a simple resource wrapper.
Bucket grants managed elsewhere can be removed on apply; inherited IAM grants are outside this
policy's scope.

## Recommended next improvements

| Priority          | Candidate                               | Useful module behavior                                                                                                                  | Current status                                     |
| ----------------- | --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| High              | Terraform deletion protection           | Expose and validate the provider's `deletion_policy`; document explicit removal of protection before destroy                            | Not exposed                                        |
| High              | Public access checks                    | Reject public IAM members when bucket public-access prevention is explicitly `enforced`; document `inherited` and organization controls | Mode validated, cross-input checks not implemented |
| High              | Lifecycle scope and noncurrent age      | Add prefix/suffix filters and days since becoming noncurrent, with action-specific validation                                           | Not exposed                                        |
| Medium            | Retention policy and Bucket Lock        | Typed retention settings, deliberate lock opt-in, and clear irreversible-change guidance                                                | Not exposed                                        |
| Medium            | Autoclass                               | Validate conflicts with manual storage-class transitions and storage-class conditions                                                   | Not exposed                                        |
| Workload-specific | Hierarchical namespace and IP filtering | Validate prerequisites, creation-time choices and access-path compatibility                                                             | Not exposed                                        |

These priorities are module-design recommendations, not promises of additional v2 scope. Check each
candidate against the minimum provider before adding it, and cover behavior with tests rather than
simply forwarding more arguments.

### Deletion protection

The provider supports `deletion_policy = "PREVENT"` to reject Terraform deletion while that value is
in state. `DELETE` permits deletion; `ABANDON` removes Terraform ownership without deleting the
bucket. The module currently relies on provider defaults. `force_destroy` also remains unexposed and
false by default: this normally stops deletion of a populated bucket, but does not protect an empty
bucket. See the
[provider resource documentation](https://github.com/hashicorp/terraform-provider-google/blob/v8.6.0/website/docs/r/storage_bucket.html.markdown).

### Public access and uniform access

For private workloads, keep `uniform_access = true`. Consider explicitly setting
`public_access_prevention = "enforced"` where organization policy does not already provide the
required protection; the current default is `inherited`. Public access prevention does not block
signed URLs. Uniform access disables ACLs and cannot be turned off after 90 consecutive days. These
operational facts merit guidance even without more inputs. See
[public access prevention](https://cloud.google.com/storage/docs/public-access-prevention) and
[uniform access](https://cloud.google.com/storage/docs/uniform-bucket-level-access).

### Retention and storage-class automation

A retention policy prevents eligible objects from being deleted or overwritten too soon, unlike a
lifecycle deletion rule or a soft-delete recovery window. Locking that policy is irreversible: it
cannot be removed or shortened. Any future module support should make locking a separate, explicit
choice. See [Bucket Lock](https://cloud.google.com/storage/docs/bucket-lock).

Autoclass cannot be combined with lifecycle `SetStorageClass` actions or `matches_storage_class`
conditions. Supporting it should include checks for both conflicts. See
[Autoclass restrictions](https://cloud.google.com/storage/docs/autoclass#restrictions).
