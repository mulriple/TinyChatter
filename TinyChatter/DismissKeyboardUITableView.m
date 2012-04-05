//
//  DismissKeyboardUITableView.m
//  TinyChatter
//
//  Created by jj on 12/4/3.
//  Copyright (c) 2012年 jtg2078@hotmail.com. All rights reserved.
//

#import "DismissKeyboardUITableView.h"

@implementation DismissKeyboardUITableView

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.superview endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

@end
