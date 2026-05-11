---
name: awesome-design-md
description: Apply design systems from 70+ iconic brands (Stripe, Apple, Airbnb, Tesla, Figma, etc.) to your UI. Use when you want to build a page or component that looks like a specific brand, or when the user asks for a design style matching a well-known company.
---

# Awesome DESIGN.md Skill

This skill provides ready-to-use design system documents (DESIGN.md) for 70+ well-known brands and companies. Each DESIGN.md contains the complete visual language of a real website: colors, typography, spacing, component styles, shadows, border-radius, and more.

## How to Use

When the user wants to build a page or component that looks like a specific brand:

1. Read the brand's `DESIGN.md` file from the corresponding subdirectory
2. Apply the design tokens (colors, typography, spacing, shadows, border-radius) to the UI you're building
3. Reference token names using `{colors.xxx}`, `{typography.xxx}`, `{rounded.xxx}`, `{spacing.xxx}`, `{component.xxx}`

## Available Brands

All brand design systems are stored in subdirectories:

```
awesome-design-md/
├── stripe/          — Payment infrastructure, signature purple gradients
├── apple/           — Premium white space, SF Pro, cinematic imagery
├── airbnb/          — Warm coral accent, photography-driven, rounded UI
├── tesla/           — Radical minimalism, full-bleed photography
├── vercel/          — Black & white precision, Geist font
├── linear.app/      — Ultra-minimal, purple accent, engineering-first
├── notion/          — Warm minimalism, serif headings, soft surfaces
├── spotify/         — Vibrant green on dark, bold type
├── nike/            — Monochrome, massive uppercase, full-bleed imagery
├── figma/           — Multi-color, playful yet professional
├── claude/          — Warm terracotta accent, clean editorial
├── cursor/          — Sleek dark interface, gradient accents
├── supabase/        — Dark emerald theme, code-first
├── nvidia/          — Green-black energy, technical power
├── spacex/          — Stark black & white, futuristic
├── shopify/         — Dark-first cinematic, neon green accent
├── ...and 55+ more
```

## Workflow

1. Ask the user which brand style they want
2. Read the corresponding `DESIGN.md` (e.g., `stripe/DESIGN.md`)
3. Apply the exact hex colors, font settings, spacing, and component styles from the file
4. Follow the "Do's and Don'ts" section to avoid anti-patterns
5. Reference the "Agent Prompt Guide" section for ready-to-use component prompts

## Example Usage

User: "Build a landing page that looks like Stripe"
→ Read `stripe/DESIGN.md`
→ Apply: background #ffffff, headings #061b31 in sohne-var weight 300, CTA #533afd, blue-tinted shadows rgba(50,50,93,0.25), 4px border-radius

User: "Make an interface inspired by Linear"
→ Read `linear.app/DESIGN.md`
→ Apply: ultra-minimal layout, purple accent #5e6ad2, keyboard-first interactions
