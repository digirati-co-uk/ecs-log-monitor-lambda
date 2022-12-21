

locals {
  filter_name = var.subscription_filter_name != "" ? var.subscription_filter_name : "${var.prefix}-ecs-log-monitor"
}

data "aws_cloudwatch_log_group" "log_group" {
  name = var.log_group
}

resource "aws_cloudwatch_log_subscription_filter" "logging" {
  depends_on      = [aws_lambda_permission.ecs_log_monitor]
  destination_arn = aws_lambda_function.ecs_log_monitor.arn
  filter_pattern  = var.log_filter_pattern
  log_group_name  = data.aws_cloudwatch_log_group.log_group.name
  name            = local.filter_name
}

resource "aws_lambda_function" "ecs_log_monitor" {
  function_name = "${var.prefix}-ecs-log-monitor"
  handler       = "main.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.ecs_log_monitor_exec_role.arn
  s3_bucket     = var.s3_bucket
  s3_key        = var.s3_key

  environment {
    variables = {
      ECS_CLUSTER_NAME = var.ecs_cluster_name
    }
  }
}

resource "aws_lambda_permission" "ecs_log_monitor" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_log_monitor.function_name
  principal     = "logs.${var.region}.amazonaws.com"
  source_arn    = "${data.aws_cloudwatch_log_group.log_group.arn}:*"
}

data "aws_iam_policy_document" "ecs_log_monitor_exec_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_log_monitor_exec_role" {
  name               = "${var.prefix}-ecs-log-monitor-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_log_monitor_exec_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_log_monitor_logging" {
  role       = aws_iam_role.ecs_log_monitor_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "ecs_permissions" {
  statement {
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_permissions" {
  name   = "${var.prefix}LogMonitorRestartECS"
  policy = data.aws_iam_policy_document.ecs_permissions.json
}

resource "aws_iam_role_policy_attachment" "ecs_permissions" {
  role       = aws_iam_role.ecs_log_monitor_exec_role.name
  policy_arn = aws_iam_policy.ecs_permissions.arn
}
