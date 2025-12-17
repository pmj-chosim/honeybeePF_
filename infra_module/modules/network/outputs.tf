output "vcn_id" {
  value = oci_core_vcn.oke_vcn.id
}

output "api_subnet_id" {
  value = oci_core_subnet.api.id
}

output "node_subnet_id" {
  value = oci_core_subnet.node.id
}

output "lb_subnet_id" {
  value = oci_core_subnet.lb.id
}
