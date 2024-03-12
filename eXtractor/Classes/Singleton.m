/*
Copyright © 2021 Insoft. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#import "Singleton.h"
#import "eXtractor-Swift.h"

@implementation Singleton

// MARK: - Init

+(instancetype)sharedInstance {
    static Singleton *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}


-(instancetype)init {
    if ((self = [super init])) {
        [self setup];
    }
    
    return self;
}

// MARK: - Setup
#pragma mark - Setup
-(void)setup {
    _image = [[Image alloc] initWithSize:ScreenSize()];
    
}
/*
-(void)redrawPalette {
    
    ViewController *viewController = (ViewController *)NSApplication.sharedApplication.windows.firstObject.contentViewController;
    
    if (viewController != nil) {
        NSInteger colorCount = Singleton.sharedInstance.image.palette.colorCount;
        CGImageRef cgImage = [Extenions createCGImageFromPixelData:Singleton.sharedInstance.image.palette.bytes ofSize:CGSizeMake(colorCount, 1)];
        
        if (cgImage != nil) {
            CGImageRef resizedCGImage = [Extenions resizeCGImage:cgImage toSize:CGSizeMake(512, 12)];
            if (resizedCGImage != nil) {
                NSImage *nsImage = [Extenions createNSImageFromCGImage:resizedCGImage];
                if (nsImage != nil) {
                    viewController.imageView.image = nsImage;
                }
            }
        }
    }
}
*/
@end
