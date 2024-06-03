variable "environment" {
  type = string
  description = "The name of the environment. Example: westa"
}

# variable "alb_zone_id" {
#   default = "Z33AYJ8TM3BH4J" # this is for us-gov-west-1. See others here: https://docs.aws.amazon.com/general/latest/gr/elb.html
# }

# variable "nlb_zone_id" {
#   default = "ZMG1MZ2THAWF1" # this is for us-gov-west-1. See others here: https://docs.aws.amazon.com/general/latest/gr/elb.html
# }

# variable domain {
#   type = string
#   description = "The root domain of the Cloud Foundry installation. The api and apps subdomains will be created using this domain. Example: westa.cloud.gov"
# }

# variable remote_state_bucket {
#   type = string 
# }

# variable remote_state_region {
#   type = string
# }

# variable remote_stack_name {
#   type = string
# }