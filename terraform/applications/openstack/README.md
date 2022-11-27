## Provisioning Openstack

## Setup
- all variables from `variables.tf` can be leveraged two ways:
    - via building a `env/local.tfvars` from the `env/local-sample.tfvars`, only required is `SSH_KEY`, rest can fall back on defaults

## First Time Rollout if using `local.tfvars`
- cd into the root of this directory (applications/minio)
- `terraform init`
- `terraform plan -var-file="env/local.tfvars"`
- then to build out openstack, `terraform apply -var-file="env/local.tfvars"`

## What this does
- provisions openstack

## Known Issues:
- cloud-config will timeout on the creation but the creation will continue, it's just terraform will see the vm as a timeout
