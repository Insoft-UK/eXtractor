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

#import "Image.h"
#import "eXtractor-Swift.h"

#pragma pack(1)     /* set alignment to 1 byte boundary */

typedef struct {
    UInt8 redChannel, greenChannel, blueChannel;
} TriColor;

typedef struct {
    UInt8 redChannel, greenChannel, blueChannel, alphaChannel;
} RGBA;

#pragma pack()   /* restore original alignment from stack */

@interface Image()


// MARK: - Private Properties

@property SKMutableTexture *mutableTexture;
@property NSMutableData *mutableData;
@property NSMutableData *scratchData;


@property BOOL changes;

@property NSInteger paletteOffset;

@end

@implementation Image


// MARK: - Init

- (id)initWithSize:(CGSize)size {
    if ((self = [super init])) {
        self.planeCount = 4;
        self.alphaPlane = NO;
        self.maskPlane = NO;
        self.bitsPerPixel = 16;
        self.bigEndian = YES;
    
        
        _tileWidth = 1;
        _tileHeight = 1;
        _padding = 0;
        _zoom = 1;
        
        _pixelFormat = ImagePixelFormatRGB555;
        
        _size = CGSizeMake(256, 256);
        [self setupWithSize: size];
        self.changes = YES;
        
        self.palette.game = YES;
    }
    
    return self;
}

- (void)setupWithSize:(CGSize)size {
    NSUInteger lengthInBytes = (NSUInteger)size.width * (NSUInteger)size.height * sizeof(UInt32);
    
    self.mutableTexture = [[SKMutableTexture alloc] initWithSize:size];
    self.mutableData = [[NSMutableData alloc] initWithCapacity:(NSUInteger)2^32];
    self.mutableData.length = lengthInBytes;
    
    self.scratchData = [[NSMutableData alloc] initWithCapacity:lengthInBytes];
    self.scratchData.length = lengthInBytes;
    
    _data = (NSData*)self.mutableData;
    
    
    
    _aspectRatio = 1.0;
    
    SKSpriteNode *node;
    
    SKMutableTexture *texture = [[SKMutableTexture alloc] initWithSize:size];
    if (texture != nil) {
        [texture modifyPixelDataWithBlock:^(void *pixelData, size_t lengthInBytes) {
            UInt32 *pixel = pixelData;
            
            NSUInteger s = size.width;
            NSUInteger l = size.height;
            
            for (NSUInteger r = 0; r < l; ++r) {
                for (NSUInteger c = 0; c < s; ++c) {
                    pixel[r * s + c] = (r & 0b1000 ? c+8 : c) & 0b1000 ? 0xFFFF0000 : 0xFFAA0000;
                }
            }
        }];
        
        
        node = [SKSpriteNode spriteNodeWithTexture:(SKTexture*)texture size:size];
        node.texture.filteringMode = SKTextureFilteringNearest;
        [self addChild:node];
        
        _palette = [[Palette alloc] init];
    }
    
    if (self.mutableTexture) {
        node = [SKSpriteNode spriteNodeWithTexture:(SKTexture*)self.mutableTexture size:size];
        node.yScale = -1;
        node.texture.filteringMode = SKTextureFilteringNearest;
        node.name = @"Image";
        [self addChild:node];
    }
    
    
}

// MARK: - Public Instance Methods

- (void)firstAtariSTPalette {
    self.paletteOffset = 0;
    [self findAtariSTPalette];
}

- (void)nextAtariSTPalette {
    self.paletteOffset += 2;
    [self findAtariSTPalette];
}

- (void)findAtariSTPalette {
    const UInt8 *bytes = (const UInt8 *)self.mutableData.bytes + self.paletteOffset;
    NSInteger limit = self.mutableData.length - sizeof(UInt16) * 16;

    while (self.paletteOffset <= limit) {
        const UInt16* pal = ( const UInt16* )bytes;
        if (self.palette.game == YES && pal[0] != 0) {
            self.paletteOffset++;
            bytes++;
            continue;
        }
        if ([Palette isAtariSteFormat:( const UInt16* )bytes] == YES) {
            for (int i=0; i<16; i++) {
                [self.palette setRgbColor:[Palette colorFrom12BitRgb:pal[i]] atIndex:i];
            }
            [self.palette setColorCount:16];
            [self.palette setTransparentIndex:0];
            return;
        } else if ([Palette isAtariStFormat:( const UInt16* )bytes] == YES) {
            for (int i=0; i<16; i++) {
                [self.palette  setRgbColor:[Palette colorFrom9BitRgb:pal[i]] atIndex:i];
            }
            [self.palette setColorCount:16];
            [self.palette setTransparentIndex:0];
            return;
        }
        self.paletteOffset++;
        bytes++;
    }
    
    
    
    self.changes = YES;
}

-(void)modifyWithContentsOfURL:(NSURL*)url {
    NSData *data = [NSData dataWithContentsOfURL:url];
    self.mutableData.length = data.length;
    [self.mutableData setData:data];
    [self setOffset:0];
}



-(void)saveImageAtURL:(NSURL *)url {
    [self.mutableTexture modifyPixelDataWithBlock:^(void *pixelData, size_t lengthInBytes) {
        CGImageRef imageRef = [Extenions createCGImageFromPixelData:pixelData ofSize:self.mutableTexture.size];
        [Extenions writeCGImage:imageRef to:url];
    }];
}

-(void)updateWithDelta:(NSTimeInterval)delta {
    if ([self.palette updateWithDelta:delta] == YES) {
        self.changes = YES;
    }
    
    
    
    
    
    if (self.changes == NO) return;
    
    ViewController *viewController = (ViewController *)NSApplication.sharedApplication.windows.firstObject.contentViewController;
    
    viewController.widthText.stringValue = [NSString stringWithFormat:@"%d", (int)self.size.width];
    viewController.heightText.stringValue = [NSString stringWithFormat:@"%d", (int)self.size.height];
    viewController.zoomText.stringValue = [NSString stringWithFormat:@"%ldx", self.zoom];
    
    if (self.aspectRatio > 1.1) {
        viewController.ratioText.stringValue = @"2:1";
    } else if (self.aspectRatio < 1.0) {
        viewController.ratioText.stringValue = @"1:2";
    } else {
        viewController.ratioText.stringValue = @"1:1";
    }
    
    viewController.infoText.stringValue = [NSString stringWithFormat:@"%ld bytes selected at offset %ld out of %ld bytes", self.selected, self.offset, self.bytes];
    
    
    
    [self.mutableTexture modifyPixelDataWithBlock:^(void *pixelData, size_t lengthInBytes) {
        memset(pixelData, 0, lengthInBytes);
      
        
        if (self.planeCount > 1) {
            if (self.bitsPerPixel == 8) {
                [self planer8BitToPixelData:pixelData];
            }
            if (self.bitsPerPixel == 16) {
                if (self.maskPlane == YES) {
                    [self mask16BitToPixelData:pixelData];
                } else {
                    [self planer16BitToPixelData:pixelData];
                }
            }
        }
        
        if (self.planeCount <= 1) {
            if (self.bitsPerPixel == 1) {
                [self packed1BitToPixelData:pixelData];
            }
            if (self.bitsPerPixel == 2) {
                [self packed2BitToPixelData:pixelData];
            }
            if (self.bitsPerPixel == 4) {
                [self packed4BitToPixelData:pixelData];
            }
            if (self.bitsPerPixel == 8) {
                [self packed8BitToPixelData:pixelData];
            }
        }
        
    }];
    
   
    if (self.planeCount <= 1) {
        if (self.bitsPerPixel == 24) {
            if (self.alphaPlane) {
                [self packed32Bit];
            }
            if (!self.alphaPlane) {
                [self packed24Bit];
            }
            [self renderTexture];
        }
        
        if (self.bitsPerPixel == 16) {
            [self render16KImageDataToScratchData];
            [self renderTexture];
        }
        
    }
    
    self.changes = NO;
}

- (void)renderTexture {
    [self.mutableTexture modifyPixelDataWithBlock:^(void *pixelData, size_t lengthInBytes) {
        memset(pixelData, 0, lengthInBytes);
        if (self.tileWidth > 1 && self.tileHeight > 1) {
            [self renderAsTilesToPixelData:pixelData];
        } else {
            [self renderAsImageToPixelData:pixelData];
        }
    }];
}

- (void)renderAsImageToPixelData:(void *)pixelData {
    NSUInteger s = self.mutableTexture.size.width;
    NSUInteger l = self.mutableTexture.size.height;
    
    NSUInteger w = self.size.width;
    NSUInteger h = self.size.height;
    
    UInt32 *src = (UInt32 *)self.scratchData.bytes;
    UInt32 *dst = (UInt32 *)pixelData;
    
    for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; ++r) {
        for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; ++c) {
            dst[r * s + c] = *src++;
        }
    }
}

- (void)renderAsTilesToPixelData:(void *)pixelData {
    NSUInteger s = self.mutableTexture.size.width;
    NSUInteger l = self.mutableTexture.size.height;
    
    NSUInteger w = self.size.width;
    NSUInteger h = self.size.height;
    
    UInt32 *src = (UInt32 *)self.scratchData.bytes;
    UInt32 *dst = (UInt32 *)pixelData;
    
    for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; r += self.tileHeight) {
        for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; c += self.tileWidth) {
            for (NSUInteger y = 0; y < self.tileHeight; y++) {
                for (NSUInteger x = 0; x < self.tileWidth; x++) {
                    dst[(r + y) * s + c + x] = *src++;
                }
            }
        }
    }
}

- (void)packed1BitToPixelData:(void *)pixelData {
    UInt32 *pixel = pixelData;
    const unsigned char *bytes = self.mutableData.bytes + self.offset;
    
    NSUInteger s = self.mutableTexture.size.width;
    NSUInteger l = self.mutableTexture.size.height;
    
    NSUInteger w = self.size.width;
    NSUInteger h = self.size.height;
    
    UInt8 data;
    
    if (self.tileWidth > 1 && self.tileHeight > 1) {
        for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; r+=self.tileHeight) {
            for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; c+=self.tileWidth) {
                for (NSUInteger y = 0; y < self.tileHeight; y++) {
                    for (NSUInteger x = 0; x < self.tileWidth; x++) {
                        data = bytes[0];
                        NSUInteger b = x % 8;
                        pixel[(r + y) * s + c + x] = (data & 1 << (7 - b)) ? 0xffffffff : 0;
                        if (b == 7) bytes += 1;
                    }
                }
            }
        }
    } else {
        for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; ++r) {
            for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; c+=8) {
                data = bytes[0];
                for (NSUInteger b = 0; b <= 7; b++) {
                    pixel[r * s + c + b] = (data & 1 << (7 - b)) ? 0xffffffff : 0;
                }
                bytes += 1;
            }
        }
    }
}
/*
- (void)packed2Bit {
    UInt8 *src = (UInt8 *)self.mutableData.bytes + self.offset;
    UInt32 *dst = (UInt32 *)self.scratchData.bytes;
    NSUInteger length = (NSUInteger)self.size.width * (NSUInteger)self.size.height;
    NSUInteger blockSize = self.tileWidth / 4 * self.tileHeight;
    
    while (length) {
        for (NSUInteger i = 0; i < blockSize; i++) {
            UInt8 data = *src;
            for (NSUInteger n = 0; n < 4; n++) {
                NSUInteger indexColor = data & 0b11;
                if (indexColor == self.palette.transparentIndex && self.alphaPlane == YES) {
                    dst[3 - n] = 0;
                } else {
                    dst[3 - n] = [self.palette rgbColorAtIndex:indexColor];
                }
                data >>= 2;
            }
            dst += 4;
            src += 1;
        }
        src += self.padding;
        length -= blockSize;
    }
}
*/
     
- (void)packed2BitToPixelData:(void *)pixelData {
    UInt32 *pixel = pixelData;
    const unsigned char *bytes = self.mutableData.bytes + self.offset;
    
    NSUInteger s = self.mutableTexture.size.width;
    NSUInteger l = self.mutableTexture.size.height;
    
    NSUInteger w = self.size.width;
    NSUInteger h = self.size.height;
    
    UInt8 data;
    
    for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; ++r) {
        for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; c+=4) {
            data = bytes[0];
            for (NSUInteger i = 0; i < 4; i++) {
                NSUInteger index = data & 0b11;
                UInt32 rgb = [self.palette rgbColorAtIndex:index];
                if (index == self.palette.transparentIndex && self.alphaPlane == YES) {
                    rgb = 0;
                }
                pixel[r * s + c + 1 - i] = rgb;
                data >>= 2;
            }
            bytes += 1;
        }
    }
}

- (void)packed4BitToPixelData:(void *)pixelData {
    UInt32 *pixel = pixelData;
    const unsigned char *bytes = self.mutableData.bytes + self.offset;
    
    NSUInteger s = self.mutableTexture.size.width;
    NSUInteger l = self.mutableTexture.size.height;
    
    NSUInteger w = self.size.width;
    NSUInteger h = self.size.height;
    
    UInt8 data;
    if (self.tileWidth > 1 && self.tileHeight > 1) {
        for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; r+=self.tileHeight) {
            for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; c+=self.tileWidth) {
                for (NSUInteger y = 0; y < self.tileHeight; y++) {
                    for (NSUInteger x = 0; x < self.tileWidth; x++) {
                        data = bytes[0];
                        for (NSUInteger i = 0; i < 2; i++) {
                            NSUInteger index = data & 0b1111;
                            UInt32 rgb = [self.palette rgbColorAtIndex:index];
                            if (index == self.palette.transparentIndex && self.alphaPlane == YES) {
                                rgb = 0;
                            }
                            pixel[(r + y) * s + c + x + 1 - i] = rgb;
                            data >>= 4;
                        }
                        bytes += 1;
                    }
                }
            }
        }
    } else {
        for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; ++r) {
            for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; c+=2) {
                data = bytes[0];
                for (NSUInteger i = 0; i < 2; i++) {
                    NSUInteger index = data & 0b1111;
                    UInt32 rgb = [self.palette rgbColorAtIndex:index];
                    if (index == self.palette.transparentIndex && self.alphaPlane == YES) {
                        rgb = 0;
                    }
                    pixel[r * s + c + 1 - i] = rgb;
                    data >>= 4;
                }
                bytes += 1;
            }
        }
    }
}

- (void)packed8BitToPixelData:(void *)pixelData {
    UInt32 *pixel = pixelData;
    const unsigned char *bytes = self.mutableData.bytes + self.offset;
    
    NSUInteger s = self.mutableTexture.size.width;
    NSUInteger l = self.mutableTexture.size.height;
    
    NSUInteger w = self.size.width;
    NSUInteger h = self.size.height;
    
    if (self.tileWidth > 1 && self.tileHeight > 1) {
        for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; r+=self.tileHeight) {
            for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; c+=self.tileWidth) {
                for (NSUInteger y = 0; y < self.tileHeight; y++) {
                    for (NSUInteger x = 0; x < self.tileWidth; x++) {
                        int i;
                        i = [self.palette rgbColorAtIndex:bytes[0]];
                        if (self.palette.transparentIndex == i && self.alphaPlane == YES) {
                            i = 0;
                        }
                        pixel[(r + y) * s + c + x] = i;
                        bytes += 1;
                    }
                }
            }
        }
    } else {
        for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; ++r) {
            for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; ++c) {
                int i;
                i = [self.palette rgbColorAtIndex:bytes[0]];
                if (self.palette.transparentIndex == i && self.alphaPlane == YES) {
                    i = 0;
                }
                pixel[r * s + c] = i;
                bytes += 1;
            }
        }
    }
    
    
}

- (UInt32)toColorFromRGB555:(UInt16) color {
    // [A0 R4 R3 R2 R1 R0 G4 G3] | [G2 G1 G0 B4 B3 B2 B1 B0]
    
    UInt32 a = color & 0b1000000000000000;
    UInt32 r = color & 0b0111110000000000;
    UInt32 g = color & 0b0000001111100000;
    UInt32 b = color & 0b0000000000011111;
    
    UInt32 rgb = (r >> 10) | (g << 6) | (b << 19);
    // [A7...0 B7...0 G7...0 R7...0]
    return 0xFF000000 | rgb | ((rgb >> 5) & 0x070707);
}

- (UInt32)toColorFromRGB565:(UInt16) color {
    // [R4 R3 R2 R1 R0 G5 G4 G3] | [G2 G1 G0 B4 B3 B2 B1 B0]
    
    UInt32 r = color & 0b1111100000000000;
    UInt32 g = color & 0b0000011111100000;
    UInt32 b = color & 0b0000000000011111;
    
    UInt32 rgb = (r >> 8) | (g << 5) | (b << 19);
    // [A7...0 B7...0 G7...0 R7...0]
    return 0xFF000000 | rgb | ((rgb >> 5) & 0x070707);
}

- (UInt32)toColorFromRGBA555:(UInt16) color {
    // [A0 R4 R3 R2 R1 R0 G4 G3] | [G2 G1 G0 B4 B3 B2 B1 B0]
    
    UInt32 a = color & 0b0000000000000001;
    UInt32 r = color & 0b1111100000000000;
    UInt32 g = color & 0b0000011111000000;
    UInt32 b = color & 0b0000000000111110;
    
    UInt32 rgb = (r >> 8) | (g << 5) | (b << 18);
    // [A7...0 B7...0 G7...0 R7...0]
    return (a * 0xFF000000) | rgb | ((rgb >> 5) & 0x070707);
}

- (UInt32)toColorFromARGB555:(UInt16) color {
    // [A0 R4 R3 R2 R1 R0 G4 G3] | [G2 G1 G0 B4 B3 B2 B1 B0]
    
    UInt32 a = color & 0b1000000000000000;
    UInt32 r = color & 0b0111110000000000;
    UInt32 g = color & 0b0000001111100000;
    UInt32 b = color & 0b0000000000011111;
    
    UInt32 rgb = (r >> 10) | (g << 6) | (b << 19);
    // [A7...0 B7...0 G7...0 R7...0]
    return (a * 0x1FE00) | rgb | ((rgb >> 5) & 0x070707);
}

- (void)render16KImageDataToScratchData {
    UInt8 *sourceData = (UInt8 *)self.mutableData.bytes + self.offset;
    UInt32 *destinationScratchData = (UInt32 *)self.scratchData.bytes;
    NSUInteger length = (NSUInteger)self.size.width * (NSUInteger)self.size.height;
    NSUInteger blockSize = self.tileWidth * self.tileHeight;
    
    while (length) {
        for (NSUInteger i = 0; i < blockSize; i++) {
            UInt16 channels;
            
            channels = (self.bigEndian) ? CFSwapInt16BigToHost(*((UInt16 *)sourceData)) : CFSwapInt16LittleToHost(*((UInt16 *)sourceData));
            if (self.pixelFormat == ImagePixelFormatRGB555) *destinationScratchData = [self toColorFromRGB555:channels];
            if (self.pixelFormat == ImagePixelFormatRGB565) *destinationScratchData = [self toColorFromRGB565:channels];
            if (self.pixelFormat == ImagePixelFormatRGBA555) *destinationScratchData = [self toColorFromRGBA555:channels];
            if (self.pixelFormat == ImagePixelFormatARGB555) *destinationScratchData = [self toColorFromARGB555:channels];
            
            if (self.alphaPlane == YES) {
                *destinationScratchData |= 0xFF000000;
            }
            
            destinationScratchData += 1;
            sourceData += 2;
        }
        sourceData += self.padding;
        length -= blockSize;
    }
}




- (void)packed24Bit {
    UInt8 *src = (UInt8 *)self.mutableData.bytes + self.offset;
    UInt32 *dst = (UInt32 *)self.scratchData.bytes;
    NSUInteger length = (NSUInteger)self.size.width * (NSUInteger)self.size.height;
    NSUInteger blockSize = self.tileWidth * self.tileHeight;
  
    while (length) {
        for (NSUInteger i = 0; i < blockSize; i++) {
            TriColor *triColor = (TriColor *)src;
            *dst++ = (UInt32)triColor->redChannel | (UInt32)triColor->greenChannel << 8 | (UInt32)triColor->blueChannel << 16 | 0xFF000000;
            src += 3;
        }
        src += self.padding;
        length -= blockSize;
    }
}


- (void)packed32Bit {
    UInt8 *src = (UInt8 *)self.mutableData.bytes + self.offset;
    UInt32 *dst = (UInt32 *)self.scratchData.bytes;
    NSUInteger length = (NSUInteger)self.size.width * (NSUInteger)self.size.height;
    NSUInteger blockSize = self.tileWidth * self.tileHeight;
    
    while (length) {
        for (NSUInteger i = 0; i < blockSize; i++) {
            *dst++ = *(UInt32 *)src;
            src += 4;
        }
        src += self.padding;
        length -= blockSize;
    }
}

     /*
- (void)planer8Bit {
    UInt8 *src = (UInt8 *)self.mutableData.bytes + self.offset;
    UInt32 *dst = (UInt32 *)self.scratchData.bytes;
    NSUInteger length = (NSUInteger)self.size.width * (NSUInteger)self.size.height;
    NSUInteger blockSize = self.tileWidth / 4 * self.tileHeight;
    
    
    while (length) {
        for (NSUInteger i = 0; i < blockSize; i++) {
            if (self.alphaPlane == YES) {
                UInt8 plane = *src++;
                UInt8 mask = 1 << 7;
                for (int n = 0; n < 8; n++) {
                    if (plane & mask) {
                        dst[n] = 0;
                    } else {
                        dst[n] = 0xFF000000;
                    }
                    
                    mask >>= 1;
                }
            }
            
            UInt8 mask = 1 << 7;
            for (int n = 0; n < 8; n++) {
                UInt32 i = 0;
                for (UInt32 p = 0; p < self.planeCount; p++) {
                    if (src[p] & mask) {
                        i |= (1 << p);
                    }
                }
                dst[n] = self.planeCount > 1 ? [self.palette rgbColorAtIndex:i] : (0xFFFFFF * i) | 0xFF000000;
                mask >>= 1;
            }
            dst += 8;
            src += self.planeCount;
        }
        src += self.padding;
        length -= blockSize;
    }
}
*/
- (void)planer8BitToPixelData:(void *)pixelData {
        UInt32 *pixel = pixelData;
        const unsigned char *bytes = self.mutableData.bytes + self.offset;
        
        NSUInteger s = self.mutableTexture.size.width;
        NSUInteger l = self.mutableTexture.size.height;
        
        NSUInteger w = self.size.width;
        NSUInteger h = self.size.height;
        
        NSUInteger step_c = self.bitsPerPixel;
        
        if (self.tileWidth > 1) {
            step_c =  self.bitsPerPixel * (self.tileWidth / self.bitsPerPixel);
        }
        
        for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; r+=self.tileHeight) {
            for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; c+=step_c) {
                
                for (NSUInteger y = 0; y < self.tileHeight; y++) {
                    for (NSUInteger x = 0; x < self.tileWidth; x+=self.bitsPerPixel) {
                
                        UInt8 *planeData = (UInt8 *)bytes;
                        
                        if (self.alphaPlane == YES) {
                            for (int n = self.bitsPerPixel - 1; n >= 0; n--) {
                                UInt8 plane = *planeData;
                                
                                if (plane & (1 << n)) {
                                    pixel[(r + y) * s + c + x + self.bitsPerPixel - 1 - n] = 0;
                                } else {
                                    pixel[(r + y) * s + c + x + self.bitsPerPixel - 1 - n] = 0xFF000000;
                                }
                            }
                            bytes += self.bitsPerPixel / 8;
                        }
                        
                        for (int n = self.bitsPerPixel - 1; n >= 0; n--) {
                            int colorIndex = 0;
                            
                            for (int p=0; p<(int)self.planeCount; p++) {
                                UInt8 plane = planeData[p];
   
                                if (plane & (1 << n)) {
                                    colorIndex |= (1 << p);
                                }
                            }
                            UInt32 color = [self.palette rgbColorAtIndex:colorIndex];
                            if (self.alphaPlane == YES && colorIndex == 0) {
                                color &= 0x00FFFFFF;
                            }
                            pixel[(r + y) * s + c + x + self.bitsPerPixel - 1 - n] = self.planeCount > 1 ? color : (0xFFFFFF * colorIndex) | 0xFF000000;
                        }
                        
                        bytes += self.bitsPerPixel / 8 * self.planeCount;
                    }
                }
                bytes += self.padding;
            }
        }

}

- (void)planer16BitToPixelData:(void *)pixelData {
    UInt32 *pixel = pixelData;
    const unsigned char *bytes = self.mutableData.bytes + self.offset;
    
    NSUInteger s = self.mutableTexture.size.width;
    NSUInteger l = self.mutableTexture.size.height;
    
    NSUInteger w = self.size.width;
    NSUInteger h = self.size.height;
    
    NSUInteger step_c = self.bitsPerPixel;
    
    if (self.tileWidth > 1) {
        step_c =  self.bitsPerPixel * (self.tileWidth / self.bitsPerPixel);
    }
    
    for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; r+=self.tileHeight) {
        for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; c+=step_c) {
            
            for (NSUInteger y = 0; y < self.tileHeight; y++) {
                for (NSUInteger x = 0; x < self.tileWidth; x+=self.bitsPerPixel) {
            
                    UInt16 *planeData = (UInt16 *)bytes;
                    
                    if (self.alphaPlane == YES) {
                        for (int n = self.bitsPerPixel - 1; n >= 0; n--) {
                            //UInt16 plane = *planeData;
                            
                            UInt16 plane = (self.bigEndian) ? CFSwapInt16BigToHost(*planeData) : CFSwapInt16LittleToHost(*planeData);
                            
//#ifdef __LITTLE_ENDIAN__
//                            plane = CFSwapInt16BigToHost(plane);
//#endif
                            if (plane & (1 << n)) {
                                pixel[(r + y) * s + c + x + self.bitsPerPixel - 1 - n] = 0;
                            } else {
                                pixel[(r + y) * s + c + x + self.bitsPerPixel - 1 - n] = 0xFF000000;
                            }
                        }
                        bytes += self.bitsPerPixel / 8;
                    }
                    
                    for (int n = self.bitsPerPixel - 1; n >= 0; n--) {
                        int colorIndex = 0;
                        
                        for (int p=0; p<(int)self.planeCount; p++) {
                            //UInt16 plane = planeData[p];
                            UInt16 plane = (self.bigEndian) ? CFSwapInt16BigToHost(planeData[p]) : CFSwapInt16LittleToHost(planeData[p]);
//#ifdef __LITTLE_ENDIAN__
//                            plane = CFSwapInt16BigToHost(plane);
//#endif
                            if (plane & (1 << n)) {
                                colorIndex |= (1 << p);
                            }
                        }
                        UInt32 color = [self.palette rgbColorAtIndex:colorIndex];
                        if (self.alphaPlane == YES && colorIndex == 0) {
                            color &= 0x00FFFFFF;
                        }
                        pixel[(r + y) * s + c + x + self.bitsPerPixel - 1 - n] = self.planeCount > 1 ? color : (0xFFFFFF * colorIndex) | 0xFF000000;
                    }
                    
                    bytes += self.bitsPerPixel / 8 * self.planeCount;
                }
            }
            bytes += self.padding;
        }
    }

}

- (void)mask16BitToPixelData:(void *)pixelData {
    UInt32 *pixel = pixelData;
    const unsigned char *bytes = self.mutableData.bytes + self.offset;
    
    NSUInteger s = self.mutableTexture.size.width;
    NSUInteger l = self.mutableTexture.size.height;
    
    NSUInteger w = self.size.width;
    NSUInteger h = self.size.height / 2;
    
    for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; ++r) {
        for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; ++c) {
            UInt16 *planeData = (UInt16 *)bytes;
            
            for (int n=(int)self.bitsPerPixel - 1; n >= 0; n--) {
                int colorIndex = 0;
                
                for (int p=0; p<(int)self.planeCount; p++) {
                    UInt16 plane = (self.bigEndian) ? CFSwapInt16BigToHost(planeData[p]) : CFSwapInt16LittleToHost(planeData[p]);
//                    UInt16 plane = planeData[p];
//#ifdef __LITTLE_ENDIAN__
//                    plane = CFSwapInt16BigToHost(plane);
//#endif
                    if (plane & (1 << n)) {
                        colorIndex |= (1 << p);
                    }
                }
                UInt32 color = [self.palette rgbColorAtIndex:colorIndex];
                if (self.alphaPlane == YES && colorIndex == 0) {
                    color &= 0x00FFFFFF;
                }
                pixel[(r - h / 2) * s + c + self.bitsPerPixel - 1 - n] = self.planeCount > 1 ? color : (0xFFFFFF * colorIndex) | 0xFF000000;
            }
            
            c += self.bitsPerPixel - 1;
            bytes += self.bitsPerPixel / 8 * self.planeCount;
        }
    }
    
    for (NSUInteger r = (l - h) / 2; r < l - (l - h) / 2; ++r) {
        for (NSUInteger c = (s - w) / 2; c < s - (s - w) / 2; ++c) {
            
            for (int n=(int)self.bitsPerPixel - 1; n >= 0; n--) {
                int colorIndex = 0;
                UInt16 *planeData = (UInt16 *)bytes;
                UInt16 plane = (self.bigEndian) ? CFSwapInt16BigToHost(*planeData) : CFSwapInt16LittleToHost(*planeData);
//                UInt16 plane = *planeData;
//#ifdef __LITTLE_ENDIAN__
//                plane = CFSwapInt16BigToHost(plane);
//#endif
                if (plane & (1 << n)) {
                    colorIndex |= 15;
                }
                
                UInt32 color = [self.palette rgbColorAtIndex:colorIndex];
                pixel[(r + h / 2) * s + c + self.bitsPerPixel - 1 - n] = self.planeCount > 1 ? color : (0xFFFFFF * colorIndex) | 0xFF000000;
            }
            
            c += self.bitsPerPixel - 1;
            bytes += 2;
        }
    }
}

- (NSInteger)deltaWidth {
    if (self.tileWidth > 1) {
        return self.tileWidth;
    }
    
    if (self.planeCount > 1) {
        return self.bitsPerPixel;
    }
    
    if (self.bitsPerPixel <= 8) {
        return 8 / self.bitsPerPixel;
    }
    
    return 1;
}

// MARK: - Private Methods

- (BOOL)isValidSize:(CGSize)size {
    if (self.bytesPerLine * (NSInteger)size.height > self.mutableData.length) {
        return NO;
    }
    return YES;
}




// MARK: - Public Class Methods

/*
+ (CGImageRef)createCGImageFromPixelData:(const void *)pixelData ofSize:(CGSize)size {
    static const size_t kComponentsPerPixel = 4;
    static const size_t kBitsPerComponent = sizeof(unsigned char) * 8;
    
    NSInteger layerWidth = size.width;
    NSInteger layerHeight = size.height;
    
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    size_t bufferLength = layerWidth * layerHeight * kComponentsPerPixel;
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pixelData, bufferLength, NULL);
    CGImageRef imageRef = CGImageCreate(layerWidth, layerHeight, kBitsPerComponent,
                                        kBitsPerComponent * kComponentsPerPixel,
                                        kComponentsPerPixel * layerWidth,
                                        rgb,
                                        kCGBitmapByteOrderDefault | kCGImageAlphaLast,
                                        provider, NULL, false,kCGRenderingIntentDefault);
    

    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgb);
    
    return imageRef;
}

+ (BOOL)writeCGImage:(CGImageRef)image to:(NSURL *)destinationURL __attribute__((warn_unused_result)) {
    
    if (image == nil) {
        return NO;
    }
    CFURLRef cfurl = (__bridge CFURLRef)destinationURL;
    CGImageDestinationRef destinationRef;
    
    if (@available(macOS 12, *)) {
        destinationRef = CGImageDestinationCreateWithURL(cfurl, kUTTypePNG, 1, nil);
    } else {
        destinationRef = CGImageDestinationCreateWithURL(cfurl, kUTTypePNG, 1, nil);
    }
    CGImageDestinationAddImage(destinationRef, image, nil);
    return CGImageDestinationFinalize(destinationRef);
}

    */

// MARK: - Public Setters

- (void)setBigEndian:(BOOL)bigEndian {
    _bigEndian = bigEndian;
    self.changes = YES;
}

- (void)setPixelFormat:(ImagePixelFormat)pixelFormat {
    _pixelFormat = pixelFormat;
    self.changes = YES;
}

- (void)setScale:(CGFloat)scale {
    self.xScale = scale;
    self.yScale = scale;
    _zoom = (NSUInteger)self.xScale;
    self.changes = YES;
}

- (void)setBitsPerPixel:(UInt32)bitsPerPixel {
    _bitsPerPixel = bitsPerPixel > 0 ? bitsPerPixel : 1;
    if (self.planeCount > 1) {
        _bitsPerPixel = _bitsPerPixel > 7 ? _bitsPerPixel & 0xF8 : 8;
    } else {
        if (bitsPerPixel == 16 && (self.tileWidth == 8 || self.tileWidth == 24)) {
            [self setTileWidth:1];
        }
    }
    [self setSize:self.size];
    self.changes = YES;
}

- (void)setPlaneCount:(UInt32)planeCount {
    if (planeCount >= 1 || planeCount <= 5) {
        _planeCount = planeCount;
        
        if (planeCount == 1) self.alphaPlane = NO;
        if (planeCount > 1 && self.bitsPerPixel == 16 && (self.tileWidth == 8 || self.tileWidth == 24)) {
            [self setTileWidth:16];
        }
        [self setSize:self.size];
        self.changes = YES;
    }
}

- (void)setAlphaPlane:(BOOL)state {
    _alphaPlane = state;
    if (_alphaPlane == YES) {
        _maskPlane = NO;
    }
    [self setSize:self.size];
    self.changes = YES;
}

- (void)setMaskPlane:(BOOL)state {
    _maskPlane = state;
    if (_maskPlane == YES) {
        _alphaPlane = NO;
    }
    [self setSize:self.size];
    self.changes = YES;
}

- (void)setTileWithWidthOf:(NSUInteger)width andHightOf:(NSUInteger)height  {
    
    self.changes = YES;
    if (width == 0 || height == 0) {
        _tileWidth = 1;
        _tileHeight = 1;
        return;
    }
    
    _tileWidth = width;
    _tileHeight = height;
    
    if (self.tileWidth == 1 && self.tileHeight > 1) _tileWidth = _tileHeight;
    if (self.tileWidth > 1 && self.tileHeight == 1) _tileHeight = self.tileWidth;
    
    [self setSize:CGSizeMake((NSUInteger)self.size.width / width * width, (NSUInteger)self.size.height / height * height)];
}

- (void)setSize:(CGSize)size {
    if (size.width > 800 || size.height > 600) return;
    
    if ([self isValidSize:size] == NO) {
        
        for (CGFloat width = size.width; width > 1; width --) {
            _size.width = width;
            for (CGFloat height = size.height; height > 1; height --) {
                _size.height = height;
                if (self.bytesPerLine * (NSInteger)height <= self.mutableData.length) return;
            }
        }
    }
    
    [self.mutableTexture modifyPixelDataWithBlock:^(void *pixelData, size_t lengthInBytes) {
        memset(pixelData, 0, lengthInBytes);
    }];
    
    
    _size = size;
    
    if (self.bitsPerPixel == 0) return;
    
    if (self.size.height < 8.0) {
        _size.height = 8.0;
    }
    if (self.size.height > self.mutableTexture.size.height) {
        _size.height = self.mutableTexture.size.height;
    }
    
    if (self.planeCount == 1) {
        if (self.bitsPerPixel <= 8) {
            NSUInteger w = (NSUInteger)size.width;
            w /= (8 / self.bitsPerPixel);
            w *= (8 / self.bitsPerPixel);
            if (w == 0) {
                w = 8 / self.bitsPerPixel;
            }
            _size.width = (CGFloat)w;
        } else {
            if (size.width < 1.0) {
                _size.width = 1;
            }
        }
    } else {
        NSUInteger w = (NSUInteger)size.width;
        w /= self.bitsPerPixel;
        w *= self.bitsPerPixel;
        if (w == 0) {
            w = self.bitsPerPixel;
        }
        _size.width = (CGFloat)w;
    }
    
    self.changes = YES;
}

- (void)setDataLength:(NSUInteger)length {
    self.mutableData.length = length;
}

- (void)setAspectRatio:(CGFloat)aspectRatio {
    _aspectRatio = aspectRatio;
    self.xScale = self.yScale * self.aspectRatio;
    self.changes = YES;
}

- (void)setPadding:(NSInteger)bytes {
    _padding = bytes;
    self.changes = YES;
}

- (void)setOffset:(NSInteger)offset {
    self.changes = YES;
    _offset = offset;
    
    if (_offset < 0) {
        _offset = 0;
        return;
    }
    
    if (_offset > self.mutableData.length - (NSInteger)self.size.height * [self bytesPerLine]) {
        _offset = (NSInteger)(self.mutableData.length - (NSInteger)self.size.height * [self bytesPerLine]);
    }
}

// MARK: - Public Getters

-(NSUInteger)selected {
    return (NSUInteger)[self bytesPerLine] * (NSUInteger)self.size.height;
}

-(NSUInteger)bytes {
    return self.mutableData.length;
}

-(NSInteger)bytesPerLine {
    NSInteger n = 0;
    NSInteger width = (NSInteger)self.size.width;
    
    if (self.bitsPerPixel < 1) _bitsPerPixel = 8;
    
    if ([self isPlaner]) {
        // bitsPerPixel is regarded as bitsPerPlane in Planer Mode.
        n = self.bitsPerPixel / 8 * self.planeCount;
        if (self.alphaPlane) {
            n += self.bitsPerPixel / 8;
        }
        n *= (width / self.bitsPerPixel);
    }
    
    if ([self isPacked]) {
        n = self.bitsPerPixel * width / 8;
    }
    
    return n;
}

// MARK: - Private Class Methods

-(BOOL)isPlaner {
    return self.planeCount > 1 ? YES : NO;
}

-(BOOL)isPacked {
    return self.planeCount <= 1 ? YES : NO;
}



@end


