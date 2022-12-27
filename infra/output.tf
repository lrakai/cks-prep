output "control_plane_ip" {
  value = "${google_compute_instance.control-plane.network_interface.0.access_config.0.nat_ip}"
}

output "control_plane_ssh_command" {
  value = "gcloud compute ssh --project=${var.project_id} --zone=${var.zone} control-plane"
}