## Provisioning Elasticsearch v6.8.23

## Setup
- all variables from `variables.tf` can be leveraged:
    - via building a `env/local.tfvars` from the `env/local-sample.tfvars` , only required is `SSH_KEY`, rest can fall back on defaults

## First Time Rollout if using `local.tfvars`
- cd into the root of this directory (applications/elasticsearch)
- `terraform init`
- `terraform plan -var-file="env/local.tfvars"`
- then to build out the elasticsearch vm for logs funneling out to Elasticsearch via Cluser-Flow & Cluster-Output based testing from a Harvester cluster, `terraform apply -var-file="env/local.tfvars"`


## What this does
- provisions elasticsearch v6.8.23 as a docker image
