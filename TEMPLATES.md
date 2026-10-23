# Velin artefact templates — design law

Agents write. Humans **read**. These are not Office themes, not Canva, not “smart art”.

If a page could be mistaken for a default Word, Excel, or PowerPoint file, it **does not ship**.

The bar: **quiet, expensive paper**. Editorial. Minimal. Never thin, never grey-on-grey, never “startup landing page”.

Velin inherits **Hermes PDF Design System 2** geometry and ink. Agents fill **slots**. They do not choose type, colour, or margin.

---

## 1. Philosophy

- **Paper, not suite.** A board pack should feel like a short book, not a deck dumped to PDF.
- **One idea per block.** No three-column “pillar” clip-art. No stock waves.
- **Ink on beige.** Navy and brown carry the voice. Orange is a **scalpel** — one rule or one figure per sheet, never a fill.
- **Read first.** If the eye stumbles, the template is wrong — not the reader.
- **Same law for office and consumer.** A household invoice is as well set as an IC memo. Cheap is a defect, not a SKU.

---

## 2. Geometry (immutable)

| | |
|---|---|
| Sheet | **A4** only (`595.3 × 841.9` pt). Letter is a release blocker. |
| Engine margin | **16mm** on every sheet (`<doc-page size="a4" margin="16mm">`) |
| Body inset | content padding `4mm 6mm 0` → ~22mm side measure |
| Measure | **62–72 characters** of IBM Plex Sans 10.5pt. Never full-bleed body text. |
| Cover | one full-bleed sheet; title sits in the type, not in a logo salad |
| Footer | every content sheet: hostname (cert CN) · ISO date · template id · content hash — 7.5pt, warm grey. Not a slogan. |

`break-inside: avoid` only on **small** blocks (callout, tile row, table row, figure, quote), each &lt; ~120mm. Never on a whole section. Headings never last on a sheet. Final sheet at least half full. `orphans: 3; widows: 3`.

---

## 3. Type (impeccable, not decorative)

**Pair (embed both; no substitutes):**

- **Libre Baskerville** — display, lead, pull quote. Serif with real italics. Cover title **34pt / ~1.15**, slightly tight tracking. H2 **17pt / 1.25**, navy, with a **1.5pt orange rule** 8pt below, 18pt above the next paragraph.
- **IBM Plex Sans** — body, UI, tables, captions. Body **10.5pt / 1.62**, ink `#33291F`. H3 **9pt / 1.3**, 600, uppercase, +0.08em tracking, brown `#6E4B34`. Captions **8pt** (never below). Tables **9.5pt**, **tabular lining figures**. Footer **7.5pt**.

**Do not:** Calibri, Arial, Inter-as-default, Comic, variable-font “personality”, all-caps body, 9pt body, 1.15 body leading, justified rivers without hyphenation. If you justify, hyphenate; **default is ragged right** for memos and minutes (easier to read). Board packs may justify **body only**, never headings.

**Lead** (first paragraph after cover or h2): Baskerville italic **13pt / 1.45**, secondary brown — one paragraph, max ~80 words.

**Pull quote:** same 13pt italic, 2mm left navy hairline, no quotation-mark garnish.

---

## 4. Ink (one set)

| Role | Hex | Use |
|---|---|---|
| Navy | `#17253F` | titles, rules of structure, footer machine name |
| Ink | `#33291F` | body |
| Secondary | `#5C4A3A` | lead, h3 |
| Warm grey | `#8A7A69` / `#A2907E` | captions, footer meta |
| Beige | `#F1E7D9` | page ground, **one** callout per sheet |
| Table tint | `#F5EDE2` | header row / zebra optional, 4% only |
| Hairline | `#DFD2C1` / `#E6DACA` | tables, boxes |
| Orange | `#D9743B` | **accent only** — rule, bullet, one key number |
| Link | `#B85C25` | rare; PDFs are for reading, not browsing |

No drop shadows, no gradients, no stock “abstract waves”, no teal-and-purple dashboards.

---

## 5. Block library (only these)

Agents may compose **only** these. Unknown block = engine refuse.

1. Cover field (title, eyebrow, meta, optional full-bleed image)
2. Lead
3. H2 + orange rule
4. H3 label
5. Body paragraphs
6. Orange-dot list (not hyphens, not emoji)
7. Beige callout — **max one per sheet**
8. Three-up stat tiles (one number orange **or** none; never all three)
9. Table with `<thead>`, hairlines, no Excel grid dump
10. Pull quote
11. Figure 60–70mm after a **paragraph**, never under a naked heading
12. Definition list

No side-by-side diagram boxes, no smart-art, no icons-as-headings.

---

## 6. Catalogue

Office and consumer share the **engine**. Different **ids**. Same type.

### Office (work father)

| id | Artefact | Form | Read time |
|---|---|---|---|
| `board-pack` | IC / board pack | PDF, cover + flowing sections | sit down |
| `memo` | Decision memo | PDF, **1–3** sheets | two minutes |
| `minutes` | Minutes | PDF | scan |
| `register` | Register | xlsx **and** PDF extract | scan |
| `model-cover` | Model cover + tabs | xlsx | scan |
| `invoice` | Invoice / notice | PDF, one sheet | glance |
| `briefing` | One-pager | PDF, **one** sheet | one minute |
| `slide-one` | One idea, one sheet | PDF *or* pptx **as a reader**, not a workshop | glance |

### Consumer (personal father)

Same ids suffixed `.life` where the work process exists (`invoice.life`, `register.life`, `memo.life`, `briefing.life`). **No** `board-pack` on consumer. No Teams letterhead.

---

## 7. Slot contracts (agents fill; they do not style)

**`memo`** — `eyebrow`, `title`, `from`, `to`, `date`, `decision` (callout), `body[]`, `ask` (h2). Hard cap 3 sheets.

**`briefing`** — `eyebrow`, `title`, `lead`, `three_stats[]` (≤3), `body` (≤400 words), `next`. **Exactly one sheet** or the job fails.

**`board-pack`** — `cover_title`, `cover_meta`, `sections[]` each `{h2, lead?, blocks[]}`. No “appendix of everything”; extra evidence is a `register` sibling.

**`minutes`** — `title`, `when`, `where`, `present[]`, `decisions[]`, `actions[]` (owner, date). Actions are a **table**, not a poem.

**`invoice`** — `issuer`, `bill_to`, `lines[]`, `total`, `due`. Tabular figures. No pastel logo.

**`register` / `model-cover`** — column types in XML; openpyxl applies **locked** styles from the same ink tokens. Header row beige, hairline borders 0.5pt, Plex 9.5pt, freeze header. No Calibri, no theme “Office 2007”.

**`slide-one`** — one sentence in Baskerville 28–32pt, one number or none, beige ground. If you need bullets, it is a `memo`.

XML in, slots out. Sample `register.xml` + `memo.xml` ship for first-run.

---

## 8. Engine

- PDF: **one** renderer — prefer **typst** with this type pair **or** DS2 HTML + weasyprint/CDP. Not both. Not reportlab layouts. Not Chromium-as-document.
- xlsx: openpyxl, tokens from this file.
- pptx only for `slide-one` reader export; **no** master with stock Motiff.
- Preview: Artefacts pane. Humans do not open Word.

---

## 9. QA gate (every file)

Release blockers:

- Not A4; margin 0; Letter
- Calibri / Arial / missing embed
- Body &lt; 10pt or leading &lt; 1.5
- Rainbow, drop shadow, clip-art cover
- Stranded heading, empty sheet, final sheet &lt; half
- “Lorem”, “Click to add title”, Excel grid in PDF
- More than one beige callout on a sheet
- Orange used as a fill
- Consumer artefact with work letterhead or Teams footer

First-run `demo-memo.pdf` + `demo-register.xlsx` must pass or the **image does not ship**.

---

## 10. What “never cheap” means

Cheap is: 9pt grey Helvetica, teal gradient header, stock handshake, “Confidential” in red Comic, 12 colours in a table, a logo bigger than the title, justified 9pt with holes, a slide with six bullets.

Expensive is: one type pair, one accent, air, a title that can be read across a table, numbers that line up, a cover that is a **sheet of paper**.
