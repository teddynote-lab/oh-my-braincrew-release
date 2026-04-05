---
description: "Slack notification standards: alert severity, message formatting, channel routing"
paths: ["**/notifications/**", "**/alerts/**", "**/slack/**"]
---

# Slack Notification Standards

## Alert Severity Levels

| Level | When | Channel | Format |
|-------|------|---------|--------|
| CRITICAL | System down, data loss risk | `#alerts-critical` | Block Kit with red accent |
| WARNING | Degraded performance, approaching limits | `#alerts-warning` | Block Kit with yellow accent |
| INFO | Deployments, scheduled events | `#alerts-info` | Simple message |

## Message Format (Block Kit)

```json
{
  "blocks": [
    {
      "type": "header",
      "text": { "type": "plain_text", "text": "[CRITICAL] Database connection pool exhausted" }
    },
    {
      "type": "section",
      "fields": [
        { "type": "mrkdwn", "text": "*Service:*\napi-server" },
        { "type": "mrkdwn", "text": "*Environment:*\nproduction" },
        { "type": "mrkdwn", "text": "*Time:*\n2026-03-20 14:30 UTC" },
        { "type": "mrkdwn", "text": "*Active Connections:*\n50/50" }
      ]
    },
    {
      "type": "actions",
      "elements": [
        { "type": "button", "text": { "type": "plain_text", "text": "View Dashboard" }, "url": "..." },
        { "type": "button", "text": { "type": "plain_text", "text": "Acknowledge" }, "action_id": "ack_alert" }
      ]
    }
  ]
}
```

## Implementation

- Use incoming webhooks for one-way notifications.
- Use Slack Web API (`@slack/web-api`) for interactive features.
- Store webhook URLs in environment variables — never hardcode.
- Implement rate limiting: max 1 message per minute per alert type (dedup).

## Alert Rules

- Every alert MUST include: severity, service name, environment, timestamp, actionable context.
- CRITICAL alerts must include a link to the relevant dashboard or runbook.
- Avoid alert fatigue: don't alert on expected behavior (scheduled maintenance, test deployments).
- Group related alerts: one message with summary, not N individual messages.

## Channel Organization

| Channel | Purpose |
|---------|---------|
| `#alerts-critical` | Immediate action required |
| `#alerts-warning` | Investigate within hours |
| `#alerts-info` | FYI, no action needed |
| `#deployments` | Deploy start/complete/rollback |

## Anti-Patterns

- Alerting on every error (alert fatigue).
- Alerts without actionable context ("something went wrong").
- Missing severity level — every alert must be classified.
- Webhook URLs committed to source code.
