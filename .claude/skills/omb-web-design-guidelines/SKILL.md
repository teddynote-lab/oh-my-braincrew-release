---
name: omb-web-design-guidelines
user-invocable: true
description: >
  Use when defining visual identity, choosing design tokens, establishing
  typography/color/motion direction, reviewing UI aesthetics, or ensuring
  design system coherence. Triggers on: "design system", "visual identity",
  "color palette", "typography", "dark mode", "design tokens", "aesthetic
  review", "make it look better", "design direction", or when web-designer
  agent starts work. Reference for all design decisions.
allowed-tools: Read, Edit, Write, Grep, Glob
---

# Web Design Guidelines

Reference for visual identity, design system coherence, and aesthetic quality. The `web-designer` agent MUST consult this skill for all design decisions. The `frontend-engineer` agent should reference this when implementing UI components.

## Design Philosophy

- Every interface must have a clear purpose and target audience. Define both before designing.
- Commit to a bold aesthetic direction — do not default to generic AI/SaaS aesthetics.
- Constraints create character. Limit your palette, type scale, and component set deliberately.
- Differentiation matters — ask "could this be any other product?" If yes, push harder.
- Match implementation complexity to the aesthetic vision: maximalist designs need elaborate code, minimalist designs need precision and restraint.

## Design System Defaults

- Component library: shadcn/ui recommended (Radix primitives + Tailwind styling). When unavailable, use equivalent headless primitives (Radix, Headless UI).
- Default fonts: Geist Sans for interface text, Geist Mono for code, metrics, IDs, and timestamps.
- Default mode: **dark mode** for dashboards, AI products, internal tools, and developer surfaces. Light mode for public-facing marketing and content-first pages.
- Default color tokens: zinc/neutral/slate base palette, **ONE** accent color, clear borders for separation.
- Hierarchy through type, spacing, and composition — not decorative elements.
- Avoid generic UI output: raw buttons, clickable divs, repeated bordered card grids, inconsistent radii, and forgotten empty/loading/error states.

## Typography

- Choose distinctive fonts — reject Inter, Roboto, Arial, and system fonts unless there is a specific design reason.
- Pair a display font (headings, hero text) with a refined body font (paragraphs, UI text).
- Geist Sans for UI and Geist Mono for data — this is the project baseline unless a design spec overrides it.
- Use the Tailwind type scale consistently. Do not invent ad-hoc sizes.
- Font weight creates hierarchy: regular (400) for body, medium (500) for labels and UI elements, semibold (600) for headings.
- Reserve monospace exclusively for code, metrics, IDs, timestamps, and commands — never for body text.

## Color and Theme

- Define colors as CSS variables in Tailwind theme for light/dark mode switching.
- One dominant base palette (zinc, neutral, or slate) + one sharp accent color.
- Never use multiple accent colors without explicit design justification.
- Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- Sufficient contrast: WCAG AA minimum (4.5:1 for text). See `.claude/rules/design/accessibility.md`.
- Avoid generic purple/blue gradients. If using gradients, make them intentional and brand-aligned.
- Avoid pure black (#000000) for backgrounds — use near-black (zinc-950, neutral-950) for visual richness.

## Motion and Interaction

- Ship at least 2-3 intentional motions for visually-led work:
  1. One entrance sequence in the hero (staggered reveals, fade-in)
  2. One scroll-linked, sticky, or depth effect
  3. One hover, reveal, or layout transition that sharpens affordance
- Use CSS transitions for micro-interactions (hover, focus, state changes): 150ms-300ms duration.
- Prefer Framer Motion / Motion for complex animations: section reveals, shared layout transitions, scroll-linked opacity/translate/scale, sticky storytelling, carousels that advance narrative, menus/drawers/modal presence.
- Hover states on every interactive element — visual feedback is mandatory.
- Motion must be: noticeable in a quick recording, smooth on mobile, fast and restrained, consistent across the page. Remove if ornamental only.
- Respect `prefers-reduced-motion` — disable non-essential animations. This is **mandatory**, not optional.

## Spatial Composition

- Use asymmetry deliberately — centered, evenly-spaced layouts are the default and often feel generic.
- Strategic use of negative space creates focus and breathing room.
- Allow elements to overlap intentionally (z-index layering) for depth.
- Break the grid sparingly for visual interest — not randomly.
- Consistent spacing scale from Tailwind: 4, 8, 12, 16, 24, 32, 48, 64, 96 (in px units).
- Composition patterns: Tabs + Card + Form for settings, Card + Table + Filters for dashboards, Sheet for mobile navigation, AlertDialog for destructive confirmation.

## Background and Texture

- Gradient meshes and subtle noise textures add depth to flat backgrounds.
- Geometric patterns for section dividers or empty states.
- Grain overlays (CSS filter or SVG) for organic warmth on dark backgrounds.
- Near-black (zinc-950, neutral-950) over pure black (#000) for richness and reduced eye strain.
- Layered transparencies and dramatic shadows for visual depth.

## Visual Pre-Build

Before any design work, articulate:
1. **Visual thesis:** one sentence describing mood, material, and energy (e.g., "terracotta warmth meets brutalist grid tension")
2. **Content plan:** hero → support → detail → final CTA (or app-appropriate structure)
3. **Interaction thesis:** 2-3 motion ideas that change the feel (e.g., "parallax hero, staggered card reveals, hover depth shift")

## Hero & Viewport Rules

The first viewport must read as one composition — not a dashboard of widgets.

- **Full-bleed hero default** for landing pages: edge-to-edge image or dominant visual plane. Constrain only the inner text/action column, not the hero container itself.
- **Viewport budget:** the first viewport should contain ONLY: brand, one headline, one short supporting sentence, one CTA group, and one dominant image. No stats, schedules, event listings, address blocks, promos, or secondary marketing content.
- **Brand hierarchy:** on branded pages, the brand/product name must be hero-level signal, not just nav text. If the first viewport could belong to another brand after removing the nav, branding is too weak.
- **Hero image quality test:** if the first screen still works after removing the image, the image is too weak. If the brand disappears after hiding the nav, hierarchy is too weak.
- **No hero overlays:** no detached labels, floating badges, promo stickers, or callout boxes on top of hero media.
- **Text over imagery:** maintain strong contrast and clear tap targets. Keep text column narrow, anchored to calm area of image.
- **Viewport calculation:** when using `100vh`/`100svh` heroes with sticky headers, subtract header height: `calc(100svh - var(--header-height))`.

## Card Philosophy

**Default: no cards.** Never use cards in the hero. Cards are allowed only when they are the container for a user interaction (click, expand, drag, configure).

**Removal test:** if removing a border, shadow, background, or radius from an element does not hurt interaction or understanding, it should not be a card. Use sections, columns, dividers, lists, and media blocks instead.

**Dashboard exception:** In app/dashboard UI where cards serve as interaction containers (click to expand, configure, or navigate), card treatment is appropriate — see Spatial Composition patterns (Tabs + Card + Form for settings, Card + Table + Filters for dashboards).

## Landing Page Design

Default section sequence:
1. **Hero:** brand/product, promise, CTA, dominant visual
2. **Support:** one concrete feature, offer, or proof point
3. **Detail:** atmosphere, workflow, product depth, or story
4. **Final CTA:** convert, start, visit, or contact

Each section: one purpose, one headline, one short supporting sentence. No section should need many small UI devices (pills, stat strips, icon rows) to explain itself.

## App & Dashboard UI

Default to Linear-style restraint: calm surface hierarchy, strong typography and spacing, few colors, dense but readable information, minimal chrome.

- Organize around: primary workspace, navigation, secondary context/inspector, one clear accent for action/state.
- **No** dashboard-card mosaics, thick borders on every region, decorative gradients behind routine product UI, multiple competing accent colors, or ornamental icons.
- Removal test: if a panel can become plain layout without losing meaning, remove the card treatment.

**Copy rules for dashboards/apps:**
- Utility copy over marketing copy. Prioritize orientation, status, and action over promise, mood, or brand voice.
- Section headings should say what the area IS or what the user CAN DO: "Selected KPIs", "Plan status", "Search metrics" — not aspirational hero lines.
- If a sentence could appear in a homepage hero or ad, rewrite it until it sounds like product UI.
- **Litmus:** if an operator scans only headings, labels, and numbers, can they understand the page immediately?

## Imagery Principles

- Imagery must do narrative work — show the product, place, atmosphere, or context. Decorative gradients and abstract backgrounds do not count as the main visual idea.
- Prefer in-situ photography over abstract gradients or fake 3D objects.
- Choose or crop images with a stable tonal area for text overlay.
- Do not use images with embedded signage, logos, or typographic clutter fighting the UI.
- Do not generate images with built-in UI frames, splits, cards, or panels.
- If multiple moments are needed, use multiple images — not one collage.
- The first viewport needs a real visual anchor. Decorative texture alone is not enough.

## Copy Strategy

- Write in product language, not design commentary. No prompt language or design commentary in the UI.
- Let the headline carry the meaning. Supporting copy: one short sentence.
- Cut repetition between sections. If deleting 30% of the copy improves the page, keep deleting.
- Give every section one responsibility: explain, prove, deepen, or convert.

## Anti-Patterns

- **Generic AI aesthetics**: Inter font + purple gradient + rounded card grid + centered layout. This is the default output of every AI tool — reject it.
- **Container soup**: nested div wrappers with no semantic purpose. Use semantic HTML + composition.
- **Decoration without purpose**: gradients, shadows, and animations that serve no functional or communicative role.
- **Ignoring dark mode**: designing for light mode only when the product is a dashboard or developer tool.
- **Multiple accent colors**: scattering rainbow accents, heavy gradients, and random glassmorphism instead of restraint.
- **Inconsistent spacing**: mixing arbitrary pixel values with Tailwind scale values.
- **Converging on common defaults**: every generation using the same fonts and colors. Vary between projects.

## Failures to Reject

These specific outputs must be rejected and regenerated:
- Generic SaaS card grid as first impression
- Beautiful image with weak brand presence
- Strong headline with no clear action
- Busy imagery behind text with poor contrast
- Sections repeating the same mood statement
- Carousel with no narrative purpose
- App UI made of stacked cards instead of layout

## Litmus Checks

Before completing any design task, verify:
1. Is the brand/product unmistakable in the first screen?
2. Is there one strong visual anchor (not just decorative texture)?
3. Can the page be understood by scanning headlines only?
4. Does each section have exactly one job?
5. Are cards actually necessary, or would a cardless layout work?
6. Does motion improve hierarchy or atmosphere (not just decorate)?
7. Would the design still feel premium if all decorative shadows were removed?

## Review Workflow

1. Read tailwind.config.ts, global CSS, and key components to assess current design language.
2. Evaluate typography choices against the "distinctive, not generic" principle.
3. Verify color palette: one base + one accent, WCAG AA contrast, no hardcoded hex in components.
4. Check motion: hover states present, prefers-reduced-motion respected, no purposeless decoration.
5. Assess spatial composition: intentional rhythm, not uniform spacing everywhere.
6. Report findings with specific file references and suggested token changes.
7. Run all litmus checks (see Litmus Checks section below) before completing. If any check fails, revise and re-check.

## Related Rules

- `.claude/rules/design/web-design-guidelines.md` — rule file version (auto-activated on file edits)
- `.claude/rules/design/accessibility.md` — WCAG requirements and contrast ratios
- `.claude/rules/design/ui-patterns.md` — structural patterns (layout, states, forms, modals)
- `.claude/rules/frontend/tailwind.md` — Tailwind utility usage and theming
- `.claude/rules/frontend/react-best-practices.md` — React quality checklist
