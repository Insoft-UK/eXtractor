/*
Copyright © 2007-2021 Insoft. All rights reserved.

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

#ifndef endian_h
#define endian_h

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
   /*
    For checking if little-endian format is used by host.
    
    Return Value
    If the little-endian format is used then 1 will be returned else 0 will be returned for big-endian.
    */
   int littleEndian(void);
   
   /*
    For checking if big-endian format is used by host.
    
    Return Value
    If the big-endian format is used then 1 will be returned else 0 will be returned for little-endian.
    */
   int bigEndian(void);
   
   /*
    For checking what endian format is used by platform.
    
    Return Value
    If the little-endian format is used then 1 will be returned else 0 will be returned for big-endian.
    */
   int littleEndian(void);

   /*
    Converts a 16-bit integer from big-endian format to the host native byte order.
    
    Parameters
    arg
    The integer whose bytes should be swapped.
    
    Return Value
    The integer with its bytes swapped. If the host is big-endian, this function returns arg unchanged.
    */
   int16_t swapInt16BigToHost(int16_t arg);
   
   /*
    Converts a 16-bit integer from little-endian format to the host native byte order.
    
    Parameters
    arg
    The integer whose bytes should be swapped.
    
    Return Value
    The integer with its bytes swapped. If the host is little-endian, this function returns arg unchanged.
    */
   int16_t swapInt16LittleToHost(int16_t arg);
   
   /*
    Alias to swapInt16BigToHost
    Converts a 16-bit integer from the host native byte order to big-endian format.
    
    Parameters
    arg
    The integer whose bytes should be swapped.
    
    Return Value
    The integer with its bytes swapped. If the host is big-endian, this function returns arg unchanged.
    */
   int16_t swapInt16HostToBig(int16_t arg);
   
   /*
    Alias to swapInt16LittleToHost
    Converts a 16-bit integer from the host native byte order to little-endian format.
    
    Parameters
    arg
    The integer whose bytes should be swapped.
    
    Return Value
    The integer with its bytes swapped. If the host is little-endian, this function returns arg unchanged.
    */
   int16_t swapInt16HostToLittle(int16_t arg);
   
   
   /*
    Converts a 32-bit integer from big-endian format to the host native byte order.
    
    Parameters
    arg
    The integer whose bytes should be swapped.
    
    Return Value
    The integer with its bytes swapped. If the host is big-endian, this function returns arg unchanged.
    */
   int32_t swapInt32BigToHost(int32_t arg);
   
   /*
    Converts a 32-bit integer from little-endian format to the host native byte order.
    
    Parameters
    arg
    The integer whose bytes should be swapped.
    
    Return Value
    The integer with its bytes swapped. If the host is little-endian, this function returns arg unchanged.
    */
   int32_t swapInt32LittleToHost(int32_t arg);
   
   /*
    Alias to swapInt32BigToHost
    Converts a 32-bit integer from the host native byte order to big-endian format.
    
    Parameters
    arg
    The integer whose bytes should be swapped.
    
    Return Value
    The integer with its bytes swapped. If the host is big-endian, this function returns arg unchanged.
    */
   int32_t swapInt32HostToBig(int32_t arg);

   /*
    Converts a 32-bit integer from the host native byte order to little-endian format.
    
    Parameters
    arg
    The integer whose bytes should be swapped.
    
    Return Value
    The integer with its bytes swapped. If the host is little-endian, this function returns arg unchanged.
    */
   int32_t swapInt32HostToLittle(int32_t arg);
#ifdef __cplusplus
}
#endif

#endif /* endian_h */
