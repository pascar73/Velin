# Velin visual identity — Grok image prompts

**Character:** adult woman (late 20s–30s). Attractive, composed, professional. Cartoon-real, not pin-up, not anime child, not uncanny CGI.

**Market (tone):** private-equity / corporate operators who live in Teams *and* households who are done with Word/Excel/Outlook. They buy quality and calm, not a gamer mascot and not a Calibri clip-art lady. Think editorial illustration that could sit on a board pack *and* a phone home screen.

**House ink (do not invent a rainbow):** navy `#17253F` · warm paper `#F1E7D9` · ink brown `#33291F` · orange `#D9743B` accent only.

---

## 0. Negative (append to every prompt)

`no photoreal skin pores, no lingerie, no cleavage focus, no bikini, no school uniform, no child, no teen, no chibi baby-face, no extra fingers, no watermark, no Calibri, no Microsoft Fluent clip-art, no neon cyberpunk, no 3D Pixar plastic, no busy background clutter`

---

## 1. Master avatar (lock the face first)

```
Character sheet, one adult woman as “Velin” — the messenger who writes the page, not the office suite.

Age 30. Attractive, intelligent face, slight smile, no smirk. Southern-European / Mediterranean features, olive-warm skin, dark brown hair in a clean low bun with a few loose strands. Sharp dark brows. Eyes: warm brown. No heavy makeup; professional.

Outfit: tailored navy (#17253F) jacket, cream (#F1E7D9) high-neck knit, small orange (#D9743B) enamel pin shaped like a folded sheet of vellum on the lapel. No logos.

Style: high-quality editorial cartoon, crisp ink, flat-but-dimensional colour, subtle paper grain. Like a luxury brand mascot drawn for a print annual report. Square 1:1, cream background, generous margin.

Front view head-and-shoulders portrait, looking at camera. Soft even light. High resolution.

Target audience: partners at a European PE firm and their families — they should trust her with a board pack and a household letter. Calm authority, not flirt, not tech-bro.

[paste negative]
```

Generate **one** face. Reuse it for everything below (“same woman as the Velin master avatar”).

---

## 2. Product logo badge — 1×1 circle (character + mark)

The woman **is** the badge. Cropped to a circle. Reduced colour or monochrome.

```
Velin product logo badge. Exactly 1:1 square canvas. Perfect circle crop, even padding, cream #F1E7D9 field outside the circle.

Inside the circle: the SAME Velin woman as the master avatar (age 30, Mediterranean, dark bun, navy #17253F jacket, cream knit, orange #D9743B vellum pin). Head-and-shoulders, facing camera, slight professional smile. Behind / beside her shoulder: a simple folded vellum page, geometric, 2–3 shapes.

She must remain recognisable at 64px: large head, simple hair mass, pin as a tiny orange triangle. Not a tiny full-body figure.

Colourway A (reduced): navy, cream, skin in two warm flats, hair one brown, orange pin only. No extra colours.
Colourway B (monochrome): same pose and crop, navy silhouette + cream paper fold on cream (or cream-on-navy). Face readable as a 3-shape profile/bust. No gradients.

Editorial cartoon, print quality, crisp. CIRCLE only, not rounded-square. No letters, no wings, no caduceus.

Deliver A and B side by side. Same woman as the attached master avatar.
[paste negative]
```

---

## 3. Icon set — four products, woman in every circle

Same face, same crop language. Product shown as a **prop she holds or stands with**, not a separate glyph.

```
Velin icon set. One image: clean 2×4 grid on cream #F1E7D9.
SAME woman as the Velin master avatar in EVERY circle (age 30, navy jacket, cream knit, orange vellum pin, dark bun). Head-and-shoulders or bust, large enough to read at 64px.

Row 1 — reduced colour (navy #17253F, cream, orange #D9743B only):
1 SERVER — circle. She stands in front of a quiet navy column/tower; one orange status dot on the tower. Not a LED rack.
2 OFFICE — circle. She holds one A4 page; thin navy window line behind. No Word/Excel/Windows.
3 CONSUMER — circle. She holds the same page; small navy lamp beside her. Home, not a toy.
4 MOBILE — circle. She holds a phone; a page fills the screen with an orange corner fold. No Apple/Play logos.

Row 2 — monochrome: identical four compositions, navy on cream only, no orange. She becomes a clear navy bust; props stay as simple navy shapes.

Every cell: perfect 1:1 circle, even padding, same face, same stroke. Tiny labels: SERVER / OFFICE / CONSUMER / MOBILE.

Target: PE launcher + household phone. Calm, expensive. She is the product face in every badge.
[paste negative]
```

If Grok cannot grid: eight separate 1:1 circle prompts, always “same Velin woman as the master avatar” + the product prop.

---

## 4. Hero lockup (avatar + mark)

```
Same Velin woman as the master avatar (age 30, navy jacket, cream knit, orange vellum pin). Waist-up, standing beside a large rounded-square Velin mark (folded vellum page). Cream studio background. Editorial cartoon, professional, high quality. She holds nothing cheap; one hand rests near the mark as if presenting a finished document. Target: PE operator and household — trustworthy, modern, not sexy-AI, not Clippy.
[paste negative]
```

---

## How to run in Grok

1. Generate **§1** until the face is right. Keep that image in the thread.  
2. §2 badge and §3 icons: **attach the master avatar** and say “same woman in every circle”.  
3. Reject a different face, a child-like face, or a full-body figure too small to read.  
4. Mono row must still look like *her*, not a generic pictogram.
