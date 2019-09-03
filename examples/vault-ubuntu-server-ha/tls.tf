resource "random_id" "consul_encrypt" {
  byte_length = 16
}

module "root_tls_self_signed_ca" {
  source = "github.com/hashicorp-modules/tls-self-signed-cert"

  name              = "${var.consul_dc}-root"
  ca_common_name    = "${var.common_name}"
  organization_name = "${var.organization_name}"
  common_name       = "${var.common_name}"
  download_certs    = "true"

  validity_period_hours = "8760"

  ca_allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

module "leaf_tls_self_signed_cert" {
  source = "github.com/hashicorp-modules/tls-self-signed-cert"

  name              = "${var.consul_dc}-leaf"
  organization_name = "${var.organization_name}"
  common_name       = "${var.common_name}"
  ca_override       = true
  ca_key_override   = "${module.root_tls_self_signed_ca.ca_private_key_pem}"
  ca_cert_override  = "${module.root_tls_self_signed_ca.ca_cert_pem}"
  download_certs    = "true"

  validity_period_hours = "8760"

  dns_names = [
    "localhost",
    "*.node.consul",
    "*.service.consul",
    "server.${var.consul_dc}.consul",
    "*.${var.consul_dc}.consul",
    "server.${var.consul_dc}.consul",
    "*.${var.consul_dc}.consul",
  ]

  ip_addresses = [
    "0.0.0.0",
    "127.0.0.1",
  ]

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}