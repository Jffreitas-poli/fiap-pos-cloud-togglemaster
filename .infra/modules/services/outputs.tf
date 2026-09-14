output "keda_service_arn" {
  value = module.keda_identity.service_arn
}
output "cluster_secret_store_service_arn" {
  value = module.cluster_secret_store_identity.service_arn
}
output "evaluation_service_arn" {
  value = module.evaluation_identity.service_arn
}
output "analytics_service_arn" {
  value = module.analytics_identity.service_arn
}