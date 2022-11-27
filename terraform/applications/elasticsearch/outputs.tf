locals {
  base64encodepw = base64encode("harvestertesting")
}

output "information_next_steps" {
  value = <<-EOF
    Hello!
    Elasticsearch v6.8.23 is FINISHED Provisioning, hooray!
    It is up at: ${harvester_virtualmachine.es-vm.network_interface[0].ip_address}
    With the respective ports open of: 9200 & 9300
    Also!
    The VM's SSH User is: ubuntu
    With the password of: ${var.ES_VM_PW}
    You will want to follow-up and perform some additional things, once validating Elasticsearch is up:
    One, build a user for Harvester to access Elasticsearch something like:
    ```
    curl --location --request POST 'http://${harvester_virtualmachine.es-vm.network_interface[0].ip_address}:9200/security/user/harvesteruser?pretty' \
    --header 'Content-Type: application/json' \
    --data-raw '{
        "password": "harvestertesting",
        "enabled": true,
        "roles": ["superuser", "kibana_admin"],
        "full_name": "Harvester TestingUser",
        "email": "harvestertesting@harvesterhci.io"
    }'
    ```
    Which, should return something like:
    ```
    {
    "_index" : "security",
    "_type" : "user",
    "_id" : "harvesteruser",
    "_version" : 1,
    "result" : "created",
    "_shards" : {
        "total" : 2,
        "successful" : 1,
        "failed" : 0
    },
    "_seq_no" : 0,
    "_primary_term" : 1
    }
    ```
    Two, build an index for Harvester to use on Elasticsearch:
    ```
    curl --location --request PUT '${harvester_virtualmachine.es-vm.network_interface[0].ip_address}:9200/harvesterindex?pretty'
    ```
    Which should return something like:
    ```
    {
    "acknowledged" : true,
    "shards_acknowledged" : true,
    "index" : "harvesterindex"
    }
    ```
    Three, 'optional' build a secret on your Harvester Cluster, with the "password" (here we've encoded the hardcoded pw as base64 already) for the Harvester Elasticsearch user with something like:
    ```
    apiVersion: v1
    kind: Secret
    metadata:
        name: elastic-test-secret
        namespace: default
    type: Opaque
    data:
        password: ${local.base64encodepw}
    ``` 
    Four, then you can configure the Cluster-Flow & Cluster-Output to use this instance of Elasticsearch
    Five, once those are hooked up you can view things are being funneled into Elasticsearch via:
    ```
    curl http://${harvester_virtualmachine.es-vm.network_interface[0].ip_address}:9200/harvesterindex/_search -u harvesteruser:harvestertesting -v | jq
    ```
  EOF

}