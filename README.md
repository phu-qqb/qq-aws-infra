# quantumqb-AWS-migration

Provisioning AWS resources to migrate Quantum Qb workspaces from Azure to AWS infrastructure.

## Purpose

The purpose of this repository is to provide automatization to create the whole bundle of resources to Quantum Qb run on:

- **Structured modules:** Definitions of resources divided by their business workflow application as well by separation by management scenarios: network, access, workstaitons, application servers, storages etc.

## Layout

`terraform/environments/` - here one can find all root TF modules for each environment separated by application. For example: production, staging. Its purpose to keep different configuraions for each run scenario.

`terraform/environments/development` - its the single environment for now to provide temporary starter configuration during developmetn phase.

`terraform/modules/xxx` - place to keep definition of resources for each application.
