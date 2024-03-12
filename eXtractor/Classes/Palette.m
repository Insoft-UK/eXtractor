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

#import "Palette.h"
#import "eXtractor-Swift.h"

@interface Palette()

// MARK: - Private Properties

@property NSMutableData *mutableData;

@property NSTimeInterval lastUpdateTime;
@property NSTimeInterval frameCount;

@property NSUInteger lowerLimit;
@property NSUInteger upperLimit;
@property NSInteger colorSteps;
@property NSTimeInterval cycleSpeed; // Number of 50Hz cycles :- PAL
@property BOOL changes;

@end


@implementation Palette

// MARK: - Init

-(id)init {
    if ((self = [super init])) {
        [self setup];
    }
    
    return self;
}

-(void)setup {
    self.mutableData = [NSMutableData dataWithCapacity:1024];
    
    for (UInt8 rgb=0; ; rgb++) {
        [self setRgbColor:[Palette colorFrom8BitRgb:rgb] atIndex:rgb];
        if (rgb == 255) break;
    }
    
    _colorCount = 256;
    _transparentIndex = 0xE3;
    
    _bytes = (UInt8 *)self.mutableData.bytes;
    
}

// MARK: - Public Instance Methods

-(void)reset {
    [self setColorAnimationWith:0
                     rightLimit:0
                       withStep:0
                     cycleSpeed:0];
    
    [self loadWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"Spectrum" ofType:@"act"]];
    _game = YES;
}

-(void)loadWithContentsOfFile:( NSString* _Nonnull )file {
    NSData *data = [NSData dataWithContentsOfFile:file];

    if ( data.length >= 768 ) { // ACT
        UInt8* byte = ( UInt8* )data.bytes;
        UInt16 c = 0;
        
        if ( data.length == 772 ) {
            _colorCount =  CFSwapInt16BigToHost(*(UInt16 *)(data.bytes + 768));
            self.mutableData.length = self.colorCount * sizeof(UInt32);
            _transparentIndex =  CFSwapInt16BigToHost(*(UInt16 *)(data.bytes + 770));
        } else {
            _colorCount = 256;
            _transparentIndex = 0xFFFF;
        }
        
        for (; c < self.colorCount; c++) {
            [self setRgbColor:( ( UInt32 )byte[2] << 16 ) | ( ( UInt32 )byte[1] << 8 ) | ( UInt32 )byte[0] atIndex:c];
            byte += 3;
        }
    } else if ( data.length <= 512 ) { // NPL
        UInt8* byte = ( UInt8* )data.bytes;
        UInt16 c = 0;
        
        _colorCount = data.length / 2;
        _transparentIndex = 227; // Default
        
        for (; c < self.colorCount; c++) { // R2 R1 R0 G2 G1 G0 B2 B1  xx xx xx xx xx xx xx B0 (le)
            UInt32 color = [Palette colorFrom9BitNextRgb:*(UInt16*)byte];
            
            [self setRgbColor:color atIndex:c];
            if (color == 0xFFFF00FF) {
                _transparentIndex = c;
            }
            
            byte += 2;
        }
    }
    
    
    self.changes = YES;
}

-(void)saveAsPhotoshopActAtPath:( NSString* _Nonnull )path {
    // Issue with NSFileHandle, so just using c until its resolved!
    
    //NSFileHandle *fileHandler = [NSFileHandle fileHandleForWritingAtPath:path];
    FILE *fp;
    
    fp = fopen([path UTF8String], "wb");
    
    if ( fp != nil ) {
        NSMutableData* act = [NSMutableData dataWithCapacity:772];
        if (act != nil) {
            act.length = 772;
                UInt8* byte = ( UInt8* )act.mutableBytes;
                UInt16 c = 0;
                
                for (; c < self.colorCount; c++) {
            
                    UInt32 rgb = [self rgbColorAtIndex:c];
#ifdef __LITTLE_ENDIAN__
                    rgb = CFSwapInt32HostToBig(rgb); // / ABGR -> RGBA
#endif

                    // RGBA
                    byte[0] = rgb >> 24;
                    byte[1] = ( rgb >> 16 ) & 255;
                    byte[2] = ( rgb >> 8 ) & 255;
                    
#ifdef DEBUG
                    NSLog(@"R:0x%02X, G:0x%02X, B:0x%02X", byte[0], byte[1], byte[2]);
#endif
                    
                    byte += 3;
                }
                
                // Zero... out any unused palette entries.
                for (; c < 256; c++) {
                    *byte++ = 0;
                    *byte++ = 0;
                    *byte++ = 0;
                }
                
                fwrite(act.bytes, sizeof(char), 768, fp);
                
                c = CFSwapInt16HostToBig(self.colorCount);
                fwrite(&c, sizeof(UInt16), 1, fp);
                
                c = CFSwapInt16HostToBig(self.transparentIndex);
                fwrite(&c, sizeof(UInt16), 1, fp);
                
                
                //[fileHandler writeData:actData];
            
        }
        //[fileHandler closeFile];
        fclose(fp);
    }
}

-(UInt32)colorAtIndex:(NSUInteger)index {
    return *( UInt32* )( self.mutableData.bytes + ( ( index & 255 ) << 2 ) );
}

-(UInt32)rgbColorAtIndex:(NSUInteger)index {
    UInt32 *pal = self.mutableData.mutableBytes;
    UInt32 rgb = pal[index & 255];
    
    return rgb;
}

-(BOOL)updateWithDelta:(NSTimeInterval)delta {
    self.frameCount += delta * 50.0;
    
    BOOL changes = self.changes;
    self.changes = NO;
    
    if (self.frameCount >= fabs(self.cycleSpeed)) {
        self.frameCount = 0.0;
        if (self.colorSteps == 0) {
            return changes;
        }
        for (NSInteger s=0; s<self.colorSteps; s++) {
            /*
            if (self.cycleSpeed > 0.0) {
                UInt32 tmpColor = [self rgbColorAtIndex:self.lowerLimit];
                for (NSUInteger i=self.lowerLimit; i<self.upperLimit; i++) {
                    [self setRgbColor:[self rgbColorAtIndex:i + 1] atIndex:i];
                }
                [self setRgbColor:tmpColor atIndex:self.upperLimit];
            }
            
            if (self.cycleSpeed < 0.0) {
                UInt32 tmpColor = [self rgbColorAtIndex:self.upperLimit];
                for (NSUInteger i=self.upperLimit; i>self.lowerLimit; i--) {
                    [self setRgbColor:[self rgbColorAtIndex:i - 1] atIndex:i];
                }
                [self setRgbColor:tmpColor atIndex:self.lowerLimit];
            }
             */
            NSInteger d = self.cycleSpeed >  0.0 ? 1 : -1;
            NSInteger i = d == 1 ? self.lowerLimit : self.upperLimit;
            NSInteger j = d == 1 ? self.upperLimit : self.lowerLimit;
            UInt32 t = [self rgbColorAtIndex:i];
            for (; i!=j; i+=d) {
                [self setRgbColor:[self rgbColorAtIndex:i + d] atIndex:i];
            }
            [self setRgbColor:t atIndex:j];
        }
        return YES;
    }
    return changes;
}

// MARK: - Public Class Methods

// ZX Spectrum NEXT :- R2 R1 R0 G2 G1 G0 B1 B0
+(UInt32)colorFrom8BitRgb:( UInt8 )rgb {
    /*
     3 bits in red and green channels give us 8 values.
     When scaled to the 0–255 range we get:
     */
    UInt32 tbl[] = {0, 36, 72, 109, 145, 182, 218, 255};

    UInt32 r = (rgb & 0b11100000) >> 5;
    UInt32 g = (rgb & 0b00011100) >> 2;
    
    /*
     2 bits in the blue channel only give us 4 values: 0 85 170 255
     If we know that we can make shades of grey by using the same value
     in all three RGB channels, it quickly becomes obvious that the
     asymmetric distribution of R3/G3 vs B2 makes it impossible to
     generate ANY shades of perfect grey at all on the Next in the new modes.

     We can find values that are close to each other, and in that case
     we see that blue will be the limiting channel. So let's just choose
     4 values we'll use for R/G that match the ones in B:
     
     So we simply convert 2 bits in the blue channel to 3 bits.
     */
    UInt32 b = (rgb & 0b00000011) << 1;
    if (rgb & 0b00000010) b |= 0b00000001;
    
    return tbl[r] | tbl[g] << 8 | tbl[b] << 16 | 0xFF000000;
}

// ZX Spectrum NEXT :- R2 R1 R0 G2 G1 G0 B2 B1  xx xx xx xx xx xx xx B0 (le)
+(UInt32)colorFrom9BitNextRgb:( UInt16 )rgb {
    /*
     3 bits in red green and blue channels give us 8 values.
     When scaled to the 0–255 range we get:
     */
    UInt32 tbl[] = {0, 36, 72, 109, 145, 182, 218, 255};
#ifdef __BIG_ENDIAN__
    rgb = CFSwapInt16LittleToHost(rgb);
#endif
    UInt32 r = (rgb & 0b11100000) >> 5;
    UInt32 g = (rgb & 0b00011100) >> 2;
    UInt32 b = ((rgb & 0b00000011) << 1) | (rgb >> 8);
    
    return tbl[r] | tbl[g] << 8 | tbl[b] << 16 | 0xFF000000;
}

// Atari ST  :- xx xx xx xx xx R2 R1 R0  xx G2 G1 G0 xx B2 B1 B0 (be)
+(UInt32)colorFrom9BitRgb:( UInt16 )rgb {
    UInt32 color;
#ifdef __LITTLE_ENDIAN__
    rgb = CFSwapInt16BigToHost(rgb);
#endif
    // xx C2 C1 C3 -> C2 C1 C0 [C2 | C1]
    rgb = ( ( rgb & 0x777 ) << 1 ) | ( ( rgb & 0x444 ) >> 2 ) | ( ( rgb & 0x222 ) >> 1 );
    color = ( ( UInt32 )( rgb & 0x0F00 ) >> 4 ) | ( ( UInt32 )( rgb & 0x00F0 ) << 8 ) | ( ( UInt32 )( rgb & 0x000F ) << 20 );
    return  color | ( color >> 4 ) | 0xFF000000;
}

// Atari STE :- xx xx xx xx R0 R3 R2 R1  G0 G3 G2 G1 B0 B3 B2 B1
+(UInt32)colorFrom12BitRgb:( UInt16 )rgb {
    UInt32 color;
#ifdef __LITTLE_ENDIAN__
    rgb = CFSwapInt16BigToHost(rgb);
#endif
    // C0 C3 C2 C1 -> C3 C2 C1 C0
    rgb = ( ( rgb & 0x777 ) << 1 ) | ( ( rgb & 0x888 ) >> 3 );
    color = ( ( UInt32 )( rgb & 0x0F00 ) >> 4 ) | ( ( UInt32 )( rgb & 0x00F0 ) << 8 ) | ( ( UInt32 )( rgb & 0x000F ) << 20 );
    return  color | ( color >> 4 ) | 0xFF000000;
}



+(BOOL)isAtariStFormat:( const UInt16* _Nonnull )rgb {
    UInt16 color;
    
    for ( int i=0; i < 16; i++) {
        color = rgb[i];
#ifdef __LITTLE_ENDIAN__
        color = CFSwapInt16BigToHost(color);
#endif
        if ( color & 0b1111100010001000 ) return NO;
    }
    
    return ![self isAnyRepeatsInList:rgb withLength:16];
}


+(BOOL)isAtariSteFormat:( const UInt16* _Nonnull )rgb {
    UInt16 color;

    for ( int i=0; i < 16; i++) {
        color = rgb[i];
#ifdef __LITTLE_ENDIAN__
        color = CFSwapInt16BigToHost(color);
#endif
        if ( color & 0b1111000000000000 ) return NO;
    }
    
    return ![self isAnyRepeatsInList:rgb withLength:16];
}

+(BOOL)isNextFormat:( const UInt16* _Nonnull )rgb {
    UInt16 color;

    for ( int i=0; i < 16; i++) {
        color = rgb[i];
        if ( color & 0b1111111000000000 ) return NO;
    }
    
    return ![self isAnyRepeatsInList:rgb withLength:16];
}

// MARK:- Public Getter & Setters


-(void)setRgbColor:( UInt32 )rgb atIndex:(NSUInteger)index {
    *( UInt32* )( self.mutableData.mutableBytes + ( ( index & 255 ) * sizeof(UInt32) ) ) = rgb | 0xFF000000;
    [Colors redrawPalette:self.mutableData.bytes colorCount:self.colorCount];
    self.changes = YES;
}

-(void)setColorWithRed:(UInt8)r green:(UInt8)g blue:(UInt8)b atIndex:(NSUInteger)index {
    *( UInt32* )( self.mutableData.mutableBytes + ( ( index & 255 ) * sizeof(UInt32) ) ) = (UInt32)r | ((UInt32)g << 8) | ((UInt32)b << 16) | 0xFF000000;
    if (index == _transparentIndex) {
        *( UInt32* )( self.mutableData.mutableBytes + ( ( index & 255 ) * sizeof(UInt32) ) ) &= 0x00FFFFFF;
    }
    [Colors redrawPalette:self.mutableData.bytes colorCount:self.colorCount];
    self.changes = YES;
}

-(void)setColorAnimationWith:(NSUInteger)leftLimit rightLimit:(NSUInteger)right withStep:(NSInteger)steps cycleSpeed:(NSTimeInterval)speed {
    self.lowerLimit = leftLimit;
    self.upperLimit = right;
    self.colorSteps = steps;
    self.cycleSpeed = speed;
}

-(void)setColorCount:(NSUInteger)count {
    _colorCount = count < 1 ? 256 : count;
    [Colors redrawPalette:self.mutableData.bytes colorCount:self.colorCount];
}

-(void)setTransparentIndex:(NSUInteger)index {
    _transparentIndex = index & 255;
}

// MARK:- Private Class Methods

+(BOOL)isAnyRepeatsInList:( const UInt16* )list withLength:( NSUInteger )length {
    for (NSUInteger i = 0; i < length; i++) {
        for (NSUInteger j = 0; j < length; j++) {
            if (i != j) {
                if (list[i] == list[j]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

@end
