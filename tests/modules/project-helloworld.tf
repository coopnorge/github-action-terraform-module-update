locals {
  helloworld-environments = {
    gcp-project   = ["staging", "production", "shared"]
    azure-project = ["staging", "production", ]
    gke-namespace = ["staging", "production", ]
    tfe-workspace = ["staging", "production", ]
  }
  helloworld = {
    gcp-project   = contains(local.helloworld-environments.gcp-project, var.environment) == true ? 1 : 0
    azure-project = contains(local.helloworld-environments.azure-project, var.environment) == true ? 1 : 0
    gke-namespace = contains(local.helloworld-environments.gke-namespace, var.environment) == true ? 1 : 0
    tfe-workspace = contains(local.helloworld-environments.tfe-workspace, var.environment) == true ? 1 : 0

    gcp_api_services = {
      production = ["secretmanager.googleapis.com", ]
      staging    = ["secretmanager.googleapis.com", "iam.googleapis.com"]
      shared     = ["secretmanager.googleapis.com", "artifactregistry.googleapis.com", "iam.googleapis.com"]
    }
    tfe = {
      working_directory = {
        production = "/terraform"
        staging    = "/terraform"
        shared     = "/terraform-shared"
      }
      repo = {
        production = "coopnorge/helloworld-infrastructure"
        staging    = "coopnorge/helloworld-infrastructure"
        shared     = "coopnorge/helloworld-infrastructure"
      }
      vcs_provider = {
        production = "github"
        staging    = "github"
        shared     = "github"
      }
    }
    costcenter   = "60318"
    servicename  = "helloworld"
    serviceowner = "platform-team"

    service_accounts = {
      production = {}
      staging    = {}
      test       = {}
      shared = {
        helloworld-github-actions = []
      }
    }
    gcp_external_account_access = {
      test = {}
      production = {
        "secrets-reader@apiplatform-production-99cc.iam.gserviceaccount.com" = ["roles/secretmanager.secretAccessor"]
      }
      staging = {
        "secrets-reader@apiplatform-staging-52e7.iam.gserviceaccount.com" = ["roles/secretmanager.secretAccessor"]
      }
      shared = {
        "coronita-gke-sa@apiplatform-staging-52e7.iam.gserviceaccount.com"  = ["roles/artifactregistry.reader"]
        "corona-gke-sa@apiplatform-production-99cc.iam.gserviceaccount.com" = ["roles/artifactregistry.reader"]
      }
    }
  }
}

module "helloworld-gcp-project" {
  count           = local.helloworld.gcp-project
  source          = "terraform.coop.no/coopnorge/new-project/google"
  version         = "1.0.0"
  environment     = var.environment
  datadog_api_key = var.datadog_api_key
  folder_id       = var.folder_id

  project_name      = "helloworld"
  servicename       = local.helloworld.servicename
  owner             = local.helloworld.serviceowner
  costcenter        = local.helloworld.costcenter
  services          = local.helloworld.gcp_api_services[var.environment]
  service_accounts  = local.helloworld.service_accounts[var.environment]
  external_accounts = local.helloworld.gcp_external_account_access[var.environment]

  # remove after migrate
  disable_dependent_services  = false
  services_disable_on_destroy = false

  monthly_budget          = 150
  notification_thresholds = [50, 75, 100]
  budget_notification_emails = [
    "607387c5.o365.coop.no@no.teams.ms", // teams channel "team-helloworld-alerts"
    "frank.thingelstad@coop.no",
  ]

  teams = {
    "engineering-guild" = ["roles/reader", ],
    "platform-guild"    = ["roles/reader", ],
  }
}

module "helloworld-namespace" {
  depends_on = [module.helloworld-gcp-project]
  count      = local.helloworld.gke-namespace
  source     = "terraform.coop.no/coopnorge/gke-namespace/google"
  version    = "1.0.1"

  service_project_id = module.helloworld-gcp-project[0].project_id
  cluster_project_id = var.cluster_project_id
  cluster_name       = var.cluster_name
  environment        = var.environment
  region             = var.region
  namespace_name     = "helloworld"
  quota_cpu          = "1"
  quota_memory       = "1Gi"

  teams = {
    "engineering-guild" = ["reader", ],
    "platform-guild"    = ["reader", ],
  }
}

module "helloworld-azure" {
  count   = local.helloworld.azure-project
  source  = "terraform.coop.no/coopnorge/new-project/azure"
  version = "~> 1"
  providers = {
    azurerm.hub = azurerm.hub
  }

  environment             = var.environment
  servicename             = local.helloworld.servicename
  owner                   = local.helloworld.serviceowner
  costcenter              = local.helloworld.costcenter
  monthly_budget          = 100
  notification_thresholds = [50, 75, 100]

  budget_notification_emails = [
    "607387c5.o365.coop.no@no.teams.ms", // teams channel "team-helloworld-alerts"
    "frank.thingelstad@coop.no",
  ]

  teams = {
    "engineering-guild" = ["Viewer", ],
    "platform-guild"    = ["Viewer", ],
  }
}

module "helloworld_example_password" {
  source      = "terraform.coop.no/coopnorge/secrets-generator/terraform"
  version     = "1.0.0"
  secret_kind = "password"
}

module "helloworld_example_tls_key" {
  source      = "terraform.coop.no/coopnorge/secrets-generator/terraform"
  version     = "1.0.0"
  secret_kind = "password"
}


module "helloworld_github_repo_infrastructure" {
  count   = var.environment == "production" ? 1 : 0
  source  = "terraform.coop.no/coopnorge/repos/github"
  version = "1.12.0-beta1"

  name                    = "helloworld-infrastructure"
  required_linear_history = false
  has_issues              = true
  has_projects            = true
  allow_auto_merge        = true

  action_secrets = {
    EXAMPLE_PASS     = module.helloworld_example_password.password
    EXAMPLE_PUB_KEY  = module.helloworld_example_tls_key.tls_public_key_openssh
    EXAMPLE_PRIV_KEY = module.helloworld_example_tls_key.tls_private_key_openssh
  }

  teams = {
    "engineering-guild" = {
      permission = "push"
    }
    "platform-guild" = {
      permission = "push"
    }
    "cloud-platform" = {
      permission = "push"
    }
    "engineering" = {
      permission = "push"
    }
    "github-review-bots" = {
      permission = "push"
    }
  }

  status_checks = [
    "build"
  ]

  install_writeback_to_pr_app = true
}

module "helloworld_github_repo" {
  count   = var.environment == "production" ? 1 : 0
  source  = "terraform.coop.no/coopnorge/repos/github"
  version = "1.12.0"

  name                    = "helloworld"
  required_linear_history = false
  has_issues              = true
  has_projects            = true
  allow_auto_merge        = true

  teams = {
    "engineering-guild" = {
      permission = "push"
    }
    "platform-guild" = {
      permission = "push"
    }
    "cloud-platform" = {
      permission = "push"
    }
    "engineering" = {
      permission = "push"
    }
  }

  status_checks = [
    "build"
  ]

  install_writeback_to_pr_app = true
  setup_reviewbot_githubtoken = true
  reviewbot_token             = var.reviewbot_token
}

module "helloworld-tfe-workspace" {
  count                = local.helloworld.tfe-workspace
  source               = "terraform.coop.no/coopnorge/new-workspace/tfe"
  version              = "1.1.0"
  ado_oauth_token      = var.ado_oauth_token
  azdo_access_token    = var.azdo_access_token
  azdo_access_username = var.azdo_access_username
  environment          = var.environment
  github_oauth_token   = var.github_oauth_token

  project_name      = "helloworld"
  repo_vcs_provider = local.helloworld.tfe.vcs_provider[var.environment]
  repo_identifier   = local.helloworld.tfe.repo[var.environment]
  auto_apply        = ["staging", "production"]
  working_directory = local.helloworld.tfe.working_directory[var.environment]

  teams = {
    "engineering-guild" = {
      workspace_admins  = true
      workspace_users   = false
      workspace_readers = false
    }
    "platform-guild" = {
      workspace_admins  = true
      workspace_users   = false
      workspace_readers = false
    }
  }

  variables = [
    {
      key         = "rg_name"
      value       = module.helloworld-azure[0].resourcegroup_name,
      sensitive   = false
      description = "Name of azure resourcegroup"
    },
    {
      key         = "kv_name"
      value       = module.helloworld-azure[0].keyvault_name,
      sensitive   = false
      description = "Name of azure keyvault"
    },
    {
      key         = "client_id"
      value       = module.helloworld-azure[0].serviceprincipal_id,
      sensitive   = false
      description = "Azure client id"
    },
    {
      key         = "client_secret"
      value       = module.helloworld-azure[0].serviceprincipal_secret,
      sensitive   = true
      description = "Azure client secret"
    },
    {
      key         = "project_id"
      value       = module.helloworld-gcp-project[0].project_id,
      sensitive   = false
      description = "Google Project Id"
    },
    {
      key         = "credentials"
      value       = base64decode(module.helloworld-gcp-project[0].terraform_service_account_key),
      sensitive   = true
      description = "Google credentials"
    },
  ]
}

module "helloworld-tfe-workspace_shared" {
  count                = var.environment == "shared" ? 1 : 0
  source               = "terraform.coop.no/coopnorge/new-workspace/tfe"
  version              = "1.1.0"
  ado_oauth_token      = var.ado_oauth_token
  azdo_access_token    = var.azdo_access_token
  azdo_access_username = var.azdo_access_username
  environment          = var.environment
  github_oauth_token   = var.github_oauth_token

  project_name      = "helloworld"
  repo_vcs_provider = local.helloworld.tfe.vcs_provider[var.environment]
  repo_identifier   = local.helloworld.tfe.repo[var.environment]
  auto_apply        = ["shared"]
  working_directory = local.helloworld.tfe.working_directory[var.environment]

  teams = {
    "engineering-guild" = {
      workspace_admins  = true
      workspace_users   = false
      workspace_readers = false
    }
    "platform-guild" = {
      workspace_admins  = true
      workspace_users   = false
      workspace_readers = false
    }
  }

  variables = [
    {
      key         = "project_id"
      value       = module.helloworld-gcp-project[0].project_id,
      sensitive   = false
      description = "Google Project Id"
    },
    {
      key         = "credentials"
      value       = base64decode(module.helloworld-gcp-project[0].terraform_service_account_key),
      sensitive   = true
      description = "Google credentials"
    },
  ]
}
