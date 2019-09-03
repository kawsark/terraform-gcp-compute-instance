# Render userdata
data "template_file" "consul_userdata" {
  template = "${file("${path.module}/scripts/consul-server.tpl")}"
  vars {
    consul_url          = "${var.consul_url}"
    dc                  = "${var.consul_dc}"
    retry_join          = "[\"provider=gce zone_pattern=${var.gcp_region}-. tag_value=consul-${var.gcp_project}-${var.consul_dc}\"]"
    consul_server_count = "${var.consul_server_count}"
    consul_license      = "${var.consul_license}"
    ca_crt              = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt            = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key            = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_encrypt      = "${random_id.consul_encrypt.b64_std}"
  }
}

data "template_file" "vault_userdata" {
  template = "${file("${path.module}/scripts/vault-server.tpl")}"
  vars {
    consul_url     = "${var.consul_url}"
    vault_url      = "${var.vault_url}"
    gcp_project    = "${var.gcp_project}"
    gcp_region     = "${var.gcp_region}"
    key_ring       = "${var.key_ring}"
    crypto_key     = "${var.crypto_key}"
    dc             = "${var.consul_dc}"
    retry_join     = "[\"provider=gce zone_pattern=${var.gcp_region}-. tag_value=consul-${var.gcp_project}-${var.consul_dc}\"]"
    vault_license  = "${var.vault_license}"
    consul_license = "${var.consul_license}"
    ca_crt         = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt       = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key       = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_encrypt = "${random_id.consul_encrypt.b64_std}"
  }
}
