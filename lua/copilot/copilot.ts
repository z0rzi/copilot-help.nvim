import { githubAuthenticate } from "./github-utils";
import { Message } from "./utils";
import Utils from "./utils";

type CopilotToken = {
  token: string;
  expires_at: string;
};

export default class CopilotSession {
  github_token: string | null = null;
  vscode_sessionid: string | null = null;
  token: { token: string } | null = null;
  machineid: string = Math.floor(Math.random() * 100000000000).toString(16);

  coreInstructions: string = "";

  chatHistory: Message[] = [];

  private readyResolve: () => void = () => {};
  ready: Promise<void> = new Promise((resolve) => {
    this.readyResolve = resolve;
  });

  constructor() {
    this.github_token = Utils.getCachedToken();

    if (!this.github_token) {
      githubAuthenticate()
        .then((token) => {
          this.github_token = token;
          return this.authenticate();
        })
        .then(() => {
          this.readyResolve();
        });
    } else {
      this.authenticate().then(() => {
        this.readyResolve();
      });
    }
  }

  /**
   * Authenticate with the Copilot API.
   */
  private async authenticate(): Promise<void> {
    if (this.github_token === null) {
      throw new Error("No token found");
    }
    this.vscode_sessionid =
      Utils.getRandomUuidv4() + String(Math.round(new Date().getTime()));

    const url = "https://api.github.com/copilot_internal/v2/token";
    const headers = {
      authorization: `token ${this.github_token}`,
      "editor-version": "vscode/1.80.1",
      "editor-plugin-version": "copilot-chat/0.4.1",
      "user-agent": "GitHubCopilotChat/0.4.1",
    };

    const response = await fetch(url, {
      method: "GET",
      headers,
    }).catch((err) => {
      console.log(
        "There was a problem when trying to authenticate to GitHub:\n"
      );
      console.log(err);
      console.log("\n\nMake sure you're connected to the internet.");
      process.exit(1);
    });

    this.token = (await response.json()) as CopilotToken;
  }

  private parseRawMessage(lines: string[]): string {
    let fullResponse = "";

    for (const line of lines) {
      if (line === "[DONE]") {
        break;
      }

      let parsedLine = null as null | {
        error?: {
          "agent-version": string;
          details: string;
          "editor-plugin-version": string;
          "editor-version": string;
          engine: string;
          message: string;
        };
        choices: {
          finish_reason: string;
          index: number;
          delta: {
            content: string;
            role: string;
          };
        }[];
        created: number;
        id: string;
      };

      try {
        parsedLine = JSON.parse(line);
      } catch (error) {
        continue;
      }
      if (parsedLine === null) continue;

      try {
        const responseContent = parsedLine["choices"][0]["delta"]["content"];

        if (responseContent !== null) {
          fullResponse += responseContent;
        }
      } catch (err) {
        if (parsedLine["error"]) {
          let errorLines = [] as string[];
          if ("message" in parsedLine["error"]) {
            errorLines.push(parsedLine["error"]["message"]);
          }
          if ("details" in parsedLine["error"]) {
            errorLines.push(parsedLine["error"]["details"]);
          }
          return errorLines.join("\n\n");
        }
        continue;
      }
    }

    return fullResponse;
  }

  addMessageToConversation(message: string, role: "user" | "system"): void {
    this.chatHistory.push({
      content: message,
      role,
    });
  }

  /**
   * @param prompt The prompt to send to the AI
   */
  async ask(prompt: string): Promise<string> {
    await this.ready;

    const url = "https://api.githubcopilot.com/chat/completions";

    if (this.token == null) {
      throw new Error("Not authenticated");
    }

    const headers = {
      Authorization: `Bearer ${this.token["token"]}`,
      "X-Request-Id": String(Utils.getRandomUuidv4()),
      "Vscode-Sessionid": this.vscode_sessionid,
      Machineid: String(this.machineid),
      "Editor-Version": "vscode/1.80.1",
      "Editor-Plugin-Version": "copilot-chat/0.4.1",
      "Openai-Organization": "github-copilot",
      "Openai-Intent": "conversation-panel",
      "Content-Type": "application/json",
      "User-Agent": "GitHubCopilotChat/0.4.1",
    } as Record<string, string>;

    this.chatHistory.push({
      content: prompt,
      role: "user",
    });

    const data = Utils.generateRequest(
      this.chatHistory,
      this.coreInstructions
    );

    let rawMessage = "";
    const response = await fetch(url, {
      method: "POST",
      headers,
      body: JSON.stringify(data),
    });

    const reader = response.body?.getReader();

    if (reader) {
      while (true) {
        const { done, value } = await reader.read();
        if (done) {
          break;
        }

        let content = new TextDecoder().decode(value);
        content = content.replace(/\n/g, "");
        rawMessage += content;
      }
    }

    const lines = rawMessage
      .replace(/^data:/, "")
      .split("data:")
      .map((line) => line.trim())
      .filter((line) => line);

    const aiAnswer = this.parseRawMessage(lines);

    this.chatHistory.push({
      content: aiAnswer,
      role: "system",
    });

    return aiAnswer;
  }
}
