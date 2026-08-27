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

variable "argocd_namespace" {
  description = "Namespace to deploy Argo CD into"
  type        = string
  default     = "infra-tools"
}

variable "argocd_chart_version" {
  description = "Version of the argo/argo-cd Helm chart"
  type        = string
  default     = "7.7.11"
}
