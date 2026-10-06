# Frequently Asked Questions

**Table of Contents**

<!-- mdformat-toc start --slug=github --no-anchors --maxlevel=6 --minlevel=2 -->

- [Security Scanning](#security-scanning)
  - [I want a bucket with uniform access disabled](#i-want-a-bucket-with-uniform-access-disabled)

<!-- mdformat-toc end -->

## Security Scanning

### I want a bucket with uniform access disabled

The module supports disabling uniform access for bucket via `uniform_access` parameter. We strongly
recommend to keep uniformed access enabled. If you disable uniform access an additional label is
placed on your bucket to prevent any security finding.
