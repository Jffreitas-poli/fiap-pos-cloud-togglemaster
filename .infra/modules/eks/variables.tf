variable "env" {
  type = string
}
variable "cluster_version" {
  type    = string
  default = "1.30"
}
variable "subnet_ids" {
  type = list(string)
}
variable "vpc_id" {
  type = string
}
variable "eks_developer_arns" {
  type = list(string)
}
variable "sg_redis" {
  type = string
}
variable "sg_rds" {
  type = string
}