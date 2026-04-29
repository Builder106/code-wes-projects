# Portal 2 — proposal email

Email infrastructure for pitching a CS Club project: a hosted Portal 2 instance where one machine runs a licensed copy and everyone else participates through a browser (controls, queue, low-latency stream).

This folder is **just the proposal email**, not the hosted-game system. The full system design lives in [`TODO-Portal2.md`](./TODO-Portal2.md) and hasn't been built yet.

## Files

- `Portal2ProposalEmail.tsx` — React Email template (`@react-email/components`). The actual content of the pitch.
- `Portal2ProposalEmail.html` — pre-rendered HTML preview of the template.
- `render-email.ts` — renders the TSX template to HTML for previewing.
- `send.tsx` / `send.js` — sends via [Resend](https://resend.com) (`RESEND_API_KEY` env var).
- `send-smtp.js`, `transporter.js` — alternate path via Nodemailer/SMTP.

## Send

```bash
npm install
RESEND_API_KEY=... node send.js          # via Resend (preferred)
# or
node send-smtp.js                         # via SMTP, see transporter.js
```

Configure recipient/sender in `send.js` before running.
