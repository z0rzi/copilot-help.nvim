#!/usr/bin/env -S sh -c '"`dirname $0`/bun" "$0" "$@"'

import fs from 'fs';

import CopilotSession from "./copilot";

const copilot = new CopilotSession();

const rawConversation = fs.readFileSync('/tmp/ai-chat.txt', "utf-8");

const lines = rawConversation.split("\n");

let messageLines = [] as string[];
let speaker = "system" as "system" | "user";
for (const line of lines) {
  if (line.startsWith("===") && line.endsWith("===")) {
    if (messageLines.length > 0) {
      copilot.addMessageToConversation(messageLines.join("\n"), speaker);
      messageLines = [];
    }

    const rawSpeaker = line.replace(/=+/g, "").trim().toLowerCase();

    if (
      rawSpeaker === "ai" ||
      rawSpeaker === "copilot" ||
      rawSpeaker === "system"
    ) {
      speaker = "system";
    } else {
      speaker = "user";
    }

    continue;
  }

  messageLines.push(line);
}

if (messageLines.length > 0) {
  copilot.ask(messageLines.join("\n")).then((response) => {
    console.log(response);
  })
}
