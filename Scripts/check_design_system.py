#!/usr/bin/env python3
#
#  check_design_system.py
#  ai-chatbot
#
#  Created by Wendra on 15/10/26.
#

"""Guard starter tokens, production literals, boundaries and three-language copy."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors = []
# These files own technical metadata or format/transform arithmetic, not user-facing copy.
METADATA = {
    'Typography/FontFace.swift', 'Extensions/Color+Hex.swift', 'Extensions/String+Resource.swift',
    'Foundations/Accessibility/ComponentIdentifier.swift',
    'Shared/Keys/ChatElementIdentifier.swift', 'Shared/Keys/ChatCopy.swift',
    'Features/Chat/Session/ChatWire.swift', 'Features/Chat/Session/ChatBackoff.swift',
    'Features/Chat/Session/ConversationState.swift', 'Features/Chat/Session/WireError.swift',
    'Features/Chat/Session/WireCancel.swift',
    'TanyaAISandboxApp/SandboxOptions.swift', 'TanyaAISandboxApp/SandboxCopy.swift',
    'TanyaAISandboxApp/SandboxFixtureFile.swift', 'TanyaAISandboxApp/TanyaAI/SandboxGatewayFrames.swift',
    'TanyaAISandboxApp/TanyaAI/SandboxWireMessage.swift'
}
paths = list((ROOT / 'Packages').glob('*/Sources/**/*.swift'))
paths += list((ROOT / 'TanyaAISandboxApp').glob('**/*.swift'))
for path in sorted(paths):
    if 'Generated' in path.parts:
        continue
    source = path.read_text()
    text = re.sub(r'/\*.*?\*/|//[^\n]*', '', source, flags=re.DOTALL)
    relative = path.relative_to(ROOT).as_posix()
    def report(message):
        errors.append(f'{relative}: {message}')
    if re.search(r'FigmaSize\.(?:spacing\d+|typographySize\d+|typographyLineHeight\d+)\b', text):
        report('Use named Figma tokens such as spacingSmall/Medium/Large and semantic typography.')
    if re.search(r'\.\s*sizeInArtwork\b|\bvar\s+sizeInArtwork\b|\bDesignKitMetrics\b', text):
        report('Use scaledToArtwork and CustomSizes in this starter.')
    if re.search(r'\b(?:minimumTapSize|strokeInArtwork|tapTargetInArtwork)\b', text):
        report('Use scaledToArtwork directly; tap/stroke sizes follow the design values.')
    if 'DesignKit' in path.parts and re.search(r'\bTanya\w*|\bimport\s+Tanya', source):
        report('DesignKit must remain feature-independent.')
    if 'Tokens' not in path.parts:
        # CustomSizes berisi dimensi point; selalu di-scale.
        # Baris, waktu, toleransi dan inset layar host tidak pernah.
        if re.search(r'\bCustomSizes\.\w+\.\w+\b(?!\s*\.scaledToArtwork)', text):
            report('CustomSizes values are artwork points; use them with .scaledToArtwork.')
        never_scaled = r'CustomTextLines|CustomMotion|LayoutTolerance|ArtworkScale|CustomScreenInsets'
        if re.search(rf'\b(?:{never_scaled})\b[\w.]*\.scaledToArtwork', text):
            report('Line counts, motion, tolerances and artwork references are never scaled.')
    if 'Tokens' in path.parts or any(relative.endswith(item) for item in METADATA):
        continue
    if re.search(r'"(?:\\.|[^"\\])*"', text):
        report('Use copy key enums (ChatCopy, SandboxCopy) and DesignIcon; keep technical metadata with its owner.')
    if re.search(r'(?<![\w.$])\d+(?:\.\d+)?(?![\w.])', text):
        report('Use FigmaSize, CustomSizes, CustomTextLines or the type value (.zero) instead of literals.')
    if re.search(r'\.(?:foregroundColor|background|fill|strokeBorder)\(\s*\.(?:red|white|black|gray|blue)', text):
        report('Use generated colors or CustomColors.')
    if not relative.endswith('Extensions/View+DesignColors.swift') and re.search(r'\b\w+ColorConstants\(\)', text):
        report('Read @Environment(\\.designColors); choose a palette with .designColors(_:) at the root.')

if re.search(r'\bInitialValues\b', '\n'.join(path.read_text() for path in paths)):
    errors.append('Use the type value (.zero, String()) instead of an InitialValues alias.')
if re.search(r'@(?:Observable|Model|Namespace|ScaledMetric)\b|#(?:externalMacro|Observable|Model)\b',
             '\n'.join(path.read_text() for path in paths)):
    errors.append('Starter uses basic SwiftUI wrappers only; no macros, Namespace or ScaledMetric.')

resources = ROOT / 'Packages/TanyaAI/Sources/TanyaAI/Resources'
tables = {}
for path in resources.glob('*.lproj/Localizable.strings'):
    entries = re.findall(r'^"([^"]+)"\s*=\s*"(.*)";', path.read_text(), re.MULTILINE)
    if len(dict(entries)) != len(entries):
        errors.append(f'{path}: duplicate key')
    tables[path.parent.stem] = dict(entries)
if set(tables) != {'en', 'id', 'zh-Hans'}:
    errors.append('Resources must include en, id and zh-Hans.')
for locale, table in tables.items():
    if set(table) != set(tables.get('en', {})) or any(not value for value in table.values()):
        errors.append(f'{locale}: missing/empty localized copy')
if errors:
    print('\n'.join(errors), file=sys.stderr)
    sys.exit(1)
print('Starter checks passed: named tokens, constants, component boundaries and en/id/zh-Hans.')
