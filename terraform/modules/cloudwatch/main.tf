resource "aws_cloudwatch_log_group" "log_roup" {
  name = var.log_roup_name
  retention_in_days = var.retention_days
}


# Step 1a: Create a Log Stream within the CloudWatch Log Group
resource "aws_cloudwatch_log_stream" "ec2_creation_log_stream" {
  name           = "ec2-creation-log-stream"
  log_group_name = aws_cloudwatch_log_group.log_roup.name
}

# Existing EventBridge Rule and Lambda Target
resource "aws_cloudwatch_event_rule" "instance_launch_rule" {
  name        = "EC2InstanceLaunchRule"
  description = "Triggers on EC2 instance launch"
  event_pattern = jsonencode({
    "source": ["aws.autoscaling"],
    "detail-type": ["EC2 Instance Launch Successful"],
    "detail": {
      "AutoScalingGroupName": ["${var.aws_autoscaling_group}"]
    }
  })
}

# Revmoing ec2 instance
resource "aws_cloudwatch_event_rule" "instance_terminate_rule" {
  name        = "EC2InstanceTerminateRule"
  description = "Triggers on EC2 instance termination"
  event_pattern = jsonencode({
    "source": ["aws.autoscaling"],
    "detail-type": ["EC2 Instance Terminate Successful"],
    "detail": {
      "AutoScalingGroupName": ["${var.aws_autoscaling_group}"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target_terminate" {
  rule      = aws_cloudwatch_event_rule.instance_terminate_rule.name
  arn       = aws_lambda_function.name_tagging_lambda.arn
}

resource "aws_cloudwatch_event_target" "lambda_target_launch" {
  rule      = aws_cloudwatch_event_rule.instance_launch_rule.name
  arn       = aws_lambda_function.name_tagging_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.name_tagging_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.instance_launch_rule.arn
}

# Assuming you have a Lambda execution role defined as `lambda_execution_role`
resource "aws_iam_role_policy_attachment" "lambda_logging_policy" {
  role       = aws_iam_role.lambda_role.name  # Replace with your Lambda role's name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role" "lambda_role" {
  name = "ec2_instance_naming_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_ec2_tagging_policy" {
  name        = "LambdaEC2TaggingPolicy"
  description = "Allows tagging EC2 instances"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateTags"
        ],
        Resource = "arn:aws:ec2:*:*:instance/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_ec2_tagging_policy.arn
}





data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_lambda_function" "name_tagging_lambda" {
  function_name = "EC2InstanceNameTaggingLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  # Inline Lambda code
  source_code_hash = filebase64sha256("${path.module}/lambda_function_payload.zip")

  filename         = "${path.module}/lambda_function_payload.zip"
  environment {
    variables = {
      INSTANCE_NAME_PREFIX = "cassandra-node"
    }
  }
}



output "event_rule_arn" {
  value = aws_cloudwatch_event_rule.instance_launch_rule.arn
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.log_roup.arn
}