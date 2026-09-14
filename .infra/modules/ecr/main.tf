resource "aws_ecr_repository" "ecr" {
  name                 = "tc-${var.env}-ecr-${var.name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}