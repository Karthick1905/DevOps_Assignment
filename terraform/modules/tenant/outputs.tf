output "database_name" {
  value = google_sql_database.tenant_db.name
}

output "secret_id" {
  value = google_secret_manager_secret.tenant_db_credentials.secret_id
}

output "gcp_service_account_email" {
  value = google_service_account.tenant_workload_identity.email
}
