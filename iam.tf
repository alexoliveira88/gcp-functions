variable "iam_member" {
   type = map(object({
      role   = string
      member = string
    }))
 }
 
resource "google_cloudfunctions_function_iam_member" "member" {
  for_each          = var.iam_member
  project           = lookup(module.metadata.projects_metadata, "project_id")
  cloud_function    = google_cloudfunctions_function.function.name
  region            = var.region 
  role              = each.value.role
  member            = each.value.member

  lifecycle {
    ignore_changes = [
      etag,
    ]
  }
}