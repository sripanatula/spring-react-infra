output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.rr_alb.dns_name
}
