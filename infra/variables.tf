variable "your_ip" {
    type = string
    description = "Your public IP address to allow ssh connections to the cluster"
}

variable "user" {
    type = string
    description = "Linux system user name"
}

variable "project_id" {
    type = string
}

variable "region" {
    type = string
    default = "us-central1"
}

variable "zone" {
    type = string
    default = "us-central1-a"
}

variable "kubernetes_minor_version" {
    type = string
    default = "1.24"
}

variable "kubernetes_community_ami_version" {
    type = string
    default = "1.24.3"
}

variable machine_type {
    type = string
    default = "e2-medium"
}

variable "workers" {
    description = "Worker names"
    type = map
    default = {
        worker1 = {
            name = "worker1"
            ip = "10.0.0.10"
        }
        worker2 = {
            name = "worker2"
            ip = "10.0.0.11"
        }
    }
}