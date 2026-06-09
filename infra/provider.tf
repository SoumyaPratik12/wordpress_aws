provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Project = "wp-platform"
      Env     = "dev"
    }
  }
}
