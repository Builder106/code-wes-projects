# Code-Wes Engineering Hub

> **Project pitches, architecture specs, and prototypes for Wesleyan University's coding club.**

## 💡 What is Code-Wes?

Code-Wes is the student-run Computer Science organization at Wesleyan University where student developers collaborate on ambitious software and systems engineering projects.

This repository serves as an open workspace for planning new club initiatives, recording architectural design documents, and building early prototypes before they launch across the university community.

## Featured Initiatives

### 1. [Portal 2 Web Bridge](https://github.com/Code-Wes/portal-web-bridge)

Turn a running copy of the video game *Portal 2* into an interactive, crowd-controlled web experiment. Using game network sockets, a fast web server, and a responsive frontend, multiple remote players can queue actions and guide players through test chambers in real time.

- Architecture and Milestones: [TODO-Portal2.md](./TODO-Portal2.md)
- Original Project Pitch: [proposal-email/](./proposal-email/)

### 2. [Piano Tool — Interactive Practice Tutor](apps/piano-tool/)

An on-device interactive piano coach and sheet music visualizer built for student musicians in campus practice rooms.

- **Real-Time DSP:** Listens to acoustic or digital pianos via device microphone using a low-latency YIN pitch detection engine.
- **Custom Staff Engine:** Vector-accurate sheet music scrolling and scoring designed with SMuFL notation standards and accessible contrast geometry.
- **Goal:** Provide an open-source, offline ear-and-sight tutor for Wesleyan student musicians and a reference project for real-time audio systems in Flutter.

---

## License

MIT License. See [LICENSE](./LICENSE).
