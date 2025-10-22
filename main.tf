module "snapshot_lambda" {
    source                 = "./modules/lambda_deploy"
    function_name          = "snapshot-lifecycle"
    function_description   = "EC2 Snapshot Lifecycle management Lambda"
    lambda_env_vars        = var.lambda_env_vars
    lambda_timeout         = 300
    lambda_mem_limit       = 256
    lambda_role_arn        = 

}

module "snapshot_step_function" {
  source                 = "./modules/lambda_steps"
  function_name          = "snapshot_Lifecycle"
  lambda_function_arn    = module.snapshot_lambda.lambda_function_arn
}

module "snapshot_eventbridge" {
  source                 = "./modules/lambda_events"
  function_name          = "snapshot_lifecycle_events"
  step_function_arn      = module.snapshot_step_function.step_function_arn
  step_function_role     = module.snapshot_step_function.step_function_role_arn
  snapshot_checker_roles = var.snapshot_checker_roles
}
