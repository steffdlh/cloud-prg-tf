variable "sg_ports" {
  type    = list(number)
  default = [80, 443] # 22 -> ssh, 80 -> http, 443 -> https
}

locals {
  private_subnet_cidrs = [
    { cidr_block = "10.0.2.0/27", az = "eu-central-1a" },
    { cidr_block = "10.0.3.0/27", az = "eu-central-1b" },
    { cidr_block = "10.0.4.0/27", az = "eu-central-1c" }
  ]

  public_subnet_cidrs = [
    { cidr_block = "10.0.0.0/27", az = "eu-central-1a" },
    { cidr_block = "10.0.5.0/27", az = "eu-central-1b" },
    { cidr_block = "10.0.6.0/27", az = "eu-central-1c" }
  ]

  project = "cloud-programming"
  environment = "prod"
}

