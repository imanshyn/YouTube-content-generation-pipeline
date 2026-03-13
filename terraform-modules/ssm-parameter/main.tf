resource "aws_ssm_parameter" "this" {
  for_each = { for p in var.parameters : p.name => p }

  name  = each.value.name
  type  = each.value.type
  value = each.value.value

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}
