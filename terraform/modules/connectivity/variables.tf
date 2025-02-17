variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

module "connectivity" {
  source        = "./modules/ec2"
  instance_name = "web-server"
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2023
  instance_type = "t3.small"
  vpc_id        = "vpc-12345678"
  subnet_id     = "subnet-abcdefgh"
}