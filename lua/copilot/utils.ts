import fs from "fs";
import path from "path";

const CACHE_PATH = path.join(process.env.HOME || "~", ".config", ".copilot");

export type Message = {
  role: "user" | "system";
  content: string;
};

function getRandomUuidv4(): string {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

function getCache() {
  if (!fs.existsSync(CACHE_PATH)) {
    fs.writeFileSync(CACHE_PATH, "{}");
  }

  const rawConfig = fs.readFileSync(CACHE_PATH, "utf-8");
  return JSON.parse(rawConfig);
}

function cacheToken(login: string, githubToken: string) {
  const config = getCache();

  config[login] = githubToken;

  fs.writeFileSync(CACHE_PATH, JSON.stringify(config));
}

function getCachedToken(login?: string): string | null {
  const config = getCache();

  if (!login) {
    // no login provided, we return the first token we find
    for (const key in config) {
      return config[key];
    }
    return null;
  }

  if (login in config) {
    return config[login];
  } else {
    return null;
  }
}

/**
 * Generate a request to send to the API.
 * Creates the prompt containing the chat history and the code if provided.
 *
 * @param chatHistory The chat history to send to the API.
 * @param analyzedCode The code to send to the API.
 * @param language The language of the code.
 *
 * @returns The request to send to the API.
 */
function generateRequest(
  chatHistory: Message[],
  analyzedCode?: string,
  language?: string,
  instructions?: string
) {
  const messages: Message[] = [
    { content: instructions ?? '', role: "system" },
  ];
  for (const message of chatHistory) {
    messages.push({ ...message });
  }
  if (!!analyzedCode) {
    messages.push({
      content: `\nActive selection:\n\`\`\`${
        language || ""
      }\n${analyzedCode}\n\`\`\``,
      role: "system",
    });
  }

  return {
    intent: true,
    model: "copilot-chat",
    n: 1,
    stream: true,
    temperature: 0.1,
    top_p: 1,
    messages,
  };
}

export default {
  cacheToken,
  getCachedToken,
  generateRequest,
  getRandomUuidv4
};
