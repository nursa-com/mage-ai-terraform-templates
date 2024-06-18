app_name        = "dataeng-mage"
app_environment = "prod"
common_tags = {
  Env       = "prod"
  ManagedBy = "terraform"
  Owner     = "data-engineering"
  Service   = "mage"
  Repo      = "nursa-com/mage-ai-terraform-templates"
}
docker_image                = "015782078654.dkr.ecr.us-west-2.amazonaws.com/dataeng-mage:f7557016dbf5cad868b67e5925984ac16a9eab24"
redshift_cluster_id         = "nursa-redshift-cluster-1"
redshift_dbname             = "dev"
redshift_user               = "data_team"
redshift_port               = 5439
redshift_host               = "redshift.prod.nursa.internal"
