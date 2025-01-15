variable "docker_host" {
  description = "The URL of the remote Docker host"
  type        = string
}

variable "ssh_key_path" {
  description = "The URL of the remote Docker host"
  type        = string
}

variable "ca_cert_path" {
  description = "Path to the CA certificate"
  type        = string
  default     = ""
}

variable "client_cert_path" {
  description = "Path to the client certificate"
  type        = string
  default     = ""
}

variable "client_key_path" {
  description = "Path to the client key"
  type        = string
  default     = ""
}
