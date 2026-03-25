output "alb_dns_name" {
  description = "Public URL for the sandbox service"
  value       = aws_lb.app.dns_name
}

output "cluster_name" {
  value = module.ecs_cluster.name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
