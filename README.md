# Kubernetes The Hard Way w/AWS & Terraform

## ⚠️ Very much a work in progress. Not intended for production use.

Following Kelsey Hightower's [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) tutorial using AWS and [Terraform](https://www.terraform.io/).

This only creates the infrastructure required for the ["Provisioning Compute Resources"](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/03-compute-resources.md) step.

## Usage

To use:

1. Create a `terraform.tfvars` file specifying the required variables. (See `terraform.tfvars.example`)
2. Run `terraform plan` to see what changes Terraform would make to your AWS resources.
3. Once verified, run `terraform apply`

At this point you can resume the tutorial to set up your Kubernetes cluster.
