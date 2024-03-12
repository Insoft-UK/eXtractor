/*
Copyright © 2020 Insoft. All rights reserved.

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

#import "MainScene.h"

#import "eXtractor-Swift.h"
#import <Cocoa/Cocoa.h>

@interface MainScene()

//@property SKLabelNode *info;
@property NSTimeInterval lastUpdateTime;
@property Image *image;


@end

@implementation MainScene

// MARK: - View

- (void)didMoveToView:(SKView *)view {
    // Setup your scene here
    [self setup];
    
    Singleton.sharedInstance.mainScene = self;
    //Singleton.sharedInstance.image = self.image;
    self.image = Singleton.sharedInstance.image;
}

- (void)willMoveFromView:(SKView *)view {
    
}

// MARK: - Setup

- (void)setup {
    CGSize size = NSApp.windows.firstObject.frame.size;
    self.size = CGSizeMake(size.width, size.height - 28);
    
    [Singleton.sharedInstance.image modifyWithContentsOfURL:[NSBundle.mainBundle URLForResource:@"eXtractor" withExtension:@"raw"]];
    Singleton.sharedInstance.image.bitsPerPixel = 24;
    Singleton.sharedInstance.image.planeCount = 1;
    Singleton.sharedInstance.image.size = CGSizeMake(256, 256);
    
    Singleton.sharedInstance.image.position = CGPointMake(self.size.width / 2, self.size.height / 2);
    [self addChild:Singleton.sharedInstance.image];
}




// MARK: - Keyboard Events

- (void)keyDown:(NSEvent *)theEvent {
    
    switch (theEvent.keyCode) {
        case 0x7b /* CURSOR LEFT */:
            [self.image setOffset:self.image.offset - 1];
            break;
            
        case 0x7c /* CURSOR RIGHT */:
            [self.image setOffset:self.image.offset + 1];
            break;
            
        case 0x7d /* CURSOR DOWN */:
            [self.image setOffset:self.image.offset + self.image.bytesPerLine];
            break;
            
        case 0x7e /* CURSOR UP */:
            [self.image setOffset:self.image.offset - self.image.bytesPerLine];
            break;
            
            
        default:
#ifdef DEBUG
            NSLog(@"keyDown:'%@' keyCode: 0x%02X", theEvent.characters, theEvent.keyCode);
#endif
            break;
    }
}



// MARK: - Update

-(void)update:(CFTimeInterval)currentTime {
    NSTimeInterval delta = currentTime - self.lastUpdateTime;
    self.lastUpdateTime = currentTime;
    
    [self.image updateWithDelta:delta];
}


// MARK: - Class Public Methods

-(void)checkForKnownFormats {
    [self.image.palette reset];
    
    if (isZXTapeFormat(self.image.data.bytes, self.image.data.length) == true) {
        [self.image setSize:CGSizeMake(64, 64)];
        [self.image setPlaneCount:1];
        [self.image setBitsPerPixel:1];
        [self.image setTileWithWidthOf:1 andHightOf:1];
        [self.image.palette loadWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"ZX Spectrum" ofType:@"act"]];
        self.image.alphaPlane = NO;
        [self.image setAspectRatio:1.0];
        [self.image setScale:4.0];
        return;
    }
    
    if (isNEOchromeFormat(self.image.data.bytes, self.image.data.length) == true) {
        NEOchrome *neo = (NEOchrome *)self.image.data.bytes;
        
        // Palette
        for (NSInteger i=0; i<256; i++) {
            UInt32 color = [Palette colorFrom12BitRgb:neo->palette[i]];
            [self.image.palette setRgbColor:color atIndex:i];
        }
        [self.image.palette setColorCount:16];
        [self.image.palette setTransparentIndex:256];
        
        if (CFSwapInt16BigToHost(neo->colorAniLimits) & 0x8000) { /// Palette Animation!
            [self.image.palette setColorAnimationWith:(CFSwapInt16BigToHost(neo->colorAniLimits) >> 4) & 0xF
                                           rightLimit:CFSwapInt16BigToHost(neo->colorAniLimits) & 0xF
                                             withStep:CFSwapInt16BigToHost(neo->colorAniSpeedDir) & 0xFF
                                           cycleSpeed:(NSTimeInterval)(CFSwapInt16BigToHost(neo->colorAniSpeedDir) & 0xFF)];
        }
        
        // Image
        [self.image setPlaneCount:4];
        [self.image setBitsPerPixel:16];
        [self.image setSize:CGSizeMake(320, 200)];
        [self.image setOffset:sizeof(NEOchrome)];
        [self.image setScale:3.0];
        return;
    }
    
    if (isDegasFormat(self.image.data.bytes, self.image.data.length) == true) {
        Degas *degas = (Degas *)self.image.data.bytes;
        
        // Palette
        for (NSInteger i=0; i<256; i++) {
            UInt32 color = [Palette colorFrom12BitRgb:degas->palette[i]];
            [self.image.palette setRgbColor:color atIndex:i];
        }
        [self.image.palette setColorCount:16];
        [self.image.palette setTransparentIndex:256];
        
        // Image
        switch (CFSwapInt16BigToHost(degas->resolution) & 3) {
            case 0:
                [self.image setPlaneCount:4];
                [self.image setBitsPerPixel:16];
                [self.image setSize:CGSizeMake(320, 200)];
                break;
                
            case 1:
                [self.image setPlaneCount:2];
                [self.image setBitsPerPixel:16];
                [self.image setSize:CGSizeMake(640, 200)];
                break;
                
            case 2:
                [self.image setPlaneCount:1];
                [self.image setBitsPerPixel:1];
                [self.image setSize:CGSizeMake(640, 400)];
                break;
                
            default:
                break;
        }
        
        [self.image setOffset:sizeof(Degas)];
        [self.image setScale:3.0];
        return;
    }
    
    if (isZXSpectrumFormat(self.image.data.bytes, self.image.data.length) == true) {
        // Image
        [self.image setDataLength:49152];
        convertZXSpectrumScreenToIndexedColor(self.image.data.bytes);
        
        [self.image setPlaneCount:1];
        [self.image setBitsPerPixel:8];
        [self.image setOffset:0];
        [self.image setSize:CGSizeMake(256, 192)];
        
        NSString *filePath = [NSBundle.mainBundle pathForResource:@"ZX Spectrum" ofType:@"act"];
        if (filePath != nil) {
            [self.image.palette loadWithContentsOfFile:filePath];
        }
        [self.image setScale:3.0];
        return;
    }
}




@end
