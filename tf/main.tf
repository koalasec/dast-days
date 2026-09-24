# main.tf

module "ec2_instance" {
  source = "../modules"

  name_prefix    = "web-server"
  instance_type  = "t3.small"
  
  common_tags = {
    Environment = "production"
    Project     = "web-app"
  }
}
