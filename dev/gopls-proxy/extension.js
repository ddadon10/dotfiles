const http = require("http");
const vscode = require("vscode");

const OPENER_ID = "local.gopls-proxy";
const LISTEN_HOST = "0.0.0.0";
const LISTEN_PORT = 18080;
const BROWSER_BASE = `http://127.0.0.1:${LISTEN_PORT}`;

let proxyServer;
let targetPort;
let output;

function activate(context) {
  output = vscode.window.createOutputChannel("gopls-proxy");
  context.subscriptions.push(output);

  context.subscriptions.push(
    vscode.window.registerExternalUriOpener(
      OPENER_ID,
      {
        canOpenExternalUri(uri) {
          return getGoplsTarget(uri)
            ? vscode.ExternalUriOpenerPriority.Preferred
            : vscode.ExternalUriOpenerPriority.None;
        },
        async openExternalUri(resolvedUri, context) {
          const sourceUri = context.sourceUri || resolvedUri;
          const target = getGoplsTarget(sourceUri);
          if (!target) {
            await vscode.env.openExternal(resolvedUri, {
              allowContributedOpeners: "default",
            });
            return;
          }

          await ensureProxy(target.port);

          const proxied = vscode.Uri.parse(`${BROWSER_BASE}${target.path}`);
          await vscode.env.openExternal(proxied, {
            allowContributedOpeners: "default",
          });
        },
      },
      {
        schemes: ["http"],
        label: "Open gopls through proxy",
      },
    ),
  );

  context.subscriptions.push({ dispose: stopProxy });
}

function deactivate() {
  stopProxy();
}

function getGoplsTarget(uri) {
  if (!uri || uri.scheme !== "http") {
    return undefined;
  }

  let url;
  try {
    url = new URL(uri.toString(true));
  } catch {
    return undefined;
  }

  if (url.hostname !== "127.0.0.1" && url.hostname !== "localhost") {
    return undefined;
  }

  if (!url.port || !url.pathname.startsWith("/gopls/")) {
    return undefined;
  }

  const port = Number(url.port);
  if (!Number.isInteger(port) || port <= 0 || port > 65535) {
    return undefined;
  }

  return {
    port,
    path: `${url.pathname}${url.search}${url.hash}`,
  };
}

async function ensureProxy(port) {
  targetPort = port;

  if (proxyServer?.listening) {
    log(`proxy target updated: ${BROWSER_BASE} -> http://127.0.0.1:${targetPort}`);
    return;
  }

  proxyServer = http.createServer(handleProxyRequest);
  proxyServer.on("error", (error) => {
    log(`proxy error: ${error.stack || error.message}`);
  });

  await new Promise((resolve, reject) => {
    proxyServer.once("error", reject);
    proxyServer.listen(LISTEN_PORT, LISTEN_HOST, () => {
      proxyServer.off("error", reject);
      resolve();
    });
  });

  log(`proxy listening: ${BROWSER_BASE} -> http://127.0.0.1:${targetPort}`);
}

function stopProxy() {
  if (!proxyServer) {
    return;
  }

  const server = proxyServer;
  proxyServer = undefined;
  server.close();
}

function handleProxyRequest(clientRequest, clientResponse) {
  if (!targetPort) {
    clientResponse.writeHead(503, { "content-type": "text/plain; charset=utf-8" });
    clientResponse.end("gopls proxy target is not configured\n");
    return;
  }

  const upstreamRequest = http.request(
    {
      hostname: "127.0.0.1",
      port: targetPort,
      method: clientRequest.method,
      path: clientRequest.url || "/",
      headers: upstreamHeaders(clientRequest.headers),
    },
    (upstreamResponse) => {
      if (shouldRewrite(upstreamResponse.headers["content-type"])) {
        rewriteResponse(upstreamResponse, clientResponse);
      } else {
        clientResponse.writeHead(
          upstreamResponse.statusCode || 502,
          upstreamResponse.statusMessage,
          rewriteHeaders(upstreamResponse.headers),
        );
        upstreamResponse.pipe(clientResponse);
      }
    },
  );

  upstreamRequest.on("error", (error) => {
    log(`upstream error: ${error.stack || error.message}`);
    if (!clientResponse.headersSent) {
      clientResponse.writeHead(502, { "content-type": "text/plain; charset=utf-8" });
    }
    clientResponse.end(`gopls proxy upstream error: ${error.message}\n`);
  });

  clientRequest.pipe(upstreamRequest);
}

function upstreamHeaders(headers) {
  return {
    ...headers,
    host: `127.0.0.1:${targetPort}`,
    "accept-encoding": "identity",
  };
}

function rewriteResponse(upstreamResponse, clientResponse) {
  const chunks = [];

  upstreamResponse.on("data", (chunk) => chunks.push(chunk));
  upstreamResponse.on("end", () => {
    const body = Buffer.concat(chunks).toString("utf8");
    const rewritten = rewriteBody(body);
    const headers = rewriteHeaders(upstreamResponse.headers);

    delete headers["content-length"];
    delete headers["content-encoding"];

    clientResponse.writeHead(
      upstreamResponse.statusCode || 502,
      upstreamResponse.statusMessage,
      headers,
    );
    clientResponse.end(rewritten);
  });
}

function shouldRewrite(contentType) {
  if (!contentType) {
    return false;
  }

  return (
    contentType.startsWith("text/") ||
    contentType.includes("javascript") ||
    contentType.includes("json") ||
    contentType.includes("xml")
  );
}

function rewriteHeaders(headers) {
  const rewritten = { ...headers };

  if (rewritten.location) {
    rewritten.location = rewriteBody(String(rewritten.location));
  }

  return rewritten;
}

function rewriteBody(value) {
  return value
    .replaceAll(`http://127.0.0.1:${targetPort}`, BROWSER_BASE)
    .replaceAll(`http://localhost:${targetPort}`, BROWSER_BASE);
}

function log(message) {
  output?.appendLine(message);
}

module.exports = {
  activate,
  deactivate,
};
