# :sparkles: :avocado: :potato: :garlic: :carrot: :hot_pepper: :onion: :broccoli: :corn: :herb: :maple_leaf: 
# Crop Bushels 
# :sparkles: :corn: :herb: :maple_leaf: :broccoli: :onion: :hot_pepper: :carrot: :garlic: :potato: :avocado: 

## Integration Utility Provisioning

### Basic Gist:
- needs (`terraform --version`) v1.3.5 and greater
- leveraging Harvester Terraform Provider and Cloud Config, we can simultaneously provision (much much much much faster than Ansible) different integration elements that we need to stand up in order to test ex: Docker-based-Rancher, Elasticsearch, MinIO (for S3), Openstack, and more.  
- all that's needed as a pre-req, is a `local.yaml` that will exist within the root of the directory that points to a Harvester cluster
- state is separate by design from one application to the next, there is "carry-over" with overhead on re-downloading images (for now...), "modules" is currently deprecated as juggling "shared resources" could get tricky 

#### With Terraform:
- drop your Harvester Cluster, `local.yaml` in the root of the project for quick integrations
- basic flow:
    - build a local.tfvars from the local-sample.tfvars (place inside provisioning application env folder), usually only `SSH_KEY` is required, can fall back on defaults for others
    - then `terraform init` from within the application directory
    - then `terraform apply -var-file="env/local.tfvars"`:
        - pay attention to the "output" message provided at the end of provisioning, that will provide additional insight on an integration application basis (as in providing information about ports used, the credentials, access points, follow-up steps, etc.)
    - then to remove `terraform apply -var-file="env/local.tfvars" -destroy`  
- `variables.tf` holds all variables with defaults used, local.tfvars will override when variable is provided

#### Future State:
- introduce more provisioning steps per application, for-instance with provisioning elasticsearch, it would be excellent to just go ahead and build an index, user, and secret - in order to make testing Cluster-Flow & Cluster-Output a bit quicker, but for now the "follow-up-steps" output message details those elements with proper interpolation of IPv4 assigned to VM etc.
- also, for instance, automating the creation of a MinIO bucket / region / SECRET & API_KEY for quicker integrations with testing S3 based backups 

## Currently Somewhat WIP, Possibly Unstable / Changes May Happen!
### Known Issues:
- Openstack, "CloudConfig" will "timeout", but the VM will be created and it will continue to be provisioning:
    - Openstack is the "most" resource intensive
- Caddy, it will "finish" provisioning, but you will be greeted with a "Welcome To Caddy" screen on that URL, as opinionatedly the provisioning in the background is still downloading the latest `harvester-master-amd64.iso`.  Once that is finished it will be at that "url" and the screen will change to just display the index with your ability to browse to see the iso.
- Sometimes can't delete image: `abc is being used by volume abc`, will need to manually clean