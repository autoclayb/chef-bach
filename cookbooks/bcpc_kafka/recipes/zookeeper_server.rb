#
# Cookbook Name:: bcpc_kafka
# Recipe: zookeeper_server
#
# This recipe is essentially a role for Zookeeper servers in a
# standalone Kafka cluster.
#
# In addition to Zookeeper itself, the ZK hosts will be running all
# the cluster maintenance items: mysql, graphite, zabbix etc.
#

include_recipe 'bcpc_kafka::default'

# For the time being, this will have to be force_override.
node.force_override[:bcpc][:hadoop][:kerberos][:enable] = false

include_recipe 'bcpc-hadoop::zookeeper_server'
