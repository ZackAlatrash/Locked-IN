# Locked In — Design Reference

This document captures the visual design language of the three main app screens (Cockpit, Planning, Logs) to serve as the reference baseline for onboarding redesign. All values are sourced directly from the codebase.

---

## Color System

### Base Backgrounds
| Role | Dark Mode | Light Mode |
|------|-----------|------------|
| Primary BG | `#0a0505` | `#F8F9FB` |
| Secondary BG | `#0f0808` | subtle peach/blue radials |
| Tertiary BG | `#120a0a` | — |
| Surface Dark | `#2d1b1c` | — |

### Cockpit Screen Backgrounds
| State | Dark | Light |
|-------|------|-------|
| Stable | Linear `#1A243D` → `#020617` | `#F8F9FB` + peach/blue radials |
| Recovery | Layered radials with `#DC2626`, `#7F1D1D` | `#FCF4F4` + pink radials |

### Accent / Authority Color
| Role | Value |
|------|-------|
| Primary Accent (stable) | Cyan `#22D3EE` |
| Authority / Recovery | Red `#ea2a33` (Theme) / `#EF4444` (logs) |
| Recovery Soft | `#F87171` (dark) / `#B91C1C` (light) |

### Text
| Role | Dark | Light |
|------|------|-------|
| Primary | `Color.white` | `#0B1220` |
| Secondary | `Color.white` opacity `0.80` | `#0B1220` reduced opacity |
| Tertiary | `Color.white` opacity `0.40` | — |
| Muted | `Color.white` opacity `0.30` | — |

### Glass / Card Surfaces
| Role | Dark | Light |
|------|------|-------|
| Glass Fill | `#0f0808` opacity `0.65` | `Color.white` opacity `0.72` |
| Glass Border | `Color.white` opacity `0.08–0.10` | `#B9C7D7` opacity `0.78` |
| Glass Highlight | `Color.white` opacity `0.04–0.10` at top | — |
| Card BG (Cockpit protocol) | `#162331` | — |

### Recovery Mode Override (all screens)
| Role | Dark | Light |
|------|------|-------|
| BG Gradients | `#15080A`, `#7F1D1D` | warm pinks |
| Glass Fill | `#1B0A0D` opacity `0.56` | `Color.white` opacity `0.84` |
| Glass Stroke | `#F87171` opacity `0.32` | `#FCA5A5` opacity `0.72` |

### Semantic / Status Colors
| State | Dark | Light |
|-------|------|-------|
| Completed (Blue Day) | `#22D3EE` opacity `0.82` | `#38BDF8` |
| Medium | `#06B6D4` opacity `0.68` | `#7DD3FC` |
| Violation | `#EF4444` opacity `0.36` | `#FCA5A5` |
| Unproductive | `#DC2626` opacity `0.22` | `#FECACA` |
| Extra | `#FDE047` opacity `0.80` | `#FDE68A` |
| Idle / Empty | `Color.white` opacity `0.06` | `#60A5FA` opacity `0.18` |

### Borders & Progress
| Role | Value |
|------|-------|
| Border | `#663336` |
| Progress Active | Authority/accent color |
| Progress Inactive | `Color.white` opacity `0.10` |

---

## Typography

Font family: **Inter** (system font stack, heavy weights used extensively).

| Style | Size | Weight | Tracking |
|-------|------|--------|----------|
| Display Large | 30px | Bold | — |
| Display Medium | 26px | Bold | — |
| Headline Large | 22px | Semibold | — |
| Headline Medium | 18px | Semibold | — |
| Body Large | 16px | Medium | — |
| Body Medium | 14px | Regular | — |
| Body Small | 12px | Regular | — |
| Button Large | 18px | Black (900) | — |
| Button Medium | 15px | Black | — |
| Caption | 10px | Bold | +0.05 to +0.20 |
| Caption Small | 11px | Semibold | — |
| Section Headers | 10px | Bold | +2.1px (UPPERCASE labels) |
| Monospaced Labels | 9–12px | Bold/Semibold | +0.8–2.0px |
| Reliability Value | 58px | Black | — |
| Protocol Title | 50px | Heavy | — |

**Tracking conventions:**
- Tight: `-0.02` (long headlines)
- Wide: `+0.05` (labels)
- Widest: `+0.20` (section dividers)
- UPPERCASE pill/badge labels: `+0.8–2.1px` literal

---

## Spacing

4px baseline grid.

| Token | Value |
|-------|-------|
| xxxs | 2px |
| xxs | 4px |
| xs | 8px |
| sm | 12px |
| md | 16px |
| lg | 20px |
| xl | 24px |
| xxl | 32px |
| xxxl | 48px |
| xxxxl | 64px |

Common screen horizontal padding: **16px**.

---

## Corner Radius

| Token | Value |
|-------|-------|
| xs | 4px |
| sm | 8px |
| md | 12px |
| lg | 16px |
| xl | 24px |
| Capsule | Full (9999px) |
| Protocol cards | 24px |
| Glass cards (cockpit) | 14–26px |
| Session history cards | 22px |
| Matrix cells | 4px |

---

## Shadows

| Role | Value |
|------|-------|
| Card shadow | `Color.black` opacity `0.40`, radius `32px` |
| Button shadow | radius `20px` |
| Accent glow | Primary color opacity `0.50–0.60`, radius `6–20px` (dark only) |
| Dark mode only — no glows in light mode |

---

## Glass Morphism Pattern

The core card surface used throughout all screens:

```
Fill:      theme glass background color at 0.65 opacity
Border:    1px stroke, Color.white at 0.08–0.10 opacity
Highlight: subtle white gradient at top (0.04–0.10 opacity)
Shadow:    Color.black 0.40–0.80, radius 8–32px
Backdrop:  .ultraThinMaterial or simulated blur
```

In **light mode**: fill flips to `Color.white` at `0.72`, border to `#B9C7D7` at `0.78`.

In **recovery mode**: fill becomes warm dark red, border picks up red tint.

---

## Button Styles

| Type | Shape | Height | BG | Border |
|------|-------|--------|-----|--------|
| Primary CTA | RoundedRect | 64px | Accent solid | None |
| Secondary | Capsule | ~40px | Accent opacity 0.20 | Accent opacity 0.42, 1px |
| Icon button | Circle 44px | 44px | White opacity 0.08 | White opacity 0.12 |
| Glass pill | Capsule | ~34px | Glass fill | Glass stroke |

Press state: scale `0.98`, opacity `0.90`, `easeInOut 0.2s`.

---

## Animation

| Role | Duration | Curve |
|------|----------|-------|
| Micro (tap feedback) | 0.18s | easeOut |
| Content transitions | 0.36s | spring (response 0.3, damping 0.82) |
| Context/modal | 0.45s | easeInOut |
| Snappy | 0.26s | spring (damping 0.86) |
| Staggered list | 0.06s per item | content spring |

---

## Component Patterns

### Section Headers
All-caps, monospaced or caption bold, `0.8–2.1px` letter spacing. Examples:
- `"ACTIVE PROTOCOLS"` — 10px bold, 2.1px tracking
- `"STRUCTURAL PLAN"` — caption bold, monospaced, 2px tracking
- `"UP NEXT"` — 10px bold, 1.8px tracking

### Status Badges / Pills
- Shape: Capsule
- Padding: `8px H / 5px V`
- Font: 9–10px, Black weight, `0.5–0.8px` tracking
- BG: Accent opacity `0.12–0.20`
- Border: Accent opacity `0.25–0.35`, 1px
- Status dot: 6–7px circle, accent color with shadow

### Progress Bars
- Height: 8–10px
- Shape: Capsule
- Track: `Color.white` opacity `0.07–0.10`
- Fill: Accent color with shadow glow (dark mode)

### Connectivity / State Banners
- Shape: Capsule
- BG: `Color.white` opacity `0.05` (dark) / `0.80` (light)
- Border: 1px glass stroke
- Status dot: 6px, cyan or amber depending on state

---

## Dark vs Light Mode Strategy

The app does not simply invert colors — each mode has its own intentional palette:

- **Dark mode** is the primary design surface. Deep near-black backgrounds, glowing accents, white text, glow shadows only in dark mode.
- **Light mode** uses off-whites and subtle tinted backgrounds. Glass cards become white-filled. Borders pick up a blue-gray tone. No glows.
- **Recovery mode** is a full theme override on top of either base mode — warm reds replace cyan, background gradients shift to deep reds/purples (dark) or pinks (light).

When implementing onboarding screens, both modes must be handled explicitly. Do not assume dark-mode values will invert correctly.

---

## SF Symbols Used in Main Screens

- `person.crop.circle` — Profile
- `checkmark.circle.fill` — Completion
- `xmark.octagon.fill` — Violation
- `checkmark.shield.fill` — System stable state
- `exclamationmark.triangle.fill` — Warnings
- `arrow.up.right` — Trend
- `plus.circle.fill` — Add protocol
- `slider.horizontal.3` — Regulate
- `rectangle.split.3x1` — Board mode toggle
- `line.3.horizontal.decrease.circle` — Filters

---

## Key Onboarding Design Constraints

When redesigning onboarding screens to match the main app, follow these rules:

1. **Use the same glass card pattern** — same fill, border, highlight.
2. **Never use pure `Color.black`** as a background — use `#0a0505` or the screen-specific gradient.
3. **Primary CTA buttons** are full-width, 64px tall, accent-filled, Black weight text.
4. **Section labels** are always ALL-CAPS, caption bold, wide letter spacing.
5. **Both light and dark mode** must be handled — do not rely on system inversion.
6. **No glows in light mode** — remove box shadows from accent elements when in light mode.
7. **Typography is Inter** — no other font family.
8. **Recovery mode** should not appear in onboarding (user hasn't started yet).
9. **Haptics** on all meaningful interactions, consistent with main app.
10. **Spacing** always from the Theme spacing token set — no arbitrary values.
