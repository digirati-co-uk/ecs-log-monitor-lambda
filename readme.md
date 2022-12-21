# ECS Log Monitor

Basic AWS lambda function used by CloudWatch log subscription and Terraform to setup. 

This lambda is intended to monitor ECS logs for a known message and restart ECS service if instance of message found. Therefor message should be as tightly filtered as possible to avoid excessive restarting of service.

## Lambda

When a message is received by lambda it parses the log_stream name (from `<ecs-service>/<container>/<service-id>` format) to find relevant ECS service name and restart service.

ECS service will only be restarted if there is _not_ an outstanding deployment. This is to avoid a flood of restarts due to a number of repeated instances of the same message.

`package.sh` is a simple bash script to build zip file for lambda.

Expects `ECS_CLUSTER_NAME` environment variable.

## Terraform

Terraform creates an AWS lambda function and CloudWatch log subscription.

Variables:
* `prefix` - used to uniquely name resources
* `s3_bucket` - bucket containing Lambda
* `s3_key` - key containing Lambda
* `ecs_cluster_name` - name of ECS cluster, used to set `ECS_CLUSTER_NAME` lambda env var
* `region` - AWS region
* `log_group` - Cloudwatch log group to create subscription for
* `log_filter_pattern` - [Filter pattern](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html) for subscription filter
* `subscription_filter_name` - Optional name for subscription filter, defaults to `"${var.prefix}-ecs-log-monitor"`

## Verify Setup

Once the TF is applied you can verify setup by manually triggering a log-event containing the relevant `log_filter_pattern`:

```bash
aws logs put-log-events --log-group-name <log-group> --log-stream-name <stream> --log-events "[{\"timestamp\":<CURRENT-TIMESTAMP>, \"message\": \"<LOG_FILTER_PATTERN>\"}]"
```