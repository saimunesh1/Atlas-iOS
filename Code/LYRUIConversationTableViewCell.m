//
//  LYRUIConversationTableViewCell.m
//  LayerSample
//
//  Created by Kevin Coleman on 8/29/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import "LYRUIConversationTableViewCell.h"
#import "LYRUIConstants.h"

static BOOL LYRUIIsDateInToday(NSDate *date)
{
    NSCalendarUnit dateUnits = NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:dateUnits fromDate:date];
    NSDateComponents *todayComponents = [[NSCalendar currentCalendar] components:dateUnits fromDate:[NSDate date]];
    return ([dateComponents day] == [todayComponents day] &&
            [dateComponents month] == [todayComponents month] &&
            [dateComponents year] == [todayComponents year] &&
            [dateComponents era] == [todayComponents era]);
}

static NSDateFormatter *LYRUIRelativeDateFormatter()
{
    static NSDateFormatter *relativeDateFormatter;
    if (!relativeDateFormatter) {
        relativeDateFormatter = [[NSDateFormatter alloc] init];
        relativeDateFormatter.dateStyle = NSDateFormatterShortStyle;
        relativeDateFormatter.doesRelativeDateFormatting = YES;
    }
    return relativeDateFormatter;
}

static NSDateFormatter *LYRUIShortTimeFormatter()
{
    static NSDateFormatter *shortTimeFormatter;
    if (!shortTimeFormatter) {
        shortTimeFormatter = [[NSDateFormatter alloc] init];
        shortTimeFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return shortTimeFormatter;
}

@interface LYRUIConversationTableViewCell ()

@property (nonatomic) NSLayoutConstraint *imageViewWidthConstraint;
@property (nonatomic) NSLayoutConstraint *imageViewHeighConstraint;
@property (nonatomic) NSLayoutConstraint *imageViewLeftConstraint;
@property (nonatomic) NSLayoutConstraint *imageViewCenterYConstraint;

@property (nonatomic) NSLayoutConstraint *conversationLabelLeftConstraint;
@property (nonatomic) NSLayoutConstraint *conversationLabelRightConstraint;
@property (nonatomic) NSLayoutConstraint *conversationLabelTopConstraint;
@property (nonatomic) NSLayoutConstraint *conversationLabelHeightConstraint;

@property (nonatomic) NSLayoutConstraint *dateLabelRightConstraint;
@property (nonatomic) NSLayoutConstraint *dateLabelTopConstraint;
@property (nonatomic) NSLayoutConstraint *dateLabelWidthConstraint;

@property (nonatomic) NSLayoutConstraint *lastMessageTextLeftConstraint;
@property (nonatomic) NSLayoutConstraint *lastMessageTextRightConstraint;
@property (nonatomic) NSLayoutConstraint *lastMessageTextTopConstraint;
@property (nonatomic) NSLayoutConstraint *lastMessageTextHeightConstraint;

@property (nonatomic) NSLayoutConstraint *unreadMessageIndicatorWidth;
@property (nonatomic) NSLayoutConstraint *unreadMessageIndicatorHeight;
@property (nonatomic) NSLayoutConstraint *unreadMessageIndicatorRight;
@property (nonatomic) NSLayoutConstraint *unreadMessageIndicatorTop;

@property (nonatomic) UIImageView *conversationImageView;
@property (nonatomic) UILabel *conversationLabel;
@property (nonatomic) UILabel *dateLabel;
@property (nonatomic) UITextView *lastMessageTextView;
@property (nonatomic) UIView *unreadMessageIndicator;

@property (nonatomic, assign) BOOL displaysImage;
@property (nonatomic, assign) CGFloat conversationLabelHeight;
@property (nonatomic, assign) CGFloat dateLabelHeight;
@property (nonatomic, assign) CGFloat dateLabelWidth;
@property (nonatomic, assign) CGFloat cellHorizontalMargin;
@property (nonatomic, assign) CGFloat imageSizeRatio;

@end

@implementation LYRUIConversationTableViewCell

// Cell Constants
static CGFloat const LYRUICellVerticalMargin = 12.0f;
static CGFloat const LYRUIConversationLabelRightPadding = -6.0f;
static CGFloat const LYRUIUnreadMessageCountLabelSize = 14.0f;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // UIAppearance Proxy Defaults
        _conversationLabelFont = LYRUIBoldFont(14);
        _conversationLabelColor = [UIColor blackColor];
        _lastMessageTextFont = LYRUILightFont(14);
        _lastMessageTextColor = [UIColor grayColor];
        _dateLabelFont = LYRUIMediumFont(14);
        _dateLabelColor = [UIColor grayColor];
        _unreadMessageIndicatorBackgroundColor = LYRUIBlueColor();
        _cellBackgroundColor = [UIColor whiteColor];
        
        // Initialize Avatar Image
        self.conversationImageView = [[UIImageView alloc] init];
        self.conversationImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.conversationImageView.backgroundColor = LYRUIGrayColor();
        [self.contentView addSubview:self.conversationImageView];
        
        // Initialize Sender Image
        self.conversationLabel = [[UILabel alloc] init];
        self.conversationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.conversationLabel.font = _conversationLabelFont;
        self.conversationLabel.textColor = _conversationLabelColor;
        [self.contentView addSubview:self.conversationLabel];
        
        // Initialize Message Text
        self.lastMessageTextView = [[UITextView alloc] init];
        self.lastMessageTextView.translatesAutoresizingMaskIntoConstraints = NO;
        self.lastMessageTextView.contentInset = UIEdgeInsetsMake(-10, -4, 0, 0);
        self.lastMessageTextView.userInteractionEnabled = NO;
        self.lastMessageTextView.font = _lastMessageTextFont;
        self.lastMessageTextView.textColor = _lastMessageTextColor;
        [self.contentView addSubview:self.lastMessageTextView];
        
        // Initialize Date Label
        self.dateLabel = [[UILabel alloc] init];
        self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        self.dateLabel.font = _dateLabelFont;
        self.dateLabel.textColor = _dateLabelColor;
        [self.contentView addSubview:self.dateLabel];
        
        self.unreadMessageIndicator = [[UIView alloc] init];
        self.unreadMessageIndicator.layer.cornerRadius = LYRUIUnreadMessageCountLabelSize / 2;
        self.unreadMessageIndicator.clipsToBounds = YES;
        self.unreadMessageIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        self.unreadMessageIndicator.backgroundColor = _unreadMessageIndicatorBackgroundColor;
        [self.contentView addSubview:self.unreadMessageIndicator];
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.backgroundColor = _cellBackgroundColor;
        self.cellHorizontalMargin = 15.0f;
        self.imageSizeRatio = 0.0f;
        self.displaysImage = NO;
        
        [self setupLayoutConstraints];
    }
    return self;
}

- (void)setConversationLabelFont:(UIFont *)conversationLabelFont
{
    _conversationLabelFont = conversationLabelFont;
    self.conversationLabel.font = conversationLabelFont;
}

- (void)setConversationLabelColor:(UIColor *)conversationLabelColor
{
    _conversationLabelColor = conversationLabelColor;
    self.conversationLabel.textColor = conversationLabelColor;
}

- (void)setLastMessageTextFont:(UIFont *)lastMessageTextFont
{
    _lastMessageTextFont = lastMessageTextFont;
    self.lastMessageTextView.font = lastMessageTextFont;
}

- (void)setLastMessageTextColor:(UIColor *)lastMessageTextColor
{
    _lastMessageTextColor = lastMessageTextColor;
    self.lastMessageTextView.textColor = lastMessageTextColor;
}

- (void)setDateLabelFont:(UIFont *)dateLabelFont
{
    _dateLabelFont = dateLabelFont;
    self.dateLabel.font = dateLabelFont;
}

- (void)setDateLabelColor:(UIColor *)dateLabelColor
{
    _dateLabelColor = dateLabelColor;
    self.dateLabel.textColor = dateLabelColor;
}

- (void)setUnreadMessageIndicatorBackgroundColor:(UIColor *)unreadMessageIndicatorBackgroundColor
{
    _unreadMessageIndicatorBackgroundColor = unreadMessageIndicatorBackgroundColor;
    self.unreadMessageIndicator.backgroundColor = unreadMessageIndicatorBackgroundColor;
}

- (void)setCellBackgroundColor:(UIColor *)cellBackgroundColor
{
    _cellBackgroundColor = cellBackgroundColor;
    self.backgroundColor = cellBackgroundColor;
}

- (void)presentConversation:(LYRConversation *)conversation
{
    self.dateLabel.text = [self dateLabelForLastMessage:conversation.lastMessage];
    
    LYRMessage *message = conversation.lastMessage;
    LYRMessagePart *messagePart = message.parts.firstObject;
    if ([messagePart.MIMEType isEqualToString:LYRUIMIMETypeTextPlain]) {
        self.lastMessageTextView.text = [[NSString alloc] initWithData:messagePart.data encoding:NSUTF8StringEncoding];
    } else if ([messagePart.MIMEType isEqualToString:LYRUIMIMETypeImageJPEG]) {
        self.lastMessageTextView.text = @"Attachment: Image";
    } else if ([messagePart.MIMEType isEqualToString:LYRUIMIMETypeImagePNG]) {
        self.lastMessageTextView.text = @"Attachment: Image";
    } else if ([messagePart.MIMEType isEqualToString:LYRUIMIMETypeLocation]) {
        self.lastMessageTextView.text = @"Attachment: Location";
    } else {
        self.lastMessageTextView.text = @"Attachment: Image";
    }
}

- (void)updateWithConversationImage:(UIImage *)image
{
    self.cellHorizontalMargin = 10.0f;
    self.imageSizeRatio = 0.60f;
    self.conversationImageView.image = image;
    self.displaysImage = YES;
}

- (void)updateWithLastMessageRecipientStatus:(LYRRecipientStatus)recipientStatus
{
    switch (recipientStatus) {
        case LYRRecipientStatusDelivered:
            self.unreadMessageIndicator.alpha = 1.0;
            break;
            
        default:
            self.unreadMessageIndicator.alpha = 0.0;
            break;
    }
}

- (void)updateWithConversationLabel:(NSString *)conversationLabel
{
    self.accessibilityLabel = conversationLabel;
    self.conversationLabel.text = conversationLabel;
    [self configureLayoutConstraintsForLabels];
}

- (NSString *)dateLabelForLastMessage:(LYRMessage *)lastMessage
{
    if (!lastMessage) return @"";
    if (!lastMessage.receivedAt) return @"";
    
    if (LYRUIIsDateInToday(lastMessage.receivedAt)) {
        return [LYRUIShortTimeFormatter() stringFromDate:lastMessage.receivedAt];
    } else {
        return [LYRUIRelativeDateFormatter() stringFromDate:lastMessage.receivedAt];
    }
}

- (void)configureLayoutConstraintsForLabels
{
    [self.conversationLabel sizeToFit];
    [self.dateLabel sizeToFit];
    [self updateConstraintConstants];
}

- (void)updateConstraintConstants
{
    self.imageViewLeftConstraint.constant = self.cellHorizontalMargin;
    
    self.conversationLabelLeftConstraint.constant = self.cellHorizontalMargin;
    self.conversationLabelHeightConstraint.constant = self.conversationLabel.frame.size.height;
    
    self.lastMessageTextLeftConstraint.constant = self.cellHorizontalMargin;
    self.lastMessageTextHeightConstraint.constant = self.lastMessageTextView.font.lineHeight * 2;
    
    self.dateLabelWidthConstraint.constant = self.dateLabel.frame.size.width;
    
    [self setNeedsUpdateConstraints];
}

- (void)setupLayoutConstraints
{
    //**********Avatar Constraints**********//
    // Width
    self.imageViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.conversationImageView
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeHeight
                                                                multiplier:self.imageSizeRatio
                                                                  constant:0];
    
    // Height
    self.imageViewHeighConstraint = [NSLayoutConstraint constraintWithItem:self.conversationImageView
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeHeight
                                                                multiplier:self.imageSizeRatio
                                                                  constant:0];
    
    // Left Margin
    self.imageViewLeftConstraint = [NSLayoutConstraint constraintWithItem:self.conversationImageView
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1.0
                                                                  constant:self.cellHorizontalMargin];
    
    // Center Y
    self.imageViewCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.conversationImageView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0
                                                                  constant:0];
    

    //**********Conversation Label Constraints**********//
    // Left Margin
    self.conversationLabelLeftConstraint =  [NSLayoutConstraint constraintWithItem:self.conversationLabel
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.conversationImageView
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.0
                                                                  constant:self.cellHorizontalMargin];

    // Right Margin
    self.conversationLabelRightConstraint = [NSLayoutConstraint constraintWithItem:self.conversationLabel
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.dateLabel
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1.0
                                                                  constant:LYRUIConversationLabelRightPadding];
    // Top Margin
    self.conversationLabelTopConstraint = [NSLayoutConstraint constraintWithItem:self.conversationLabel
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1.0
                                                                  constant:LYRUICellVerticalMargin];
    // Height
    self.conversationLabelHeightConstraint = [NSLayoutConstraint constraintWithItem:self.conversationLabel
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.0
                                                                  constant:self.conversationLabelHeight];
    //**********Date Label Constraints**********//
    // Width
    self.dateLabelWidthConstraint = [NSLayoutConstraint constraintWithItem:self.dateLabel
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.0
                                                                  constant:0];
    // Right Margin
    self.dateLabelRightConstraint = [NSLayoutConstraint constraintWithItem:self.dateLabel
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.0
                                                                  constant:0];

    // Top Margin
    self.dateLabelTopConstraint = [NSLayoutConstraint constraintWithItem:self.dateLabel
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1.0
                                                                 constant:LYRUICellVerticalMargin];

    //**********Message Text Constraints**********//
    //Left Margin
    self.lastMessageTextLeftConstraint = [NSLayoutConstraint constraintWithItem:self.lastMessageTextView
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.conversationImageView
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.0
                                                                  constant:self.cellHorizontalMargin];
    // Right Margin
    self.lastMessageTextRightConstraint = [NSLayoutConstraint constraintWithItem:self.lastMessageTextView
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.0
                                                                  constant:-6];
    // Top Margin
    self.lastMessageTextTopConstraint = [NSLayoutConstraint constraintWithItem:self.lastMessageTextView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.conversationLabel
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.0
                                                                  constant:4];
    // Height
    self.lastMessageTextHeightConstraint = [NSLayoutConstraint constraintWithItem:self.lastMessageTextView
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.0
                                                                  constant:self.lastMessageTextView.font.lineHeight * 2];
    
    //**********Unread Messsage Label Constraints**********//
    //Width
    self.unreadMessageIndicatorWidth = [NSLayoutConstraint constraintWithItem:self.unreadMessageIndicator
                                                                      attribute:NSLayoutAttributeWidth
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                                     multiplier:1.0
                                                                       constant:LYRUIUnreadMessageCountLabelSize];
    // Height
    self.unreadMessageIndicatorHeight = [NSLayoutConstraint constraintWithItem:self.unreadMessageIndicator
                                                                       attribute:NSLayoutAttributeHeight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0
                                                                        constant:LYRUIUnreadMessageCountLabelSize];
    // Top Margin
    self.unreadMessageIndicatorTop = [NSLayoutConstraint constraintWithItem:self.unreadMessageIndicator
                                                                   attribute:NSLayoutAttributeRight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.conversationLabel
                                                                   attribute:NSLayoutAttributeLeft
                                                                  multiplier:1.0
                                                                    constant:-6];
    // Right
    self.unreadMessageIndicatorRight = [NSLayoutConstraint constraintWithItem:self.unreadMessageIndicator
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.conversationLabel
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:0];
    
    [self.contentView addConstraint:self.imageViewWidthConstraint];
    [self.contentView addConstraint:self.imageViewHeighConstraint];
    [self.contentView addConstraint:self.imageViewLeftConstraint];
    [self.contentView addConstraint:self.imageViewCenterYConstraint];
   
    [self.contentView addConstraint:self.conversationLabelLeftConstraint];
    [self.contentView addConstraint:self.conversationLabelRightConstraint];
    [self.contentView addConstraint:self.conversationLabelTopConstraint];
    [self.contentView addConstraint:self.conversationLabelHeightConstraint];
    
    [self.contentView addConstraint:self.dateLabelRightConstraint];
    [self.contentView addConstraint:self.dateLabelTopConstraint];
    [self.contentView addConstraint:self.dateLabelWidthConstraint];
    
    [self.contentView addConstraint:self.lastMessageTextLeftConstraint];
    [self.contentView addConstraint:self.lastMessageTextRightConstraint];
    [self.contentView addConstraint:self.lastMessageTextTopConstraint];
    [self.contentView addConstraint:self.lastMessageTextHeightConstraint];
    
    [self.contentView addConstraint:self.unreadMessageIndicatorWidth];
    [self.contentView addConstraint:self.unreadMessageIndicatorHeight];
    [self.contentView addConstraint:self.unreadMessageIndicatorTop];
    [self.contentView addConstraint:self.unreadMessageIndicatorRight];
    
    [super updateConstraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat seperatorInset;
    if (self.displaysImage) {
        seperatorInset = self.frame.size.height * self.imageSizeRatio + self.cellHorizontalMargin * 2;
    } else {
        seperatorInset = self.cellHorizontalMargin * 2;
    }

    self.separatorInset = UIEdgeInsetsMake(0, seperatorInset, 0, 0);
    self.conversationImageView.layer.cornerRadius = self.frame.size.height * self.imageSizeRatio / 2;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (selected) {
        self.unreadMessageIndicator.alpha = 0.0f;
    }
}

@end
