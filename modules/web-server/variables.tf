variable "CREATOR" {
  type = string
  description = "Name to include in 'Created by' tag"
}

variable "VMCOUNT" {
  type = number
  description = "Number of VMs to deploy"
}

variable "ADMIN_PASS" {
  type = string
  description = "Administrator password for VMs"
}

variable "IMAGE_NAME" {
  type = string
  description = "Name of the Packer Image to use for the VMs"
}

variable "IMAGE_RG" {
  type = string
  description = "Name of the Resource Group where the Packer Image resides"
}

variable "RGNAME" {
  type = string
  description = "Name of the Resource Group to create and contain these resources"
}