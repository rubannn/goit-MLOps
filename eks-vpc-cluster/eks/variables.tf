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

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "goit-mlops"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "cpu_instance_types" {
  description = "Instance types for the CPU node group. t3.micro used because the AWS Free plan only allows Free Tier-eligible on-demand instance types."
  type        = list(string)
  default     = ["t3.micro"]
}

variable "gpu_instance_types" {
  description = "Instance types for the GPU/workload node group. Small instance used to demonstrate workload isolation without incurring GPU costs (also Free Tier-eligible)."
  type        = list(string)
  default     = ["t3.micro"]
}

variable "cpu_desired_size" {
  description = "Desired number of nodes in the cpu-nodes group"
  type        = number
  default     = 1
}

variable "gpu_desired_size" {
  description = "Desired number of nodes in the gpu-nodes group"
  type        = number
  default     = 1
}
