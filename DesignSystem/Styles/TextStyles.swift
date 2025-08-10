//
//  TextStyles.swift
//  AirLink
//
//  Created by Konrad Kmiecik on 10/08/2025.
//

import SwiftUI

// MARK: - AirLink Text Styles

/// Kolekcja wszystkich stylów tekstu używanych w AirLink
/// Zgodne z iOS Human Interface Guidelines i Dynamic Type
struct AirLinkTextStyles {
    
    // MARK: - Hierarchical Text Styles
    
    static let largeTitle = AirLinkLargeTitleStyle()
    static let title1 = AirLinkTitle1Style()
    static let title2 = AirLinkTitle2Style()
    static let title3 = AirLinkTitle3Style()
    static let headline = AirLinkHeadlineStyle()
    static let body = AirLinkBodyStyle()
    static let callout = AirLinkCalloutStyle()
    static let subheadline = AirLinkSubheadlineStyle()
    static let footnote = AirLinkFootnoteStyle()
    static let caption1 = AirLinkCaption1Style()
    static let caption2 = AirLinkCaption2Style()
    
    // MARK: - Specialized Text Styles
    
    static let navigationTitle = AirLinkNavigationTitleStyle()
    static let sectionHeader = AirLinkSectionHeaderStyle()
    static let listItemTitle = AirLinkListItemTitleStyle()
    static let listItemSubtitle = AirLinkListItemSubtitleStyle()
    static let placeholder = AirLinkPlaceholderStyle()
    static let error = AirLinkErrorStyle()
    static let success = AirLinkSuccessStyle()
    static let warning = AirLinkWarningStyle()
    
    // MARK: - Chat Specific Styles
    
    static let messageText = AirLinkMessageTextStyle()
    static let messageAuthor = AirLinkMessageAuthorStyle()
    static let messageTimestamp = AirLinkMessageTimestampStyle()
    static let chatTitle = AirLinkChatTitleStyle()
    static let chatSubtitle = AirLinkChatSubtitleStyle()
    static let typingIndicator = AirLinkTypingIndicatorStyle()
    
    // MARK: - Contact Specific Styles
    
    static let contactName = AirLinkContactNameStyle()
    static let contactStatus = AirLinkContactStatusStyle()
    static let avatarLetter = AirLinkAvatarLetterStyle()
    
    // MARK: - Settings Specific Styles
    
    static let settingsHeader = AirLinkSettingsHeaderStyle()
    static let settingsItem = AirLinkSettingsItemStyle()
    static let settingsValue = AirLinkSettingsValueStyle()
    static let settingsFooter = AirLinkSettingsFooterStyle()
}

// MARK: - Basic Text Styles

struct AirLinkLargeTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.largeTitle)
            .foregroundColor(AirLinkColors.textPrimary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkTitle1Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.title)
            .foregroundColor(AirLinkColors.textPrimary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkTitle2Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.title2)
            .foregroundColor(AirLinkColors.textPrimary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkTitle3Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.title3)
            .foregroundColor(AirLinkColors.textPrimary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkHeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.headline)
            .foregroundColor(AirLinkColors.textPrimary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkBodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.body)
            .foregroundColor(AirLinkColors.textPrimary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkCalloutStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.callout)
            .foregroundColor(AirLinkColors.textPrimary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkSubheadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.subheadline)
            .foregroundColor(AirLinkColors.textSecondary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkFootnoteStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.footnote)
            .foregroundColor(AirLinkColors.textSecondary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkCaption1Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.caption)
            .foregroundColor(AirLinkColors.textTertiary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkCaption2Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.caption2)
            .foregroundColor(AirLinkColors.textTertiary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

// MARK: - Specialized Text Styles

struct AirLinkNavigationTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.navigationTitle)
            .foregroundColor(AirLinkColors.navigationTitle)
            .lineLimit(1)
            .multilineTextAlignment(.center)
    }
}

struct AirLinkSectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.settingsHeader)
            .foregroundColor(AirLinkColors.textSecondary)
            .textCase(.uppercase)
            .lineLimit(1)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkListItemTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.body)
            .foregroundColor(AirLinkColors.textPrimary)
            .lineLimit(1)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkListItemSubtitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.footnote)
            .foregroundColor(AirLinkColors.textSecondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkPlaceholderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.body)
            .foregroundColor(AirLinkColors.inputPlaceholder)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkErrorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.footnote)
            .foregroundColor(AirLinkColors.statusError)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkSuccessStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.footnote)
            .foregroundColor(AirLinkColors.statusSuccess)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkWarningStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.footnote)
            .foregroundColor(AirLinkColors.statusWarning)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

// MARK: - Chat Specific Text Styles

struct AirLinkMessageTextStyle: ViewModifier {
    
    let isFromCurrentUser: Bool
    
    init(isFromCurrentUser: Bool = false) {
        self.isFromCurrentUser = isFromCurrentUser
    }
    
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.messageText)
            .foregroundColor(
                isFromCurrentUser
                ? AirLinkColors.myMessageText
                : AirLinkColors.otherMessageText
            )
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkMessageAuthorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.messageAuthor)
            .foregroundColor(AirLinkColors.primary)
            .lineLimit(1)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkMessageTimestampStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.messageTime)
            .foregroundColor(AirLinkColors.messageTimestamp)
            .lineLimit(1)
            .multilineTextAlignment(.trailing)
    }
}

struct AirLinkChatTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.contactName)
            .foregroundColor(AirLinkColors.textPrimary)
            .lineLimit(1)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkChatSubtitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.footnote)
            .foregroundColor(AirLinkColors.textSecondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkTypingIndicatorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.footnote.italic())
            .foregroundColor(AirLinkColors.textTertiary)
            .lineLimit(1)
            .multilineTextAlignment(.leading)
    }
}

// MARK: - Contact Specific Text Styles

struct AirLinkContactNameStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.contactName)
            .foregroundColor(AirLinkColors.textPrimary)
            .lineLimit(1)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkContactStatusStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.contactStatus)
            .foregroundColor(AirLinkColors.textSecondary)
            .lineLimit(1)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkAvatarLetterStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.avatarLetter)
            .foregroundColor(.white)
            .lineLimit(1)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Settings Specific Text Styles

struct AirLinkSettingsHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.settingsHeader)
            .foregroundColor(AirLinkColors.textSecondary)
            .textCase(.uppercase)
            .lineLimit(1)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkSettingsItemStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.settingsItem)
            .foregroundColor(AirLinkColors.textPrimary)
            .lineLimit(1)
            .multilineTextAlignment(.leading)
    }
}

struct AirLinkSettingsValueStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.settingsValue)
            .foregroundColor(AirLinkColors.textSecondary)
            .lineLimit(1)
            .multilineTextAlignment(.trailing)
    }
}

struct AirLinkSettingsFooterStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.current.typography.settingsFooter)
            .foregroundColor(AirLinkColors.textTertiary)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
    }
}

// MARK: - Text View Extensions

extension Text {
    
    // MARK: - Basic Text Styles
    
    func largeTitleStyle() -> some View {
        self.modifier(AirLinkTextStyles.largeTitle)
    }
    
    func title1Style() -> some View {
        self.modifier(AirLinkTextStyles.title1)
    }
    
    func title2Style() -> some View {
        self.modifier(AirLinkTextStyles.title2)
    }
    
    func title3Style() -> some View {
        self.modifier(AirLinkTextStyles.title3)
    }
    
    func headlineStyle() -> some View {
        self.modifier(AirLinkTextStyles.headline)
    }
    
    func bodyStyle() -> some View {
        self.modifier(AirLinkTextStyles.body)
    }
    
    func calloutStyle() -> some View {
        self.modifier(AirLinkTextStyles.callout)
    }
    
    func subheadlineStyle() -> some View {
        self.modifier(AirLinkTextStyles.subheadline)
    }
    
    func footnoteStyle() -> some View {
        self.modifier(AirLinkTextStyles.footnote)
    }
    
    func caption1Style() -> some View {
        self.modifier(AirLinkTextStyles.caption1)
    }
    
    func caption2Style() -> some View {
        self.modifier(AirLinkTextStyles.caption2)
    }
    
    // MARK: - Specialized Text Styles
    
    func navigationTitleStyle() -> some View {
        self.modifier(AirLinkTextStyles.navigationTitle)
    }
    
    func sectionHeaderStyle() -> some View {
        self.modifier(AirLinkTextStyles.sectionHeader)
    }
    
    func listItemTitleStyle() -> some View {
        self.modifier(AirLinkTextStyles.listItemTitle)
    }
    
    func listItemSubtitleStyle() -> some View {
        self.modifier(AirLinkTextStyles.listItemSubtitle)
    }
    
    func placeholderStyle() -> some View {
        self.modifier(AirLinkTextStyles.placeholder)
    }
    
    func errorStyle() -> some View {
        self.modifier(AirLinkTextStyles.error)
    }
    
    func successStyle() -> some View {
        self.modifier(AirLinkTextStyles.success)
    }
    
    func warningStyle() -> some View {
        self.modifier(AirLinkTextStyles.warning)
    }
    
    // MARK: - Chat Specific Text Styles
    
    func messageTextStyle(isFromCurrentUser: Bool = false) -> some View {
        self.modifier(AirLinkMessageTextStyle(isFromCurrentUser: isFromCurrentUser))
    }
    
    func messageAuthorStyle() -> some View {
        self.modifier(AirLinkTextStyles.messageAuthor)
    }
    
    func messageTimestampStyle() -> some View {
        self.modifier(AirLinkTextStyles.messageTimestamp)
    }
    
    func chatTitleStyle() -> some View {
        self.modifier(AirLinkTextStyles.chatTitle)
    }
    
    func chatSubtitleStyle() -> some View {
        self.modifier(AirLinkTextStyles.chatSubtitle)
    }
    
    func typingIndicatorStyle() -> some View {
        self.modifier(AirLinkTextStyles.typingIndicator)
    }
    
    // MARK: - Contact Specific Text Styles
    
    func contactNameStyle() -> some View {
        self.modifier(AirLinkTextStyles.contactName)
    }
    
    func contactStatusStyle() -> some View {
        self.modifier(AirLinkTextStyles.contactStatus)
    }
    
    func avatarLetterStyle() -> some View {
        self.modifier(AirLinkTextStyles.avatarLetter)
    }
    
    // MARK: - Settings Specific Text Styles
    
    func settingsHeaderStyle() -> some View {
        self.modifier(AirLinkTextStyles.settingsHeader)
    }
    
    func settingsItemStyle() -> some View {
        self.modifier(AirLinkTextStyles.settingsItem)
    }
    
    func settingsValueStyle() -> some View {
        self.modifier(AirLinkTextStyles.settingsValue)
    }
    
    func settingsFooterStyle() -> some View {
        self.modifier(AirLinkTextStyles.settingsFooter)
    }
}
