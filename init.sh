#!/bin/bash

docker-compose scale shard0=3 shard1=3 configsvr=2

sleep 3

docker exec -it mongocluster_shard0_1 mongo --port 27018 --eval 'rs.initiate(
    {
        _id : "shard0",
        members: [
        { _id : 0, host : "mongocluster_shard0_1:27018" },
        { _id : 1, host : "mongocluster_shard0_2:27018" },
        { _id : 2, host : "mongocluster_shard0_3:27018" }
        ]
    }
);'

docker exec -it mongocluster_shard1_1 mongo --port 27018 --eval 'rs.initiate(
    {
        _id : "shard1",
        members: [
        { _id : 0, host : "mongocluster_shard1_1:27018" },
        { _id : 1, host : "mongocluster_shard1_2:27018" },
        { _id : 2, host : "mongocluster_shard1_3:27018" }
        ]
    }
);'

docker exec -it mongocluster_configsvr_1 mongo --port 27019 --eval 'rs.initiate(
    {
        _id : "configsvr",
        configsvr: true,
        members: [
        { _id : 0, host : "mongocluster_configsvr_1:27019" },
        { _id : 1, host : "mongocluster_configsvr_2:27019" }
        ]
    }
);'

docker-compose scale mongos=1

sleep 5

docker exec -it mongocluster_mongos_1 mongo --eval 'sh.addShard("shard0/mongocluster_shard0_1:27018,mongocluster_shard0_2:27018,mongocluster_shard0_3:27018");
                                                    sh.addShard("shard1/mongocluster_shard1_1:27018,mongocluster_shard1_2:27018,mongocluster_shard1_3:27018");'