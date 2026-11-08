# Tree lengkap DesignKit dan TanyaAI

Dihasilkan oleh `python3 Scripts/package_tree.py`. Aturan penempatan ada di
[PACKAGE_STRUCTURE.md](PACKAGE_STRUCTURE.md). Tree ini mencantumkan seluruh file package
yang dikelola Git, termasuk source, tests, token, font/lisensi, isi xcassets, localization,
manifest, dan shared scheme Xcode. File lokal baru yang tidak di-ignore juga ikut dicatat.
Build output, cache, serta konfigurasi pribadi yang di-ignore tidak termasuk.

- **DesignKit:** 122 file.
- **TanyaAI:** 101 file.
- **Total:** 223 file.

```text
Packages/
├── DesignKit/
│   ├── .swiftpm/
│   │   └── xcode/
│   │       └── xcshareddata/
│   │           └── xcschemes/
│   │               └── DesignKit.xcscheme
│   ├── Sources/
│   │   └── DesignKit/
│   │       ├── Components/
│   │       │   ├── Actions/
│   │       │   │   ├── ActionCard.swift
│   │       │   │   └── SuggestionChip.swift
│   │       │   ├── Images/
│   │       │   │   └── RemoteImage.swift
│   │       │   ├── Inputs/
│   │       │   │   ├── GrowingTextInput/
│   │       │   │   │   └── Views/
│   │       │   │   │       ├── BoundedTextView.swift
│   │       │   │   │       └── GrowingTextInput.swift
│   │       │   │   └── MessageComposer/
│   │       │   │       ├── Extensions/
│   │       │   │       │   └── MessageComposerAction+Icon.swift
│   │       │   │       ├── Models/
│   │       │   │       │   └── MessageComposerAction.swift
│   │       │   │       └── Views/
│   │       │   │           ├── ArtworkButtonStyle.swift
│   │       │   │           └── MessageComposer.swift
│   │       │   ├── Lists/
│   │       │   │   └── HostedTable/
│   │       │   │       ├── Controllers/
│   │       │   │       │   └── EmbeddedHostingController.swift
│   │       │   │       ├── Protocols/
│   │       │   │       │   └── HostedContentAttaching.swift
│   │       │   │       └── Views/
│   │       │   │           ├── HostingTableViewCell.swift
│   │       │   │           └── LayoutTrackingTableView.swift
│   │       │   ├── Markdown/
│   │       │   │   ├── Extensions/
│   │       │   │   │   └── AttributedString+MarkdownStyle.swift
│   │       │   │   ├── Models/
│   │       │   │   │   ├── MarkdownBlock.swift
│   │       │   │   │   ├── MarkdownColumnAlignment.swift
│   │       │   │   │   ├── MarkdownDocument.swift
│   │       │   │   │   ├── MarkdownList.swift
│   │       │   │   │   ├── MarkdownListItem.swift
│   │       │   │   │   ├── MarkdownNode.swift
│   │       │   │   │   ├── MarkdownTable.swift
│   │       │   │   │   ├── MarkdownTaskState.swift
│   │       │   │   │   ├── MarkdownTextRole.swift
│   │       │   │   │   └── MarkdownTextStyle.swift
│   │       │   │   ├── Parsing/
│   │       │   │   │   ├── MarkdownParser+Blocks.swift
│   │       │   │   │   ├── MarkdownParser+Inline.swift
│   │       │   │   │   ├── MarkdownParser.swift
│   │       │   │   │   └── MarkdownSyntax.swift
│   │       │   │   └── Views/
│   │       │   │       ├── MarkdownBlocksView.swift
│   │       │   │       ├── MarkdownBlockView.swift
│   │       │   │       ├── MarkdownCodeBlock.swift
│   │       │   │       ├── MarkdownContent.swift
│   │       │   │       ├── MarkdownImageView.swift
│   │       │   │       ├── MarkdownListView.swift
│   │       │   │       └── MarkdownTableView.swift
│   │       │   ├── Messages/
│   │       │   │   ├── MessageBubble/
│   │       │   │   │   └── Views/
│   │       │   │   │       ├── MessageBubble.swift
│   │       │   │   │       └── MessageBubbleShape.swift
│   │       │   │   └── DateChip.swift
│   │       │   └── Screen/
│   │       │       ├── ScreenHeader.swift
│   │       │       └── ScreenScaffold.swift
│   │       ├── Extensions/
│   │       │   ├── CGFloat+Artwork.swift
│   │       │   ├── CGFloat+ScrollProgress.swift
│   │       │   ├── Color+Hex.swift
│   │       │   └── String+Resource.swift
│   │       ├── Foundations/
│   │       │   ├── Accessibility/
│   │       │   │   └── ComponentIdentifier.swift
│   │       │   ├── Appearance/
│   │       │   │   ├── Extensions/
│   │       │   │   │   ├── View+DesignColors.swift
│   │       │   │   │   └── View+Surface.swift
│   │       │   │   └── ViewModifiers/
│   │       │   │       ├── CardStyle.swift
│   │       │   │       └── DesignShadow.swift
│   │       │   ├── Iconography/
│   │       │   │   ├── Extensions/
│   │       │   │   │   ├── Image+DesignColorIcon.swift
│   │       │   │   │   └── Image+DesignIcon.swift
│   │       │   │   └── Keys/
│   │       │   │       ├── DesignColorIcon.swift
│   │       │   │       └── DesignIcon.swift
│   │       │   └── Typography/
│   │       │       ├── Extensions/
│   │       │       │   └── FontFace+SwiftUI.swift
│   │       │       ├── Models/
│   │       │       │   └── FontFace.swift
│   │       │       └── FontLoader.swift
│   │       ├── Resources/
│   │       │   ├── Assets.xcassets/
│   │       │   │   ├── backArrow.imageset/
│   │       │   │   │   ├── backArrow.pdf
│   │       │   │   │   └── Contents.json
│   │       │   │   ├── chevronRight.imageset/
│   │       │   │   │   ├── chevronRight.pdf
│   │       │   │   │   └── Contents.json
│   │       │   │   ├── lightbulb.imageset/
│   │       │   │   │   ├── Contents.json
│   │       │   │   │   └── lightbulb.pdf
│   │       │   │   ├── moreMenu.imageset/
│   │       │   │   │   ├── Contents.json
│   │       │   │   │   └── moreMenu.pdf
│   │       │   │   ├── reply.imageset/
│   │       │   │   │   ├── Contents.json
│   │       │   │   │   └── reply.pdf
│   │       │   │   ├── send-off.imageset/
│   │       │   │   │   ├── Contents.json
│   │       │   │   │   └── send-off.pdf
│   │       │   │   ├── send-on.imageset/
│   │       │   │   │   ├── Contents.json
│   │       │   │   │   └── send-on.pdf
│   │       │   │   ├── send-pause.imageset/
│   │       │   │   │   ├── Contents.json
│   │       │   │   │   └── send-pause.pdf
│   │       │   │   ├── Contents.json
│   │       │   │   └── README.md
│   │       │   └── Fonts/
│   │       │       ├── FiraSans-Bold.ttf
│   │       │       ├── FiraSans-BoldItalic.ttf
│   │       │       ├── FiraSans-Italic.ttf
│   │       │       ├── FiraSans-Medium.ttf
│   │       │       ├── FiraSans-OFL.txt
│   │       │       ├── FiraSans-Regular.ttf
│   │       │       ├── FiraSans-SemiBold.ttf
│   │       │       ├── OpenSans-Bold.ttf
│   │       │       ├── OpenSans-Medium.ttf
│   │       │       ├── OpenSans-OFL.txt
│   │       │       ├── OpenSans-Regular.ttf
│   │       │       └── SOURCES.md
│   │       └── Tokens/
│   │           ├── Generated/
│   │           │   ├── DefaultColorConstants.swift
│   │           │   ├── FigmaColorProtocol.swift
│   │           │   ├── FigmaSize.swift
│   │           │   ├── PremierColorConstants.swift
│   │           │   └── PrivateColorConstants.swift
│   │           ├── ArtworkScale.swift
│   │           ├── CustomBasePaletteColor.swift
│   │           ├── CustomColors.swift
│   │           ├── CustomScreenInsets.swift
│   │           ├── CustomSizes.swift
│   │           ├── CustomTextLines.swift
│   │           └── LayoutTolerance.swift
│   ├── Tests/
│   │   └── DesignKitTests/
│   │       ├── Components/
│   │       │   ├── Actions/
│   │       │   │   └── SuggestionChipTests.swift
│   │       │   ├── Images/
│   │       │   │   └── RemoteImageTests.swift
│   │       │   ├── Inputs/
│   │       │   │   ├── GrowingTextInput/
│   │       │   │   │   └── Views/
│   │       │   │   │       └── EditorTests.swift
│   │       │   │   └── MessageComposer/
│   │       │   │       └── Models/
│   │       │   │           └── MessageComposerActionTests.swift
│   │       │   ├── Lists/
│   │       │   │   └── HostedTable/
│   │       │   │       └── Views/
│   │       │   │           └── HostingTableViewCellTests.swift
│   │       │   ├── Markdown/
│   │       │   │   ├── Extensions/
│   │       │   │   │   └── MarkdownStyleTests.swift
│   │       │   │   ├── Parsing/
│   │       │   │   │   └── MarkdownParserTests.swift
│   │       │   │   └── Views/
│   │       │   │       ├── MarkdownListViewTests.swift
│   │       │   │       └── MarkdownTableViewTests.swift
│   │       │   ├── Messages/
│   │       │   │   ├── MessageBubble/
│   │       │   │   │   └── Views/
│   │       │   │   │       ├── MessageBubbleShapeTests.swift
│   │       │   │   │       └── MessageBubbleTests.swift
│   │       │   │   └── DateChipTests.swift
│   │       │   └── Screen/
│   │       │       └── ScreenHeaderTests.swift
│   │       ├── Extensions/
│   │       │   ├── ColorHexTests.swift
│   │       │   └── ScrollProgressTests.swift
│   │       ├── Foundations/
│   │       │   ├── Appearance/
│   │       │   │   ├── Extensions/
│   │       │   │   │   └── DesignColorsTests.swift
│   │       │   │   └── ViewModifiers/
│   │       │   │       └── SurfaceStyleTests.swift
│   │       │   ├── Iconography/
│   │       │   │   └── Keys/
│   │       │   │       └── AssetTests.swift
│   │       │   └── Typography/
│   │       │       └── FontTests.swift
│   │       ├── Support/
│   │       │   └── AsyncWait.swift
│   │       ├── Tokens/
│   │       │   └── ArtworkSizingTests.swift
│   │       └── MarkdownTextRoleTests.swift
│   └── Package.swift
└── TanyaAI/
    ├── .swiftpm/
    │   └── xcode/
    │       └── xcshareddata/
    │           └── xcschemes/
    │               └── TanyaAI.xcscheme
    ├── Sources/
    │   └── TanyaAI/
    │       ├── Bridging/
    │       │   ├── TanyaAIChatTransport.swift
    │       │   ├── TanyaAIHost.swift
    │       │   └── TanyaAITransportError.swift
    │       ├── Features/
    │       │   └── Chat/
    │       │       ├── Composer/
    │       │       │   └── ComposerSection.swift
    │       │       ├── ConversationList/
    │       │       │   ├── Controllers/
    │       │       │   │   ├── ChatTableController+Parking.swift
    │       │       │   │   ├── ChatTableController+Scroll.swift
    │       │       │   │   └── ChatTableController.swift
    │       │       │   ├── Extensions/
    │       │       │   │   ├── Array+ChatListItem.swift
    │       │       │   │   └── Array+ChatRow.swift
    │       │       │   ├── Formatting/
    │       │       │   │   └── ChatDateFormat.swift
    │       │       │   ├── Models/
    │       │       │   │   ├── ChatDay.swift
    │       │       │   │   ├── ChatDayIdentifier.swift
    │       │       │   │   ├── ChatListItem.swift
    │       │       │   │   ├── ChatListItemID.swift
    │       │       │   │   ├── ChatRowActions.swift
    │       │       │   │   ├── ChatRowInputs.swift
    │       │       │   │   └── ChatTableState.swift
    │       │       │   └── Views/
    │       │       │       ├── ChatListRow.swift
    │       │       │       └── ChatTable.swift
    │       │       ├── FollowUps/
    │       │       │   └── FollowUpsSection.swift
    │       │       ├── Gateway/
    │       │       │   ├── Decoding/
    │       │       │   │   ├── Date+Wire.swift
    │       │       │   │   └── JSONDecoder+Wire.swift
    │       │       │   ├── Models/
    │       │       │   │   ├── ChatEvent.swift
    │       │       │   │   ├── ChatHistoryPage.swift
    │       │       │   │   ├── ConversationState.swift
    │       │       │   │   ├── ServerSentEvent.swift
    │       │       │   │   ├── WireCancel.swift
    │       │       │   │   ├── WireEnvelope.swift
    │       │       │   │   ├── WireError.swift
    │       │       │   │   ├── WireHistoryPage.swift
    │       │       │   │   ├── WireInit.swift
    │       │       │   │   ├── WireMessage.swift
    │       │       │   │   ├── WireRetryHint.swift
    │       │       │   │   └── WireSendAck.swift
    │       │       │   ├── Streaming/
    │       │       │   │   └── ServerSentEventParser.swift
    │       │       │   └── ChatWire.swift
    │       │       ├── Keys/
    │       │       │   ├── Extensions/
    │       │       │   │   ├── Image+ChatImage.swift
    │       │       │   │   └── String+ChatCopy.swift
    │       │       │   ├── ChatCopy.swift
    │       │       │   ├── ChatElementIdentifier.swift
    │       │       │   ├── ChatImage.swift
    │       │       │   └── TanyaAILink.swift
    │       │       ├── Messages/
    │       │       │   ├── Extensions/
    │       │       │   │   └── Array+ChatMessage.swift
    │       │       │   ├── Models/
    │       │       │   │   ├── ChatAuthor.swift
    │       │       │   │   ├── ChatMessage.swift
    │       │       │   │   ├── ChatMessageStatus.swift
    │       │       │   │   ├── ChatRow.swift
    │       │       │   │   └── LocalQuestion.swift
    │       │       │   └── Views/
    │       │       │       └── MessageRow.swift
    │       │       ├── Session/
    │       │       │   ├── Models/
    │       │       │   │   ├── ChatConnection.swift
    │       │       │   │   ├── ChatHistoryPhase.swift
    │       │       │   │   ├── ChatTurn.swift
    │       │       │   │   └── ChatTurnPhase.swift
    │       │       │   ├── ChatBackoff.swift
    │       │       │   ├── TanyaAIBridge+Connection.swift
    │       │       │   ├── TanyaAIBridge+Turn.swift
    │       │       │   └── TanyaAIBridge.swift
    │       │       ├── Welcome/
    │       │       │   ├── Models/
    │       │       │   │   ├── WelcomeContent.swift
    │       │       │   │   ├── WelcomeGreeting.swift
    │       │       │   │   └── WelcomeShortcut.swift
    │       │       │   └── Views/
    │       │       │       └── WelcomeSection.swift
    │       │       └── ChatScreen.swift
    │       └── Resources/
    │           ├── Assets.xcassets/
    │           │   ├── chatBackground.imageset/
    │           │   │   ├── chatBackground@2x.png
    │           │   │   └── Contents.json
    │           │   ├── welcomeOrb.imageset/
    │           │   │   ├── Contents.json
    │           │   │   └── welcomeOrb@3x.png
    │           │   └── Contents.json
    │           ├── en.lproj/
    │           │   └── Localizable.strings
    │           ├── id.lproj/
    │           │   └── Localizable.strings
    │           └── zh-Hans.lproj/
    │               └── Localizable.strings
    ├── Tests/
    │   └── TanyaAITests/
    │       ├── Bridging/
    │       │   └── TanyaAIHostTests.swift
    │       ├── Features/
    │       │   └── Chat/
    │       │       ├── Composer/
    │       │       │   └── ComposerSectionTests.swift
    │       │       ├── ConversationList/
    │       │       │   ├── Controllers/
    │       │       │   │   ├── ChatTableActionsTests.swift
    │       │       │   │   ├── ChatTableControllerTests.swift
    │       │       │   │   └── ChatTableRefreshTests.swift
    │       │       │   ├── Extensions/
    │       │       │   │   └── ChatDayTests.swift
    │       │       │   ├── Formatting/
    │       │       │   │   └── ChatDateFormatTests.swift
    │       │       │   └── Models/
    │       │       │       └── ChatListItemTests.swift
    │       │       ├── Gateway/
    │       │       │   ├── Models/
    │       │       │   │   ├── ChatEventTests.swift
    │       │       │   │   └── ChatHistoryPageTests.swift
    │       │       │   └── Streaming/
    │       │       │       └── ServerSentEventParserTests.swift
    │       │       ├── Keys/
    │       │       │   ├── ChatImageTests.swift
    │       │       │   └── LocalizationTests.swift
    │       │       ├── Messages/
    │       │       │   ├── Extensions/
    │       │       │   │   └── ChatMessageMergeTests.swift
    │       │       │   └── Models/
    │       │       │       ├── ChatMessageDocumentTests.swift
    │       │       │       └── ChatRowTests.swift
    │       │       ├── Session/
    │       │       │   ├── Models/
    │       │       │   │   └── ChatTurnTests.swift
    │       │       │   ├── ChatBackoffTests.swift
    │       │       │   ├── TanyaAIBridgeConnectionTests.swift
    │       │       │   ├── TanyaAIBridgeFollowUpTests.swift
    │       │       │   ├── TanyaAIBridgeScrollTests.swift
    │       │       │   ├── TanyaAIBridgeTests.swift
    │       │       │   └── TanyaAIBridgeTurnTests.swift
    │       │       └── ChatScreenContentTests.swift
    │       └── Support/
    │           ├── AsyncWait.swift
    │           ├── ChatTableFixture.swift
    │           ├── FakeChatTransport.swift
    │           ├── TanyaAIBridge+Delivery.swift
    │           └── WireFixture.swift
    └── Package.swift
```

Tidak ada folder intent kosong. Folder intent ditambahkan bersama implementasi flow pertamanya.

Setelah menambah atau memindahkan file, jalankan generator ini. Pemeriksaan
`python3 Scripts/package_tree.py --check` juga dijalankan oleh `Scripts/check_style.sh`.
