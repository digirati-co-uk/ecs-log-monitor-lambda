variable "prefix" {
  description = "Prefix to customise names of elements in AWS"
}

variable "s3_bucket" {
  description = "S3 bucket where ecs-log-monitor lambda source is found"
}

variable "s3_key" {
  description = "S3 key where ecs-log-monitor lambda source is found"
}

variable "ecs_cluster_name" {
  description = "ECS cluster where services are located"
}

variable "region" {
  description = "Current aws region"
  default     = "eu-west-1"
}

variable "log_group" {
  description = "Name of Cloudwatch log group to create subscription on"
}

variable "log_filter_pattern" {
  description = "Pattern used to filter Cloudwatch logs"
}

variable "subscription_filter_name" {
  description = "Optional subscription filter name"
  default     = ""
}