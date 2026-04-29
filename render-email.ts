import "dotenv/config";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as React from "react";
import { render } from "@react-email/render";
import Portal2ProposalEmail, { subject } from "./Portal2ProposalEmail";

async function main() {
  const envSender = process.env.SENDER_NAME;
  const envReply = process.env.REPLY_EMAIL;
  const envRecipient = process.env.RECIPIENT_NAME;

  const senderName = envSender ?? "Olayinka Vaughan";
  const replyEmail = envReply ?? "yvaughan@wesleyan.edu";
  const recipientName = envRecipient ?? "CS Club Board Members";

  const element = React.createElement(Portal2ProposalEmail, {
    recipientName,
    senderName,
    replyEmail,
  });

  const html = await render(element, { pretty: true });
  const outFile = path.resolve(process.cwd(), "Portal2ProposalEmail.html");
  await fs.writeFile(outFile, html, "utf8");
  console.log(`Subject: ${subject}`);
  console.log(`Sender: ${senderName} | Reply-To: ${replyEmail}`);
  console.log(`Wrote: ${outFile}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
