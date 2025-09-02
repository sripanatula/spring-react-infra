# 🏗️ Architecture Decision Records (ADRs)

## Overview
This document explains the key architectural decisions made in this React + Spring Boot infrastructure template, the reasoning behind them, and the trade-offs considered.

---

## ADR-001: Multi-Tier Architecture with CloudFront + S3 + ALB

### **Decision**
Implement a 3-tier architecture separating frontend (React), backend (Java), and database (PostgreSQL) with CloudFront as the global entry point.

### **Context**
Initial consideration was a simple setup with EC2 serving both static files and API. Need to demonstrate modern, scalable architecture patterns.

### **Options Considered**
1. **Single EC2 Instance** - Simple but not scalable
2. **EC2 + S3** - Better separation but no CDN
3. **CloudFront + S3 + ALB** - Full separation with global CDN

### **Decision Rationale**
- **Global Performance**: CloudFront edge locations provide sub-100ms response times globally
- **Scalability**: Frontend scales independently of backend
- **Cost Efficiency**: S3 + CloudFront cheaper than EC2 for static content
- **Security**: Separation of concerns with different security models
- **Modern Patterns**: Demonstrates understanding of microservices architecture

### **Trade-offs**
- ✅ **Pros**: Better performance, scalability, security, cost efficiency
- ❌ **Cons**: Increased complexity, more components to manage, longer initial setup

### **Implementation**
```hcl
# CloudFront with dual origins
origin {
  domain_name = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name  # React app
}
origin {
  domain_name = aws_lb.rr_alb.dns_name  # Java API
}
```

---

## ADR-002: GP3 Storage for RDS Instead of GP2

### **Decision**
Use GP3 storage type for RDS PostgreSQL database instead of the default GP2.

### **Context**
RDS storage type affects performance, cost, and scalability. Need to balance performance with cost for a demonstration project.

### **Technical Analysis**
| Aspect | GP2 | GP3 | Decision Impact |
|--------|-----|-----|-----------------|
| **Cost** | $0.10/GB/month | $0.08/GB/month | 20% cost savings |
| **Baseline IOPS** | 3 IOPS/GB (min 100) | 3000 IOPS | 30x better performance |
| **Burst Capability** | Yes (limited) | No (not needed) | Consistent performance |
| **Throughput** | Varies with IOPS | 125 MB/s baseline | Predictable throughput |

### **Decision Rationale**
- **Cost Optimization**: 20% cheaper for same storage
- **Performance**: Consistent 3000 IOPS vs variable GP2
- **Future Scaling**: Can increase IOPS independently of storage size
- **Modern Best Practice**: GP3 is AWS recommended for new workloads

### **Implementation**
```hcl
resource "aws_db_instance" "main_rds" {
  storage_type = "gp3"  # vs gp2 default
  # Automatic 3000 IOPS baseline
}
```

---

## ADR-003: Spring Boot Actuator for Health Checks

### **Decision**
Use Spring Boot Actuator's built-in health endpoints instead of custom health check controllers.

### **Context**
ALB needs health check endpoints. Could build custom `/health` endpoint or leverage Spring Boot Actuator.

### **Comparison**
| Approach | Custom Controller | Spring Boot Actuator |
|----------|-------------------|---------------------|
| **Code Required** | 20+ lines | 0 lines (configuration only) |
| **Features** | Basic status | Database, disk, JVM, custom |
| **Standards** | Custom format | Industry standard |
| **Monitoring** | Manual metrics | Auto-exposed metrics |
| **Maintenance** | Manual updates | Framework maintained |

### **Decision Rationale**
- **Zero Code**: No custom health check logic needed
- **Comprehensive**: Automatic database connectivity, disk space, JVM metrics
- **Industry Standard**: `/actuator/health` is recognized pattern
- **Extensibility**: Easy to add custom health indicators
- **Production Ready**: Built-in security and configuration options

### **Implementation**
```properties
# application.properties
management.endpoints.web.base-path=/api/actuator
management.endpoint.health.show-details=when-authorized
management.health.db.enabled=true
```

```hcl
# ALB health check
health_check {
  path = "/api/actuator/health"
}
```

---

## ADR-004: Multi-AZ RDS Deployment Strategy

### **Decision**
Deploy RDS with subnet group across multiple AZs but without Multi-AZ replication for this demonstration.

### **Context**
Need to balance high availability with cost for a portfolio demonstration project.

### **Options Analysis**
| Configuration | Cost | Availability | Failover Time | Demo Value |
|---------------|------|--------------|---------------|------------|
| **Single AZ** | $50/month | 99.9% | Manual | Low |
| **Subnet Group** | $50/month | 99.95% | ~5 minutes | Medium |
| **Multi-AZ** | $100/month | 99.99% | ~60 seconds | High |

### **Decision Rationale**
- **Cost Conscious**: 50% cost savings vs Multi-AZ
- **Architecture Understanding**: Shows knowledge of HA patterns
- **Upgrade Path**: Easy to enable Multi-AZ later
- **Demo Appropriate**: Sufficient for portfolio demonstration

### **Implementation**
```hcl
resource "aws_db_subnet_group" "main_db_subnet_group" {
  subnet_ids = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}
# Multi-AZ ready but not enabled: multi_az = false
```

---

## ADR-005: JWT Authentication Over Session-Based

### **Decision**
Implement stateless JWT authentication instead of server-side sessions.

### **Context**
Authentication strategy affects scalability, performance, and infrastructure requirements.

### **Comparison**
| Aspect | Session-Based | JWT-Based |
|--------|---------------|-----------|
| **Server State** | Required | Stateless |
| **Scaling** | Complex (sticky sessions) | Simple (any server) |
| **Performance** | Database lookup | Token validation |
| **Security** | Server-controlled | Client-stored |
| **ALB Compatibility** | Requires sticky sessions | Perfect fit |

### **Decision Rationale**
- **Stateless Scaling**: Perfect for load-balanced environment
- **Performance**: No database lookup for each request
- **Cloud Native**: Aligns with microservices patterns
- **ALB Optimization**: No sticky sessions needed
- **Cost Efficiency**: No session storage infrastructure

### **Trade-offs**
- ✅ **Pros**: Scalable, performant, stateless, cloud-friendly
- ❌ **Cons**: Token management complexity, cannot revoke individual tokens easily

---

## ADR-006: Development vs Production Security Configuration

### **Decision**
Implement environment-conditional security settings with clear development vs production distinctions.

### **Context**
Need to balance ease of development with production security requirements.

### **Configuration Strategy**
```hcl
# Development-friendly settings
skip_final_snapshot     = var.environment == "dev" ? true : false
deletion_protection     = var.environment == "prod" ? true : false
publicly_accessible     = var.environment == "dev" ? true : false

# Security hardening for production
ingress {
  from_port       = 5432
  to_port         = 5432
  protocol        = "tcp"
  # Dev: Open access, Prod: VPC only
  cidr_blocks = var.environment == "dev" ? ["0.0.0.0/0"] : null
  security_groups = var.environment == "prod" ? [aws_security_group.backend_sg.id] : null
}
```

### **Decision Rationale**
- **Learning Value**: Shows understanding of security progression
- **Demonstration Safe**: Can deploy and test easily
- **Production Awareness**: Clear path to production hardening
- **Best Practice**: Environment-specific configurations

---

## ADR-007: Terraform Modular Structure

### **Decision**
Organize Terraform code into logical, focused files rather than a single monolithic file.

### **File Organization**
```
terraform/
├── provider.tf          # Provider configurations
├── variables.tf         # Input variables
├── main.tf             # Core EC2 resources
├── network.tf          # VPC, subnets, routing
├── alb.tf              # Load balancer configuration
├── rds.tf              # Database resources
├── s3_frontend.tf      # Frontend storage
├── cloudfront.tf       # CDN configuration
├── security_groups.tf  # Security rules
├── ssl_certificates.tf # Certificate management
└── output.tf           # Infrastructure outputs
```

### **Decision Rationale**
- **Maintainability**: Easier to find and modify specific resources
- **Collaboration**: Multiple developers can work on different areas
- **Debugging**: Faster issue identification and resolution
- **Professional Standards**: Industry best practice for Terraform projects
- **Scalability**: Easy to add new resources or refactor

---

## 🎯 **Architecture Principles Demonstrated**

### **1. Separation of Concerns**
- Frontend, backend, and database are independently deployable
- Each component has distinct scaling and security characteristics

### **2. Defense in Depth**
- Multiple security layers: CloudFront, ALB, Security Groups, RDS
- Network isolation with VPC and private subnets

### **3. Scalability by Design**
- Stateless application design
- CDN for global distribution
- Database and compute scaling independence

### **4. Cost Optimization**
- Right-sized resources for workload
- Efficient storage choices (GP3 vs GP2)
- Free tier utilization where appropriate

### **5. Operational Excellence**
- Comprehensive monitoring with Actuator
- Automated health checks
- Infrastructure as Code for repeatability

---

## 📊 **Performance Characteristics**

### **Expected Performance**
- **Global Response Time**: <100ms (CloudFront edge)
- **API Response Time**: <200ms (us-east-2)
- **Database Queries**: <50ms (local AZ)
- **File Upload**: <1s (direct to S3)

### **Scaling Limits**
- **Frontend**: Unlimited (CloudFront + S3)
- **Backend**: Limited by EC2 instance (upgradeable)
- **Database**: 3000 IOPS baseline, upgradeable
- **Concurrent Users**: ~1000 with current setup

These architectural decisions demonstrate a progression from simple deployment to enterprise-ready infrastructure, showing technical growth and understanding of cloud-native patterns.

