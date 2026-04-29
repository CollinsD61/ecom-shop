# ──────────────────────────────────────────────
# ECR Repositories
# ──────────────────────────────────────────────

resource "aws_ecr_repository" "this" {
  for_each = toset(var.repository_names)

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = {
    Name = each.value
  }
}
