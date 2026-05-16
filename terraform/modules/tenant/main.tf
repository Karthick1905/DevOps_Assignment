resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_sql_database" "tenant_db" {
  name     = var.db_name
  instance = var.sql_instance_name
}

resource "google_sql_user" "tenant_user" {
  name     = var.db_user
  instance = var.sql_instance_name
  password = random_password.db_password.result
}

resource "google_secret_manager_secret" "tenant_db_credentials" {
  secret_id = "tenant-${var.tenant_name}-credentials"

  replication {
    auto {}
  }

  labels = {
    tenant = var.tenant_name
  }
}

resource "google_secret_manager_secret_version" "tenant_db_credentials_version" {
  secret = google_secret_manager_secret.tenant_db_credentials.id

  secret_data = jsonencode({
    database = google_sql_database.tenant_db.name
    username = google_sql_user.tenant_user.name
    password = random_password.db_password.result
  })
}

resource "google_service_account" "tenant_workload_identity" {
  account_id   = "${replace(var.tenant_name, "-", "")}-wi"
  display_name = "Workload Identity for ${var.tenant_name}"
}

resource "google_secret_manager_secret_iam_member" "tenant_secret_reader" {
  secret_id = google_secret_manager_secret.tenant_db_credentials.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.tenant_workload_identity.email}"
}

resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.tenant_workload_identity.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_serviceaccount}]"
}
