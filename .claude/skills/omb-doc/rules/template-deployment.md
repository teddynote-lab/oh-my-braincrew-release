---
title: Deployment Document Template
impact: HIGH
tags: template, deployment, infra, runbook
---

## Deployment Document Template

Deployment documents record how a service is built, shipped, and operated. They exist so any engineer can deploy or recover the service without asking the original author. Use this template for every new file in `docs/deployment/`.

A deployment doc has two audiences: someone doing a planned deployment and someone waking up at 3am to fix a broken one. Both must be able to follow it without context.

**Incorrect (missing structure, no runbook, commands not verified):**

```markdown
---
title: Deploy the App
status: active
---

## Deployment

Run `make deploy` to deploy. Make sure you have AWS access.

If something breaks, check the logs.
```

**Correct (full template with all required sections):**

```markdown
---
title: [Service Name] Deployment
category: deployment
status: draft | active | deprecated
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: deployment, [service-name], [cloud-provider]
relates-to: src/[service-path]
depends-on: docs/deployment/_overview.md
---

# [Service Name] Deployment

## Overview

One paragraph describing what this service does, how it is deployed (container,
serverless, VM), which cloud provider and region it targets, and what a normal
deployment cycle looks like (e.g., "deployed via GitHub Actions on every push to
`main`; staging and production are separate stacks").

---

## Architecture Diagram

<!-- Show deployment topology: where code runs, how traffic reaches it,
     which external services it depends on. Keep to ≤ 15 nodes. -->

\`\`\`mermaid
graph TD
    GH[GitHub Actions] -->|docker push| ECR[AWS ECR]
    ECR -->|pull| ECS[ECS Fargate]
    ECS -->|reads/writes| RDS[(PostgreSQL RDS)]
    ECS -->|cache| REDIS[(Redis ElastiCache)]
    CF[CloudFront CDN] -->|origin| ECS
    USER[User] -->|HTTPS| CF
\`\`\`

---

## Prerequisites

List every tool, access grant, and credential required before running any
deployment command. An engineer setting up for the first time must be able to
complete this list independently.

- **Tools**
  - `aws-cli >= 2.x` — `brew install awscli`
  - `docker >= 24.x` — `brew install --cask docker`
  - `terraform >= 1.7` — `brew install terraform`
  - `make` — included with Xcode Command Line Tools
- **Access**
  - AWS IAM role `deploy-[service]-[env]` — request via Slack `#infra-access`
  - GitHub environment `production` approval — requires team lead approval
  - Read access to `1Password` vault `[Service] Production Secrets`
- **Local Setup**
  - Run `./scripts/setup-deploy-env.sh` to configure AWS profiles
  - Verify access: `aws sts get-caller-identity --profile [service]-prod`

---

## Environment Configuration

All environment variables must be present in the target environment before
deployment. `Required: yes` means the service will refuse to start without it.

| Variable | Required | Default | Description |
|---|---|---|---|
| `DATABASE_URL` | yes | — | PostgreSQL connection string (from secrets manager) |
| `REDIS_URL` | yes | — | Redis connection string |
| `APP_SECRET_KEY` | yes | — | 32-byte random hex for session signing |
| `LOG_LEVEL` | no | `info` | Logging verbosity: `debug`, `info`, `warn`, `error` |
| `PORT` | no | `8000` | HTTP port the service binds to |
| `SENTRY_DSN` | no | — | Sentry error tracking DSN; omit to disable |
| `FEATURE_FLAG_[NAME]` | no | `false` | Toggle for in-progress features |

Secrets are stored in AWS Secrets Manager under the path
`/[service]/[environment]/`. Load them with:

\`\`\`bash
aws secretsmanager get-secret-value \
  --secret-id /[service]/production/ \
  --query SecretString \
  --output text | jq .
\`\`\`

---

## Deployment Steps

Run steps in order. Do not skip. Each step includes a verification command to
confirm it succeeded before moving to the next.

1. **Pull latest and verify CI is green**

   \`\`\`bash
   git checkout main && git pull
   # Confirm the latest commit passed CI before continuing
   gh run list --limit 1
   \`\`\`

2. **Build and tag the Docker image**

   \`\`\`bash
   make build VERSION=$(git rev-parse --short HEAD)
   docker images | grep [service-name]
   \`\`\`

3. **Run integration tests against the staging environment**

   \`\`\`bash
   make test-integration ENV=staging
   # All tests must pass before promoting to production
   \`\`\`

4. **Push image to ECR**

   \`\`\`bash
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin \
     [account-id].dkr.ecr.us-east-1.amazonaws.com

   make push VERSION=$(git rev-parse --short HEAD)
   \`\`\`

5. **Deploy to production**

   \`\`\`bash
   make deploy ENV=production VERSION=$(git rev-parse --short HEAD)
   # This triggers ECS to perform a rolling replacement of tasks
   \`\`\`

6. **Verify the deployment**

   \`\`\`bash
   # Wait for tasks to stabilize (typically 2-3 minutes)
   aws ecs wait services-stable \
     --cluster [cluster-name] \
     --services [service-name]

   # Confirm the health endpoint returns 200
   curl -sf https://[service-domain]/health | jq .
   \`\`\`

---

## Rollback Procedure

Use this when a deployment causes errors and must be reversed quickly. The goal
is to restore the last known-good version within 5 minutes.

1. **Identify the last good image tag**

   \`\`\`bash
   # List the last 5 deployed image tags
   aws ecr describe-images \
     --repository-name [service-name] \
     --query 'sort_by(imageDetails, &imagePushedAt)[-5:].imageTags' \
     --output json
   \`\`\`

2. **Redeploy the previous tag**

   \`\`\`bash
   make deploy ENV=production VERSION=[previous-tag]
   \`\`\`

3. **Confirm rollback succeeded**

   \`\`\`bash
   aws ecs wait services-stable \
     --cluster [cluster-name] \
     --services [service-name]

   curl -sf https://[service-domain]/health | jq .
   \`\`\`

4. **Create an incident ticket** referencing the bad tag and link it in
   `#incidents` Slack channel.

---

## Monitoring and Alerts

The on-call engineer responds to all CRITICAL alerts within 15 minutes.
WARNING alerts are investigated within 1 business day.

| Metric | Threshold | Severity | Action |
|---|---|---|---|
| HTTP 5xx error rate | > 1% over 5 min | CRITICAL | Page on-call, begin rollback |
| P99 response latency | > 2000ms over 5 min | WARNING | Check slow query log, scale if needed |
| ECS task restarts | > 3 in 10 min | CRITICAL | Check container logs, consider rollback |
| Database connection pool | > 80% utilization | WARNING | Review query patterns, scale read replicas |
| Disk usage (RDS) | > 75% | WARNING | Trigger manual snapshot, plan storage increase |
| CPU utilization (ECS) | > 85% over 10 min | WARNING | Scale out task count |

Dashboard: [Link to CloudWatch / Grafana / Datadog dashboard]

Runbook alerts link directly to the relevant runbook section below.

---

## Runbook

Step-by-step procedures for common operational tasks. Each task is self-contained.

### Scale ECS task count

\`\`\`bash
aws ecs update-service \
  --cluster [cluster-name] \
  --service [service-name] \
  --desired-count [N]
\`\`\`

### Force a new deployment (without a new image)

Useful after updating environment variables or task definition parameters.

\`\`\`bash
aws ecs update-service \
  --cluster [cluster-name] \
  --service [service-name] \
  --force-new-deployment
\`\`\`

### Tail live application logs

\`\`\`bash
aws logs tail /ecs/[service-name] \
  --follow \
  --since 15m \
  --format short
\`\`\`

### Connect to a running container (debug shell)

\`\`\`bash
aws ecs execute-command \
  --cluster [cluster-name] \
  --task [task-arn] \
  --container [service-name] \
  --command "/bin/sh" \
  --interactive
\`\`\`

### Rotate database credentials

1. Generate new credentials in AWS Secrets Manager:
   `aws secretsmanager rotate-secret --secret-id /[service]/production/DATABASE_URL`
2. Trigger a force-new-deployment (see above) so tasks pick up the new secret.
3. Verify health endpoint returns 200 after tasks stabilize.

---

## Changelog

| Date | Change | Breaking |
|---|---|---|
| YYYY-MM-DD | Initial document | no |
```

Reference: [AWS ECS Rolling Deployments](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-ecs.html)
