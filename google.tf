# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

provider "google" {}

resource "google_project_service" "svc" {
  project = var.google_project_id
  service = "${each.value}.googleapis.com"

  for_each = toset([
    "run",
  ])
}

resource "google_cloud_run_service" "app" {
  project = var.google_project_id

  name     = "nightscout"
  location = var.google_cloud_region

  template {
    spec {
      containers {
        image = var.app_image

        env {
          name  = "MONGODB_URI"
          value = local.atlas_uri
        }
      }
    }
  }

  lifecycle {
    # this stops terraform from trying to revert to the sample app after you've
    # pushed new changes through CI
    ignore_changes = [template[0].spec[0].containers[0].image]
  }

  depends_on = [google_project_service.svc["run"]]
}

resource "google_cloud_run_service_iam_binding" "app" {
  location = google_cloud_run_service.app.location
  project  = google_cloud_run_service.app.project
  service  = google_cloud_run_service.app.name

  role    = "roles/run.invoker"
  members = ["allUsers"]
}
