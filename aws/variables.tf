variable "AWS_ACCESS_KEY_ID" {
  type    = string
  default = "AWS_ACCESS_KEY_ID"
}

variable "AWS_SECRET_ACCESS_KEY" {
  type    = string
  default = "AWS_SECRET_ACCESS_KEY"
}

variable "DATABASE_CONNECTION_URL" {
  type    = string
  default = ""
}

variable "app_count" {
  type    = number
  default = 1
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "us-west-2"
}

variable "aws_cloudwatch_retention_in_days" {
  type        = number
  description = "AWS CloudWatch Logs Retention in Days"
  default     = 30
}

variable "app_name" {
  type        = string
  description = "Application Name"
  default     = "mage-data-prep"
}

variable "app_environment" {
  type        = string
  description = "Application Environment"
  default     = "production"
}

variable "ecs_task_cpu" {
  description = "ECS task cpu"
  default     = 8192
}

variable "ecs_task_memory" {
  description = "ECS task memory"
  default     = 16384
}

variable "public_subnets" {
  description = "List of public subnets"
  default     = ["172.31.202.0/24", "172.31.203.0/24"]
}

variable "private_subnets" {
  description = "List of private subnets"
  default     = ["172.31.200.0/24", "172.31.201.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  default     = ["us-west-2a", "us-west-2b"]
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "prod"
    ManagedBy   = "Terraform"
    Owner       = "data-engineering"
  }
}

variable "redshift_host" {
  description = "Redshift host"
  default     = "redshift-cluster-1.cjxjxjxjxjxj.us-west-2.redshift.amazonaws.com"
}

variable "redshift_dbname" {
  description = "Redshift database name"
  default     = "redshift"
}

variable "redshift_user" {
  description = "Redshift user"
  default     = "redshift"
}

variable "redshift_cluster_id" {
  description = "Redshift cluster identifier"
  default     = "redshift-cluster-1"
}

