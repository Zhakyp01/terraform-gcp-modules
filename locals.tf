locals {
  region_str    = split("-", var.region)
  region_letter = substr(local.region_str[1], 8, 1)
  region_number = substr(local.region_str[1], length(local.region_str[1]) - 1, 1)

  project_id = var.project_id == null ? var.project_id : var.project_id

  instance_name = var.instance_name == null ? lower("gep${local.region_letter}${local.region_number}${lookup(var.user_labels, "tla")}") : var.instance_name
  # instance_name = format("%s-%s", var.instance_name, substr(md5(module.gce-advanced-container.container.image), 0, 8))

}

