output "tenant_database" {
  value = module.tenant_acme_corp.database_name
}

output "tenant_secret_id" {
  value = module.tenant_acme_corp.secret_id
}

output "tenant_gcp_service_account" {
  value = module.tenant_acme_corp.gcp_service_account_email
}
