variable "db_user" {
  type        = string
  description = "Uzivatelske jmeno pro databazi"
}

variable "db_password" {
  type        = string
  description = "Heslo pro uzivatele databaze"
}

variable "db_root_password" {
  type        = string
  description = "Hlavni root heslo databaze"
}

terraform {
  required_providers {
    docker = {
        source = "kreuzwerker/docker"
        version = "~> 3.0.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "mariadb_image" {
    name = "mariadb:10.11"
}

resource "docker_container" "mariadb_container" {
    name = "ecommerce_db"
    image = docker_image.mariadb_image.name

    env = [ 
        "MARIADB_DATABASE=ecomdb",
        "MARIADB_USER=${var.db_user}",
        "MARIADB_PASSWORD=${var.db_password}",
        "MARIADB_ROOT_PASSWORD=${var.db_root_password}"
        ]

    networks_advanced {
      name = docker_network.ecommerce_net.name
  }

    volumes {
      host_path      = abspath("${path.module}/../db-load-script.sql")
      container_path = "/docker-entrypoint-initdb.d/db-load-script.sql"
      read_only      = true
    }
}

resource "docker_image" "web_image" {
  name = "ecommerce_web:latest"
  build {
    context = abspath("${path.module}/..")
  }
  
}

resource "docker_container" "web_container" {
  name = "ecommerce-web"
  image = docker_image.web_image.name
  ports {
    internal = 80
    external = 8082
  }

  networks_advanced {
    name = docker_network.ecommerce_net.name
  }
  
  env = [ 
    "DB_HOST=${docker_container.mariadb_container.name}",
    "DB_USER=${var.db_user}",
    "DB_PASSWORD=${var.db_password}",
    "DB_NAME=ecomdb"
   ]

}

resource "docker_network" "ecommerce_net" {
  name = "ecommerce_network"
}