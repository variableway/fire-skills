# Quality checklist — pre-delivery gate

Run before declaring any UI done. Every item is a known failure mode. This is the canonical merge of `frontend-design-masterclass` (§8, most complete), `frontend-design-engineer` (Fase 5), `ui-pro-magic` (Step 5), `taste-skill` (pre-flight), and `21st-frontend-design` (verify).

A passing checklist is **necessary but not sufficient** — also run the three success tests in `design-language.md` (justified / coherent / not-a-re-run).

## Visual

- [ ] No emoji used as UI icons — SVGs only (Lucide or Heroicons)
- [ ] All icons from one consistent set with matching `viewBox` (24×24)
- [ ] Brand logos verified against official sources (Simple Icons)
- [ ] Hover states cause NO layout shift (opacity/color, not `scale` transforms)
- [ ] No default Tailwind color classes without customization
- [ ] Typography pairing is intentional and loaded (not system fallback)
- [ ] No card sickness — landing pages use full-bleed sections, NOT card wrappers
- [ ] No orphan pills — decorative badges serving no function removed
- [ ] No stat strips or eyebrow titles above headlines
- [ ] Images have correct dimensions/aspect ratios (no bad crops or cutoffs)
- [ ] Design style name does NOT leak into the page copy
- [ ] Em dashes absent from shipped copy (headlines, subheads, buttons, descriptions)

## Interaction

- [ ] `cursor-pointer` on every clickable element
- [ ] Every interactive element has visible hover feedback
- [ ] Hover verified on ALL elements that *look* clickable (missing hovers reveal AI slop)
- [ ] Transitions 150–300ms (never >500ms UI, never 0ms); use motion tokens, not hardcoded
- [ ] Focus states visible and styled (not browser defaults, never `outline: none`)
- [ ] Touch targets ≥ 44×44px on mobile
- [ ] Nav backdrop/blur appears on scroll so it doesn't clash with content below

## Light / dark mode

- [ ] Light: text contrast passes WCAG AA (4.5:1 minimum)
- [ ] Light: glass/transparent elements use sufficient opacity (`bg-white/80+`, not `bg-white/10`)
- [ ] Light: borders `gray-200` or darker (not `white/10`)
- [ ] Dark: text off-white (`#E8E8E8`), not pure white
- [ ] Dark: surfaces use subtle gradients, not flat solid colors
- [ ] Both modes tested; no invisible elements in either

## Layout

- [ ] Floating nav has spacing from edges (not flush `top-0 left-0 right-0`)
- [ ] Content below fixed nav has compensating padding
- [ ] Consistent max-width container throughout (`max-w-6xl` / `max-w-7xl`)
- [ ] No horizontal scroll on mobile (test at 320px / 375px)
- [ ] Responsive breakpoints tested: 320, 768, 1024, 1440 px

## Accessibility

- [ ] Semantic HTML (`article`, `section`, `nav`, `main`)
- [ ] All images have descriptive `alt` text
- [ ] All form inputs have associated labels
- [ ] Color is never the only state indicator
- [ ] `prefers-reduced-motion` disables animations and parallax (global override shipped)
- [ ] Keyboard navigation works for all interactive elements

## Motion system

- [ ] Motion tokens (`--duration-*`, `--ease-*`) defined in `:root`
- [ ] No bare `ease`, `ease-in-out`, or hardcoded durations — tokens throughout
- [ ] Enters use `--ease-enter` (decelerate), exits use `--ease-exit` (accelerate)
- [ ] Enter durations ~1.25–1.5× exit durations (asymmetric)
- [ ] Modals/dialogs use `--ease-spring` on enter
- [ ] Animations use GPU-composited properties only (transform, opacity)

## Performance

- [ ] Fonts loaded with `display: swap` or preloaded (`next/font` in Next.js)
- [ ] Images use modern formats (WebP/AVIF) with `width`/`height` set
- [ ] No layout thrashing from scroll handlers (transient values on refs, not state)
- [ ] ≤ 3 WebGL canvases per page; heavy effects deferred via `next/dynamic { ssr: false }`
- [ ] Print stylesheet hides nav/footer, forces white background

## Code (stack-specific)

- [ ] TypeScript: no type errors (`npx tsc --noEmit`)
- [ ] No hardcoded generic colors (`bg-blue-500` etc.) — direction tokens applied
- [ ] Mobile-first verified (DevTools at 375px before delivery)
- [ ] shadcn base components not re-implemented with raw HTML
- [ ] `cn()` used for class merging; variants via CVA where applicable

## Post-generation vibe-check (quick)

1. **Card audit** — cards that shouldn't be cards? Remove them.
2. **Pill audit** — decorative pills/badges? Remove.
3. **Hover audit** — every clickable-looking element has a hover state?
4. **Nav audit** — exactly 3 default items? Vary it.
5. **Copy audit** — did the design style name leak into the copy?
6. **Image audit** — cropped correctly with good visual weight?
7. **Color audit** — defaulting to purple-blue gradients?

## Variety test (multi-surface sessions)

If you generate multiple pages or redesign within a session, each output MUST differ on:
- layout structure (not just a color swap)
- font pairing
- animation approach
- section flow (not the same hero → 3-cards → CTA → footer)

Identical structure + different colors = too few internal templates. Vary deliberately.
