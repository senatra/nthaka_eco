# Nthaka.Eco UI style guide

## Foundation

Use `AppTheme.light()` and `AppTheme.dark()` as the single visual source of truth. The app follows the platform system font with SF Pro preferred, then Inter, Segoe UI, and Roboto. The type scale is 34, 28, 22, 17, 15, 13, and 11. Use named `TextTheme` styles rather than custom font sizes.

Space layout on the 4pt/8pt grid with `AppTheme.spacing*`. Controls are 44px high with a 10px corner radius; cards are 14px and modal sheets are 20px.

## Buttons

`FilledButton` is primary: blue, 44px minimum touch target, 15px semibold label. Use `OutlinedButton` for secondary actions; it receives the shared light-gray/tinted fill. `TextButton` is tertiary. Use `AppTheme.destructiveIconButtonStyle` for icon-only destructive actions. Disabled controls use the framework disabled state automatically.

## Forms

Use `InputDecoration` with a top/floating `labelText`, optional `helperText`, and the validator error string. `TextField`, `TextFormField`, and `DropdownButtonFormField` automatically receive the shared 44px, 10px-radius surface, blue focus outline, muted placeholder, and red error state. Do not apply local fills, borders, or padding.

## Selection controls and feedback

Use `SwitchListTile`, `Checkbox`, `Radio`, `FilterChip`, and `SegmentedButton` without local styling. The theme supplies iOS-like green switches, blue selection states, accessible separators, and compact labels. Alerts, bottom sheets, date pickers, snackbars, and cards use the same surface, radius, and low-elevation treatment in light and dark mode.

## Accessibility and motion

Keep text labels on icon actions via `tooltip`, retain semantic labels, and preserve a 44px touch target. Platform focus and pressed states are kept visible through the shared button/input themes. Do not add essential animation; platform transitions and reduced-motion preferences remain respected.
