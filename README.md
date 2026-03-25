# ECS Sandbox

A Terraform project that provisions a containerized application on AWS ECS Fargate behind an Application Load Balancer, inside a custom VPC.

---

## Architecture

```
                          Internet
                             │
                             ▼
                    ┌─────────────────┐
                    │  ALB (public)   │  port 80
                    │  alb-sg         │  0.0.0.0/0 → :80
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │         VPC 10.0.0.0/16      │
              │                              │
              │  Public Subnets              │
              │  ┌──────────┐ ┌──────────┐  │
              │  │10.0.1.0/24│ │10.0.2.0/24│ │
              │  └────┬─────┘ └────┬─────┘  │
              │       │  NAT GW    │         │
              │       └─────┬──────┘         │
              │             │                │
              │  Private Subnets             │
              │  ┌──────────┐ ┌──────────┐  │
              │  │10.0.11.0/24│ │10.0.12.0/24││
              │  │           │ │          │  │
              │  │ ECS Task  │ │ ECS Task │  │
              │  │ (Fargate) │ │ (Fargate)│  │
              │  │  ecs-sg   │ │  ecs-sg  │  │
              │  └──────────┘ └──────────┘  │
              │                              │
              └──────────────────────────────┘

  State Backend: S3 (ecs-sanbox-vrv) + native lock file
```

---

## Resources Provisioned

| Resource | Name | Description |
|---|---|---|
| VPC | `demo-ecs-sandbox-vpc` | 10.0.0.0/16, DNS enabled |
| Public Subnets | 10.0.1.0/24, 10.0.2.0/24 | us-east-1a, us-east-1b |
| Private Subnets | 10.0.11.0/24, 10.0.12.0/24 | us-east-1a, us-east-1b |
| NAT Gateway | single | Outbound internet for private subnets |
| ECS Cluster | `demo-ecs-sandbox-cluster` | Fargate capacity provider |
| ECS Task Definition | `demo-ecs-sandbox-task` | 256 CPU / 512 MB, awsvpc mode |
| ECS Service | `demo-ecs-sandbox-svc` | 2 desired tasks, Fargate |
| ALB | `demo-ecs-sandbox-alb` | Internet-facing, port 80 |
| Target Group | `demo-ecs-sandbox-tg` | IP target type, health check `/` |
| ALB Listener | HTTP:80 | Forwards to target group |
| Security Group (ALB) | `demo-ecs-sandbox-alb-sg` | Inbound 80 from 0.0.0.0/0 |
| Security Group (ECS) | `demo-ecs-sandbox-ecs-sg` | Inbound from ALB SG only |
| IAM Role | `demo-ecs-sandbox-task-execution-role` | ECS task execution role |
| S3 Backend | `ecs-sanbox-vrv` | Remote Terraform state |

---

## File Structure

```
ecs-sandbox/
├── providers.tf        # AWS provider + Terraform version constraints
├── backend.tf          # S3 remote state backend
├── variables.tf        # Input variable declarations
├── terraform.tfvars    # Variable values (region, image, desired_count)
├── main-vpc.tf         # VPC module + ECS cluster module + common_tags local
├── main-alb.tf         # Security groups, ALB, target group, listener
├── main-service.tf     # IAM role, task definition, ECS service
└── output.tf           # Outputs: ALB DNS, cluster name, VPC ID
```

---

## Variables

| Variable | Default | Description |
|---|---|---|
| `region` | `us-east-1` | AWS region |
| `project_name` | `ecs-sandbox` | Resource name prefix (overridden to `demo-ecs-sandbox` in tfvars) |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `public_subnets` | `["10.0.1.0/24","10.0.2.0/24"]` | Public subnet CIDRs |
| `private_subnets` | `["10.0.11.0/24","10.0.12.0/24"]` | Private subnet CIDRs |
| `container_image` | `public.ecr.aws/docker/library/nginx:stable` | Container image to run |
| `container_port` | `80` | Port the container listens on |
| `desired_count` | `1` | Number of ECS tasks (overridden to `2` in tfvars) |

---

## Outputs

| Output | Description |
|---|---|
| `alb_dns_name` | Public DNS of the ALB — use this to access the app |
| `cluster_name` | ECS cluster name |
| `vpc_id` | VPC ID |

---

## Usage

### Prerequisites
- Terraform >= 1.5.0
- AWS credentials configured
- S3 bucket `ecs-sanbox-vrv` created in `us-east-1`

### Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Access the app

```bash
terraform output alb_dns_name
# Open the returned URL in a browser
```

### Destroy

```bash
terraform destroy
```

---

## Networking & Security

- ECS tasks run in **private subnets** — not directly reachable from the internet.
- Only the **ALB security group** can reach ECS tasks on the container port.
- Outbound internet access for tasks (e.g. pulling images) goes through the **single NAT Gateway** in the public subnet.
- ALB is **internet-facing** and accepts HTTP on port 80.

---

## Modules Used

| Module | Source | Version |
|---|---|---|
| VPC | `terraform-aws-modules/vpc/aws` | ~> 5.0 |
| ECS Cluster | `terraform-aws-modules/ecs/aws//modules/cluster` | ~> 5.0 |
# ecs-sandbox
