#!/usr/bin/env -S sh -c '"`dirname $0`/bun" "$0" "$@"'

import fs from "fs";

import CopilotSession from "./copilot";
import { checkGithubAuth } from "./github-utils";

let mode: string | null = null;
let args = [] as string[];
let coreInstruction = "";

const allArgs = process.argv.slice(2);
while (allArgs.length > 0) {
  const arg = allArgs.shift();
  if (!arg) break;

  if (arg.startsWith("--")) {
    if (arg.startsWith("--core_instruction_file")) {
      const [_, coreInstructionFile] = arg.split("=");

      if (fs.existsSync(coreInstructionFile)) {
        coreInstruction = fs.readFileSync(coreInstructionFile, "utf-8");
      }
    }
    continue;
  }

  if (mode === null) {
    mode = arg;
  } else {
    args.push(arg);
  }
}

let copilot: CopilotSession;

switch (mode) {
  case "connect":
    const deviceCode = args[0];
    await checkGithubAuth(deviceCode.trim())
    break;
  case "chat":
    copilot = new CopilotSession();
    if (coreInstruction) {
      copilot.coreInstructions = coreInstruction;
    }
    const rawConversation = fs.readFileSync(
      args[0],
      "utf-8"
    );

    const lines = rawConversation.split("\n");

    let messageLines = [] as string[];
    let speaker = "system" as "system" | "user";
    for (const line of lines) {
      if (line.startsWith("# ===") && line.endsWith("===")) {
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
      const lastMessage = messageLines.join("\n");
      copilot.ask(lastMessage).then((response) => {
        console.log(response);
      });
    }
    break;
  case "macro":
    copilot = new CopilotSession();
    if (coreInstruction) {
      copilot.coreInstructions = coreInstruction;
    }

    const macroPath = args[0];
    const codePath = args[1];

    if (!fs.existsSync(macroPath)) {
      console.log(`This macro does not exist...`);
      process.exit(1);
    }

    const macro = fs.readFileSync(macroPath, "utf-8");
    const code = fs.readFileSync(codePath, "utf-8");

    copilot.addMessageToConversation('From now on, only the code blocks will be kept from your answer, so if you give additional information, do it in the form of comments in the code itself.\nRemember to always delimit your code with 3 backticks (```).', 'system');
    copilot.addMessageToConversation('Analysed code : ' + '\n' + code + '\n\nInstructions:\n' + macro, 'user');

    copilot.ask(macro, code).then((response) => {
      // only keeping the code part of the answer
      let codeStarted = false;

      for (const line of response.split("\n")) {
        if (line.startsWith("```")) {
          if (!codeStarted) {
            codeStarted = true;
            continue;
          } 
          // code ended
          process.exit(0);
        }

        if (codeStarted) {
          console.log(line);
        }
      }

      if (!codeStarted) {
        // no code found in the answer... We just print the whole answer
        console.log(response);
      }
    })
}
