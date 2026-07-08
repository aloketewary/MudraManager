---
name: Mudra Precision
colors:
  surface: '#f3fcf3'
  surface-dim: '#d3dcd4'
  surface-bright: '#f3fcf3'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#edf6ed'
  surface-container: '#e7f0e8'
  surface-container-high: '#e1ebe2'
  surface-container-highest: '#dce5dc'
  on-surface: '#151d18'
  on-surface-variant: '#3b4a41'
  inverse-surface: '#2a322d'
  inverse-on-surface: '#eaf3ea'
  outline: '#6b7b70'
  outline-variant: '#bacbbe'
  surface-tint: '#006c46'
  primary: '#006c46'
  on-primary: '#ffffff'
  primary-container: '#01e599'
  on-primary-container: '#00613e'
  inverse-primary: '#00e297'
  secondary: '#296a4b'
  on-secondary: '#ffffff'
  secondary-container: '#abeec7'
  on-secondary-container: '#2e6e4f'
  tertiary: '#825500'
  on-tertiary: '#ffffff'
  tertiary-container: '#ffbd5d'
  on-tertiary-container: '#754c00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#4dffb2'
  primary-fixed-dim: '#00e297'
  on-primary-fixed: '#002112'
  on-primary-fixed-variant: '#005234'
  secondary-fixed: '#aef1ca'
  secondary-fixed-dim: '#92d5af'
  on-secondary-fixed: '#002112'
  on-secondary-fixed-variant: '#075134'
  tertiary-fixed: '#ffddb3'
  tertiary-fixed-dim: '#fcba5b'
  on-tertiary-fixed: '#291800'
  on-tertiary-fixed-variant: '#633f00'
  background: '#f3fcf3'
  on-background: '#151d18'
  surface-variant: '#dce5dc'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.04em
  display-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 42px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.05em
  mono-sm:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '400'
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
  container-margin: 24px
  gutter: 16px
---

## Brand & Style
The design system embodies a premium, future-forward fintech identity characterized by **Technical Minimalism** with a sophisticated, grotesque typographic edge. It targets high-net-worth users who value precision through a lens of modern accessibility.

The aesthetic remains a fusion of high-performance tools and organic elegance. The UI evokes a sense of "digital craftsmanship" through a **Light-Mode High-Contrast** aesthetic that emphasizes "Paper Tech"—a clean, gallery-like space punctuated by soft, rounded lines and high-vibrancy accents. The shift from a monochromatic base to a palette of deep forest greens and warm ambers adds a layer of established wealth and natural stability to the Swiss-inspired clarity.

## Colors
This design system utilizes a sophisticated light palette optimized for clarity and professional focus, moving away from pure grays toward tinted neutrals.

- **Background:** Crisp, neutral light surfaces (#f9faf9) form the foundation for all base layers to ensure readability and focus.
- **Primary (Vivid Mint):** A high-vibrancy accent (#01e599) used for primary action items, success states, and data highlights.
- **Secondary (Muted Forest):** A deep, professional green (#438362) used for structural elements and secondary emphasis.
- **Tertiary (Warm Amber):** A golden accent (#ffbd5d) reserved for growth indicators, premium features, and financial insights.
- **Neutral (Steel Sage):** A warm, greenish-gray (#707972) used for borders, secondary text, and low-priority icons.

## Typography
The typographic hierarchy is built on a technical grotesque pairing, moving away from rounded terminals toward a cohesive, geometric, and authoritative aesthetic.

- **Headlines:** Use **Hanken Grotesk** for its clean, contemporary geometry. Tracking is tightened in display sizes to maintain a "locked-in" editorial look.
- **Body:** **Hanken Grotesk** provides a consistent, highly legible feel for financial data and descriptions, offering professional weight.
- **Data/Labels:** **Geist** is used for currency values, timestamps, and metadata. Its precise, geometric nature provides a "modern-digital" character that feels high-tech and incredibly accurate.

## Layout & Spacing
The layout philosophy is **Expansive**. We avoid information density in favor of focus.

- **Grid:** A 12-column grid for desktop, 4-column for mobile.
- **Negative Space:** Use `lg` (48px) and `xl` (80px) spacing to separate major sections, allowing the spacious light background to act as a structural element.
- **Safe Areas:** Generous 24px horizontal margins on mobile to ensure content feels "inset" and premium.
- **Alignment:** Strict adherence to left-alignment for text, with financial figures often right-aligned for balance in lists.

## Elevation & Depth
Depth is achieved through **Tonal Layering and Soft Shadows**, using color-tinted depth rather than neutral grays to maintain the system's character.

- **The "Glass" Effect:** Floating cards use a 1px solid border (Muted Forest at 10-15% opacity) and a background blur (20px - 40px) to indicate elevation while maintaining an airy feel.
- **Tonal Stacking:** Surfaces are distinguished by subtle tonal shifts. A higher elevation level is represented by a slightly warmer, light-green fill.
- **Interactive Depth:** When a user interacts with a card, use a subtle lift (Z-axis shadow) with a soft, Sage-tinted character to maintain the approachable, premium character.

## Shapes
The shape language is dominated by **Rounded Precision**.

- **Cards:** Use `rounded-lg` (16px / 1rem) to create a soft, modern, and professional frame.
- **Buttons:** Medium-radius rounded corners that balance the sharp terminals of the Hanken Grotesk typeface.
- **Micro-elements:** Chips and tags should use `rounded-md` (8px / 0.5rem) to maintain consistency with the larger containers.

## Components
- **Primary Buttons:** Medium-radius rounded corners, Vivid Mint (#01E599) background with Muted Forest (#438362) text for high-contrast legibility.
- **Secondary Buttons:** Transparent background with a 1px border (Steel Sage at 30%) and medium-radius rounding.
- **Interactive Cards:** Subtle background blur with a soft stroke and `rounded-lg` corners. Content should have generous padding (24px-32px).
- **Inputs:** Minimalist filled container with `rounded-md` corners. The focus state should utilize the Primary Vivid Mint. Typography for values should use Geist.
- **Charts:** Ultra-thin lines (1.5px) in Vivid Mint or Warm Amber for comparison. No heavy grid lines; use a Steel Sage baseline.
- **Bottom Navigation:** A floating "dock" with high background blur and a 1px top border. Icons are stroke-based, switching to Vivid Mint when active.
- **Chips:** Small, rounded tags using `mono-sm` (Geist) typography, used for transaction categories.