data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_vcn" "oke_vcn" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_ocid
  display_name   = "${var.name_prefix}-vcn"
  dns_label      = "${var.name_prefix}vcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.name_prefix}-internet-gateway"
  vcn_id         = oci_core_vcn.oke_vcn.id
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.name_prefix}-nat-gateway"
  vcn_id         = oci_core_vcn.oke_vcn.id
}

resource "oci_core_service_gateway" "sgw" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.name_prefix}-service-gateway"
  vcn_id         = oci_core_vcn.oke_vcn.id
  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}

resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.name_prefix}-public-rt"

  route_rules {
    destination       = var.anywhere_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_route_table" "private_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.name_prefix}-private-rt"

  route_rules {
    destination       = var.anywhere_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat.id
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sgw.id
  }
}

resource "oci_core_security_list" "api" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.name_prefix}-api-sl"

  egress_security_rules {
    destination = var.anywhere_cidr
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = var.tcp_protocol_number
    source   = var.anywhere_cidr
    tcp_options {
      max = 6443
      min = 6443
    }
  }

  ingress_security_rules {
    protocol = var.tcp_protocol_number
    source   = var.vcn_cidr
  }
}

resource "oci_core_security_list" "node" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.name_prefix}-node-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.vcn_cidr
  }
}

resource "oci_core_subnet" "api" {
  cidr_block        = var.api_subnet_cidr
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.oke_vcn.id
  display_name      = "${var.name_prefix}-api-subnet"
  route_table_id    = oci_core_route_table.public_rt.id
  security_list_ids = [oci_core_security_list.api.id]
}

resource "oci_core_subnet" "node" {
  cidr_block                 = var.node_subnet_cidr
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.oke_vcn.id
  display_name               = "${var.name_prefix}-node-subnet"
  route_table_id             = oci_core_route_table.private_rt.id
  security_list_ids          = [oci_core_security_list.node.id]
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "lb" {
  cidr_block        = var.lb_subnet_cidr
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.oke_vcn.id
  display_name      = "${var.name_prefix}-lb-subnet"
  route_table_id    = oci_core_route_table.public_rt.id
  security_list_ids = [oci_core_security_list.api.id]
}
