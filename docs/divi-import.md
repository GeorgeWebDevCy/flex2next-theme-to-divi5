# Flex2 Next -> Divi 5 Import

Files created for the migration:

- `exports/flex2next-divi5-homepage.json`
- `flex2next-divi-child/`
- `scripts/build-flex2-divi5-export.ps1`

## What the export includes

- A Divi 5-native layout built from `divi/*` blocks, not legacy `et_pb_*` shortcodes.
- Flex2 global colors imported as Divi global colors.
- Flex2 spacing, typography, radius, and sizing tokens imported as Divi global variables.
- Page-level custom CSS that recreates the current dark Flex2 one-page site.
- A single shortcode in the layout: `[fluentform id="1"]`.

## Import order

1. Activate the `Divi` parent theme or the `flex2next-divi-child` theme.
2. In WordPress, create or open the homepage you want to use.
3. Enable Divi Builder on that page.
4. Open Divi portability import and import `exports/flex2next-divi5-homepage.json`.
5. Set the page template to `Blank Page` so the Divi layout controls the header and footer.
6. Set that page as the site homepage in WordPress settings.

## Child theme

The child theme is intentionally minimal:

- It only declares the Flex2 Geist font faces.
- It does not lock content into PHP templates.
- All homepage structure and copy remain editable inside Divi.

## Fluent Forms note

The layout uses `[fluentform id="1"]` exactly as requested.

The repository file `fluentform-export-forms-1-11-03-2026.json` appears to contain a form with `id: 2`, not `id: 1`.

If your imported/contact form ends up with a different ID:

- either update the shortcode inside Divi after import, or
- recreate/import the form so the final shortcode really is `[fluentform id="1"]`.

## Regenerating the export

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-flex2-divi5-export.ps1
```
