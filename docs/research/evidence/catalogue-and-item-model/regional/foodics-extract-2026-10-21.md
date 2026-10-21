# Foodics public developer docs — factual extract (2026-10-21)

Read on 2026-10-21 by the main session in the Claude built-in browser (script-rendered pages; the research fetch tool returned DNS errors, 403s or navigation only — part-6 F601, part-7 F708/F710). Public pages only, no sign-in, no API call, no cookie banner shown. **This is an extract of facts — endpoint paths, field names, types, enumerations and structure — written by the main session. Vendor prose is not copied** (copyright). The researcher of part 8 writes the findings from this file. API reference pages show "Last Updated: 9/1/2026, 6:22:28 AM" (as displayed by the site). Business sample values in the pages (SAR, +03:00) are the vendor's examples.

## E1 — Guide: Menu Structuring
URL: https://developers.foodics.com/guides/menu-structuring.html (no last-updated stamp shown)
- Menu hierarchy named by the guide: categories → products → modifiers; plus combos and menu groups.
- `GET /categories`: fields id, name, name_localized (nullable), reference, created/updated/deleted_at. Categories are optional for sending orders.
- `GET /products`: fields id, sku, barcode, name, name_localized, description, description_localized, image, is_active, is_stock_product, is_ready, pricing_method, selling_method, preparation_time, price, calories, timestamps. Each product must be attached to a category.
- `GET /products?include=category,tax_group,branches,modifiers`: `tax_group` {id, name}; `branches[]` with pivot {price (nullable), is_active, is_in_stock}; `modifiers[]` with pivot {is_splittable_in_half, minimum_options, maximum_options, free_options, default_options_ids, excluded_options_ids}.
- `GET /modifiers?include=options,options.tax_group,options.branches`: modifier {id, name, name_localized, is_ready}; option {id, name, name_localized, sku, is_active, is_in_stock, price, calories, tax_group, branches[] pivot {price, is_active, is_in_stock}}.
- `GET /combos?include=category,tags,timed_events,branches,sizes,items.options.products,items.options.branches`: combo {id, sku, barcode, name, name_localized, description(_localized), is_active, is_ready}; `sizes[]` {id, name, name_localized}; `items[]` (slots) {id, name, name_localized, is_upgradable, options[]}; each option has, per combo size id, {price, product{id}, branches[] pivot {price}}; combo `branches[]` pivot {is_active}; combos link `timed_events`.
- `GET /groups` (menu groups): {id, name, name_localized, image, items_index[]}; include products, combos, subgroups, giftCardProducts. The guide names uses: a different menu per branch, breakfast/lunch/dinner menus, a menu for a given third-party app.
- The guide tells integrators to use list endpoints rather than per-item gets (rate limit, HTTP 429).

## E2 — Guide: Order Calculation Formulas
URL: https://developers.foodics.com/guides/order-calculation-formulas.html
- Product taxes = the taxes common to the branch and the product (intersection); option taxes and charge taxes likewise (branch ∩ option, branch ∩ charge).
- Tax-exclusive unit price = unit price ÷ (1 + Σ rates/100) when tax-inclusive pricing is on, else unit price.
- Option total = product quantity × option quantity × option unit price.
- Product discount may or may not include modifiers (a flag); discounts can be taxable or not; order discount spread as a percentage.
- Order rounding amount = round(order sums) to a rounding level by a rounding mode − order sums; total = sums + rounding.

## E3 — Guide: Inventory Suppliers Integration
URL: https://developers.foodics.com/guides/inventory_suppliers_integration.html
- Branches = outlets; warehouses = central stores; both are locations for inventory transactions.
- Inventory items are raw and/or produced items used as ingredients; identified by name, SKU, barcode.
- Quantities in a purchase follow the item's storage unit; the guide's mapping table uses a purchase-to-storage factor (e.g. a pack of 12 litres → 12 litres; a 12-piece pack against a 6-piece storage pack → 2).
- Purchasing = transaction type 1 created closed (status 4); return to supplier = type 4; fields items.cost (excl. tax), paid_tax, invoice_number, invoice_date, additional_cost.
- Test-case list mentions "inventory end of day times" per branch/warehouse.

## E4 — API: Inventory Items
URL: https://apidocs.foodics.com/core/resources/inventory_items.html
- Fields: id, sku*, barcode, name*, name_localized, minimum_level, maximum_level, par_level (strings), storage_unit* (string), ingredient_unit* (documented type integer; sample value "gram"), storage_to_ingredient_factor* (double), costing_method* (1 fixed cost, 2 calculate cost from ingredients), category, cost (double), is_product (boolean), tags, branches (pivot minimum/maximum/par level per branch, in storage unit), ingredients (inventory items used to produce this item; pivot quantity, yield_percentage), suppliers (pivot order_unit, order_to_storage_factor, minimum_order_quantity, cost, code), yield_percentage ("net percentage of the produced inventory item").
- Attach ingredient: `POST /inventory_items/{id}/ingredients/{itemId}`, quantity in the ingredient unit.
- Levels per branch: `POST /inventory_items/{id}/branches/{branchId}`.
- Delete is soft (restore endpoint exists).

## E5 — API: Products (attributes only)
URL: https://apidocs.foodics.com/core/resources/products.html
- Additional fields beyond E1: is_stock_product ("cannot have more than 1 ingredient"; quantity and cost follow that single ingredient), is_non_revenue (excluded from revenue, tax-free, not discountable, refundable), pricing_method (1 preset, 2 open price), selling_method (1 unit, 2 weight), costing_method (1 fixed, 2 from ingredients), cost, discounts[], timed_events[], groups[], ingredients[].
- Modifier attachment pivot: unique_options (each option max 1), minimum_options, maximum_options, free_options, default_options_ids, excluded_options_ids.
- Branch pivot: price, is_active, is_in_stock.
- Ingredient pivot: quantity, **inactive_in_order_types** (order types in which that ingredient is not consumed).
- Attach endpoints: `/products/{id}/ingredients/{inventoryItemId}`, `/products/{id}/modifiers/{modifierId}`, `/products/{id}/branches/{branchId}`.

## E6 — API: Inventory Transactions
URL: https://apidocs.foodics.com/core/resources/inventory_transactions.html
- Fields include business_date, reference, type*, status*, branch*, other_branch, supplier, order, creator, poster, **reason**, items*, posted_at.
- Types: 1 Purchasing; 2 Transfer Sending; 3 Quantity Adjustment ("deducting quantities for customizable reasons"); 4 Return to Supplier; 5 Production; 6 Transfer Receiving; 7 Consumption from Production; 8 Consumption from Order; 9 Return from Order; 10 Waste from Order; 11 Return from Transfer; 12 Waste from Production.
- Type 10 is auto-created from waste actions on sales during void and returns; type 9 is the return-to-stock counterpart; type 12 from waste during production.
- Statuses: 1 Draft, 2 Pending, 3 Declined, 4 Closed.

## E7 — API: Inventory Day
URL: https://apidocs.foodics.com/core/resources/inventory_day.html
- `POST /inventory_end_day/{branchId}` manually ends the business day for one location.

## E8 — API: Settings (selected fields)
URL: https://apidocs.foodics.com/core/resources/settings.html
- business_currency, business_timezone, localization_enabled (boolean), receipt_main_language, receipt_localized_language, receipt_print_language (integer; sample 3), receipt_show_rounding, sms_localized_language, **tax_inclusive_pricing** (boolean, business-wide: "whether business prices are tax exclusive or tax inclusive"), final_price_rounding_level (0.01, 0.1, 0.25, 0.5, 1), final_price_rounding_method (none, average = closest half-up, up, down).
- Two-language model: a main language (`name`) and one localized language (`name_localized`).

## E9 — API: Timed Events
URL: https://apidocs.foodics.com/core/resources/timed_events.html
- Purpose: adjust menu prices or availability for a limited period; applied to the original price before all discounts.
- Fields: name, name_localized, type*, value*, priority, is_active, from_date*, to_date*, from_time*, to_time*, is_sat … is_fri (weekday flags), order_types* (array), products, combos, branches, tags, categories, price_tag, customer_tags.
- Types: 1 fixed price; 2 reduce by amount; 3 reduce by percent; 4 increase by amount; 5 increase by percent; 6 activate products; 7 deactivate products.

## E10 — API: Price Tags
URL: https://apidocs.foodics.com/core/resources/price_tags.html
- Purpose: one product with several prices for different order sources and order types, instead of duplicate products.
- Fields: name, name_localized, timed_events, products, combo_options, order_tag, modifier_options, branches.
- The sample branch object shows: name_localized, type, opening_from, opening_to, **inventory_end_of_day_time**, receipt_header, receipt_footer, settings {branch_tax_number, branch_tax_registration_name}.
