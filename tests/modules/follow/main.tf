module "helloworld_github_repo" {
  source  = "terraform.coop.no/coopnorge/repos/github"
  version = "~> 1.0"
  name    = "helloworld"
}