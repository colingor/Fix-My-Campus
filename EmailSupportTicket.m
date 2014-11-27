//
//  EmailSupportTicket.m
//  Estates Audit
//
//  Created by murray king on 27/11/2014.
//  Copyright (c) 2014 Colin Gormley. All rights reserved.
//

#import "EmailSupportTicket.h"

NSString * const SUPPORT_EMAIL_ADDRESS = @"support@eaudit.jitbit.com";

@implementation EmailSupportTicket


- (id)initWithSubject:(NSString *) subject
               message:(NSString *) message
                 imageAttachment:(UIImage *) image
                  viewController:(UIViewController<MFMailComposeViewControllerDelegate> *)viewController{
                     if( self = [super init] )
    {
        self.subject = subject;
        self.message = message;
        self.image = image;
        self.viewController = viewController;
    }
    
    return self;
}

- (void)sendSupportEmail {

    MFMailComposeViewController * mail = [[MFMailComposeViewController alloc] init];
    [mail setMailComposeDelegate:self.viewController];
    
    if([MFMailComposeViewController canSendMail]){
    
        [mail setSubject:self.subject];
        [mail setMessageBody:self.message isHTML:NO];
        [mail setToRecipients:@[ SUPPORT_EMAIL_ADDRESS ]];
        
        UIImage *image = self.image;
        NSData *myData = UIImagePNGRepresentation(image);
        [mail addAttachmentData:myData mimeType:@"image/png" fileName:@"image.png"];
 
        [self.viewController presentViewController:mail animated:YES completion:NULL];

    }
}


@end
