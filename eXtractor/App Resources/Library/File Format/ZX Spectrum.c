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

#include "ZX Spectrum.h"

bool isZXSpectrumFormat(const void *rawData, long unsigned int length) {
    if (length != 6912) { /// A ZX Spectrum Screen file will always be exacly 6912 bytes in length.
        return false;
    }
    
    return true;
}

void convertZXSpectrumScreenToIndexedColor(const void *rawData) {
    uint8_t *pixelData = (uint8_t *)rawData;
    uint8_t buf[49152];
    
    //memcpy(ulaPixelData, dest, 6912);
    
    for (int r = 0; r < 192; ++r)
    {
        
        /*
         
         Video data...
         
         Pixels :- address is 010S SRRR CCCX XXXX
         Attrs  :- address is 0101 10YY YYYX XXXX
         
         S = Section (0-2)
         C = Cell row within section (0-7)
         R = Pixel row within cell (0-7)
         X = X coord (0-31)
         Y = Y coord (0-23)
         
         ROW = SSCC CRRR
         = YYYY Y000
         
         */
        
        uint16_t p = ((r & 0x0c0) << 5) + ((r & 0x7) << 8) + ((r & 0x38) << 2);
        uint16_t a = 6144 + ((r & 0xf8) << 2);
        
        uint16_t ink,paper;
        
        for (int c = 0; c < 256; c+=8)
        {
            uint8_t data = pixelData[p++];
            uint8_t attr = pixelData[a++];
            
            if (attr & 0b01000000) {
                ink = attr & 0b00000111 + 8;
                paper = ((attr & 0b00111000) >> 3) + 8;
            } else {
                ink = attr & 0b00000111;
                paper = (attr & 0b00111000) >> 3;
            }
            
            for (int i = 0; i < 8; ++i) {
                buf[c + r * 256 + i] = (data & (0x80 >> i)) ? ink : paper;
            }
            
        }
    }
    
    memcpy(pixelData, buf, sizeof(buf));
}





