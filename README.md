# README

Will start and stop one or more EC2 instances on a set schedule.

By default it will start the instances at 7 AM, and stop them at 7 PM. This can be changed in the Terraform module.

## Deployment 

1. Change instance ID's in (start|stop)/function.py
2. Run `terraform init`
3. Run `terraform apply`

## TODO

- Read instance ID's from central file and package on the fly
- Separate main.tf out into multiple files for readability

