variable "env" { type = string }
variable "db_name" { type = string }
variable "db_user" { type = string }
variable "db_pass" {
  type      = string
  sensitive = true
}
variable "sng_id" { type = string }
variable "sg_id" { type = string }
