//
//  EmailSupportTicket.h
//  Estates Audit
//
//  Created by murray king on 27/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

extern NSString * const SUPPORT_EMAIL_ADDRESS;

@interface EmailSupportTicket : NSObject

- (id)initWithSubject:(NSString *) subject
               message:(NSString *) message
                 imageAttachment:(UIImage *) image
                 viewController:(UIViewController<MFMailComposeViewControllerDelegate> *)viewController;

- (void)sendSupportEmail;


@property NSString *subject;
@property NSString *message;
@property UIImage * image;
@property (weak)UIViewController<MFMailComposeViewControllerDelegate> * viewController;
@end
