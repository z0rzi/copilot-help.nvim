import Utils from "./utils";

type AuthResponse = {
  device_code: string;
  user_code: string;
  verification_uri: string;
  expires_in: number;
  interval: number;
};

const LOGIN_HEADERS = {
  accept: "application/json",
  "content-type": "application/json",
  "editor-version": "Neovim/0.9.2",
  "editor-plugin-version": "copilot.lua/1.11.4",
  "user-agent": "GithubCopilot/1.133.0",
};

async function checkGithubAuth(deviceCode: string): Promise<string> {
  const url = "https://github.com/login/oauth/access_token";

  const accessTokenResponse = await fetch(url, {
    method: "POST",
    headers: LOGIN_HEADERS,
    body: JSON.stringify({
      client_id: "Iv1.b507a08c87ecfe98",
      device_code: deviceCode,
      grant_type: "urn:ietf:params:oauth:grant-type:device_code",
    }),
  });

  if (!accessTokenResponse.ok) {
    console.log("Failed to fetch access token");
    return "";
  }

  const accessTokenData = (await accessTokenResponse.json()) as Record<
    string,
    string
  >;
  if (!("access_token" in accessTokenData)) {
    console.log("access_token not in response");
    return "";
  }

  const { access_token, token_type } = accessTokenData;
  const userUrl = "https://api.github.com/user";
  const userHeaders = {
    Authorization: `${token_type} ${access_token}`,
    "User-Agent": "GithubCopilot/1.133.0",
    Accept: "application/json",
  };

  const userResponse = await fetch(userUrl, {
    method: "GET",
    headers: userHeaders,
  });

  if (!userResponse.ok) {
    console.log("Failed to fetch user data");
    return "";
  }

  const userData = (await userResponse.json()) as { login: string };
  Utils.cacheToken(userData.login, access_token);
  return access_token;
}

async function githubRequestAuth(): Promise<AuthResponse> {
  const url = "https://github.com/login/device/code";

  const response = await fetch(url, {
    method: "POST",
    headers: LOGIN_HEADERS,
    body: JSON.stringify({
      client_id: "Iv1.b507a08c87ecfe98",
      scope: "read:user",
    }),
  });

  if (response.ok) {
    return (await response.json()) as AuthResponse;
  } else {
    throw new Error("Failed to fetch authentication data");
  }
}

export async function githubAuthenticate() {
  const req = await githubRequestAuth();
  console.log(
    "Please visit",
    req["verification_uri"],
    "and enter",
    req["user_code"]
  );

  let ghToken = await checkGithubAuth(req["device_code"]);
  while (!ghToken) {
    await new Promise((resolve) => setTimeout(resolve, 1000 * req["interval"]));
    ghToken = await checkGithubAuth(req["device_code"]);
  }
  console.log("Successfully authenticated");

  return ghToken;
}
