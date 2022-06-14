resource "aws_dms_replication_instance" "default" {
  allocated_storage            = 5
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  engine_version               = "3.4.6"
  multi_az                     = false
  preferred_maintenance_window = "sun:10:30-sun:14:30"
  publicly_accessible          = false
  replication_instance_class   = "dms.t3.micro"
  replication_instance_id      = "dms-replication-instance"

  depends_on = [
    aws_iam_role_policy_attachment.dms-access-for-endpoint-AmazonDMSRedshiftS3Role,
    aws_iam_role_policy_attachment.dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole,
    aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole
  ]
}


resource "aws_dms_endpoint" "source_mysql" {
  endpoint_id   = "source-mysql-dms-endpoint"
  endpoint_type = "source"
  engine_name   = "mysql"

  database_name = "application"
  username      = "admin"
  password      = "mypassword"
  port          = 3306
  server_name   = "db-transactional-1.cyol4ijfx9sw.us-east-1.rds.amazonaws.com"
}

resource "aws_dms_endpoint" "target_s3" {
  endpoint_id   = "target-s3-dms-endpoint"
  endpoint_type = "target"
  engine_name   = "s3"

  s3_settings {
    bucket_name                      = module.datalake.s3_bucket_id
    data_format                      = "parquet"
    include_op_for_full_load         = true
    service_access_role_arn          = aws_iam_role.dmscdc-execution-role.arn
    parquet_timestamp_in_millisecond = true
  }
}

resource "aws_dms_replication_task" "mysql-task" {
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.default.replication_instance_arn
  replication_task_id      = "dms-replication-task-mysql"
  start_replication_task   = true
  table_mappings           = <<MAP
{
  "rules": [
    {
      "rule-type": "selection",
      "rule-id": "1",
      "rule-name": "1",
      "object-locator": {
        "schema-name": "application",
        "table-name": "%"
      },
      "rule-action": "include",
      "filters": []
    }
  ]
}
MAP

  source_endpoint_arn = aws_dms_endpoint.source_mysql.endpoint_arn
  target_endpoint_arn = aws_dms_endpoint.target_s3.endpoint_arn

  lifecycle {
    ignore_changes = [
      start_replication_task,
      replication_task_settings
    ]
  }
}
