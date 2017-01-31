//
//  AppDelegate.m
//  VoIPPushTest
//
//  Created by Leo_hsu on 2017/1/31.
//  Copyright © 2017年 Leo_hsu. All rights reserved.
//

#import "AppDelegate.h"
#import <PushKit/PushKit.h>
#import <UserNotifications/UserNotifications.h>

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

static NSString *kNotificationIdentifier = @"NotificationIdentifier";

@interface AppDelegate () <UNUserNotificationCenterDelegate, PKPushRegistryDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self setupRemoteNotification:application];
    
    [self voipRegistration];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {

}


- (void)applicationDidEnterBackground:(UIApplication *)application {

}


- (void)applicationWillEnterForeground:(UIApplication *)application {

}


- (void)applicationDidBecomeActive:(UIApplication *)application {

}


- (void)applicationWillTerminate:(UIApplication *)application {

}

// Register for VoIP notifications
- (void) voipRegistration {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    // Create a push registry object
    PKPushRegistry * voipRegistry = [[PKPushRegistry alloc] initWithQueue: mainQueue];
    // Set the registry's delegate to self
    voipRegistry.delegate = self;
    // Set the push type to VoIP
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

#pragma mark - PKPushRegistryDelegate

// Handle updated push credentials
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials: (PKPushCredentials *)credentials forType:(NSString *)type {
    // Register VoIP push token (a property of PKPushCredentials) with server
    NSString *str = [NSString stringWithFormat:@"%@",credentials.token];
    NSString *tokenStr = [[[str stringByReplacingOccurrencesOfString:@"<" withString:@""]
                  stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"token = %@", tokenStr);
    NSLog(@"type = %@", type);
}

// Handle incoming pushes
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    /*
    payload = {
        aps =     {
            alert = "This is a message";
            sound = default;
            title = "VoIP Push Test";
        };
    }
     */
    // Process the received push
    NSLog(@"payload = %@", payload.dictionaryPayload);
    NSLog(@"type = %@", type);
    
    NSDictionary *payloadDict = payload.dictionaryPayload[@"aps"];
    NSString *title = payloadDict[@"title"];
    NSString *message = payloadDict[@"alert"];
    
    //present a local notification to visually see when we are recieving a VoIP Notification
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        [self registerLocalNotification:title message:message];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Local notification" message:@"You got a message" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:cancelAction];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    }
    
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type {
    NSLog(@"token invalidated");
}

#pragma mark - local notification

- (void)registerLocalNotification:(NSString *)title message:(NSString *)msg {
    // Send local notification after alerTime(in seconds)
    NSInteger alerTime = 1;
    
    if( SYSTEM_VERSION_LESS_THAN( @"10.0" ) )
    {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        if (notification) {
            notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:alerTime];
            notification.timeZone = [NSTimeZone defaultTimeZone];
            notification.alertTitle = title;
            notification.alertBody = msg;
            NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:@"notification_1", @"id", nil];
            notification.userInfo = infoDict;
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        }
    }
    else
    {
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        
        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
        content.title = title;
        content.body = msg;
        content.sound = [UNNotificationSound defaultSound];
        
        UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger
                                                      triggerWithTimeInterval:alerTime repeats:NO];
        
        UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:kNotificationIdentifier
                                                                              content:content trigger:trigger];
        
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            NSLog(@"completed!");
        }];
    }
}

#pragma mark - register APNs

- (void) setupRemoteNotification:(UIApplication *)application {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    // Push notification
    if( SYSTEM_VERSION_LESS_THAN( @"10.0" ) )
    {
        if([application respondsToSelector:@selector(registerUserNotificationSettings:)])
        {
            // For ios 8 and later
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound) categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
            
        }
        else
        {
            // For ios 7 and earlier
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
        }
        
        
    }
    else
    {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error)
         {
             if( !error )
             {
                 [[UIApplication sharedApplication] registerForRemoteNotifications];
                 NSLog( @"Push registration success - iOS 10" );
             }
             else
             {
                 NSLog( @"Push registration FAILED - iOS 10" );
                 NSLog( @"ERROR: %@ - %@", error.localizedFailureReason, error.localizedDescription );
                 NSLog( @"SUGGESTIONS: %@ - %@", error.localizedRecoveryOptions, error.localizedRecoverySuggestion );
             }
         }];
    }
}

@end
