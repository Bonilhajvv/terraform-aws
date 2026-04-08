terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configuração do provider AWS
# Caso não esteja utilizando o aws cli, é necessário configurar as credenciais de acesso
# access_key = "my-access-key"
#  secret_key = "my-secret-key"

provider "aws" {
  region = "us-east-1"
}

# Cria uma VPC
resource "aws_vpc" "aws-vpc" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "aws-vpc"
  }
}