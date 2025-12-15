variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID"
}

variable "name_prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "vcn_cidr" {
  type        = string
  description = "VCN CIDR"
}

variable "api_subnet_cidr" {
  type        = string
  description = "API subnet CIDR"
}

variable "node_subnet_cidr" {
  type        = string
  description = "Node subnet CIDR"
}

variable "lb_subnet_cidr" {
  type        = string
  description = "LB subnet CIDR"
}
