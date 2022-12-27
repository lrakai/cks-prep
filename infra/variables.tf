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
