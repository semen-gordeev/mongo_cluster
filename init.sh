#!/bin/bash

docker network create mongocluster_default

docker-compose scale shard01=1 shard02=1 shard03=1 shard11=1 shard12=1 shard13=1 configsvr1=1 configsvr2=1

sleep 3

docker exec -it mongocluster_shard01_1 mongo --port 27018 --eval 'rs.initiate(
    {
        _id : "shard0",
        members: [
        { _id : 0, host : "mongocluster_shard01_1:27018" },
        { _id : 1, host : "mongocluster_shard02_1:27018" },
        { _id : 2, host : "mongocluster_shard03_1:27018" }
        ]
    }
);'

docker exec -it mongocluster_shard11_1 mongo --port 27018 --eval 'rs.initiate(
    {
        _id : "shard1",
        members: [
        { _id : 0, host : "mongocluster_shard11_1:27018" },
        { _id : 1, host : "mongocluster_shard12_1:27018" },
        { _id : 2, host : "mongocluster_shard13_1:27018" }
        ]
    }
);'

docker exec -it mongocluster_configsvr1_1 mongo --port 27019 --eval 'rs.initiate(
    {
        _id : "configsvr",
        configsvr: true,
        members: [
        { _id : 0, host : "mongocluster_configsvr1_1:27019" },
        { _id : 1, host : "mongocluster_configsvr2_1:27019" }
        ]
    }
);'

docker-compose scale mongos=1

sleep 15

docker exec -it mongocluster_mongos_1 mongo --eval 'sh.addShard("shard0/mongocluster_shard01_1:27018,mongocluster_shard02_1:27018,mongocluster_shard03_1:27018");
                                                    sh.addShard("shard1/mongocluster_shard11_1:27018,mongocluster_shard12_1:27018,mongocluster_shard13_1:27018");'
