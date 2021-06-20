# 
# Create IAM resources
#

resource "aws_iam_role" "lambda_startstop_role" {
  name = "lambda_startstop_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_startstop_policy" {
  name = "lambda_startstop_policy"
  role = aws_iam_role.lambda_startstop_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Stop*",
		    "ec2:DescribeInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# 
# Zip needed Lambda functions
#

data "archive_file" "lambda_start" {
  type = "zip"
  output_path = "${path.module}/lambda_start.zip"
  source_dir = "${path.module}/start/"
}

data "archive_file" "lambda_stop" {
  type = "zip"
  output_path = "${path.module}/lambda_stop.zip"
  source_dir = "${path.module}/stop/"
}

#
# Create Lambda functions
# 

resource "aws_lambda_function" "lambda_start" {
  filename        = "lambda_start.zip"
  function_name   = "lambda_start"
  timeout		      = 10  
  role            = aws_iam_role.lambda_startstop_role.arn
  handler         = "lambda_handler"
  runtime         = "python3.8"
}

resource "aws_lambda_function" "lambda_stop" {
  filename        = "lambda_stop.zip"
  function_name   = "lambda_stop"
  timeout		      = 10  
  role            = aws_iam_role.lambda_startstop_role.arn
  handler         = "lambda_handler"
  runtime         = "python3.8"
}

# 
# Create CloudWatch Event Rules
#

resource "aws_cloudwatch_event_rule" "lambda_start_event_rule" {
  name        = "lambda-start-event-rule"
  description = "Start running EC2 instance at a specified time each day"
  schedule_expression = "cron(0 7 * * ? *)" # Every day at 7 AM
}

resource "aws_cloudwatch_event_rule" "lambda_stop_event_rule" {
  name        = "lambda-stop-event-rule"
  description = "Stop running EC2 instance at a specified time each day"
  schedule_expression = "cron(0 19 * * ? *)" # Every day at 7 PM
}

#
# Create Event Rule Targets
#

resource "aws_cloudwatch_event_target" "lambda_start_event_rule_target" {
  rule      = aws_cloudwatch_event_rule.lambda_start_event_rule.name
  target_id = "TriggerLambdaFunction"
  arn       = aws_lambda_function.lambda_start.arn
}

resource "aws_cloudwatch_event_target" "lambda_stop_event_rule_target" {
  rule      = aws_cloudwatch_event_rule.lambda_stop_event_rule.name
  target_id = "TriggerLambdaFunction"
  arn       = aws_lambda_function.lambda_stop.arn
}

#
# Add Lambda permissions
#

resource "aws_lambda_permission" "allow_cloudwatch_start" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_start.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_start_event_rule.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_stop" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_stop.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_stop_event_rule.arn
}