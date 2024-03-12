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

#include "Degas.h"

bool isDegasFormat(const void *rawData, long unsigned int length) {
    if (length != 32034) { /// A Degas file will always be exacly 32,034 bytes in length.
        if (length != 32066) { /// DEGAS Elite file will always be exacly 32,066 bytes in length.
            return false;
        } else {
            // DEGAS Elite
            // TODO: Palette Animation...
        }
    }
    
    const Degas *degas_ref = (Degas *)rawData;
    if ((swapInt16BigToHost(degas_ref->resolution) & 3) > 2) return false;
 
    return true;
}

// PackBits Compression Algorithm
void unpackBits(void *dst, const void *pck, size_t n) {
    char *p = (char  *)pck;
    char *o = dst;
    
    int i = 0;
    
    while (i < n) {
        int k = p[i];
        if (k >= 128) {
            k = 256 - k;
            for (int j = 0; j <= k; ++j) {
                *o++ = p[i+1];
            }
            i++;
        } else {
            int j;
            for (j = 0; j <= k; ++j) {
                *o++ = p[i+j+1];
            }
            i += j;
        }
        i++;
    }
}




