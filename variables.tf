variable "function_name" {
  description = "Nome da função"
}

variable "runtime" {
  description =  "Opcoes nodejs14, nodejs10, nodejs12, nodejs14, python37, python38, python39, dotnet3, go113, java11, ruby27"
}

variable "available_memory_mb" {
  default = 256
}

variable "bucket_name" {
  description = "Nome do bucket que sera criado"
  default = ""
}

variable "archive_name" {
  description = "Nome do archive que sera criado"
}

variable "event_trigger" {
  type        = map(string)
  default     = {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = "google_pubsub_topic.pubsub.id"
  }  
  description = "A source that fires events in response to a condition in another service."
}

variable "trigger_http" {
  type        = bool
  default     = null
  description = "Wheter to use HTTP trigger instead of the event trigger."
}

variable "event_trigger_failure_policy_retry" {
  type        = bool
  default     = false
  description = "A toggle to determine if the function should be retried on failure."
}

variable "function_timeout" {
  description = "Timeout (in seconds)"
  default     = "90"
}

variable "vpc_connector_egress_settings" {
  description = "VPC Connector Egress Settings. Allowed values are ALL_TRAFFIC and PRIVATE_RANGES_ONLY."
  default     = null
}

variable "function_source_directory" {
  type        = string
  description = "The contents of this directory will be archived and used as the function source. (defaults to standard SLO generator code)"
  default     = ""
}

variable "entry_point" {
  type        = string
  description = "The name of a method in the function source which will be invoked when the function is executed."
}

variable "ingress_settings" {
  type        = string
  default     = "ALLOW_ALL"
  description = "The ingress settings for the function. Allowed values are ALLOW_ALL, ALLOW_INTERNAL_AND_GCLB and ALLOW_INTERNAL_ONLY. Changes to this field will recreate the cloud function."
}

variable "region" {}

variable "service_account_email" {
 default = null
 }

variable "vpc_connector" {
  type        = list(map(string))
  default     = []
  description = "List of VPC serverless connectors."
}

variable "vpc_connector_enable" {
  type = bool
  description = "(optional) Habilita VPC Connector"
}