// Matugen user.js
// Overrides Gecko's LookAndFeel system colors used for the native ::selection
// fallback paint (Highlight/HighlightText), independent of the GTK theme.
// ::selection rules in userContent.css don't apply to real web content in
// current Zen/Firefox (user-origin stylesheets are excluded from the
// highlight-pseudo-element cascade), so this is the only reliable way to
// theme text selection color on regular web pages.
user_pref("ui.highlight", "{{colors.primary.default.hex}}");
user_pref("ui.highlighttext", "{{colors.surface.default.hex}}");
user_pref("ui.selecteditem", "{{colors.primary.default.hex}}");
user_pref("ui.selecteditemtext", "{{colors.on_primary.default.hex}}");
