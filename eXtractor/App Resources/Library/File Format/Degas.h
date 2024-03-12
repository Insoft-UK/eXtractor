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

#ifndef Degas_h
#define Degas_h

#include "common.h"

#pragma pack(1)     /* set alignment to 1 byte boundary */

typedef struct {
    int16_t resolution;     /*
                             resolution [0 = low res, 1 = medium res, 2 = high res]
                             Other bits may be used in the future; use a simple bit
                             test rather than checking for specific word values.
                             */
    
    int16_t palette[16];
} Degas;

#pragma pack()   /* restore original alignment from stack */


/* Set up for C function definitions, even when using C++ */
#ifdef __cplusplus
extern "C" {
#endif

    bool isDegasFormat(const void *rawData, long unsigned int length);

/* Ends C function definitions when using C++ */
#ifdef __cplusplus
}
#endif

#endif /* Degas_h */
