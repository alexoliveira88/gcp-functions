output "eventy_type" {
  value = google_cloudfunctions_function.function.event_trigger
  }

output "https_trigger_url" {
  value = google_cloudfunctions_function.function.https_trigger_url
  }

