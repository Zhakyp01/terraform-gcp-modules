variable "project_id" {
  type        = string
  description = "Project ID of the GCP project"
  default     = "propane-dogfish-395916"
}

variable "proxy_gce" {
  type = string
}
variable "sql_instance_name" {
  type = string
}

variable "instance_name" {
  description = "Name of the instance, Overrides the standard name that is generated based on region, environment, TLA, and identifier"
  type        = string
  default     = null
}

variable "connection_name" {
  type    = string
  default = null
}

variable "machine_type" {
  type    = string
  default = "e2-micro"
}


variable "region" {
  type        = string
  description = "Region of the GCP project"
}

variable "zone" {
  type        = string
  description = "The zone for the master instance, it should be something like: \"us-central-a\", \"us-east-c\"."
}

variable "user_labels" {
  description = "The key/value labels for the master instances."
  type = object({
    tla                       = string
    ci                        = string
    environment               = string
    portfolio_manager         = string
    new_cost_center           = string
    pending_deletion          = string
    resource_last_update_date = string
    opt_in_handler            = string
    opt_out_handler           = string
    resource_location         = string
    workload_type             = string
  })
  validation {
    condition     = length(var.user_labels) != 0
    error_message = "Must specify label values"
  }
  default = {
    tla                       = "sample_tla"
    ci                        = "sample_ci"
    environment               = "sample_environment"
    portfolio_manager         = "sample_manager"
    new_cost_center           = "sample_cost_center"
    pending_deletion          = "sample_pending"
    resource_last_update_date = "sample_update_date"
    opt_in_handler            = "sample_opt_in"
    opt_out_handler           = "sample_opt_out"
    resource_location         = "sample_location"
    workload_type             = "sample_workload"
  }
}
variable "proxy_port" {
  type    = number
  default = 5444
}

# variable "proxy_subnet" {
#   type    = string
#   default = null
# }


