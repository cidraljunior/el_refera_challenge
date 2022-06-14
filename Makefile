.ONESHELL:
terraform_plan:
	cd infra/
	terraform init
	terraform plan

terraform_apply:
	cd infra/
	terraform apply

terraform_destroy:
	cd infra/
	terraform destroy