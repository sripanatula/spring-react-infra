#!/bin/bash

# Set profile and region
PROFILE="default"
REGION="us-east-2"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
AUDIT_DIR="aws_audit_$TIMESTAMP"

# Create output directory
mkdir -p "$AUDIT_DIR"

# Summary file
SUMMARY_FILE="$AUDIT_DIR/summary.txt"

# Audit sections
aws ec2 describe-instances \
  --profile $PROFILE --region $REGION \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags]' \
  --output table > "$AUDIT_DIR/ec2_instances.txt"

aws ec2 describe-security-groups \
  --profile $PROFILE --region $REGION \
  --query 'SecurityGroups[*].[GroupName,GroupId,Description,VpcId]' \
  --output table > "$AUDIT_DIR/security_groups.txt"

aws ec2 describe-vpcs \
  --profile $PROFILE --region $REGION \
  --query 'Vpcs[*].[VpcId,CidrBlock,IsDefault,State]' \
  --output table > "$AUDIT_DIR/vpcs.txt"

aws ec2 describe-addresses \
  --profile $PROFILE --region $REGION \
  --query 'Addresses[*].[PublicIp,InstanceId,AllocationId]' \
  --output table > "$AUDIT_DIR/elastic_ips.txt"

aws ec2 describe-volumes \
  --profile $PROFILE --region $REGION \
  --query 'Volumes[*].[VolumeId,Size,State,AvailabilityZone]' \
  --output table > "$AUDIT_DIR/ebs_volumes.txt"

aws rds describe-db-instances \
  --profile $PROFILE --region $REGION \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,Engine,DBInstanceStatus]' \
  --output table > "$AUDIT_DIR/rds_instances.txt"

aws s3api list-buckets \
  --profile $PROFILE \
  --query 'Buckets[*].Name' \
  --output table > "$AUDIT_DIR/s3_buckets.txt"

aws iam list-users \
  --profile $PROFILE \
  --query 'Users[*].[UserName,CreateDate]' \
  --output table > "$AUDIT_DIR/iam_users.txt"

aws cloudfront list-distributions \
  --profile $PROFILE \
  --query 'DistributionList.Items[*].[Id,Status,Comment,DomainName]' \
  --output table > "$AUDIT_DIR/cloudfront_distributions.txt"

# --- Generate Summary ---
echo "--- AWS Resource Audit Summary ($TIMESTAMP) ---" > "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "EC2 Instances: $(aws ec2 describe-instances --profile $PROFILE --region $REGION --query 'Reservations[*].Instances[*].InstanceId' --output text | wc -w)" >> "$SUMMARY_FILE"
echo "Security Groups: $(aws ec2 describe-security-groups --profile $PROFILE --region $REGION --query 'SecurityGroups[*].GroupId' --output text | wc -w)" >> "$SUMMARY_FILE"
echo "VPCs: $(aws ec2 describe-vpcs --profile $PROFILE --region $REGION --query 'Vpcs[*].VpcId' --output text | wc -w)" >> "$SUMMARY_FILE"
echo "RDS Instances: $(aws rds describe-db-instances --profile $PROFILE --region $REGION --query 'DBInstances[*].DBInstanceIdentifier' --output text | wc -w)" >> "$SUMMARY_FILE"
echo "S3 Buckets: $(aws s3api list-buckets --profile $PROFILE --query 'Buckets[*].Name' --output text | wc -w)" >> "$SUMMARY_FILE"
echo "CloudFront Distributions: $(aws cloudfront list-distributions --profile $PROFILE --query 'DistributionList.Items[*].Id' --output text | wc -w)" >> "$SUMMARY_FILE"
echo "IAM Users: $(aws iam list-users --profile $PROFILE --query 'Users[*].UserName' --output text | wc -w)" >> "$SUMMARY_FILE"

# Optional: zip the folder (commented out by default)
# zip -r "$AUDIT_DIR.zip" "$AUDIT_DIR"

echo "✅ AWS audit completed. Files saved in $AUDIT_DIR/"
echo "📋 Summary:"
cat "$SUMMARY_FILE"
