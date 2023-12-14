data "aws_secretsmanager_secret" "atlantis_github_secrets" {
  name = "atlantis/github-app-credentials"
}

data "aws_secretsmanager_secret_version" "atlantis_github_secrets_latest" {
  secret_id = data.aws_secretsmanager_secret.atlantis_github_secrets.id
}

module "atlantis" {
  source  = "terraform-aws-modules/atlantis/aws"

  name = "atlantis"

  # ECS Container Definition
  atlantis = {
    environment = [
      {
        name  = "ATLANTIS_REPO_ALLOWLIST"
        value = "github.com/nursa-com/*"
      },
    ]
    secrets = [
      {
        name  = "ATLANTIS_GH_APP_ID"
        valueFrom = "arn:aws:secretsmanager:us-west-2:015782078654:secret:atlantis/github-app-id-wTpT3T"
      },
      {
        name  = "ATLANTIS_GH_APP_KEY"
        valueFrom = "arn:aws:secretsmanager:us-west-2:015782078654:secret:atlantis/github-app-key-Hh7qOj"
      },
      {
        name  = "ATLANTIS_GH_WEBHOOK_SECRET"
        valueFrom = "arn:aws:secretsmanager:us-west-2:015782078654:secret:atlantis/github-webook-secret-ivKF9J"
      },
    ]
  }

  # ECS Service
  service = {
    # Provide Atlantis permission necessary to create/destroy resources
    tasks_iam_role_policies = {
      AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
    }
  }
  service_subnets = [data.aws_subnet.subnet_1.id, data.aws_subnet.subnet_2.id]
  vpc_id          = data.aws_vpc.aws-vpc.id

  # ALB
  alb_subnets             = [data.aws_subnet.subnet_1.id, data.aws_subnet.subnet_2.id]
  certificate_domain_name = data.aws_acm_certificate.cert.domain
  route53_zone_id         = data.aws_route53_zone.nursa_dataeng.zone_id

  tags = {
      Service  = "atlantis"   
      ManagedBy = "Terraform"
      Owner     = "data-engineering"
      Name = "dataeng-atlantis"
    }
}