provider "google" {
    project = ""
    region = ""

}

data "google_compute_network" "net" {
    name = "default"
  
}
resource "google_compute_firewall" "firewall" {
    name = "allow-http"
    network = data.google_compute_network.net.name
    allow {
      ports = ["80"]
      protocol = "tcp"
    }
    source_ranges = ["0.0.0.0/0"]

}

resource "google_compute_health_check" "health" {
    name = "allow-health-check"
    http_health_check {
      port = 80
    }

}

resource "google_compute_instance_template" "instance_temp" {
    name_prefix = "apache2"
    machine_type = "e2-medium"
    disk {
      source = ""
      boot = true
      auto_delete = true
    }
    network_interface {
      network = data.google_compute_network.net.name
      access_config {
        
      }
    }
}

resource "google_compute_instance_group_manager" "MIG" {
    name = "apache2-mig"
    zone = ""
    base_instance_name = "apache"
    version {
      instance_template = google_compute_instance_template.instance_temp.id
    }
    target_size = 2
    auto_healing_policies {
      health_check = google_compute_health_check.health.id
      initial_delay_sec = 120
    }
  
}

resource "google_compute_backend_service" "service" {
    name = "backend-svc"
    protocol = "HTTP"
    port_name = "http"
    health_checks = [google_compute_health_check.health.id]
    backend {
      group = 
    }
  
}

resource "google_compute_url_map" "url" {
    name = "apache-url"
    default_service = google_compute_backend_service.service.id

}

resource "google_compute_target_http_proxy" "http_proxy" {
    name = "target-url"
    url_map = google_compute_url_map.url.id
}

resource "google_compute_global_forwarding_rule" "ford_rule" {
    name = "global-rule"
    target = google_compute_target_http_proxy.http_proxy.id
    port_range = "80"
  
}


output "load_balancer_ipaddress" {
    value = google_compute_global_forwarding_rule.ford_rule.ip_address
}