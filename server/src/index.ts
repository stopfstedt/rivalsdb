import { createServer } from "./server/server.js";
import { startBot } from "./bot/index.js";
import { runBotServer } from "./env.js";

createServer().then(async ({ run, shutdown }) => {
  await run();
  console.log("Server is running");

  if (runBotServer) {
    await startBot();
    console.log("Bot is running");
  }

  process.once("SIGTERM", shutdown);
});
