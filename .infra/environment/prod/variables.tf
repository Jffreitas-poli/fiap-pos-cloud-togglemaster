variable "env" {
  type = string
}

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}
variable "public_subnets" {
  type = map(object({
    az   = string
    cidr = string
  }))
  default = {
    public_1 = {
      az   = "us-east-1a"
      cidr = "10.0.0.0/20"
    },
    public_2 = {
      az   = "us-east-1b"
      cidr = "10.0.16.0/20"
    },
    public_3 = {
      az   = "us-east-1c"
      cidr = "10.0.32.0/20"
    }
  }
}
variable "private_subnets" {
  type = map(object({
    az   = string
    cidr = string
  })) 
  default = {
    private_1 = {
      az   = "us-east-1a"
      cidr = "10.0.128.0/20"
    },
    private_2 = {
      az   = "us-east-1b"
      cidr = "10.0.144.0/20"
    },
    private_3 = {
      az   = "us-east-1c"
      cidr = "10.0.160.0/20"
    }
  }
}

variable "rds_names" {
  type = list(string)
  default = ["auth", "flags", "targeting"]
}
variable "rds_passs" {
  type      = list(string)
  sensitive = true
}

variable "cluster_version" {
  type    = string
  default = "1.36"
}
variable "eks_developer_arns" {
  type = list(string)
}

variable "git_repo_claim_prefix" {
  type = string
}

variable "ecr_names" {
  type = list(string)
  default = ["auth", "flag", "targeting", "evaluation", "analytics"]
}
