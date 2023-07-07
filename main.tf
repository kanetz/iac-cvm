module "provisioning" {
  source = "./modules/provisioning"
}

resource "time_static" "start_time" {}
resource "time_static" "end_time" {
  triggers = {
    cvm_instance_ready = length(module.provisioning.cvm_instance)
    private_key_ready  = length(module.provisioning.private_key_file)
  }
}
locals {
  elapsed_time_unix    = time_static.end_time.unix - time_static.start_time.unix
  elapsed_time_hours   = floor(local.elapsed_time_unix / 3600)
  elapsed_time_minutes = floor(local.elapsed_time_unix % 3600 / 60)
  elapsed_time_seconds = local.elapsed_time_unix % 60
  elapsed_time_message    = format("%s%s%s",
    local.elapsed_time_hours > 0 ? "${local.elapsed_time_hours}h" : "",
    (local.elapsed_time_hours > 0 || local.elapsed_time_minutes > 0) ? "${local.elapsed_time_minutes}m" : "",
    "${local.elapsed_time_seconds}s"
  )
}

output "_01_total_elapsed_time" {
  value = local.elapsed_time_message
}
output "_02_ssh_to_instance" {
  value = "ssh -i ${abspath(module.provisioning.private_key_file.filename)} root@${module.provisioning.cvm_instance.public_ip}"
}
