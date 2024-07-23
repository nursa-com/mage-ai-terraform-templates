app_name        = "dataeng-mage"
app_environment = "prod"

ecs_task_memory     = 24576
ecs_task_cpu        = 8192

common_tags = {
  Env       = "prod"
  ManagedBy = "terraform"
  Owner     = "data-engineering"
  Service   = "mage"
  Repo      = "nursa-com/mage-ai-terraform-templates"
}

redshift_cluster_id = "nursa-redshift-cluster-1"
redshift_dbname     = "dev"
redshift_user       = "data_team"
redshift_port       = 5439
redshift_host       = "redshift.prod.nursa.internal"
