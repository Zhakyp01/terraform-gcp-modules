# module "gce-advanced-container" {
#   source = "../proxyinstall"

#   container = {
#     # image = "busybox"
#     image = "gcr.io/cloudsql-docker/gce-proxy:latest"
#     command = [
#       "/cloud_sql_proxy"
#     ]
#     args = [
#       "-instances=keybank-deloitte:us-centra11:sql-proxy=tcp:O.O.O.O:5432"
#     ]
#     securityContext = {
#       privileged : true
#     }
#     tty : true
#     env = [
#       {
#         name  = "EXAMPLE"
#         value = "VAR"
#       }
#     ]
#   }
#   restart_policy = "OnFailure"
# }

# output "container" {
#   description = "The container metadata provided to the module"
#   value       = module.gce-advanced-container.container
# }


# resource "google_compute_router" "nat_router" {
#   name    = "nat-router"
#   project = local.project_id
#   region  = var.region
#   network = "projects/${local.project_id}/global/networks/default"
# }

# resource "google_compute_router_nat" "nat_config" {
#   name                   = "nat-config"
#   router                 = google_compute_router.nat_router.name
#   nat_ip_allocate_option = "MANUAL_ONLY"

#   # Specify the NAT IP addresses
#   # nat_ip {
#   #   source_ip_range = "35.222.144.58" # Replace with your desired IP address
#   #   name            = "nat-ip-1"
#   # }
#   # nat_ip {
#   #   source_ip_range = "192.168.1.11" # Replace with another desired IP address
#   #   name            = "nat-ip-2"
#   # }

#   source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS" # Adjust this as needed

#   min_ports_per_vm                 = 64
#   udp_idle_timeout_sec             = 120
#   icmp_idle_timeout_sec            = 30
#   tcp_established_idle_timeout_sec = 120
# }


resource "google_compute_instance" "sql_proxy_gce_instance" {
  project      = local.project_id
  name         = "sql-proxy-tests-4-${local.instance_name}"
  machine_type = var.machine_type
  zone         = var.zone

  allow_stopping_for_update = false
  labels                    = var.user_labels

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    # subnetwork = var.proxy_subnet
    network = "default"
    # access_config {
    #   nat_ip = "35.222.144.58"
    # }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    "google-logging-enabled" = "true"
    # gce-container-declaration = module.gce-advanced-container.metadata_value
    gce-container-declaration = var.proxy_gce
    # "gce-container-declaration" = "spec:\n containers:\n  - name: sql-proxy\n   image: 'gcr.io/cloudsql-docker/gce-proxy:latest'\n   command:\n  - /cloud_sql_proxy\n  args:\n    - >-\n   -instances=${var.connection_name}=tcp:0.0.0.0:${var.proxy_port}\n  securityContext:\n  privileged: true\n   stdin: true\n  tty:  true\n  restartPolicy: Always"

    # "metadata_startup_script"   = "echo '{\"live-restore\": true, \"log-opts\":{\"max-size\": \"1kb\", \"max-file\": \"5\" }, \"storage-driver\": \"overlay2\", \"mtu\": 1460}' | sudo jq . | sudo tee /etc/docker/daemon.json >/dev/null; sudo systemctl restart docker"
  }

  metadata_startup_script = "echo '{\"live-restore\": true, \"log-opts\":{\"max-size\": \"1kb\", \"max-file\": \"5\" }, \"storage-driver\": \"overlay2\", \"mtu\": 1460}' | sudo jq . | sudo tee /etc/docker/daemon.json >/dev/null; sudo systemctl restart docker"


  service_account {
    email = google_service_account.proxy_sa_service_account.email
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/sqlservice.admin",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }

  depends_on = [
    google_service_account.proxy_sa_service_account,
  ]

  lifecycle {
    #  prevent_destroy = true
    create_before_destroy = true
  }
}


resource "google_service_account" "proxy_sa_service_account" {
  account_id   = "proxy-${var.sql_instance_name}"
  display_name = "Proxy SA for ${var.sql_instance_name} PostgreSQL instance"
  description  = "Service account used for proxy GCE instance"
  project      = local.project_id
}

resource "google_project_iam_member" "proxy_sa_sql_client_role" {
  project = local.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.proxy_sa_service_account.email}"
}

