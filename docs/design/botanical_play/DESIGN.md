---
name: Botanical Play
colors:
  surface: '#f8faf5'
  surface-dim: '#d9dbd6'
  surface-bright: '#f8faf5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4ef'
  surface-container: '#edeee9'
  surface-container-high: '#e7e9e4'
  surface-container-highest: '#e1e3de'
  on-surface: '#191c19'
  on-surface-variant: '#414942'
  inverse-surface: '#2e312e'
  inverse-on-surface: '#f0f1ec'
  outline: '#717971'
  outline-variant: '#c1c9bf'
  surface-tint: '#366847'
  primary: '#00361a'
  on-primary: '#ffffff'
  primary-container: '#1a4d2e'
  on-primary-container: '#88bd95'
  inverse-primary: '#9dd3aa'
  secondary: '#b80049'
  on-secondary: '#ffffff'
  secondary-container: '#e2165f'
  on-secondary-container: '#fffbff'
  tertiary: '#002f54'
  on-tertiary: '#ffffff'
  tertiary-container: '#004678'
  on-tertiary-container: '#71b5ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#b8f0c5'
  primary-fixed-dim: '#9dd3aa'
  on-primary-fixed: '#00210e'
  on-primary-fixed-variant: '#1d5031'
  secondary-fixed: '#ffd9de'
  secondary-fixed-dim: '#ffb2be'
  on-secondary-fixed: '#400014'
  on-secondary-fixed-variant: '#900038'
  tertiary-fixed: '#d1e4ff'
  tertiary-fixed-dim: '#9ecaff'
  on-tertiary-fixed: '#001d36'
  on-tertiary-fixed-variant: '#00497d'
  background: '#f8faf5'
  on-background: '#191c19'
  surface-variant: '#e1e3de'
typography:
  display-lg:
    fontFamily: Montserrat
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Montserrat
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 48px
  xl: 80px
  gutter: 24px
  margin: 32px
---

## Brand & Style

This design system establishes a premium, hospitable atmosphere for high-end play park management. It bridges the gap between sophisticated SaaS efficiency and the joyful, organic nature of a luxury botanical park. The personality is grounded and professional yet vibrantly energetic, ensuring that park administrators feel in control while the interface reflects the warmth of the guest experience.

The design style is **Modern Organic**. It leverages expansive white space, soft layered depth, and hyper-rounded geometry to evoke feelings of safety, growth, and premium service. It avoids the clinical "bare-bones" look of traditional POS systems in favor of a lush, tactile interface that mirrors the physical beauty of a well-maintained garden.

## Colors

The palette is anchored by **Deep Green**, providing a professional and natural foundation that suggests stability and growth. The **Warm Pink** accent serves as the "heart" of the system, used sparingly for primary actions and brand-centric highlights.

- **Primary (Deep Green):** Used for navigation, headers, and primary structural elements. 
- **Accent (Warm Pink):** Reserved for high-priority calls to action and "bonding" moments in the UI.
- **Supportive Highlights:** Soft Blue (Status/Info), Orange (Warnings/Active Sessions), and Yellow (Attention/Premium tiers) add a playful variety without compromising the professional base.
- **Backgrounds:** Utilizes a hierarchy of clean whites and subtle off-whites (#F8F9FA) to maintain a crisp, airy aesthetic that prioritizes legibility.

## Typography

The typography strategy pairs the geometric confidence of **Montserrat** for headings with the supreme utility of **Inter** for body text and data.

- **Headlines:** Use Montserrat to convey a modern, premium feel. Bold weights are preferred for high-level navigation and section titles to create a strong visual hierarchy.
- **Body & UI:** Inter is used for all functional text, ensuring high legibility in data-dense park management views.
- **Hierarchy:** Generous scale differences between display titles and body text are used to create an editorial, "high-end magazine" feel within the dashboard.

## Layout & Spacing

The layout philosophy follows a **Fluid Grid** with intentional "breathability." It avoids the cramped density of legacy management software, opting for generous margins and internal padding to reduce cognitive load.

- **Grid:** A 12-column system for desktop, transitioning to 4 columns for mobile.
- **Rhythm:** An 8px linear scale governs all spacing. For large container padding, `lg` (48px) is the default to ensure the "premium" feel of unhurried space.
- **Responsive Behavior:** On mobile, margins reduce to 16px, but touch targets remain at a minimum of 48px to accommodate busy park staff on the move.

## Elevation & Depth

This design system uses **Ambient Shadows** and **Tonal Layers** to create a sense of physical presence.

- **Surface Levels:** The primary background is the lowest level. White cards with soft shadows represent the interactive layer.
- **Shadow Profile:** Shadows should be highly diffused, using a slight primary color tint (e.g., #1A4D2E at 4-8% opacity) rather than pure black. This keeps the shadows feeling "natural" and soft, like shade in a garden.
- **Interaction Depth:** When an element is pressed or active, it should visually "settle" into the page (reduced shadow) or lift (increased blur) to provide tactile feedback.

## Shapes

The shape language is defined by **pronounced circularity**. To achieve the "friendly and safe" feel requested, the design system utilizes higher-than-average corner radii.

- **Base Radius (8px):** For small inputs and nested elements.
- **Standard Radius (16px):** For standard buttons and UI cards.
- **Large Radius (24px - 32px):** For main containers, modal windows, and primary action buttons.
- **Full Rounding:** Used for status chips and decorative avatars to reinforce the organic, petal-like brand identity.

## Components

### Buttons & Interactivity
Buttons feature 24px-32px corner radii. The **Primary Action** uses the Warm Pink (#E91E63) with white text. **Secondary Actions** use the Deep Green outline or subtle grey fills. All buttons must have a minimum height of 48px to remain touch-friendly.

### Cards
Cards are the primary container for visitor data and park metrics. They feature a white background, 24px corner radius, and a "Soft Depth" shadow. Use the Primary Green for thin header accents within cards to denote category.

### Chips & Status Indicators
Status chips use pill-shaped (fully rounded) geometry. They utilize the supportive palette (Blue, Orange, Yellow) with low-opacity backgrounds and high-contrast text for immediate glanceability without visual clutter.

### Inputs
Input fields should feel "hollow" and clean, using a light grey border (#E0E0E0) that thickens and changes to Deep Green on focus. Corners should match the button radius (16px) for a consistent "squishy" tactile feel.

### Lists & Tables
Lists should avoid harsh dividing lines. Instead, use alternating row backgrounds in very soft grey or leave 8px of vertical space between list-items to maintain the airy layout philosophy.

### Progress & Availability Icons
Use organic, leaf-inspired or circular progress bars to indicate park capacity or session time remaining, echoing the "Garden" theme of the brand.