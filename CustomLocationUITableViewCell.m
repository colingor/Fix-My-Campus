//
//  CustomLocationUITableViewCell.m
//  Estates Audit
//
//  Created by Colin Gormley on 24/08/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "CustomLocationUITableViewCell.h"

@implementation CustomLocationUITableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.contentMode = UIViewContentModeScaleToFill;
    
    self.imageView.frame = CGRectMake(10, 1, 55, 55);
    self.textLabel.frame = CGRectMake(75, self.textLabel.frame.origin.y,self.textLabel.frame.size.width,self.textLabel.frame.size.height);
    self.detailTextLabel.frame = CGRectMake(75,self.detailTextLabel.frame.origin.y,self.detailTextLabel.frame.size.width,self.detailTextLabel.frame.size.height);
}

@end
