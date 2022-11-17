## Provisioning MINIO

## Setup
- all variables from `variables.tf` can be leveraged two ways:
    - via building a `env/local.tfvars` from the `env/local-sample.tfvars` (suggested)
    - via building a `.env` from the `.sample-env`

## First Time Rollout if using `local.tfvars` (suggested)
- cd into the root of this directory (applications/minio)
- `terraform init`
- `terraform plan -var-file="env/local.tfvars"`
- then to build out the minio vm for s3 based testing, `terraform apply -var-file="env/local.tfvars"`

## First Time Rollout if using `.env` file
- `source .env` 
- `terraform init`
- `terraform plan`
- `terraform apply`

## What this does
- provisions minio as a systemd service on a ubuntu based distro, if you restart the VM, systemd will bring the service back online  
