output "elb_dns_name" {
  description = "Public DNS name of Load Balancer"
  value = aws_elb.my-elb.dns_name
}