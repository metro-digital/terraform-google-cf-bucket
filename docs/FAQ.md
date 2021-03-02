# Frequently Asked Questions
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Table of Contents

- [Security Scanning](#security-scanning)
  - [I want a bucket with uniform access disabled](#i-want-a-bucket-with-uniform-access-disabled)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Security Scanning
### I want a bucket with uniform access disabled
The module supports disabling uniform access for bucket via `uniform_access` parameter. We strongly recommend to keep uniformed access enabled.
If you disable uniform access an additional label is placed on your bucket to prevent any security finding.