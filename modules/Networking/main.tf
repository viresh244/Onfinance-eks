provider "aws" {
     region = var.region
}

# VPC Resource
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
    
    tags = {
        Name = "${var.project_name}-vpc"
        Environment = var.environment
    }
}

# Public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]
    map_public_ip_on_launch = true

    tags = {
        name = "${var.project_name}-public-subnet-${count.index + 1}"
        Environment = var.environment
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "kubernetes.io/role/elb" = 1
    }
}


# Private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]

    tags = {
        name = "${var.project_name}-private-subnet-${count.index + 1}"
        Environment = var.environment
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb" = 1
    }
}


# Internet Gateway
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.project_name}-igw"
        Environment = var.environment
    }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
    count = length(var.public_subnet_cidrs)
    domain = "vpc"

    tags = {
        Name = "${var.project_name}-nat-eip-${count.index + 1}"
        Environment = var.environment
    }
}


# NAT Gateway
resource "aws_nat_gateway" "main" {
    count = length(var.public_subnet_cidrs)
    allocation_id = aws_eip.nat[count.index].id
    subnet_id = aws_subnet.public[count.index].id

    tags = {
        Name = "${var.project_name}-nat-gateway-${count.index + 1}"
        Environment = var.environment
    }

    depends_on = [ aws_internet_gateway.main ]
}

# Route Table for Public Subnets
  resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route = {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "${var.project_name}-public-route-table"
        Environment = var.environment
    }
  }


  # Route table for Private Subnets
  resource "aws_route_table" "private" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id

        route {
            cidr_block = "0.0.0.0/0"
            nat_gateway_id = aws_nat_gateway.main[count.index].id
        } 

    tags = {
        Name = "${var.project_name}-private-route-table-${count.index + 1}"
        Environment = var.environment
    }

  }

  # Route table association for Public Subnets
    resource "aws_route_table_association" "public" {
        count = length(var.public_subnet_cidrs)
        subnet_id = aws_subnet.public[count.index].id
        route_table_id = aws_route_table.public.id
    }

    # Route table association for Private Subnets
    resource "aws_route_table_association" "private" {
        count = length(var.private_subnet_cidrs)
        subnet_id = aws_subnet.private[count.index].id
        route_table_id = aws_route_table.private[count.index].id
    }


    # Security group for EKS cluster
     resource "aws_security_group" "eks_cluster" {
        
        name = "${var.project_name}-eks-cluster-sg"
        description = "Security group for EKS cluster"
        vpc_id = aws_vpc.main.id

        egress = {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_block = ["0.0.0.0/0"]
        }

        tags = {
            Name = "${var.project_name}-eks-cluster-sg"
            Environment = var.environment
        }

     }

     # Security group for EKS worker nodes
      resource "aws_security_group" "eks_nodes" {
        name = "${var.project_name}-eks-nodes-sg"
        description = "Security group for EKS worker nodes"
        vpc_id = aws_vpc.main.id

            egress {
                from_port = 0
                to_port = 0
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
            } 

            tags = {
                Name = "${var.project_name}-eks-nodes-sg"
                Environment = var.environment
            }

      }




      # Allow Worker Nodes to communicate with the Cluster
      resource "aws_security_group" "nodes_to_cluster" {
        description = Allow worker nodes to communicate with the cluster API server
        from_port = 443
        to_port = 443
        protocol = "tcp"
        security_group_id = aws_security_group.eks_cluster.id
        source_security_group_id = aws_security_group.eks_nodes.id
        type = "ingress"
      }


        # Allow Cluster to communicate with Worker Nodes
        resource "aws_security_group" "cluster_to_nodes" {
        description = Allow cluster to communicate with worker nodes
        from_port = 1024
        to_port = 65535
        protocol = "tcp"
        security_group_id = aws_security_group.eks_nodes.id
        source_security_group_id = aws_security_group.eks_cluster.id
        type = "ingress"
        }