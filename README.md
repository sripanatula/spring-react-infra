# React + Spring Boot AWS Infrastructure Template

A modern, scalable cloud infrastructure template built with Terraform for React + Java Spring Boot applications. This template implements enterprise-grade architecture patterns using AWS managed services and can be easily customized for any project.

## 🏗️ Architecture Overview

```
Users → CloudFront (CDN) → S3 (React App) + ALB (Java API) → RDS (PostgreSQL)
```

**Key Components:**
- **Frontend**: React SPA served via CloudFront + S3
- **Backend**: Java Spring Boot API with JWT authentication
- **Database**: PostgreSQL on AWS RDS with automated backups
- **CDN**: Global content delivery with CloudFront
- **Load Balancing**: Application Load Balancer with health checks
- **Security**: End-to-end HTTPS with ACM certificates

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.5.0
- Domain name (optional, for custom SSL certificates)

### Deployment

1. **Configure Variables**
   ```bash
   cd terraform/
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Deploy Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Deploy Applications**
   - Backend: Deploy Spring Boot app to EC2 (port 8080)
   - Frontend: Build React app and sync to S3 bucket
   - See [deployment guide](terraform/deployment_guide.md) for details

## 📁 Project Structure

```
├── terraform/                  # Infrastructure as Code
│   ├── *.tf                   # Terraform configurations
│   ├── deployment_guide.md    # Detailed deployment instructions
│   └── terraform.tfvars.example
├── scripts/
│   └── aws_audit.sh           # Infrastructure auditing script
├── docs/
│   └── ARCHITECTURE_DECISIONS.md  # Technical decisions and rationale
└── README.md                  # This file
```

## 🔧 Technical Highlights

### Infrastructure Features
- **Multi-AZ Deployment**: High availability across multiple availability zones
- **Load Balancing**: Application Load Balancer with health checks and auto-scaling support
- **Network Security**: VPC isolation with public/private subnet architecture
- **Monitoring**: Integrated CloudWatch metrics and Spring Boot Actuator health endpoints
- **Storage Optimization**: GP3 storage with 3000 IOPS baseline for cost-effective performance
- **Global CDN**: CloudFront distribution with edge caching for worldwide content delivery

### Architecture Patterns
- **Stateless Design**: JWT-based authentication enabling horizontal scaling
- **Infrastructure as Code**: Complete automation using Terraform with modular structure
- **Environment Flexibility**: Configurable for development, staging, and production deployments
- **Defense in Depth**: Multiple security layers with IAM roles and Security Groups
- **Microservices Ready**: Containerized deployment support with Docker integration

## 🛡️ Security Features

- **Network Isolation**: Private subnets for database
- **SSL/TLS**: End-to-end encryption with ACM
- **JWT Authentication**: Stateless token-based auth
- **Security Groups**: Granular access controls
- **IAM Roles**: Principle of least privilege

## 📊 Performance Characteristics

- **Global Response Time**: <100ms (CloudFront edge locations)
- **API Response Time**: <200ms (regional deployment)
- **Database Performance**: 3000 IOPS baseline with GP3
- **Concurrent Users**: Scales to 1000+ with current setup

## 💰 Cost Optimization

- **Free Tier Eligible**: Uses t2.micro instances
- **GP3 Storage**: 20% cost savings over GP2
- **S3 + CloudFront**: Cost-effective static hosting
- **Right-sized Resources**: Optimized for workload requirements

## 🔄 Deployment Environments

Supports multiple environments with different configurations:
- **Development**: Open access, skip final snapshots
- **Staging**: Production-like with relaxed security
- **Production**: Full security hardening and backup retention

## 📈 Scaling Options

- **Frontend**: Unlimited scaling via CloudFront + S3
- **Backend**: EC2 instance upgrades or Auto Scaling Groups
- **Database**: RDS scaling options (compute, storage, IOPS)
- **Global**: Multi-region deployment support

## 🛠️ Technology Stack

- **Infrastructure**: Terraform for Infrastructure as Code
- **Frontend**: React SPA with CloudFront CDN and S3 hosting
- **Backend**: Java Spring Boot with Application Load Balancer
- **Database**: PostgreSQL on AWS RDS with Multi-AZ support
- **Monitoring**: CloudWatch metrics and Spring Boot Actuator endpoints
- **Security**: AWS IAM roles, VPC isolation, and SSL/TLS encryption

## 📚 Documentation

- [Architecture Decisions](docs/ARCHITECTURE_DECISIONS.md) - Technical decisions and rationale
- [Deployment Guide](terraform/deployment_guide.md) - Step-by-step deployment instructions
- [Terraform Documentation](terraform/README.md) - Infrastructure details

---

*This infrastructure template follows modern cloud engineering practices and can be adapted for production workloads with appropriate security and compliance configurations.*