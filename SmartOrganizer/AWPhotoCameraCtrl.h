//
//  AWPhotoCameraCtrl.h
//  SmartOrganizer
//
//  Created by iwat on 11/11/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AWPhotoCameraCtrl : UIViewController

@property (weak) IBOutlet UIView *previewView;

- (IBAction)takePicture;

@end
