# React + Spring Boot Infrastructure Deployment Guide

## 🏗️ Infrastructure Changes Made

### New Components Added:
1. **S3 Bucket** (`s3_frontend.tf`) - Hosts React build files
2. **CloudFront Distribution** (`cloudfront.tf`) - Global CDN with dual origins
3. **Updated ALB Configuration** - Now API-only, port 8080
4. **Updated Security Groups** - Allow Spring Boot port 8080

### Modified Components:
- **ALB Target Group**: Now targets port 8080 (Spring Boot default)
- **Health Check**: Updated to `/api/health` endpoint
- **Security Groups**: Allow port 8080 from ALB

## 🚀 Deployment Steps

### 1. Update Terraform Infrastructure
```bash
cd terraform/
terraform plan
terraform apply
```

### 2. Configure Your Java Spring Boot Application

#### Add CORS Configuration
Add this to your Spring Boot application:

```java
@Configuration
@EnableWebSecurity
public class WebConfig implements WebMvcConfigurer {
    
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOriginPatterns("https://*.cloudfront.net", "https://your-domain.com")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }
}
```

#### Update Application Properties
```properties
# application.properties
server.port=8080
server.servlet.context-path=/api

# CORS settings
spring.web.cors.allowed-origins=https://*.cloudfront.net
spring.web.cors.allowed-methods=GET,POST,PUT,DELETE,OPTIONS
spring.web.cors.allowed-headers=*
spring.web.cors.allow-credentials=true

# Database connection (use RDS endpoint from terraform output)
spring.datasource.url=jdbc:postgresql://${RDS_ENDPOINT}:5432/myapp
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}

# JWT configuration
jwt.secret=${JWT_SECRET}
jwt.expiration=86400000
```

#### Enable Spring Boot Actuator Health Endpoints
Spring Boot Actuator provides comprehensive health monitoring out of the box!

**Add to your `pom.xml`:**
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

**Update `application.properties`:**
```properties
# Actuator endpoints configuration
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=when-authorized
management.endpoint.health.show-components=always
management.health.db.enabled=true
management.health.diskspace.enabled=true

# Health endpoint specific settings
management.endpoints.web.base-path=/api/actuator
management.endpoint.health.group.readiness.include=readinessState,db
management.endpoint.health.group.liveness.include=livenessState,diskSpace
```

**What you get automatically:**
- `/api/actuator/health` - Overall application health
- `/api/actuator/health/readiness` - Kubernetes readiness probe
- `/api/actuator/health/liveness` - Kubernetes liveness probe
- Database connectivity checks
- Disk space monitoring
- Custom health indicators (if you add them)

**Example Health Response:**
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "PostgreSQL",
        "validationQuery": "isValid()"
      }
    },
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 21474836480,
        "free": 18253611008,
        "threshold": 10485760,
        "exists": true
      }
    }
  }
}
```

### 3. Build and Deploy Java Application

#### Docker Deployment (Recommended)
```dockerfile
FROM openjdk:17-jdk-slim

WORKDIR /app
COPY target/myapp-backend.jar app.jar

EXPOSE 8080

ENV RDS_ENDPOINT=your-rds-endpoint
ENV DB_USERNAME=postgres
ENV DB_PASSWORD=your-password
ENV JWT_SECRET=your-jwt-secret

CMD ["java", "-jar", "app.jar"]
```

#### Deploy to EC2
```bash
# SSH to EC2 instance
ssh -i ~/.ssh/myapp-key.pem ec2-user@<EC2_IP>

# Install Docker
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo usermod -a -G docker ec2-user

# Pull and run your application
docker run -d \
  -p 8080:8080 \
  -e RDS_ENDPOINT=<terraform-output-rds-endpoint> \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=<your-password> \
  -e JWT_SECRET=<your-secret> \
  --name myapp-backend \
  your-dockerhub-username/myapp-backend:latest
```

### 4. Build and Deploy React Application

#### Environment Configuration
```javascript
// .env.production
REACT_APP_API_URL=https://your-cloudfront-domain.cloudfront.net/api

// .env.development  
REACT_APP_API_URL=http://localhost:8080/api
```

#### API Service Configuration
```javascript
// src/services/api.js
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL;

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// JWT token interceptor
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default apiClient;
```

#### Build and Deploy React App
```bash
# Build React app for production
npm run build

# Deploy to S3 (get bucket name from terraform output)
aws s3 sync build/ s3://myapp-frontend-<random-suffix> --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id <cloudfront-distribution-id> \
  --paths "/*"
```

## 🔐 Security Considerations

### Immediate Actions:
1. **Restrict RDS Access**: Update RDS security group to only allow backend SG
2. **Add SSL Certificates**: Implement HTTPS for both CloudFront and ALB
3. **Environment Variables**: Store secrets in AWS Systems Manager Parameter Store
4. **Remove SSH Access**: Use AWS Systems Manager Session Manager instead

### Production Hardening:
```hcl
# Update RDS security group (in security_groups.tf)
resource "aws_security_group" "rds_sg" {
  name        = "myapp-rds-sg"
  description = "Allow PostgreSQL access from backend only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]  # Only from backend
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "myapp-rds-sg"
  }
}
```

## 📊 Traffic Flow

```
User Request → CloudFront → 
  ├── Static Assets (React) → S3 Bucket
  └── /api/* requests → ALB → EC2 (Spring Boot:8080) → RDS PostgreSQL
```

## 🧪 Testing

### Frontend Testing:
```bash
# Access your React app
https://<cloudfront-domain>.cloudfront.net
```

### API Testing:
```bash
# Spring Boot Actuator Health Check
curl https://<cloudfront-domain>.cloudfront.net/api/actuator/health

# Detailed health info (if configured)
curl https://<cloudfront-domain>.cloudfront.net/api/actuator/health/db

# Application metrics
curl https://<cloudfront-domain>.cloudfront.net/api/actuator/metrics

# Authentication test
curl -X POST https://<cloudfront-domain>.cloudfront.net/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'
```

### Spring Boot Actuator Benefits:
- **Database Health**: Automatic PostgreSQL connection monitoring
- **Memory Usage**: JVM heap and non-heap memory stats
- **HTTP Metrics**: Request counts, response times, error rates
- **Custom Metrics**: Add business-specific metrics easily
- **Application Info**: Build version, Git commit, deployment info

## 📝 Next Steps

1. **Custom Domain**: Add Route 53 and ACM certificates
2. **Monitoring**: Add CloudWatch dashboards and alarms
3. **CI/CD**: Set up GitHub Actions for automated deployments
4. **Backup Strategy**: Configure automated RDS backups and S3 versioning
5. **Scaling**: Consider auto-scaling groups and multi-AZ deployment

