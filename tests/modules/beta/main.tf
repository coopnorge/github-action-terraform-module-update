module "helloworld_github_repo" {
  source  = "terraform.coop.no/coopnorge/repos/github"
  version = "1.12.1-beta1"
  name    = "helloworld"
}