variable "region" {
  default = "europe-west1-d" 
}

variable "gce_ssh_user" {
default = "ansible"
}


variable "gce_ssh_pub_key_file" {
default = "./id_rsa.pub"
}

provider "google" {
  credentials = "${file("ansible.json")}"
  project     = "mohamed-194111"
  region      = "${var.region}"
}

resource "google_compute_instance" "master1" {
  count        = 1
  name         = "master1" 
  machine_type = "n1-standard-1" 
  zone         = "${var.region}" 
  tags = ["nw-tag","master-k8s"]

boot_disk {
   initialize_params {
     image = "ubuntu-1604-xenial-v20170328"
   }
 }

metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }
}

resource "google_compute_instance" "node" {
  count        = 2
  name         = "node${count.index + 1}"
  machine_type = "f1-micro"
  zone         = "${var.region}"
  tags = ["nw-tag","node-k8s"]

boot_disk {
   initialize_params {
     image = "ubuntu-1604-xenial-v20170328"
   }
 }
metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }
  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }
}
resource "google_compute_firewall" "allow_k8s_master" {
  name    = "allow-k8s-master"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_tags = ["node-k8s"]
  target_tags = ["master-k8s"]
}
