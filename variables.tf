variable "resource_group_location" {
  type        = string
  default     = <SET THIS INFORMATION>
  description = "Location of the resource group."
}

variable "resource_group_name" {
  type        = string
  default     =  <SET THIS INFORMATION>
  description = "Resource group name hosting the hub and spoke resources"
}

variable "customize_hub_script" {
    type = string
    default = "init-hub.sh"
}