import "dotenv/config";
import React from "react";
import { Resend } from "resend";
import Portal2ProposalEmail, { subject } from "./Portal2ProposalEmail";

const resendApiKey = process.env.RESEND_API_KEY;
if (!resendApiKey) {
  console.error("Missing RESEND_API_KEY environment variable.");
  process.exit(1);
}

const resend = new Resend(resendApiKey);

const from = process.env.MAIL_FROM || "Olayinka Vaughan <yvaughan@wesleyan.edu>";
const to = (process.env.MAIL_TO || "vaughanolayinka@gmail.com").split(",").map((s) => s.trim());

const element = (
  <Portal2ProposalEmail
    recipientName={process.env.RECIPIENT_NAME || "CS Club Board Members"}
    senderName={process.env.SENDER_NAME || "Olayinka Vaughan"}
    senderRole={process.env.SENDER_ROLE || "Project Lead / Club Member"}
    replyEmail={process.env.REPLY_EMAIL || "yvaughan@wesleyan.edu"}
  />
);

const send = async () => {
  const response = await resend.emails.send({
    from,
    to,
    subject,
    react: element,
  });
  console.log("Email queued:", response);
};

send().catch((err) => {
  console.error("Failed to send email:", err);
  process.exit(1);
});
