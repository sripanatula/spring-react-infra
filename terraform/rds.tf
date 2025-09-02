resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "rds" {
  identifier              = "${var.project_name}-db"
  engine                  = "postgres"
  engine_version          = "14.18"
  instance_class          = "db.t3.medium"
  
  # Storage Configuration
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_max_allocated_storage  # Auto-scaling
  storage_type           = var.db_storage_type
  storage_encrypted      = true
  iops                   = var.db_storage_type == "io1" || var.db_storage_type == "io2" ? var.db_iops : null
  
  # Database Configuration
  username                = var.db_username
  password                = var.db_password
  publicly_accessible     = true
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  
  # Backup and Maintenance
  skip_final_snapshot     = var.environment == "dev" ? true : false
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"  # UTC
  maintenance_window     = "sun:04:00-sun:05:00"  # UTC
  deletion_protection     = var.environment == "prod" ? true : false
  apply_immediately       = var.environment == "dev" ? true : false
  
  # Performance Monitoring
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  monitoring_interval     = 60
  monitoring_role_arn    = aws_iam_role.rds_monitoring_role.arn

  tags = {
    Name        = "${var.project_name}-rds"
    Environment = var.environment
  }
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}
