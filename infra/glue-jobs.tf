resource "aws_s3_bucket_object" "jobs" {
  for_each = toset([
    "DMSCDC_LoadIncremental.py",
    "DMSCDC_LoadInitial.py",
    "DMSCDC_Controller.py",
    "DMSCDC_ProcessTable.py"
  ])

  bucket = module.glue-jobs.s3_bucket_id
  key    = each.key
  source = "./../glue_jobs/${each.key}"
  etag   = filemd5("./../glue_jobs/${each.key}")
}


resource "aws_glue_job" "python-jobs" {
  for_each = toset(["DMSCDC_Controller", "DMSCDC_ProcessTable"])
  name     = each.key
  role_arn = aws_iam_role.dmscdc-execution-role.arn

  command {
    name = "pythonshell"
    script_location = "s3://${module.glue-jobs.s3_bucket_id}/${each.key}.py"
    python_version = 3
  }

  max_capacity = 0.0625

  default_arguments = {
      "--job-bookmark-option"   =  "job-bookmark-disable"
      "--TempDir" = "s3://${module.glue-jobs.s3_bucket_id}"
      "--enable-metrics" = ""
  }

  execution_property {
    max_concurrent_runs = 50
  }
}


resource "aws_glue_job" "spark-jobs" {
  for_each = toset(["DMSCDC_LoadIncremental", "DMSCDC_LoadInitial"])
  name     = each.key
  role_arn = aws_iam_role.dmscdc-execution-role.arn

  command {
    name = "glueetl"
    script_location = "s3://${module.glue-jobs.s3_bucket_id}/${each.key}.py"
    python_version = 3
  }
  number_of_workers = 2
  worker_type  = "G.1X"
  glue_version = "3.0"

  default_arguments = {
      "--job-bookmark-option"   =  "job-bookmark-disable"
      "--TempDir" = "s3://${module.glue-jobs.s3_bucket_id}"
      "--enable-metrics" = ""
  }

  execution_property {
    max_concurrent_runs = 50
  }
}

resource "aws_glue_trigger" "example" {
  name     = "DMSCDC-Trigger-mysql"
  schedule = "cron(0 0 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = "DMSCDC_Controller"
    arguments = {
      "--bucket" = module.datalake.s3_bucket_id
      "--out_bucket" = module.data-warehouse.s3_bucket_id
    }
  }
}

resource "aws_glue_crawler" "staging-application" {
  database_name = "application"
  name          = "crawler-staging-application"
  role          = aws_iam_role.dmscdc-execution-role.arn
  schedule      = "cron(0 0 * * ? *)"

  s3_target {
    path = "s3://${module.data-warehouse.s3_bucket_id}"
  }
}