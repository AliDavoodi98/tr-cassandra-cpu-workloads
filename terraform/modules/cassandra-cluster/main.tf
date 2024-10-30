resource "aws_placement_group" "placement_group_cluster" {
  name = "placement-group"
  strategy = "cluster"
}

resource "aws_launch_template" "main" {
  name_prefix = "cassandra_node"
  image_id = var.ami_id
  instance_type = "m5.large"

  security_group_names = [aws_security_group.main.name]

  # network_interfaces {
  #   security_groups = [aws_security_group.main.id]
  # }
}

resource "aws_security_group" "main" {
  name = "cassandra-security-group"
  description = "Setup Cassandra access"

  ingress {
    description = "Allow Cassandra Cluster"
    from_port = 9042
    to_port = 9042
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    description = "Allow Outbound"
    from_port = 0
    to_port = 0
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = {
    Name = "asg-sg"
  }
}

resource "aws_autoscaling_group" "main" {
  availability_zones = ["us-east-1a"]
  name = "aws-autoscaling-group"
  max_size = 5
  min_size = 0
  desired_capacity = 1
  health_check_grace_period = 300
  health_check_type = "ELB"
  force_delete = true
  placement_group = aws_placement_group.placement_group_cluster.id
  launch_template {
    id = aws_launch_template.main.id 
    version = "$Latest"
  }
  
}

output "aws_autoscaling_group" {
  value = aws_autoscaling_group.main.name
}