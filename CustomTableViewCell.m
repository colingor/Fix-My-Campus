//
//  CustomTableViewCell.m
//  Estates Audit
//
//  Created by Colin Gormley on 12/05/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "CustomTableViewCell.h"

@implementation CustomTableViewCell

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
//    self.imageView.contentMode = UIViewContentModeScaleToFill;
    
    self.imageView.frame = CGRectMake(15, 5, 85, 85);
    self.textLabel.frame = CGRectMake(120,self.textLabel.frame.origin.y,self.textLabel.frame.size.width,self.textLabel.frame.size.height);
    self.detailTextLabel.frame = CGRectMake(120,self.detailTextLabel.frame.origin.y,self.detailTextLabel.frame.size.width,self.detailTextLabel.frame.size.height);
}

@end
