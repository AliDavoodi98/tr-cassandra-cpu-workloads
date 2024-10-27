resource "aws_cloudwatch_log_group" "log_roup" {
  name = var.log_roup_name
  retention_in_days = var.retention_days
}

resource "aws_cloudwatch_event_rule" "node_creation" {
  name = "EC2InstanceLaunchRule"
  description = "Log the records at the time of Cassandra node creation"
  event_pattern = jsonencode({
    "source": ["aws.autoscaling"],
    "detail-type": ["EC2 Instance Launch Successful"],
    "detail": {
      "AutoScalingGroupName": ["${var.aws_autoscaling_group}"]
    }
  })
}

provider "aws" {
  region = "us-west-2" # Specify your AWS region
}

# Step 1: Create a CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ec2_creation_log_group" {
  name              = "/aws/events/ec2-creation-log-group"
  retention_in_days = 7 # Adjust retention as needed
}

# Step 2: Create an IAM Role for EventBridge to publish to CloudWatch Logs
resource "aws_iam_role" "eventbridge_logging_role" {
  name = "EventBridgeLoggingRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_logging_policy" {
  name = "EventBridgeLoggingPolicy"
  role = aws_iam_role.eventbridge_logging_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = aws_cloudwatch_log_group.log_roup.arn
      }
    ]
  })
}

resource "aws_cloudwatch_event_target" "log_target" {
  rule = aws_cloudwatch_event_rule.node_creation.name
  arn  = aws_cloudwatch_log_group.log_roup.arn
  role_arn  = aws_iam_role.eventbridge_logging_role.arn
}