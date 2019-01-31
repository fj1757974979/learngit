//
//  LoginViewController.h
//  NewSDK
//
//  Created by nothing on 2018/9/3.
//  Copyright © 2018年 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController{
    NSString *userName;
    NSString *password;
    
}

@property(retain,nonatomic) NSString *userName;
@property(retain,nonatomic) NSString *password;


+(LoginViewController *)getInstance;



@end

