//
//  ChatViewCell.m
//  TinyChatter
//
//  Created by jj on 12/4/10.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "ChatViewCell.h"

@implementation ChatViewCell

#pragma mark - define

#define MESSAGE_LABEL_WIDTH         240
#define MESSAGE_LABEL_MIN_HEIGHT    39
#define SHOW_LAYER_BORDER(s) s.layer.borderWidth = 2.0f; s.layer.borderColor = [[UIColor redColor] CGColor];

#pragma mark - synthesize

@synthesize messageLabel;
@synthesize cellMode;
@synthesize deliverLabel;
@synthesize readLabel;

#pragma mark - dealloc

- (void)dealloc
{
    [messageLabel release];
    [deliverLabel release];
    [readLabel release];
    
    [super dealloc];
}

#pragma mark - init

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier mode:(CellViewCellMode)aMode
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        if(aMode == CellViewCellModeLeftAlign)
        {
            messageLabel = [[UILabel alloc] init];
            messageLabel.frame = CGRectMake(5, 5, MESSAGE_LABEL_WIDTH, MESSAGE_LABEL_MIN_HEIGHT);
            messageLabel.font = [UIFont boldSystemFontOfSize:13];
            messageLabel.backgroundColor = [UIColor clearColor];
            messageLabel.textAlignment = UITextAlignmentLeft;
            messageLabel.numberOfLines = 0;
            [self.contentView addSubview:messageLabel];
            //SHOW_LAYER_BORDER(messageLabel)
            
            deliverLabel = [[UILabel alloc] init];
            deliverLabel.frame = CGRectMake(5 + MESSAGE_LABEL_WIDTH + 3, 5, 20, 15);
            deliverLabel.font = [UIFont boldSystemFontOfSize:10];
            deliverLabel.backgroundColor = [UIColor clearColor];
            deliverLabel.textColor = [UIColor darkGrayColor];
            deliverLabel.text = @"D";
            [self.contentView addSubview:deliverLabel];
            //SHOW_LAYER_BORDER(deliverLabel)
            
            readLabel = [[UILabel alloc] init];
            readLabel.frame = CGRectMake(5 + MESSAGE_LABEL_WIDTH + 3, 20, 20, 15);
            readLabel.font = [UIFont boldSystemFontOfSize:10];
            readLabel.backgroundColor = [UIColor clearColor];
            readLabel.textColor = [UIColor darkGrayColor];
            readLabel.text = @"R";
            [self.contentView addSubview:readLabel];
            //SHOW_LAYER_BORDER(readLabel)
        }
        
        if(aMode == CellViewCellModeRightAlign)
        {
            messageLabel = [[UILabel alloc] init];
            messageLabel.frame = CGRectMake(320 - 5 - MESSAGE_LABEL_WIDTH, 5, MESSAGE_LABEL_WIDTH, MESSAGE_LABEL_MIN_HEIGHT);
            messageLabel.font = [UIFont boldSystemFontOfSize:13];
            messageLabel.backgroundColor = [UIColor clearColor];
            messageLabel.textAlignment = UITextAlignmentRight;
            messageLabel.numberOfLines = 0;
            [self.contentView addSubview:messageLabel];
            //SHOW_LAYER_BORDER(messageLabel)
            
            deliverLabel = [[UILabel alloc] init];
            deliverLabel.frame = CGRectMake(320 - 5 - MESSAGE_LABEL_WIDTH - 28, 5, 20, 15);
            deliverLabel.font = [UIFont boldSystemFontOfSize:10];
            deliverLabel.backgroundColor = [UIColor clearColor];
            deliverLabel.textColor = [UIColor darkGrayColor];
            deliverLabel.text = @"D";
            [self.contentView addSubview:deliverLabel];
            //SHOW_LAYER_BORDER(deliverLabel)
            
            readLabel = [[UILabel alloc] init];
            readLabel.frame = CGRectMake(320 - 5 - MESSAGE_LABEL_WIDTH - 28, 20, 20, 15);
            readLabel.font = [UIFont boldSystemFontOfSize:10];
            readLabel.backgroundColor = [UIColor clearColor];
            readLabel.textColor = [UIColor darkGrayColor];
            readLabel.text = @"R";
            [self.contentView addSubview:readLabel];
            //SHOW_LAYER_BORDER(readLabel)
        }
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setMessage:(NSString *)aString
{
    self.messageLabel.text = aString;
    CGFloat height = [aString sizeWithFont:[UIFont boldSystemFontOfSize:13] constrainedToSize:CGSizeMake(MESSAGE_LABEL_WIDTH, 1000)].height;
    CGRect frame = self.messageLabel.frame;
    frame.size.height = height + 4;
    self.messageLabel.frame = frame;
}

@end
