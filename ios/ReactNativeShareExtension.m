#import "ReactNativeShareExtension.h"
#import "React/RCTRootView.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define URL_IDENTIFIER @"public.url"
#define IMAGE_IDENTIFIER @"public.image"
#define TEXT_IDENTIFIER (NSString *)kUTTypePlainText

NSExtensionContext* extensionContext;

@implementation ReactNativeShareExtension {
    NSTimer *autoTimer;
    NSString* type;
    NSString* value;
}

- (UIView*) shareView {
    return nil;
}

RCT_EXPORT_MODULE();

- (void)viewDidLoad {
    [super viewDidLoad];

    //object variable for extension doesn't work for react-native. It must be assign to gloabl
    //variable extensionContext. in this way, both exported method can touch extensionContext
    extensionContext = self.extensionContext;

    UIView *rootView = [self shareView];
    if (rootView.backgroundColor == nil) {
        rootView.backgroundColor = [[UIColor alloc] initWithRed:1 green:1 blue:1 alpha:0.1];
    }

    self.view = rootView;
}


RCT_EXPORT_METHOD(close:(NSString *)appGroupId) {
    [self cleanUpTempFiles:appGroupId];
    [extensionContext completeRequestReturningItems:nil
                                  completionHandler:nil];
}



RCT_REMAP_METHOD(data,
                 appGroupId: (NSString *)appGroupId
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    [self extractDataFromContext: extensionContext withAppGroup:appGroupId andCallback:^(NSArray* items ,NSException* err) {
        if (items == nil) {
            resolve(nil);
            return;
        }
        resolve(items[0]);
    }];
}

RCT_REMAP_METHOD(dataMulti,
                 appGroupId: (NSString *)appGroupId
                 resolverMulti:(RCTPromiseResolveBlock)resolve
                 rejecterMulti:(RCTPromiseRejectBlock)reject)
{
    [self extractDataFromContext: extensionContext withAppGroup: appGroupId andCallback:^(NSArray* items ,NSException* err) {
        resolve(items);
    }];
}

typedef void (^ProviderCallback)(NSString *content, NSString *contentType, BOOL owner, NSException *exception);

- (void)extractDataFromContext:(NSExtensionContext *)context withAppGroup:(NSString *) appGroupId andCallback:(void(^)(NSArray *items ,NSException *exception))callback {
    @try {
        NSExtensionItem *item = [context.inputItems firstObject];
        NSArray *attachments = item.attachments;
        NSMutableArray *items = [[NSMutableArray alloc] init];
        
        __block int attachmentIdx = 0;
        __block ProviderCallback providerCb = nil;
        providerCb = ^ void (NSString *content, NSString *contentType, BOOL owner, NSException *exception) {
            if (exception) {
                callback(nil, exception);
                return;
            }
            
            if (content != nil) {
                [items addObject:@{
                                   @"type": contentType,
                                   @"value": content,
                                   @"owner": [NSNumber numberWithBool:owner],
                                   }];
            }
            
            ++attachmentIdx;
            if (attachmentIdx == [attachments count]) {
                callback(items, nil);
            } else {
                [self extractDataFromProvider:attachments[attachmentIdx] withAppGroup:appGroupId andCallback: providerCb];
            }
        };
        [self extractDataFromProvider:attachments[0] withAppGroup:appGroupId andCallback: providerCb];
    }
    @catch (NSException *exception) {
        callback(nil,exception);
    }
}

- (void)extractDataFromProvider:(NSItemProvider *)provider withAppGroup:(NSString *) appGroupId andCallback:(void(^)(NSString* content, NSString* contentType, BOOL owner, NSException *exception))callback {
    
    NSURL *tempContainerURL = [ReactNativeShareExtension tempContainerURL:appGroupId];
    
    if([provider hasItemConformingToTypeIdentifier:@"public.image"]) {
        [provider loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:^(id<NSSecureCoding, NSObject> item, NSError *error) {
            if (error) {
                callback(nil, nil, NO, error);
                return;
            }
            
            if (tempContainerURL == nil){
                return callback(nil, nil, NO, nil);
            }
            
            NSInteger index = [[(NSURL *)item absoluteString] rangeOfString:@"/" options:NSBackwardsSearch].location;
            NSString *fileName = [[(NSURL *)item absoluteString] substringFromIndex:index+1];
            
            NSURL *tempFileURL = [tempContainerURL URLByAppendingPathComponent: fileName];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[(NSURL *)item absoluteString]]];
            
            BOOL created = [data writeToFile:[tempFileURL path] atomically:YES];
            if (created) {
                return callback([tempFileURL absoluteString], @"public.image", YES, nil);
            } else {
                return callback(nil, nil, NO, nil);
            }
        }];
        return;
    }
    
    if([provider hasItemConformingToTypeIdentifier:@"public.url"]) {
        [provider loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(id<NSSecureCoding, NSObject> item, NSError *error) {
            if (error) {
                callback(nil, nil, NO, error);
                return;
            }
            
            if (tempContainerURL == nil){
                return callback(nil, nil, NO, nil);
            }
            
            NSInteger index = [[(NSURL *)item absoluteString] rangeOfString:@"/" options:NSBackwardsSearch].location;
            NSString *fileName = [[(NSURL *)item absoluteString] substringFromIndex:index+1];
            
            NSURL *tempFileURL = [tempContainerURL URLByAppendingPathComponent: fileName];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[(NSURL *)item absoluteString]]];
            
            BOOL created = [data writeToFile:[tempFileURL path] atomically:YES];
            if (created) {
                return callback([tempFileURL absoluteString], @"public.url", YES, nil);
            } else {
                return callback(nil, nil, NO, nil);
            }
        }];
        return;
    }

    callback(nil, nil, NO, nil);
}

+ (NSURL*) tempContainerURL: (NSString*)appGroupId {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *containerURL = [manager containerURLForSecurityApplicationGroupIdentifier: appGroupId];
    NSURL *tempDirectoryURL = [containerURL URLByAppendingPathComponent:@"shareTempItems"];
    if (![manager fileExistsAtPath:[tempDirectoryURL path]]) {
        NSError *err;
        [manager createDirectoryAtURL:tempDirectoryURL withIntermediateDirectories:YES attributes:nil error:&err];
        if (err) {
            return nil;
        }
    }
    
    return tempDirectoryURL;
}

- (void) cleanUpTempFiles:(NSString *)appGroupId {
    NSURL *tmpDirectoryURL = [ReactNativeShareExtension tempContainerURL:appGroupId];
    if (tmpDirectoryURL == nil) {
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *tmpFiles = [fileManager contentsOfDirectoryAtPath:[tmpDirectoryURL path] error:&error];
    if (error) {
        return;
    }
    
    for (NSString *file in tmpFiles)
    {
        error = nil;
        [fileManager removeItemAtPath:[[tmpDirectoryURL URLByAppendingPathComponent:file] path] error:&error];
    }
}

@end
