variable "docker_host" {
  description = "The URL of the remote Docker host"
  type        = string
}

variable "ssh_key_path" {
  description = "File path to the SSH private key"
  type        = string
  sensitive   = true
}

variable "semaphore_admin" {
  description = "Semaphore admin username"
  type        = string
}

variable "semaphore_admin_password" {
  description = "Semaphore admin password"
  type        = string
  sensitive   = true
}

variable "semaphore_admin_name" {
  description = "Semaphore admin name"
  type        = string
}

variable "semaphore_admin_email" {
  description = "Semaphore admin email"
  type        = string
}

variable "media_server" {
  description = "DNS of the media server"
  type        = string
}

variable "transmission_mnt" {
  description = "Path to the Transmission download volume"
  type        = string
}

variable "media_library_mnt" {
  description = "Path to the media library volume"
  type        = string
}

variable "openvpn_username" {
  description = "OpenVPN username"
  type        = string
  sensitive   = true
}

variable "openvpn_password" {
  description = "OpenVPN password"
  type        = string
  sensitive   = true
}

variable "timezone" {
  description = "Region/City timezone"
  type        = string
}