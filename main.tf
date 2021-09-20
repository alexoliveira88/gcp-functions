terraform {
  required_version = ">= 0.14.0"
  required_providers {
    google = ">= 3.50.0"
    random = ">= 2.2"
  }
}

locals {
  vpc_connector_enable = var.vpc_connector_enable ? { for connector in var.vpc_connector : var.function_name => connector } : {}
}

data "google_storage_bucket_object" "archive" {
name          = var.archive_name
bucket        = var.bucket_name
}

resource "google_cloudfunctions_function" "function" {
  project                       = lookup(module.metadata.projects_metadata, "project_id")
  region                        = var.region
  name                          = var.function_name
  labels                        = merge(module.bvs-labels.common_labels, var.extra_labels, { resource = "google_cloudfunctions_function", billing_id = var.function_name, environment = module.metadata.envAlias, type = "serverless" })
  runtime                       = var.runtime
  available_memory_mb           = var.available_memory_mb
  source_archive_bucket         = var.bucket_name
  source_archive_object         = var.archive_name
  entry_point                   = var.entry_point
  ingress_settings              = var.ingress_settings
  timeout                       = var.function_timeout
  trigger_http                  = var.trigger_http
  service_account_email         = var.service_account_email


dynamic "event_trigger" {
    for_each = var.trigger_http == null ? [1] : [] 

    content {
      event_type = var.event_trigger["event_type"]
      resource   = var.event_trigger["resource"]

      failure_policy {
        retry = var.event_trigger_failure_policy_retry
      }
    }
 }

vpc_connector                 = var.vpc_connector_enable  ? google_vpc_access_connector.connector[var.function_name].id : null 
vpc_connector_egress_settings = var.vpc_connector_egress_settings

depends_on = [
    google_vpc_access_connector.connector,
    google_project_iam_member.google_sa_vpcaccess,
    google_project_iam_member.google_sa_cloudservices,
    google_project_iam_member.google_sa_gcf_admin_robot,
]

}

#################VPC CONNECTOR################
resource "google_vpc_access_connector" "connector" {
  for_each = local.vpc_connector_enable
  #for_each = var.vpc_connector_enable ? { for connector in var.vpc_connector : var.function_name => connector } : {}
  provider      = google-beta
  name          = lookup(each.value, "name", var.function_name)            
  machine_type  = lookup(each.value, "machine_type", "e2-micro")
  min_throughput = lookup(each.value, "min_throughput", "200")
  max_throughput = lookup(each.value, "max_throughput", "300")
  min_instances = lookup(each.value, "min_instances", "2")
  max_instances = lookup(each.value, "max_instances", "3")
  region = var.region 
  project =  lookup(each.value, "host_project_id", "${module.metadata.projects_metadata.host_project_id}") 
  subnet {
    name = each.value.subnet_name 
  }
}

resource "google_compute_firewall" "serverless_to_vpc_connector" {
  for_each = local.vpc_connector_enable
  project     = module.metadata.projects_metadata.host_project_id 
  name        = "serverless-to-connector-${var.function_name}" 
  network     = lookup(module.metadata.projects_metadata, "vpc_network")
  direction   = "INGRESS"
  description = "Creates firewall rule targeting tagged instances"
  source_ranges = ["107.178.230.64/26", "35.199.224.0/19"]
  allow {
    protocol = "icmp"
  }
  allow {
    protocol  = "tcp"
    ports     = ["667"]
  }
  allow {
    protocol  = "udp"
    ports     = ["665", "666"]
  }
  target_tags = ["vpc-connector-${var.region}-${lookup(each.value, "name", var.function_name)}"]

  lifecycle {
    ignore_changes = [
      source_service_accounts, 
      source_tags, 
      target_service_accounts
    ]
  }
}

resource "google_compute_firewall" "vpc_connector_health_checks" {
  for_each = local.vpc_connector_enable
  project     = module.metadata.projects_metadata.host_project_id 
  name        = "connector-health-checks-${var.function_name}"
  network     = lookup(module.metadata.projects_metadata, "vpc_network")
  direction   = "INGRESS"
  description = "Creates firewall rule targeting tagged instances"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "108.170.220.0/23"]
  allow {
    protocol  = "tcp"
    ports     = ["667"]
  }
  target_tags = ["vpc-connector-${var.region}-${lookup(each.value, "name", var.function_name)}"]

  lifecycle {
    ignore_changes = [
      source_service_accounts, 
      source_tags, 
      target_service_accounts
    ]
  }
}

data "google_project" "project" {
    for_each = local.vpc_connector_enable
    #for_each = var.vpc_connector_enable ? { for connector in var.vpc_connector : var.function_name => connector } : {}
    project_id = lookup(module.metadata.projects_metadata, "project_id")
}

resource "google_project_iam_member" "google_sa_vpcaccess" {
  for_each = local.vpc_connector_enable
  project  = lookup(each.value, "host_project_id", "${module.metadata.projects_metadata.host_project_id}") 
  role     = "roles/compute.networkUser"
  member   = "serviceAccount:service-${data.google_project.project[each.key].number}@gcp-sa-vpcaccess.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "google_sa_cloudservices" {
  for_each = local.vpc_connector_enable
  project  = lookup(each.value, "host_project_id", "${module.metadata.projects_metadata.host_project_id}") 
  role     = "roles/compute.networkUser"
  member   = "serviceAccount:${data.google_project.project[each.key].number}@cloudservices.gserviceaccount.com"
} 

resource "google_project_iam_member" "google_sa_gcf_admin_robot" {
  for_each = local.vpc_connector_enable
  project  = lookup(each.value, "project_id", "${module.metadata.projects_metadata.project_id}") 
  role     = "roles/vpcaccess.user"
  member   = "serviceAccount:service-${data.google_project.project[each.key].number}@gcf-admin-robot.iam.gserviceaccount.com"
} 

resource "google_project_iam_member" "google_sa_gcf_admin_robot_host_project" {
  for_each = local.vpc_connector_enable
  project  = lookup(each.value, "project_id", "${module.metadata.projects_metadata.host_project_id}") 
  role     = "roles/vpcaccess.user"
  member   = "serviceAccount:service-${data.google_project.project[each.key].number}@gcf-admin-robot.iam.gserviceaccount.com"
} 


