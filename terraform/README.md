# React + Spring Boot Infrastructure

This Terraform configuration sets up a modern, scalable infrastructure for React + Spring Boot applications on AWS.

## Structure

The configuration is organized as follows:

- **provider.tf** – AWS provider configuration
- **variables.tf** – Input variables
- **terraform.tfvars** – Variable values
- **network.tf** – VPC, Subnets, Route Tables, Internet Gateway
- **main.tf** – EC2 Instance and Security Group for backend
- **alb.tf** – Application Load Balancer, Target Group, Listener
- **output.tf** – Output values (ALB DNS, EC2 public IP)

## What’s Been Provisioned

### ✅ VPC
- CIDR: `10.0.0.0/16`

### ✅ Public Subnets
- `public_az1`: `10.0.1.0/24` in `us-east-2a`
- `public_az2`: `10.0.2.0/24` in `us-east-2b`

### ✅ Internet Gateway & Route Table
- Public route table with route to IGW
- Associated with both public subnets

### ✅ EC2 Instance
- Amazon Linux 2
- Placed in `public_az1` subnet
- Public IP assigned
- SSH + HTTP open via security group

### ✅ Application Load Balancer (ALB)
- Public-facing
- Spread across 2 subnets
- Listener on port 80
- Targets the EC2 backend

### ✅ Outputs
- ALB DNS Name
- EC2 Public IP

### ✅ RDS (PostgreSQL)
- Instance type: `db.t3.medium`
- PostgreSQL version: `14.18`
- Storage: 20 GB (GP2)
- Subnet group: spans `public_az1` and `public_az2`
- Publicly accessible for development use
- Encrypted at rest
- Provisioned via Terraform
- Output exposed via `rds_endpoint`

---

### ✅ Outputs (Updated)
- ALB DNS Name
- EC2 Public IP
- **RDS Endpoint**

---

### 🚧 Upcoming Steps
- Deploy application to EC2 (via Docker or direct install)
- Create DB schema or restore from previous environment
- Configure app to use RDS PostgreSQL
- Test full-stack functionality
- Harden access (e.g., restrict RDS to VPC, add bastion host or VPN)
