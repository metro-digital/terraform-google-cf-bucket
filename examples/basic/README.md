# Basic v2 bucket example

This example uses `metro-digital/cf-bucket/google` from the public Terraform Registry. It requires
the v2 release to be published before initialization. `~> 2.0` allows all module 2.x releases.
`~> 8.6` allows Google provider 8.x releases starting at 8.6.0.

Supply `bucket_name` and `project_id` in a local `terraform.tfvars` file and replace the example IAM
member before planning or applying:

```hcl
bucket_name = "YOUR-GLOBALLY-UNIQUE-BUCKET-NAME"
project_id  = "your-project-id"
```

```sh
terraform init -backend=false
terraform validate
terraform plan
```

Initialization and validation do not create resources. Planning uses a real Google provider and
requires credentials; applying creates a bucket and owns its full IAM policy. Google-managed
encryption is used by default. Optional logging, KMS-key and encryption enforcement examples are
shown in the root README.
