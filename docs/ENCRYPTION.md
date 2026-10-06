# Bucket encryption

[Back to the module](../README.md) | [Migration](MIGRATION.md#v2-release)

Google-managed encryption is recommended for normal use. Choose a customer-managed KMS key only when
the workload has a specific requirement and someone owns key availability, permissions and recovery.

## Default encryption and enforcement

Omit `encryption`, or set it to `null`, to leave the optional encryption block unconfigured. New
buckets use Google-managed encryption by default:

```hcl
encryption = null
```

A default key selects how uploads are encrypted when they do not specify another method. Enforcement
determines which encryption types uploads are allowed to use. Setting a default KMS key alone does
not enforce CMEK-only uploads.

| Type                     | Who controls the key                 | Enforcement input                                 |
| ------------------------ | ------------------------------------ | ------------------------------------------------- |
| Google-managed (GMEK)    | Google                               | `google_managed_encryption_enforcement_config`    |
| Customer-managed (CMEK)  | Your organization, through Cloud KMS | `customer_managed_encryption_enforcement_config`  |
| Customer-supplied (CSEK) | The uploader supplies the key        | `customer_supplied_encryption_enforcement_config` |

Each optional enforcement object contains `restriction_mode`: `NotRestricted` allows that type;
`FullyRestricted` prohibits it for new objects. No restrictions are enabled by the module's default
configuration.

## Allow only Google-managed encryption

Use this when customer-controlled keys must not be used for new uploads:

```hcl
encryption = {
  google_managed_encryption_enforcement_config = {
    restriction_mode = "NotRestricted"
  }
  customer_managed_encryption_enforcement_config = {
    restriction_mode = "FullyRestricted"
  }
  customer_supplied_encryption_enforcement_config = {
    restriction_mode = "FullyRestricted"
  }
}
```

Uploads requesting a prohibited encryption type fail. Existing objects keep their encryption, so
enabling this policy does not migrate previously encrypted data. See
[Google's enforcement guide](https://cloud.google.com/storage/docs/encryption/enforce-encryption-types).

## Use a customer-managed key as an exception

Pass a full crypto-key resource name, without a `cryptoKeyVersions` suffix:

```hcl
encryption = {
  default_kms_key_name = "projects/PROJECT/locations/eu/keyRings/RING/cryptoKeys/KEY"
}
```

The module does not create the key, grant key permissions or manage key rotation. The key location
must match the bucket location, and the bucket project's Cloud Storage service agent needs
`roles/cloudkms.cryptoKeyEncrypterDecrypter` on the key. Keep required key versions available for
objects already encrypted with them. Changing the bucket's default key does not re-encrypt existing
objects. See
[Google's CMEK guide](https://cloud.google.com/storage/docs/encryption/using-customer-managed-keys).

## Checks and limits

The module rejects malformed key resource names, invalid or null restriction modes, a configuration
restricting all three types, and a default KMS key combined with restrictions on both CMEK and CSEK.
Remove the default KMS key before applying a Google-managed-only policy.

These checks validate the supplied configuration. They cannot establish whether a key exists,
whether IAM grants are sufficient, whether its location is compatible, or whether application
uploads will comply. Review the plan and test the upload path when changing an existing bucket. The
`effective_time` values are computed by Google and are not module inputs.

All three enforcement fields require Google provider `>= 7.26, < 9.0`, the module's supported
provider range. The [migration guide](MIGRATION.md) explains the conversion from the v1 encryption
list to this nullable object.
