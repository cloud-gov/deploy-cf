variable "stack_name" {
  type        = string
  description = "Like development, staging, or production."
}

# Database credentials

variable "rds_host" {
  type        = string
  description = "Hostname of the RDS instance for the Cloud Service Broker."
}

variable "rds_port" {
  type        = string
  description = "Port of the RDS instance for the Cloud Service Broker."
}

variable "rds_name" {
  type        = string
  description = "Database name within the RDS instance for the Cloud Service Broker."
}

variable "rds_username" {
  type        = string
  description = "Database username of the RDS instance for the Cloud Service Broker."
}

variable "rds_password" {
  type        = string
  sensitive   = true
  description = "Database password of the RDS instance for the Cloud Service Broker."
}

# Application variables

variable "ecr_access_key_id" {
  description = "For pulling the CSB image from ECR."
  type        = string
}

variable "ecr_secret_access_key" {
  description = "For pulling the CSB image from ECR."
  sensitive   = true
  type        = string
}

variable "instances" {
  description = "Number of instances of the CSB app to run."
  type        = number
}

variable "cg_smtp_aws_ses_zone" {
  type        = string
  description = "When the user does not provide a domain, a subdomain will be created for them under this DNS zone."
}

// Broker credentials
variable "aws_access_key_id_govcloud" {
  type = string
}

variable "aws_secret_access_key_govcloud" {
  type      = string
  sensitive = true
}

variable "aws_region_govcloud" {
  type = string
}

variable "aws_access_key_id_commercial" {
  type = string
}

variable "aws_secret_access_key_commercial" {
  type      = string
  sensitive = true
}

variable "aws_region_commercial" {
  type = string
}

variable "org_name" {
  type        = string
  description = "The name of the Cloud Foundry organization in which the broker will be deployed."
}

variable "space_name" {
  type        = string
  description = "The name of the Cloud Foundry space in which the broker will be deployed."
}

variable "docker_image_name" {
  type        = string
  description = "Full name (but not tag or SHA) of the Docker image the broker will use."
}

variable "docker_image_version" {
  type        = string
  description = "Tag or SHA of the Docker image the broker will use. For example, ':latest' or '@sha256:abc123...'."
  default     = ":latest"
}

variable "broker_route_domain" {
  type        = string
  description = "The domain under which the broker's route will be created. For example, 'fr.cloud.gov'."
}
