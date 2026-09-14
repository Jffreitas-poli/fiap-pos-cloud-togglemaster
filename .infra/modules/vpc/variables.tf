variable "env" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnets" { type = map(object({
  az   = string
  cidr = string
})) }
variable "private_subnets" { type = map(object({
  az   = string
  cidr = string
})) }
