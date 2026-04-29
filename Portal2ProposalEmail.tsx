import * as React from "react";
import { Html, Head, Preview, Body, Container, Section, Heading, Text, Img, Link, Button } from "@react-email/components";

export const subject = "Let's try a Portal 2 web experiment (club project)";

export type Portal2ProposalEmailProps = {
  recipientName?: string;
  senderName?: string;
  senderRole?: string;
  replyEmail?: string;
};

export default function Portal2ProposalEmail({
  recipientName = "CS Club Board Members",
  senderName = "Olayinka Vaughan",
  senderRole = "Project Lead / Club Member",
  replyEmail = "yvaughan@wesleyan.edu",
}: Portal2ProposalEmailProps) {
  return (
    <Html>
      <Head />
      <Preview>Build a tiny website inside Portal 2</Preview>
      <Body style={styles.body}>
        <Container style={styles.container}>
          <Section style={styles.brandRow}>
            <Img
              src="https://upload.wikimedia.org/wikipedia/commons/1/12/Portal_2_Official_Logo.png"
              alt="Portal 2 Logo"
              width={220}
              height={48}
              style={styles.logo}
            />
            <Text style={styles.tagline}>Let’s rebuild the Portal 2 web server — together</Text>
          </Section>

          <Section style={{ padding: "20px 32px 16px" }}>
            <Heading as="h1" style={styles.h1}>Build a tiny website inside Portal 2</Heading>
            <Text style={styles.muted}>To: {recipientName}</Text>
            <Text style={styles.muted}>From: {senderName} · {senderRole}</Text>
          </Section>

          <Section style={{ ...styles.section, ...styles.sectionAccentBlue }}>
            <Heading as="h2" style={styles.h2}><span style={styles.chipBlue}>Overview</span>What this is</Heading>
            <Text style={styles.p}>
              We’re recreating that YouTube project where Portal 2 acts like a simple web server. One computer runs the game. A little helper app listens for web clicks and turns them into safe in‑game actions. You press a button on a web page → something happens in the test chamber.
            </Text>
          </Section>

          <Section style={{ ...styles.section, ...styles.sectionAlt, ...styles.sectionAccentOrange }}>
            <Heading as="h2" style={styles.h2}><span style={styles.chipOrange}>Video</span>See it in action (quick video)</Heading>
            <Link href="https://www.youtube.com/watch?v=-v5vCLLsqbA" style={styles.videoLink}>
              <Img
                src="https://img.youtube.com/vi/-v5vCLLsqbA/hqdefault.jpg"
                alt="Watch: I hosted a web server in Portal 2 (YouTube)"
                width={576}
                height={324}
                style={styles.videoThumb}
              />
            </Link>
            <div style={{ textAlign: "center", marginTop: 8 }}>
              <Button href="https://www.youtube.com/watch?v=-v5vCLLsqbA" style={styles.buttonPrimary}>Watch on YouTube</Button>
            </div>
          </Section>

          <Section style={{ ...styles.section, ...styles.sectionAccentBlue }}>
            <Heading as="h2" style={styles.h2}><span style={styles.chipBlue}>How</span>How it works (simple version)</Heading>
            <ul style={styles.ul}>
              <li>Turn on a special console in Portal 2 (a built‑in command window).</li>
              <li>Our helper app hears web requests (the normal rules are called “HTTP”).</li>
              <li>We map those requests to safe game commands (like “spawn a cube”).</li>
              <li>The web page shows what happened, and you can try the next thing.</li>
            </ul>
            <Text style={styles.note}>Everyone uses a browser. Only the host computer needs Portal 2.</Text>
          </Section>

          <Section style={{ ...styles.section, ...styles.sectionAlt, ...styles.sectionAccentOrange }}>
            <Heading as="h2" style={styles.h2}><span style={styles.chipOrange}>Hands‑on</span>What you’ll do</Heading>
            <ul style={styles.ul}>
              <li>Help design a few buttons and pages (no prior experience needed).</li>
              <li>Test simple routes like “home” and “status” and see them load.</li>
              <li>Try a live update: click a button → something changes in the chamber.</li>
              <li>Optional: build a tiny “webpage made of cubes” in a room.</li>
            </ul>
          </Section>

          <Section style={{ ...styles.section, ...styles.sectionAccentBlue }}>
            <Heading as="h2" style={styles.h2}><span style={styles.chipBlue}>Plan</span>Plan (5 short weeks)</Heading>
            <ol style={styles.ol}>
              <li><b>Week 1</b>: Agree on the few routes and buttons. Write simple tests first.</li>
              <li><b>Week 2</b>: Hook up the game console to our helper app.</li>
              <li><b>Week 3</b>: Make the pages load correctly (no “stuck loading” issues).</li>
              <li><b>Week 4</b>: Add the live‑update button and a tiny web UI.</li>
              <li><b>Week 5</b>: Polish and (if time) try the “DOM made of cubes” demo.</li>
            </ol>
          </Section>

          <Section style={{ ...styles.section, ...styles.sectionAlt, ...styles.sectionAccentOrange }}>
            <Heading as="h2" style={styles.h2}><span style={styles.chipOrange}>Gear</span>What we need</Heading>
            <ul style={styles.ul}>
              <li><b>One host computer</b> (or small cloud VM) to run Portal 2.</li>
              <li><b>One Steam copy of Portal 2</b> on that host.</li>
              <li><b>Free tools</b> for the helper app and web page.</li>
              <li><b>Cost</b>: self‑host ≈ free; cloud time ≈ a dollar or so per hour during demos.</li>
            </ul>
          </Section>

          <Section style={{ ...styles.section, ...styles.sectionAccentBlue }}>
            <Heading as="h2" style={styles.h2}><span style={styles.chipBlue}>FAQ</span>Common questions</Heading>
            <ul style={styles.ul}>
              <li>“Can people break things?” We only allow a short, safe list of actions.</li>
              <li>“What if it crashes?” We add auto‑restart and keep it simple.</li>
              <li>“Is this legal?” We use a licensed copy of Portal 2 on the host.</li>
            </ul>
          </Section>

          <Section style={{ ...styles.section, ...styles.sectionAlt, ...styles.sectionAccentOrange }}>
            <Heading as="h2" style={styles.h2}><span style={styles.chipOrange}>Goal</span>What ‘done’ looks like</Heading>
            <ul style={styles.ul}>
              <li>“Home” and “Status” pages load fast and finish correctly.</li>
              <li>Clicking a button runs a safe action you can see in the chamber.</li>
              <li>A live‑update button changes something in real time.</li>
              <li>Everything still works after a restart.</li>
              <li>Bonus: a tiny room that shows a mini web page as cubes.</li>
            </ul>
          </Section>

          <Section style={styles.footer}>
            <Text style={{ ...styles.p, color: "#e2e8f0" }}>
              Questions or feedback? Reply to <Link href={`mailto:${replyEmail}`} style={styles.footerLink}>{replyEmail}</Link>.
            </Text>
            <Text style={{ ...styles.mutedSmall, color: "#a7b0bb" }}>
              Prepared by {senderName}. If approved, we’ll scaffold with tests first and ship a simple demo.
            </Text>
          </Section>
        </Container>
      </Body>
    </Html>
  );
}

const styles: Record<string, React.CSSProperties> = {
  body: {
    backgroundColor: "#0b1220",
    color: "#0b1220",
    margin: 0,
    padding: 0,
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
  },
  container: {
    width: "100%",
    maxWidth: 640,
    backgroundColor: "#ffffff",
    borderRadius: 12,
    boxShadow: "0 10px 30px rgba(0,0,0,0.28)",
    overflow: "hidden",
  },
  brandRow: {
    backgroundColor: "#0f172a",
    padding: "20px 24px 14px",
    textAlign: "center" as const,
    borderBottom: "2px solid #1e293b",
  },
  logo: {
    display: "block",
    margin: "0 auto 6px",
  },
  tagline: {
    color: "#aab4c2",
    fontSize: 12,
  },
  h1: {
    margin: 0,
    fontSize: 24,
    lineHeight: "28px",
    color: "#0b1220",
  },
  h2: {
    margin: 0,
    fontSize: 18,
    lineHeight: "22px",
    color: "#0b1220",
    marginBottom: 10,
  },
  section: {
    padding: "16px 32px",
    borderTop: "1px solid #eef2f7",
  },
  sectionAlt: {
    backgroundColor: "#f8fbff",
  },
  sectionAccentBlue: {
    borderTop: "3px solid #1e90ff",
  },
  sectionAccentOrange: {
    borderTop: "3px solid #f59e0b",
  },
  chipBlue: {
    backgroundColor: "#e8f2ff",
    color: "#0b1220",
    padding: "2px 8px",
    borderRadius: 9999,
    fontSize: 11,
    fontWeight: 700,
    display: "inline-block",
    marginRight: 8,
  },
  chipOrange: {
    backgroundColor: "#fff3e0",
    color: "#0b1220",
    padding: "2px 8px",
    borderRadius: 9999,
    fontSize: 11,
    fontWeight: 700,
    display: "inline-block",
    marginRight: 8,
  },
  p: {
    margin: 0,
    marginTop: 8,
    marginBottom: 8,
    color: "#1f2937",
    fontSize: 14,
    lineHeight: "22px",
  },
  muted: {
    margin: 0,
    color: "#667085",
    fontSize: 12,
  },
  mutedSmall: {
    margin: 0,
    color: "#8b98a5",
    fontSize: 12,
  },
  ul: {
    margin: 0,
    paddingLeft: 18,
    color: "#1f2937",
    fontSize: 14,
    lineHeight: "22px",
  },
  ol: {
    margin: 0,
    paddingLeft: 18,
    color: "#1f2937",
    fontSize: 14,
    lineHeight: "22px",
  },
  note: {
    margin: 0,
    marginTop: 8,
    color: "#0b3a6b",
    backgroundColor: "#eaf2ff",
    padding: "10px 12px",
    borderRadius: 8,
    fontSize: 13,
    borderLeft: "4px solid #1e90ff",
  },
  buttonPrimary: {
    backgroundColor: "#1e90ff",
    color: "#ffffff",
    padding: "10px 14px",
    borderRadius: 8,
    textDecoration: "none",
    fontWeight: 700,
    display: "inline-block",
  },
  buttonSecondary: {
    backgroundColor: "#f59e0b",
    color: "#111827",
    padding: "10px 14px",
    borderRadius: 8,
    textDecoration: "none",
    fontWeight: 700,
    display: "inline-block",
  },
  footer: {
    backgroundColor: "#0f172a",
    padding: "16px 32px 24px",
  },
  footerLink: {
    color: "#60a5fa",
    textDecoration: "underline",
  },
  link: {
    color: "#2563eb",
    textDecoration: "underline",
  },
  videoLink: {
    display: "block",
    textDecoration: "none",
  },
  videoThumb: {
    width: "100%",
    height: "auto",
    display: "block",
    borderRadius: 10,
    border: "1px solid #e5e7eb",
  },
};
