# Shared receipt attachments — HomeBuddy

Status: **implementation specification**, not yet a working feature. This branch is isolated from main. The existing local application currently has only task storage; appliance and receipt screens must be introduced together.

## User story

A person buys a washing machine, a microwave and a coffee maker on **one long receipt**. They capture the receipt once (multiple overlapping photos or a single PDF supported) and associate it with all three appliances. The original file(s) occupy disk space only once, while each appliance displays the same receipt.

## Required data model (Drift migration)

- `Appliances`: `id`, `name`, `brand?`, `model?`, `serialNumber?`, `purchasedAt?`, `room?`.
- `Receipts`: `id`, `createdAt`, `merchant?`, `purchaseDate?`, `currency?`, `totalAmountMinor?`, `originalFileName?`.
- `ReceiptFiles`: `id`, `receiptId`, `relativePrivatePath`, `mimeType`, `sha256`, `byteLength`, `pageOrder`. One receipt can consist of multiple pages/photos. Store binary bytes in app-private filesystem **once**, not as BLOBs in SQLite.
- `ApplianceReceipts`: `applianceId`, `receiptId`, `role` (purchase / warranty / other). Composite primary key on `(applianceId, receiptId, role)` (or choose another uniqueness invariant if role may change).
- `ReceiptLineItems` (optional): `id`, `receiptId`, `description`, `quantity?`, `unitPriceMinor?`, `lineTotalMinor?`. Optional `ReceiptLineItemAppliances` mapping supports explicit allocation of items on a shared receipt. Do not assume receipt total is the individual appliance price.

Use integer minor units for money and ISO currency codes. Never generate a default warranty expiry without a verified policy or user-provided date.

## File lifecycle / integrity

1. Import through camera, gallery or file picker. For a long receipt, support multiple images in ordered sequence; do **not** pretend an ordinary camera photo captured all text.
2. Copy selected files to private permanent app storage; never depend on image_picker temporary cache.
3. Optionally deduplicate *identical bytes* using SHA-256 plus byte-length confirmation. Do not merge different receipt photos just because OCR looks similar.
4. Wrap DB metadata and link modifications in transactions. Handle file writes and DB operations with staging/cleanup, since the filesystem cannot participate in a SQLite transaction.
5. The same receipt ID can link to an arbitrary number of appliances.
6. Removing a receipt from one appliance deletes only its **link**. Other appliances continue to access it.
7. Deleting the final link must **not silently destroy** the receipt. Offer: keep in Documents / permanently delete. For permanent deletion remove file bytes only after successful DB change and handle failures/retry.
8. Provide explicit deletion/retention behavior on appliance removal, orphan cleanup, and import cancellation.
9. Don't expose documents via public file paths. Use explicit temporary share/export copies when a user requests sharing.
10. Local export and future backup must preserve both receipt records and their appliance associations; restore must reconstruct links.

## Minimal UX acceptance

- Add appliance A; capture long store receipt as 2 photos.
- Add appliance B and C; choose **Attach existing receipt** → select the same receipt.
- Each appliance displays the receipt in Documents, including both photo pages.
- Show 'This receipt is linked to 3 appliances' and list their names.
- Unlink receipt from B: A and C still open it, only one stored file set exists.
- For each appliance allow optionally marking a receipt line item; never automatically divide the receipt's total across products.
- Creating an appliance without a receipt is allowed; receipt upload and OCR are optional.
- Avoid automatic uploads to any AI provider; OCR only after explicit user action and consent.

## Safety and privacy

Receipts can contain addresses, payment-card fragments, loyalty identifiers and purchased-item details. Keep local by default; no automatic cloud sync or AI analysis. Redact data only on explicitly requested exports, never edit the original evidence. Preserve originals for warranty or insurance claims. Make backup/export instructions clear: local-only data can be lost with the phone.

## Tests required

- Link one receipt to three appliances without file duplication.
- Add receipt from multi-photo import, ordering survives restart.
- Unlink one appliance; others retain access.
- Prevent duplicate join rows; attach existing receipt works after app restart.
- Import interrupted / storage full leaves no unusable records.
- Deleting appliance doesn't unexpectedly delete shared receipt.
- Orphan retention and explicit permanent deletion.
- Currency and amounts correctly represented.
- Export/restore round-trip preserves all links.
- Existing tasks and reminders unaffected by Drift migration.

## Integration plan for the MacBook Codex agent

1. Pull this branch or inspect this specification.
2. Review current **local** Drift schema and unapplied changes; do not overwrite newer local edits.
3. Implement migration, repositories, permanent storage, pages and actions with tests.
4. Show actual screenshots and test outputs, including `flutter analyze`, `flutter test`, Android debug build.
5. Merge only after review; do not claim this feature is implemented merely because this specification exists.
