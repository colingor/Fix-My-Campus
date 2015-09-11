//
//  BuildingTableViewCell.m
//  Estates Audit
//
//  Created by Colin Gormley on 10/09/2015.
//  Copyright (c) 2015 Colin Gormley. All rights reserved.
//

#import "BuildingTableViewCell.h"

@implementation BuildingTableViewCell

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
    
    self.imageView.frame = CGRectMake(10, 5, 60, 60);
    
    self.textLabel.frame = CGRectMake(80,self.textLabel.frame.origin.y,self.textLabel.frame.size.width,self.textLabel.frame.size.height);
    self.detailTextLabel.frame = CGRectMake(80,self.detailTextLabel.frame.origin.y,self.detailTextLabel.frame.size.width,self.detailTextLabel.frame.size.height);
}

@end
