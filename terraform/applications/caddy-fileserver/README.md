## Provisioning Caddy

## Setup
- all variables from `variables.tf` can be leveraged two ways:
    - via building a `env/local.tfvars` from the `env/local-sample.tfvars` (suggested) , only required is `SSH_KEY`, rest can fall back on defaults

## First Time Rollout if using `local.tfvars` (suggested)
- cd into the root of this directory (applications/caddy-fileserver)
- `terraform init`
- `terraform plan -var-file="env/local.tfvars"`
- then to build out the caddy-fileserver, `terraform apply -var-file="env/local.tfvars"`

## What this does
- provisions a caddy fileserver that operates over port 80 by default
- will grab the "current" harvester-master-amd64.iso
- will have home/ubuntu/harvester-isos in which that serves as the file serving directory
- NOTE: once it's finished, file "may" still be downloading - THIS might occur if you see the "Caddy Works" page, it's still loading in the master iso... just give it some time, you can check by refreshing the page, eventually it will drop you into the index with the latest harvester master iso 
- you can login as ubuntu, and just `wget` additional files or scp things over the the /home/ubuntu/harvester-isos directory, like building version.yamls or anything else
