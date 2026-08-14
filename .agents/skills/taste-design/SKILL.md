---
name: taste-design
description: Semantic Design System Skill for SMART MAINTENANCE (Google Stitch). Enforces premium, anti-generic UI standards across Flutter Mobile and React Dashboard — strict typography, calibrated color palettes, tactile components, and hardware-accelerated performance.
---

# Stitch Design Taste — SMART MAINTENANCE

## Single Source of Truth
Consult `DESIGN.md` at the project root for full color codes, typography pairings, and layout rules.

## Core Directives & Constraints

1. **Color Palette Enforcement**:
   - Primary Brand Accent: Emerald Green (`#0A543D`)
   - Secondary Accent / Badges: Gold / Warm Amber (`#EEBD1B`)
   - Action / Urgent CTA: Vivid Orange (`#EA580C`)
   - Canvas Neutrals: Deep Slate (`#0F172A`), Steel (`#475569`), Pure Card (`#FFFFFF`), Soft Background (`#F8FAFC`).
   - Pure black (`#000000`) and AI neon purple/blue glows are strictly BANNED.

2. **Typography Standards**:
   - Titles/Headlines: Track-tight `-0.02em`, Outfit / Cabinet Grotesk / Montserrat.
   - Body/Paragraphs: Relaxed 1.5 leading, Inter / Geist / Roboto.
   - Monospace: JetBrains Mono / Geist Mono for intervention references (`#302`), codes (`FGA1`), and currency amounts (`FCFA`).

3. **Component & Mobile UX Standards**:
   - Minimum tap target: **44px × 44px** on mobile.
   - Buttons: Tactile feedback on active state (`-1px` vertical translate).
   - Cards: Subtle borders (`1px` Slate-200), rounded corners (12-16px), diffused whisper shadows.
   - Skeletons: Prefer animated skeleton loaders over raw circular progress indicators during async loading states.

4. **Anti-Patterns ("AI Tells" to Avoid)**:
   - No pure black background or text.
   - No fake AI-generated statistics (e.g. "99.99% Uptime SLA", "124ms response time").
   - No missing cancellation / back buttons on payment modals.
   - No truncation issues without proper `ellipsis` handling.
