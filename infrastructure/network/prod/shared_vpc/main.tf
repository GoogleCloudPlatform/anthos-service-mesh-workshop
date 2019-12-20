###################  NETWORK  #######################
# create shared-vpc in the host project with 4 subnets
module "create_vpc_in_host_project" {
  source          = "terraform-google-modules/network/google"
  version         = "1.4.2"
  project_id      = data.terraform_remote_state.host_project.outputs.host_project_id
  network_name    = var.network_name
  routing_mode    = var.routing_mode
  shared_vpc_host = true

  subnets = [
    {
      subnet_name      = var.subnet_01_name
      subnet_ip        = var.subnet_01_ip
      subnet_region    = var.subnet_01_region
      subnet_flow_logs = "true"
      description      = var.subnet_01_description
    },
    {
      subnet_name      = var.subnet_02_name
      subnet_ip        = var.subnet_02_ip
      subnet_region    = var.subnet_02_region
      subnet_flow_logs = "true"
      description      = var.subnet_02_description
    },
    {
      subnet_name      = var.subnet_03_name
      subnet_ip        = var.subnet_03_ip
      subnet_region    = var.subnet_03_region
      subnet_flow_logs = "true"
      description      = var.subnet_03_description
    },
    {
      subnet_name      = var.subnet_04_name
      subnet_ip        = var.subnet_04_ip
      subnet_region    = var.subnet_04_region
      subnet_flow_logs = "true"
      description      = var.subnet_04_description
    },
  ]

  secondary_ranges = {
    "${var.subnet_01_name}" = [
      {
        range_name    = var.subnet_01_secondary_svc_1_name
        ip_cidr_range = var.subnet_01_secondary_svc_1_range
      },
      {
        range_name    = var.subnet_01_secondary_svc_2_name
        ip_cidr_range = var.subnet_01_secondary_svc_2_range
      },
      {
        range_name    = var.subnet_01_secondary_pod_name
        ip_cidr_range = var.subnet_01_secondary_pod_range
      },
    ]
    "${var.subnet_02_name}" = [
      {
        range_name    = var.subnet_02_secondary_svc_1_name
        ip_cidr_range = var.subnet_02_secondary_svc_1_range
      },
      {
        range_name    = var.subnet_02_secondary_svc_2_name
        ip_cidr_range = var.subnet_02_secondary_svc_2_range
      },
      {
        range_name    = var.subnet_02_secondary_pod_name
        ip_cidr_range = var.subnet_02_secondary_pod_range
      },
    ]
    "${var.subnet_03_name}" = [
      {
        range_name    = var.subnet_03_secondary_svc_1_name
        ip_cidr_range = var.subnet_03_secondary_svc_1_range
      },
      {
        range_name    = var.subnet_03_secondary_svc_2_name
        ip_cidr_range = var.subnet_03_secondary_svc_2_range
      },
      {
        range_name    = var.subnet_03_secondary_pod_name
        ip_cidr_range = var.subnet_03_secondary_pod_range
      },
    ]
    "${var.subnet_04_name}" = [
      {
        range_name    = var.subnet_04_secondary_svc_1_name
        ip_cidr_range = var.subnet_04_secondary_svc_1_range
      },
      {
        range_name    = var.subnet_04_secondary_svc_2_name
        ip_cidr_range = var.subnet_04_secondary_svc_2_range
      },
      {
        range_name    = var.subnet_04_secondary_pod_name
        ip_cidr_range = var.subnet_04_secondary_pod_range
      },
    ]
  }
}

# create firewall rules to allow-all inernally and SSH from external
module "net-firewall" {
  source                  = "terraform-google-modules/network/google//modules/fabric-net-firewall"
  version                 = "1.3.0"
  project_id              = module.create_vpc_in_host_project.svpc_host_project_id
  network                 = module.create_vpc_in_host_project.network_name
  internal_ranges_enabled = true
  internal_ranges         = ["10.0.0.0/8"]
  internal_allow = [
    { "protocol" : "all" },
  ]
}