terraform {
  required_providers {
    vagrant = {
      source  = "bmatcuk/vagrant"
      version = "~> 4.0.0"
    }
  }
}

resource "vagrant_vm" "case-study" {
  vagrantfile_dir = "../kubernetes-vagrant"
  get_ports = true
}
