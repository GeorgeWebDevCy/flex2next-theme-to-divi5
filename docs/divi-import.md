# Flex2 Next -> Divi 5 Import

Files created for the migration:

- `exports/flex2next-divi5-homepage.json`
- `exports/flex2next-divi5-theme-builder.json`
- `flex2next-divi-child/`
- `scripts/build-flex2-divi5-export.ps1`

## What the export includes

- A Divi 5 homepage layout built from `divi/*` blocks.
- A Divi Theme Builder export that creates the default website template with a global header and global footer.
- Flex2 global colors and variables imported into Divi.
- Shared site styling loaded from the child theme instead of page-only custom CSS.
- The contact form rendered from `[fluentform id="1"]` inside a Divi text module so the shortcode executes on the front end.

## Import order

1. Activate the `flex2next-divi-child` theme.
2. Open `Divi > Theme Builder`.
3. Use Divi portability import there and import `exports/flex2next-divi5-theme-builder.json`.
4. When prompted, import it as the default website template so the global header and footer are assigned correctly.
5. Create or open the homepage you want to use and enable Divi Builder on that page.
6. Import `exports/flex2next-divi5-homepage.json` into that page.
7. Keep the page on the normal/default template. Do not use `Blank Page`, because the Theme Builder now supplies the header and footer.
8. Set that page as the site homepage in WordPress settings.

## Child theme

The child theme is now required for the migration if you want the imported layout to match the source design:

- It loads the Flex2 Geist and Geist Mono font faces.
- It contains the shared styling for the homepage plus the Theme Builder header and footer.
- It keeps the content editable in Divi instead of locking the site into PHP templates.

## Fluent Forms note

The layout uses `[fluentform id="1"]`.

The repository file `fluentform-export-forms-1-11-03-2026.json` appears to contain a form with `id: 2`, not `id: 1`.

If your final form ID is different after import, update the shortcode inside the Divi contact section text module.

## Regenerating the exports

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-flex2-divi5-export.ps1
```
