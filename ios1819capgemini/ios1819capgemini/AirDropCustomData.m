//
//  AirDropCustomData.m
//  ios1819capgemini
//
//  Created by Michael Schott on 14.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

#import "AirDropCustomData.h"

@implementation AirDropCustomData

- (id)initWithURL:(NSURL *)url subject:(NSString *)subject;
{
    self = [super init];
    if (self != nil) {
        self.url = url;
        self.subject = subject;
    }
    return self;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return self.url;
}

- (id)activityViewController:(UIActivityViewController *)activityViewController
         itemForActivityType:(NSString *)activityType
{
    return self.url;
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController
              subjectForActivityType:(NSString *)activityType
{
    return self.subject;
}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController
      thumbnailImageForActivityType:(NSString *)activityType
                      suggestedSize:(CGSize)size
{
    if ([activityType isEqualToString:UIActivityTypeAirDrop]) {
        return [UIImage imageNamed:@"AppIcon"];
    }
    return nil;
}

@end
