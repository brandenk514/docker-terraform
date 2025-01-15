variable "docker_host" {
  description = "The URL of the remote Docker host"
  type        = string
}

variable "ssh_key_path" {
  description = "The URL of the remote Docker host"
  type        = string
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
  description = "The URL of the remote Docker host"
  type        = string
}