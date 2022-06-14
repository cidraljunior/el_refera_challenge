module "datalake" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "datalake-raw-refera-challenge"
  acl    = "private"
}

module "data-warehouse" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "data-warehouse-refera-challenge"
  acl    = "private"
}

module "glue-jobs" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "glue-jobs-refera-challenge"
  acl    = "private"
}
