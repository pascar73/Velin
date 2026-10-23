# VELIN — project brief

**Agent-native computing for work and everyday life.**

VELIN aims to make the agent the primary interface to computing. People describe an outcome; agents carry out approved work and produce finished documents, models, registers, and other artefacts for people to review.

## The problem

Professional and household work is scattered across applications, files, messages, and manual formatting. Completing a task often means operating several tools before reaching a useful result. VELIN proposes a coherent environment built around the requested result and the human decisions needed to achieve it.

## Product vision

An Ubuntu-based environment combines an agent runtime, controlled tool access, a shared artefact workspace, and consistent document templates. The intended experience covers a board paper, a financial model, a household letter, or a service task through the same request-and-review workflow.

The planned family has four products:

| Product | Intended role |
| --- | --- |
| VELIN server | Coordinates agents, shared services, inference access, and enrolled devices. |
| VELIN office desktop | Provides the professional workspace, business templates, and approved corporate integrations. |
| VELIN consumer desktop | Provides the personal workspace and household templates. |
| VELIN mobile companion | Provides an Android companion for presence, summaries, and artefact access. |

## What exists today

The latest golden image, confirmed by the project owner, is `golden-agent-24.04.5-amd64-20260928-2222.iso`, built on 28 September 2026. It is an approximately 3.94 GiB Ubuntu 24.04.5 server ISO with Pi and the DeepSeek Harness bundled. Its documented setup flow collects API keys at first boot, starts the agent environment, provides a Pi console, and keeps SSH available for administration. DSH is documented as listening on loopback with token protection.

The ISO is accessible in the Obsidian vault. Its header has been read successfully; this repository preparation has not independently boot-tested the image or recomputed its full checksum. The recorded SHA256 is `934a38022d37cfe1b409945976aa04bdeb2526bafc6111af8bff90cd639cdf03`.

October architecture documents describe the wider VELIN family. A newer local architecture copy changes the default runtime toward Hermes. These are product evolution proposals; they do not establish that the September image implements the four products, the device fabric, or the proposed integrations.

## Design principles

- **Human control:** explicit approval for changes, constrained capabilities, and an independent administrative recovery route.
- **Privacy by design:** provision credentials at runtime; keep secrets out of distributable images; support local inference paths.
- **Finished work:** consistent, readable artefacts and reusable templates carry the value of the product.
- **A focused system:** a minimal Ubuntu foundation and explicit package choices.
- **A coherent family:** shared foundations across professional, personal, server, and mobile experiences.

These principles are design targets. Each requires implementation and validation in subsequent releases.

## Intended users and value

The initial audience is professionals and operators with recurring document and coordination work, alongside households seeking a simpler personal computing experience. The intended value is fewer manual handoffs, consistent outputs, and clearer control over what agents can do. Productivity, cost, reliability, and adoption benefits remain to be measured.

## Next milestones

1. Preserve the golden-image build scripts, dependency versions, and test evidence in a reproducible source tree.
2. Reconcile the September Pi-based build with the October VELIN architecture and runtime decisions.
3. Validate a fresh installation, credential provisioning, updates, and recovery on representative hardware or VMs.
4. Deliver one complete request-to-artefact workflow with human review.
5. Implement and validate device enrolment and permissions before expanding the product family.

## Sources

- Vault: `Infrastructure/golden-image/README.md`, `SHA256SUMS`, and `Golden-Image-Project-Report.pdf`.
- Vault: `RAW/Agentic_Loop/LOOP_003/artifacts/ael/` architecture, packages, identity, templates, and wrap-up.
- Local comparison: `/Users/agent/.hermes/output/agentic-enterprise-linux/ARCHITECTURE.md`.
- Project owner confirmation that the September ISO is the latest image.
