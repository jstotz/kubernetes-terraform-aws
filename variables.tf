variable "name" {
  type = "string"
}

variable "ami_id" {
  default = "ami-d651b8ac"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_role" {
  type = "string"
}

variable "public_key" {
  type = "string"
}
