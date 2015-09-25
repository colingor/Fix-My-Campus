//
//  ViewPhotoViewController.h
//  Estates Audit
//
//  Created by murray king on 13/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo+Create.h"
@interface ViewPhotoViewController : UIViewController<UIScrollViewDelegate>
@property(nonatomic, strong) Photo *photo ;
@property(nonatomic, strong) NSString *photoUrl ;
@end
