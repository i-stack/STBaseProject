# Migrating to STBaseProject 2.0

STBaseProject 2.0 removes the source-compatibility APIs that were retained for 1.x callers.

## API replacements

| Removed API | Replacement |
| --- | --- |
| `UIFont.st_systemFont` / `st_boldSystemFont` | `UIFont.st_preferredFont` or `STTypographyToken.font` |
| `UIFont.st_italicSystemFont` | Build an italic base font and scale it with `UIFontMetrics` |
| `UIFont.st_monospacedSystemFont` / `st_monospacedDigitSystemFont` | `UIFont.st_preferredMonospacedFont` or a `UIFontMetrics`-scaled digit font |
| Completion-based `STBaseViewModel.st_request`, `st_get`, `st_post`, `st_put`, `st_delete` | The corresponding `st_requestPublisher`, `st_getPublisher`, `st_postPublisher`, `st_putPublisher`, `st_deletePublisher` API |
| Completion-based `st_dispatchRequest` | `st_dispatchRequestPublisher` |
| `STProgressHUD` methods taking `animated: Bool` | Methods taking `animation: STHUDAnimation` |
| `STAlertController.setAutoDismissOnAction` | `setAutoDismiss` |
| `Data.isValidJSON` | `isJSONData` |
| `STBaseModel.st_getValueType` | `st_valueKind` |
| `STBtn.identifier` | `stringIdentifier`, `tag`, or `accessibilityIdentifier` |

`STCryptoService.st_clearKeyCache` has no replacement because the service does not maintain an in-memory key cache.

## Font scaling semantics

The removed `st_systemFont`, `st_boldSystemFont`, `st_italicSystemFont`, and monospaced font helpers multiplied their input by `STDeviceAdapter.widthScale`. Font sizes could therefore grow with the screen width, including on iPad and other wide layouts.

Their 2.0 replacements intentionally do not apply screen-width scaling. `st_preferredFont`, `st_preferredMonospacedFont`, and `STTypographyToken.font` apply the app-level `STFontManager.fontSizeScale` and then use `UIFontMetrics` for Dynamic Type. A mechanical symbol replacement can consequently produce a smaller font on wide layouts even though the code still compiles.

Prefer the new behavior for text: layout dimensions and text accessibility scaling should remain independent. If an existing component must preserve its former width-relative visual scale, derive the base size from that component's container and then apply Dynamic Type:

```swift
let adapter = STDeviceAdapter.containerAdapter(for: containerView.bounds.size)
let baseSize = adapter?.scaledWidth(designFontSize) ?? designFontSize
let font = UIFont.st_preferredFont(
    ofSize: baseSize,
    forTextStyle: .body,
    compatibleWith: containerView.traitCollection
)
```

Recalculate the font when the container size or preferred content size category changes. Do not use the global screen width as a substitute for the component's available width.

## Intentionally retained compatibility

The 2.0 migration does not change persisted or encrypted data formats, XIB/Storyboard adaptation behavior, or operating-system availability fallbacks.
