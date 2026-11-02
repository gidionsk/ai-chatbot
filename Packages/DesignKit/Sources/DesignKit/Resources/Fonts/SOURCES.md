# Font resources

DesignKit bundles eight static faces. Register all of them once during bootstrap
with `try FontFace.registerFonts()`. `FontLoader` handles repeated registration.
The exact PostScript names below were read from each bundled font's name table.

| FontFace | File | PostScript name |
| --- | --- | --- |
| `firaSansRegular` | FiraSans-Regular.ttf | FiraSans-Regular |
| `firaSansMedium` | FiraSans-Medium.ttf | FiraSans-Medium |
| `firaSansSemiBold` | FiraSans-SemiBold.ttf | FiraSans-SemiBold |
| `firaSansBold` | FiraSans-Bold.ttf | FiraSans-Bold |
| `firaSansItalic` | FiraSans-Italic.ttf | FiraSans-Italic |
| `openSansRegular` | OpenSans-Regular.ttf | OpenSansRoman-Regular |
| `openSansMedium` | OpenSans-Medium.ttf | OpenSansRoman-Medium |
| `openSansBold` | OpenSans-Bold.ttf | OpenSans-Bold |

## Sources and licenses

- Fira Sans version 4.203: unmodified static files from
  [google/fonts, revision e345593](https://github.com/google/fonts/tree/e345593da2a4d596212542edbd28f2ed08fe6cbe/ofl/firasans).
  The upstream license is included verbatim as `FiraSans-OFL.txt`.
- Open Sans Regular/Medium version 3.003: existing starter static files from
  [Open Sans](https://fonts.google.com/specimen/Open+Sans). These files use the
  `OpenSansRoman-…` PostScript naming scheme.
- Open Sans Bold version 3.003: unmodified static file from
  [googlefonts/opensans, revision bd7e376](https://github.com/googlefonts/opensans/blob/bd7e37632246368c60fdcbd374dbf9bad11969b6/fonts/ttf/OpenSans-Bold.ttf).
  Its PostScript name is `OpenSans-Bold`, with no `Roman` segment.

Both families use the SIL Open Font License 1.1; the existing `OpenSans-OFL.txt`
covers Open Sans. Preserve font copyright notices and licenses when distributing
the package.

Chinese glyphs use the iOS Core Text fallback cascade when absent from the
selected font. Tests check that all eight faces render Chinese without missing
glyph boxes. Verify the final approved Chinese font before brand sign-off.
