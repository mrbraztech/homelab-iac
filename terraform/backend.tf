terraform {
  backend "s3" {
    bucket                      = "proxmox-ct-state"
    key                         = "homelab/terraform.tfstate"
    region                      = "us-east-1"
    endpoint                    = "http://192.168.10.12:9000"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
