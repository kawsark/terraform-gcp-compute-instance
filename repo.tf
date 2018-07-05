variable "github_token" {}
variable "github_organization" {}
variable "repo" {}
variable "description" {}
variable "private" {}

provider "github" {
  token        = "${var.github_token}"
  organization = "${var.github_organization}"
}

module "repo" {
  source             = "git@github.com:HappyPathway/terraform-github-repository.git"
  version            = "1.0.0"
  description        = "${var.description}"
  name               = "${var.repo}"
  private            = "${var.private}"
  gitignore_template = "Terraform"
}

output "git_clone_url" {
  value = "${module.repo.git_clone_url}"
}
