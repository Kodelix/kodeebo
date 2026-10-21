# Loyverse public API reference — factual extract (2026-10-21)

Read on 2026-10-21 by the main session in the Claude built-in browser (script-rendered page; the research fetch tool returned only the page header or a DNS error — part-6 F601). Public page only, no sign-in, no API call, no cookie banner shown. **Extract of facts — field names, types, enumerations, structure — written by the main session; vendor prose is not copied.** The researcher of part 8 writes the findings from this file.

URL: https://developer.loyverse.com/docs/ — "Loyverse API (1.0)"; base URL `https://api.loyverse.com/v1.0`. No page-level last-updated date was found.

## L1 — Items
- Item fields seen: item_name (1..64 chars), handle, category_id, image_url, option1_name, option2_name, option3_name (three option axes; examples Size, Color, Material), track_stock (default false), sold_by_weight (default false), is_composite ("contains a specified quantity of other items"), use_production (default false), components[] {variant_id, quantity (sample 999999.999)}, primary_supplier_id, tax_ids[] (taxes applied to the item), modifiers_ids[], form (SQUARE, CIRCLE, SUN, OCTAGON) and color (GREY, RED, PINK, ORANGE, GREEN, BLUE, PURPLE) — the counter tile's shape and colour.
- No name translation or localization field was found anywhere in the reference (text search for "translat", "locali": no match).

## L2 — Variants
- Variant fields seen: variant_id, sku (1..40 chars, unique), reference_variant_id (≤128, external reference), barcode (1..128), cost, purchase_cost, default_pricing_type (FIXED or VARIABLE; default VARIABLE), default_price, and `stores[]` per variant: {store_id, pricing_type (FIXED/VARIABLE), price, available_for_sale, optimal_stock, low_stock}.

## L3 — Modifiers
- Modifier: id, name, position, stores[] (store ids where available), modifier_options[] {id, name, price, position}. No minimum, maximum, required or default field appears in the modifier schema sample.

## L4 — Taxes and inventory
- A tax has `type` INCLUDED or ADDED (per tax).
- Inventory level: {variant_id, store_id, in_stock (number ≤ 9999999.999)}; update by store_id with stock_after.
- Shift totals compute gross sales "after taxes with type INCLUDED" (shift object description).
