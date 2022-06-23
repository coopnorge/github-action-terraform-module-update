# Terraform module update action

 This action will create pull creates for updating your terraform modules lusing latest. Dependabot
  currently has issues with this. As long as dependabot has not fixed this, this action can
  be used. Currently only supports terraform module registry (public/private).
## Inputs

## `directory`

**Required** Directory where the terraform files are.

## `token`

Token for accessing the terraform module registry. For public registries this can be left empty

## `github_token`

**Required** Github token which allows creating pull requests and do a checkout of the code.

## Example usage

uses: coopnorge/github-action-terraform-module-update@v1
with:
  directory: terraform
  token: ${{ secrets.token }}
  github_token: ${{ secrets.github_token }}