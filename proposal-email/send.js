// send.js (ESM) — requires Node 18+ or "type":"module" in package.json
import { Resend } from 'resend';
import React from 'react';
import Portal2ProposalEmail, { subject } from './Portal2ProposalEmail.js';

const resend = new Resend(process.env.RESEND_API_KEY);

// Tip: use a verified sender domain with Resend (e.g., club@yourdomain)
await resend.emails.send({
  from: 'yvaughan@wesleyan.edu',
  to: 'vaughanolayinka@gmail.com',
  subject,
  react: (
    <Portal2ProposalEmail
      recipientName="CS Club Board Members"
      senderName="Olayinka Vaughan"
      senderRole="Project Lead / Club Member"
      replyEmail="yvaughan@wesleyan.edu"
    />
  ),
});