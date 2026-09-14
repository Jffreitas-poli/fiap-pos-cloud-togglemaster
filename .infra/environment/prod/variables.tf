variable "env" {
  type = string
}

variable "vpc_cidr" {
  type = string
}
variable "public_subnets" { type = map(object({
  az   = string
  cidr = string
})) }
variable "private_subnets" { type = map(object({
  az   = string
  cidr = string
})) }

variable "rds_names" {
  type = list(string)
}
variable "rds_passs" {
  type      = list(string)
  sensitive = true
}

variable "cluster_version" {
  type    = string
  default = "1.30"
}
variable "eks_developer_arns" {
  type = list(string)
}

variable "git_repo_claim_prefix" {
  type = string
}

variable "ecr_names" {
  type = list(string)
}
