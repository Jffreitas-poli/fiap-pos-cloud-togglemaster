resource "aws_db_instance" "rds" {
  identifier             = "tc-${var.env}-rds-${var.db_name}"
  engine                 = "postgres"
  engine_version         = "18.3"
  multi_az               = false
  db_name                = "${var.db_name}_db"
  username               = var.db_user
  password               = var.db_pass
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_subnet_group_name   = var.sng_id
  vpc_security_group_ids = [var.sg_id]
  port                   = 5432
  skip_final_snapshot    = true
  publicly_accessible    = false
  tags                   = { Name = "${var.env}-rds" }
}
