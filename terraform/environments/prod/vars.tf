variable "ktcloud_api_url" {
  description = "kt cloud API URL"
  type        = string
}

variable "ktcloud_api_key" {
  description = "kt cloud API Key"
  type        = string
  sensitive   = true
}

variable "ktcloud_secret_key" {
  description = "kt cloud Secret Key"
  type        = string
  sensitive   = true
}