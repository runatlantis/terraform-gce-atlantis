# These are the resources needed specifically in order to get IAP to
# function. Note that some are used as inputs to the atlantis module in
# main.tf.

# Note that you can only have a single IAP brand per project; if you are
# already using IAP in this project you will not need this resource.
resource "google_iap_brand" "example" {
  support_email     = "you@example.com"
  application_title = "Atlantis"
  project           = local.project_id
}

resource "google_iap_client" "atlantis" {
  display_name = "Atlantis"
  brand        = google_iap_brand.example.name
  project      = local.project_id
}

# The below resource will allow this person to access the UI via IAP.
# Each person or entity you want to add to the allow list will need a
# separate resource. If you would like to have a single place to define
# your allow list, look into using the google_iap_web_backend_service_iam_binding
# resource.
resource "google_iap_web_backend_service_iam_member" "jane_atlantis" {
  web_backend_service = module.atlantis.iap_backend_service_name
  role                = "roles/iap.httpsResourceAccessor"
  member              = "user:jane@example.com"
  project             = local.project_id
}
