// send-smtp.js
require('dotenv').config();
const fs = require('fs');
const nodemailer = require('nodemailer');

(async () => {
  const html = fs.readFileSync('Portal2ProposalEmail.html', 'utf8');

  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: String(process.env.SMTP_SECURE || 'false') === 'true',
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
  });

  const info = await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to: process.env.MAIL_TO, // comma-separated list OK
    subject: "Let's try a Portal 2 web experiment (club project)",
    html,
  });

  console.log('Sent:', info.messageId);
})().catch(err => {
  console.error(err);
  process.exit(1);
});