# Font resources

DesignKit bundles six static Fira Sans faces. Register all of them once during bootstrap
with `try FontFace.registerFonts()`. `FontLoader` handles repeated registration.
The exact PostScript names below were read from each bundled font's name table.

| FontFace | File | PostScript name |
| --- | --- | --- |
| `firaSansRegular` | FiraSans-Regular.ttf | FiraSans-Regular |
| `firaSansMedium` | FiraSans-Medium.ttf | FiraSans-Medium |
| `firaSansSemiBold` | FiraSans-SemiBold.ttf | FiraSans-SemiBold |
| `firaSansBold` | FiraSans-Bold.ttf | FiraSans-Bold |
| `firaSansItalic` | FiraSans-Italic.ttf | FiraSans-Italic |
| `firaSansBoldItalic` | FiraSans-BoldItalic.ttf | FiraSans-BoldItalic |

## Sources and licenses

- Fira Sans version 4.203: unmodified static files from
  [google/fonts, revision e345593](https://github.com/google/fonts/tree/e345593da2a4d596212542edbd28f2ed08fe6cbe/ofl/firasans).
  The upstream license is included verbatim as `FiraSans-OFL.txt`.

Fira Sans uses the SIL Open Font License 1.1. Preserve font copyright notices and
licenses when distributing the package.

Chinese glyphs use the iOS Core Text fallback cascade when absent from the
selected font. Tests check that all six faces render Chinese without missing
glyph boxes. Verify the final approved Chinese font before brand sign-off.
