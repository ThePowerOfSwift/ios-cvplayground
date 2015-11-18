//
//  IWPhotoCameraCtrl.h
//  CVPlayground
//
//  Created by iwat on 11/11/15.
//  Copyright © 2015 Chaiwat Shuetrakoonpaiboon (iwat). All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IWPhotoCameraCtrl : UIViewController

@property (weak) IBOutlet UIView *previewView;

- (IBAction)takePicture;

@end
