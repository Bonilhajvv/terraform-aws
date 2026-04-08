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

# Configuração do módulo VPC
module "module-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "module-vpc"
  cidr = "10.0.0.0/16"

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]


  enable_nat_gateway   = true // subnets privadas acessarem internet (sem serem acessadas)
  enable_vpn_gateway   = true // para acessar a VPC via VPN
  enable_dns_hostnames = true // para ter nomes ao invés de host dentro da VPC

  tags = {
    "kubernetes.io/cluster/cluster_" = "shared" // tags para identificar os recursos da VPC, mostra que a vpc é compartilhada entre os clusters kubernetes
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/cluster_" = "shared"
    "kubernetes.io/role/elb"         = "1" // tag para o cluster kubernetes identificar os recursos da VPC e para identificar as subnets públicas para o ELB, dessa forma o cluster kubernetes irá criar os ELBs nas subnets públicas para expor os serviços do cluster para a internet
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/cluster_"  = "shared"
    "kubernetes.io/role/internal-elb" = "1" // tag para o cluster kubernetes identificar os recursos da VPC e para identificar as subnets privadas para o ELB, dessa forma o cluster kubernetes irá criar os ELBs nas subnets privadas para expor os serviços do cluster para a vpc interna
  }
}

# Configuração do módulo EKS
# Cria um cluster Kubernetes (EKS) completo dentro da sua VPC, utilizando as subnets privadas para os nós do cluster e as subnets públicas para o endpoint do cluster e para os ELBs que serão criados para expor os serviços do cluster para a internet
module "module-eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "module-eks"
  kubernetes_version = "1.33"

  vpc_id                 = module.module-vpc.vpc_id          // O módulo VPC exporta o ID da VPC criada, que é necessário para criar o cluster EKS dentro dessa VPC
  subnet_ids             = module.module-vpc.private_subnets // O módulo VPC exporta os IDs das subnets privadas criadas, que são necessárias para criar o cluster EKS dentro dessas subnets privadas
  endpoint_public_access = true                              // para permitir acesso ao endpoint do cluster EKS pela internet, caso contrário o endpoint do cluster EKS só seria acessível dentro da VPC


  eks_managed_node_groups = {
    "ng-1" = {
      desired_capacity = 3 // número de nós desejados para o cluster EKS, nesse caso estamos utilizando 3 nós, mas esse número pode ser ajustado de acordo com a necessidade do ambiente
      max_capacity     = 3 // número máximo de nós para o cluster EKS, nesse caso estamos utilizando 3 nós, mas esse número pode ser ajustado de acordo com a necessidade do ambiente
      min_capacity     = 1 // número mínimo de nós para o cluster EKS, nesse caso estamos utilizando 1 nó, mas esse número pode ser ajustado de acordo com a necessidade do ambiente

      instance_types = ["t3.medium"] // tipo de instância para os nós do cluster EKS, nesse caso estamos utilizando a instância t3.medium, que é uma instância de uso geral com um bom equilíbrio entre custo e desempenho
    }
  }
}
