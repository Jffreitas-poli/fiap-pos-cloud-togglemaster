variable "env" {
  type = string
}
variable "cluster_endpoint" {
  type = string
}
variable "cluster_ca_certificate" {
  type = string
}
variable "cluster_token" {
  type = string
}
variable "oidc_provider" {
  type = string
}
variable "oidc_provider_arn" {
  type = string
}
variable "service_namespace" {
  type = string
}
variable "service_account" {
  type = string
}
variable "policy_json" {
  type = list(string)
}
variable "policy_arn" {
  type = list(string)
}
variable "have_annotations" {
  type = list(string)
}
