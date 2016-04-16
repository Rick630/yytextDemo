//
//  ViewController.m
//  yytextIssue
//
//  Created by Rick on 4/16/16.
//  Copyright © 2016 Rick. All rights reserved.
//

#import "ViewController.h"
#import "YYText.h"

#define WIDTH [UIScreen mainScreen].bounds.size.width - 30

@interface ViewController ()
{
    NSString *originText;
    
    YYLabel *contentLab;
    UIScrollView *contentScroll;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    contentLab = [YYLabel new];
    contentLab.numberOfLines = 0;
    contentLab.font = [UIFont systemFontOfSize:16];

    contentScroll = [[UIScrollView alloc] initWithFrame:CGRectOffset(self.view.bounds, 15, 0)];
    [self.view addSubview:contentScroll];
    [contentScroll addSubview:contentLab];
    
    [self initData];
    
    [self fillData];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    YYTextLayout *layout = [YYTextLayout layoutWithContainerSize:CGSizeMake(WIDTH, MAXFLOAT) text:contentLab.attributedText];
    contentLab.frame = CGRectMake(0, 0, WIDTH, layout.textBoundingSize.height);
    
    contentScroll.contentSize = CGSizeMake(0, layout.textBoundingSize.height);
}
-(void)initData
{
    //不能显示
    NSData *response = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"response" ofType:@"txt"]];
    
    //显示正常
//    NSData *response = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"response2" ofType:@"txt"]];

    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:nil];
    
    originText = data[@"data"][@"content"];

}

-(void)fillData
{
    NSArray *components = [self componentsOfContent:originText];
    
    NSMutableAttributedString *attContent = [NSMutableAttributedString new];
    
    for(NSString *component in components) {
        NSAttributedString *attString = [self yyAttStrWithComponent:component];
        if (!attString) {
            continue;
        } else {
            [attContent appendAttributedString:attString];
        }
    }
    
    attContent.yy_lineSpacing = 10;
    
    contentLab.attributedText = attContent;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - function
- (NSArray *)componentsOfContent:(NSString *)originContentText {
    NSMutableArray *imageUrls = [NSMutableArray new];
    
    //用正则找出图片url <img src=\"(.+?)\" alt=\"\" />
    NSRegularExpression *regular =[[NSRegularExpression alloc]initWithPattern:@"<img.*?/>" options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray *array = [regular matchesInString:originContentText options:0 range:NSMakeRange(0, [originContentText length])];
    
    if(array.count == 0)  {
        [imageUrls addObject:originContentText];
    } else {
        NSRange lastRange = NSMakeRange(0, 0);
        
        for(NSTextCheckingResult *result in array) {
            NSRange textRange = result.range;
            if(textRange.location > 0) {
                NSString *preString = [originContentText substringWithRange:NSMakeRange(lastRange.location+lastRange.length, textRange.location-(lastRange.location+lastRange.length))];
                if(preString.length > 0)
                    [imageUrls addObject:preString];
            }
            
            NSString *urlText = [originContentText substringWithRange:textRange];
            [imageUrls addObject:urlText];
            
            if([result isEqual:[array lastObject]] && ((textRange.location + textRange.length) < originContentText.length)) {
                NSString *postString = [originContentText substringWithRange:NSMakeRange(textRange.location+textRange.length, originContentText.length-(textRange.location+textRange.length))];
                [imageUrls addObject:postString];
            }
            lastRange = textRange;
        }
    }
    
    return imageUrls;
}
- (NSAttributedString *)yyAttStrWithComponent:(NSString *)component {
    NSMutableAttributedString *attachText = [NSMutableAttributedString new];
    
    if([component rangeOfString:@"<img src=\""].length > 0 || [component rangeOfString:@"src=\""].length > 0) {
        
        NSRegularExpression *reg = [[NSRegularExpression alloc]initWithPattern:@"src=\"(.*?)\"" options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:nil];
        NSArray *results = [reg matchesInString:component options:0 range:NSMakeRange(0, component.length)];
        NSString *absoluteUrl = results.count > 0 ? [component substringWithRange:[((NSTextCheckingResult *)results[0]) rangeAtIndex:1]]:nil;
        
        if(!absoluteUrl || absoluteUrl.length == 0)
            return nil;
        
        //云服务器上用相对路径 先判断有没有http
        absoluteUrl = [absoluteUrl hasPrefix:@"http"]?absoluteUrl:[NSString stringWithFormat:@"%@%@",@"http://static.qiuqiusd.com",absoluteUrl];
        
//        NSURL *imageUrl = [NSURL URLWithString:absoluteUrl];
        //获得Image size
        CGSize size = [self sizeOfImage:absoluteUrl];
        
        //添加图片视图
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];

        //set image
        
        
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.clipsToBounds = YES;
        imageView.userInteractionEnabled = YES;
        imageView.backgroundColor = [UIColor redColor];
        
        
        attachText = [NSMutableAttributedString yy_attachmentStringWithContent:imageView contentMode:UIViewContentModeCenter attachmentSize:size alignToFont:[UIFont systemFontOfSize:16] alignment:YYTextVerticalAlignmentCenter];
    } else {
        NSMutableAttributedString *attS = [[NSMutableAttributedString alloc] initWithString:component];
        attS.yy_font = [UIFont systemFontOfSize:16];
        [attachText appendAttributedString:attS];
    }
    
    return attachText;
}
-(CGSize)sizeOfImage:(NSString *)imgUrl
{
    CGFloat imageWidth = WIDTH;
    
    NSArray *sizes = [imgUrl componentsSeparatedByString:@"_"];
    CGSize size = CGSizeMake(imageWidth, imageWidth);
    if(sizes.count > 1) {
        NSString *ratioStr = [imgUrl componentsSeparatedByString:@"_"][1];
        CGFloat realWidth = [[[ratioStr componentsSeparatedByString:@"x"] lastObject] floatValue];
        CGFloat realHeight = [[[ratioStr componentsSeparatedByString:@"x"] firstObject] floatValue];
        if (realWidth != 0 && realHeight != 0) {
            size = CGSizeMake(imageWidth, (realHeight/realWidth)*imageWidth);
        }
    }
    
    return size;
}
@end
