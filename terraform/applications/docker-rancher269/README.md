## Provisioning Docker Rancher v2.6.9

## Setup
- all variables from `variables.tf` can be leveraged two ways:
    - via building a `env/local.tfvars` from the `env/local-sample.tfvars` (suggested)  , only required is `SSH_KEY`, rest can fall back on defaults

## First Time Rollout if using `local.tfvars` (suggested)
- cd into the root of this directory (applications/minio)
- `terraform init`
- `terraform plan -var-file="env/local.tfvars"`
- then to build out the dockerized rancher v2.6.9, `terraform apply -var-file="env/local.tfvars"`

## First Time Rollout if using `.env` file
- `source .env` 
- `terraform init`
- `terraform plan`
- `terraform apply`

## What this does
- provisions dockerized Rancher v2.6.9