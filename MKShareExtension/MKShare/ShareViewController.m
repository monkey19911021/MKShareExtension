//
//  ShareViewController.m
//  MKShare
//
//  Created by DONLINKS on 16/6/21.
//  Copyright © 2016年 Donlinks. All rights reserved.
//

#import "ShareViewController.h"

#define APP_ID (@"shareextrension")

static NSInteger const maxCharactersAllowed =  140;//字符数上限

@interface ShareViewController ()

@end

@implementation ShareViewController
{
    NSMutableArray<UIImage *> *attachImageArray;
    NSMutableArray<NSString *> *attachStringArray;
    NSMutableArray<NSURL *> *attachURLArray;
}
//相当于 viewDidAppear
- (void)presentationAnimationDidFinish
{
    self.placeholder = @"输入发布内容";
    
    attachImageArray = @[].mutableCopy;
    attachStringArray = @[].mutableCopy;
    attachURLArray = @[].mutableCopy;
    
    //提取图片和分享 URL
    [self fetchItemDataAtBackground];
}

/**
 *  监测文本框的内容变化，输入文字时会调用该方法
 *
 *  @return post 按钮是否能点击
 */
- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    
    NSInteger textLength = self.contentText.length;
    self.charactersRemaining = @(maxCharactersAllowed - textLength);
    if(self.charactersRemaining.integerValue < 0){
        return NO;
    }
    
    return YES;
}

//点击 Post 后调用
- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    
    [self uploadData];
    
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    
}

//点击 cancel 之后调用
-(void)didSelectCancel
{
    NSError *error = [NSError errorWithDomain:@"MK" code:500 userInfo:@{@"error": @"用户取消"}];
    [self.extensionContext cancelRequestWithError:error];
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    
    SLComposeSheetConfigurationItem *item = [SLComposeSheetConfigurationItem new];
    item.title = @"预览";
    __weak SLComposeSheetConfigurationItem *weakItem = item;
    item.tapHandler = ^(void){
        weakItem.valuePending = YES;
        NSLog(@"image: %@", attachImageArray);
        NSLog(@"URL: %@", attachURLArray);
        NSLog(@"sring: %@", attachStringArray);
        NSLog(@"content: %@", self.contentText);
        
    };
    return @[item];
}

//提取数据
- (void)fetchItemDataAtBackground
{
    //后台执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSArray<NSExtensionItem *> *itemArray = self.extensionContext.inputItems;
        
        //实际上只有一个 NSExtensionItem 对象
        NSExtensionItem *item = itemArray.firstObject;
        NSArray<NSItemProvider *> *providerArray = item.attachments;
        
        //输出 userInfo 或者 attachments 就可以看到 dataType 对应的字符串是啥了
        //        NSLog(@"userInfo: %@", item.userInfo);
        
        for(NSItemProvider *provider in providerArray){
            //实际上一个NSItemProvider里也只有一种数据类型
            NSString *dataType = provider.registeredTypeIdentifiers.firstObject;
            if([dataType isEqualToString:@"public.image"]){
                
                [provider loadItemForTypeIdentifier:dataType options:nil completionHandler:^(UIImage *image, NSError *error) {
                    [attachImageArray addObject:image];
                }];
                
            } else if([dataType isEqualToString:@"public.plain-text"]){
                
                [provider loadItemForTypeIdentifier:dataType options:nil completionHandler:^(NSString *plainStr, NSError *error) {
                    [attachStringArray addObject: plainStr];
                }];
                
            } else if([dataType isEqualToString:@"public.url"]){
                
                [provider loadItemForTypeIdentifier:dataType options:nil completionHandler:^(NSURL *url, NSError *error) {
                    [attachURLArray addObject: url];
                }];
                
            }
        }
        
    });
}

//上传数据
- (void)uploadData
{
    NSString *configName = @"com.donlinks.MKShareExtension.BackgroundSessionConfig";
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier: configName];
    sessionConfig.sharedContainerIdentifier = @"group.MKShareExtension";
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration: sessionConfig];
    NSURLSessionDataTask *task = [session dataTaskWithRequest: [self urlRequestWithShareData]];
    [task resume];
}

//组装 request 数据
- (NSURLRequest *)urlRequestWithShareData
{
    NSURL *uploadURL = [NSURL URLWithString: @"http://requestb.in/11sgq3y1"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: uploadURL];
    
    //设置表单头
    [request addValue: @"application/json" forHTTPHeaderField: @"Content-Type"];
    [request addValue: @"application/json" forHTTPHeaderField: @"Accept"];
    [request setHTTPMethod: @"POST"];
    
    //设置 JSON 数据
    NSMutableDictionary *dic = @{}.mutableCopy;
    NSMutableArray *imgInfoArray = @[].mutableCopy;
    for(UIImage *image in attachImageArray){
        [imgInfoArray addObject: [self imgInfo: image]];
    }
    
    NSMutableArray<NSString *> *urlArray = @[].mutableCopy;
    for(NSURL *url in attachURLArray){
        [urlArray addObject: url.relativeString];
    }
    
    [dic setObject: urlArray forKey: @"URL"];
    [dic setObject: attachStringArray forKey: @"extraString"];
    [dic setObject: imgInfoArray forKey: @"image"];
    
    NSError *error = nil;
    NSData *uplodData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error: &error];
    if(uplodData){
        
        request.HTTPBody = uplodData;
        
    }else{
        NSLog(@"JSONError: %@", error.localizedDescription);
    }
    
    return request;
}

- (NSDictionary *)imgInfo:(UIImage *)image
{
    NSMutableDictionary *dic = @{}.mutableCopy;
    
    [dic setObject: @(image.size.height).stringValue forKey: @"height"];
    [dic setObject: @(image.size.width).stringValue forKey: @"width"];
    [dic setObject: @(image.scale).stringValue forKey: @"scale"];
    [dic setObject: image.description forKey: @"description"];
    
    return dic;
}

@end
