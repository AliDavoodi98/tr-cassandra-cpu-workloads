provider "aws" {
  region = "us-east-1"
}

module "cassandra_cluster" {
  source = "./modules/cassandra-cluster"
  ami_id = "ami-0ebfd941bbafe70c6"
}

module "cassandra-registeration-cloudwatch-logs" {
  source = "./modules/cloudwatch"
  log_roup_name = "cassandra-registeration-cloudwatch-logs" 
  retention_days = 7
  aws_autoscaling_group = module.cassandra_cluster.aws_autoscaling_group
}

