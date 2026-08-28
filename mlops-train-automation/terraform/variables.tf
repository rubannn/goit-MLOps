variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "goit-terraform"
}

variable "project_name" {
  description = "Name prefix for Lambda functions, IAM roles, and the Step Function"
  type        = string
  default     = "mlops-train-automation"
}
