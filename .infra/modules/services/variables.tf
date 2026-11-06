variable "env" {
  type = string
}
variable "cluster_name" {
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
variable "loki_chunk_bucket_name" {
  type = string
}
variable "loki_ruler_bucket_name" {
  type = string
}