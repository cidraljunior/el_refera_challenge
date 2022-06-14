# DMS CDC

data "aws_iam_policy_document" "dmscdc-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com", "glue.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "dmscdc-execution-policy" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:CreateTable",
      "dynamodb:UpdateItem",
      "dynamodb:UpdateTable",
      "dynamodb:GetItem",
      "dynamodb:DescribeTable",
      "iam:GetRole",
      "iam:PassRole",
      "dms:StartReplicationTask",
      "dms:TestConnection",
      "dms:StopReplicationTask"
      ]

    resources = [
      "arn:aws:dynamodb:${local.region}:${local.account_id}:table/DMSCDC_Controller",
      "arn:aws:iam::${local.account_id}:role/DMSCDC_ExecutionRole",
      "arn:aws:dms:${local.region}:${local.account_id}:endpoint:*",
      "arn:aws:dms:${local.region}:${local.account_id}:task:*"
    ]
  }

  statement {
    actions = [
      "dms:DescribeConnections",
      "dms:DescribeReplicationTasks"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "dmscdc-execution-role" {
  assume_role_policy = data.aws_iam_policy_document.dmscdc-assume-role.json

  inline_policy {
    name   = "DMSCDCExecutionPolicy"
    policy = data.aws_iam_policy_document.dmscdc-execution-policy.json
  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
  max_session_duration = "3600"
  name                 = "DMSCDC_ExecutionRole"
  path                 = "/"
}


## DMS

data "aws_iam_policy_document" "dms-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "dms-access-for-endpoint" {
  assume_role_policy = data.aws_iam_policy_document.dms-assume-role.json
  name               = "dms-access-for-endpoint"
}

resource "aws_iam_role_policy_attachment" "dms-access-for-endpoint-AmazonDMSRedshiftS3Role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"
  role       = aws_iam_role.dms-access-for-endpoint.name
}

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  assume_role_policy = data.aws_iam_policy_document.dms-assume-role.json
  name               = "dms-cloudwatch-logs-role"
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
}

resource "aws_iam_role" "dms-vpc-role" {
  assume_role_policy = data.aws_iam_policy_document.dms-assume-role.json
  name               = "dms-vpc-role"
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms-vpc-role.name
}