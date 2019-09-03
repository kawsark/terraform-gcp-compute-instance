data "google_compute_default_service_account" "default" {}
# Use existing keyring
data "google_kms_key_ring" "key_ring" {
  project  = "${var.gcp_project}"
  name     = "${var.key_ring}"
  location = "${var.gcp_region}"
}

# Use existing key
data "google_kms_crypto_key" "crypto_key" {
  name     = "${var.crypto_key}"
  key_ring = "${data.google_kms_key_ring.key_ring.self_link}"
}

# Create a KMS key ring
#resource "google_kms_key_ring" "key_ring" {
#  project  = "${var.gcp_project}"
#  name     = "${var.key_ring}"
#  location = "${var.gcp_region}"
#}

# Create a crypto key for the key ring
#resource "google_kms_crypto_key" "crypto_key" {
#  name            = "${var.crypto_key}"
#  key_ring        = "${google_kms_key_ring.key_ring.self_link}"
#  rotation_period = "100000s"
#}

# Add the service account to the Keyring
resource "google_kms_key_ring_iam_binding" "vault_iam_kms_binding" {
  key_ring_id = "${data.google_kms_key_ring.key_ring.id}"
  role        = "roles/owner"

  members = [
    "serviceAccount:${data.google_compute_default_service_account.default.email}",
  ]
}