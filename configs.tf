module "metadata" {
  source = "gcs::https://www.googleapis.com/storage/v1/bvs-terraform-modules/bvs-global-config-v1.0.11.zip" 
  tribo  = lower(lookup(var.labels, "value-stream", ))
}
