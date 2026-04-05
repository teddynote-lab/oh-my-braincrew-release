---
description: Configure Slack channel credentials (bot token, signing secret, channel ID)
argument-hint: "<bot-token> <signing-secret> <channel-id>"
---


Save the provided Slack credentials to `~/.claude/channels/slack/.env`:

1. Create directory `~/.claude/channels/slack/` if it doesn't exist
2. Write the `.env` file with:
   - SLACK_BOT_TOKEN=<first argument>
   - SLACK_SIGNING_SECRET=<second argument>
   - SLACK_CHANNEL_ID=<third argument>
3. Set file permissions to 0600

If no arguments provided, ask the user for each value using AskUserQuestion.
