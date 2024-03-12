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

#ifndef NEOchrome_h
#define NEOchrome_h

#include "common.h"

#pragma pack(1)     /* set alignment to 1 byte boundary */

typedef struct {
    int16_t flag;              // flag word [always 0]
    int16_t resolution;        // resolution [0 = low res, 1 = medium res, 2 = high res]
    
    int16_t palette[16];
    char filename[12];      // filename [usually "        .   "]
    
    int16_t colorAniLimits;    /*
                             color animation limits.  High bit (bit 15) set if color
                             animation data is valid.  Low byte contains color animation
                             limits (4 most significant bits are left/lower limit,
                             4 least significant bits are right/upper limit).
                             */
    
    int16_t colorAniSpeedDir;  /*
                             color animation speed and direction.  High bit (bit 15) set
                             if animation is on.  Low order byte is # vblanks per step.
                             If negative, scroll is left (decreasing).  Number of vblanks
                             between cycles is |x| - 1
                             */
    
    int16_t numOfColorSteps;   /*
                             # of color steps (as defined in previous word) to display
                             picture before going to the next.  (For use in slide shows)
                             */
    
    int16_t imageXoffset;      // image X offset [unused, always 0]
    int16_t imageYoffset;      // image Y offset [unused, always 0]
    
    int16_t imageWidth;        // image width [unused, always 320]
    int16_t imageHeight;       // image height [unused, always 200]
    
    int16_t _reserved[33];         // reserved for future expansion
    
} NEOchrome;

#pragma pack()   /* restore original alignment from stack */


/* Set up for C function definitions, even when using C++ */
#ifdef __cplusplus
extern "C" {
#endif

    bool isNEOchromeFormat(const void *rawData, long unsigned int length);

/* Ends C function definitions when using C++ */
#ifdef __cplusplus
}
#endif

#endif /* NEOchrome_h */
