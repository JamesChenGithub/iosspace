//
//  XTHWDecoder.m
//  VideoToolBoxSample
//
//  Created by 陈耀武 on 2020/8/3.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "XTHWDecoder.h"

@interface XTHWDecoder () {
    VTDecompressionSessionRef       _decoderSession;
    CMVideoFormatDescriptionRef     _decodeFormatDesc;

    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
}
@end

@implementation XTHWDecoder

static void didDecompress(void * CM_NULLABLE decompressionOutputRefCon, void * CM_NULLABLE sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CM_NULLABLE CVImageBufferRef imageBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ) {
    XTHWDecoder *decoder = (__bridge XTHWDecoder *)decompressionOutputRefCon;
    if (decoder.delegate && [decoder.delegate respondsToSelector:@selector(gotDecodedFrame:)]) {
        CVPixelBufferRef *outputPixBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
        
        *outputPixBuffer = CVPixelBufferRetain(imageBuffer);
        [decoder.delegate gotDecodedFrame:imageBuffer];
    }
    
    
}

- (BOOL)initXTHWDecoder {
    if (_decoderSession) {
        return YES;
    }

    const uint8_t *const parameterSetPointers[2] = {_sps, _pps};
    const size_t parameterSetSizes[2] = {_spsSize, _ppsSize};
    
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPointers, parameterSetSizes, 4, &_decodeFormatDesc);
    if (status == noErr) {
        // 硬解必须是 kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        // 或者是kCVPixelFormatType_420YpCbCr8Planar
        // 因为iOS是  nv12  其他是nv21
        NSDictionary *destPixelBufAttr =  @{
            (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
            (id)kCVPixelBufferWidthKey:@(480),
            (id)kCVPixelBufferHeightKey:@(640),
            (id)kCVPixelBufferOpenGLCompatibilityKey:@(YES)
        };
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
        callBackRecord.decompressionOutputCallback = didDecompress;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault, _decodeFormatDesc, NULL, (__bridge CFDictionaryRef)destPixelBufAttr, &callBackRecord, &_decoderSession);
        if (status == noErr) {
            NSLog(@"VTDecompressionSessionCreate status=%d", status);
            return NO;
        } else {
            VTSessionSetProperty(_decoderSession, kVTDecompressionPropertyKey_ThreadCount, (__bridge CFTypeRef)[NSNumber numberWithInt:1]);
            VTSessionSetProperty(_decoderSession, kVTDecompressionPropertyKey_ThreadCount, kCFBooleanTrue);
            return YES;
        }
    } else {
        NSLog(@"CMVideoFormatDescriptionCreateFromH264ParameterSets status=%d", status);
        return NO;
    }
    
    
    return YES;
}

- (void)decodeNalu:(uint8_t *)frame size:(uint32_t)frameSize {
    int nalu_type = frame[4] &0x1F;
    CVPixelBufferRef pixelBuffer = NULL;
    
    uint32_t nalSize = frameSize - 4;
    uint8_t *pNalSize = (uint8_t *)(&nalSize);
    frame[0] =  *(pNalSize + 3);
    frame[1] =  *(pNalSize + 2);
    frame[2] =  *(pNalSize + 1);
    frame[3] =  *(pNalSize + 0);
    
    switch (nalu_type) {
        case 0x05:
            if ([self initXTHWDecoder]) {
                pixelBuffer = [self decode:frame size:frameSize];
            }
            break;
        case 0x07:
            _spsSize = frameSize - 4;
            _sps = malloc(_spsSize);
            memcpy(_sps, &frame[4], _spsSize);
            break;
        case 0x08:
            _ppsSize = frameSize - 4;
            _pps = malloc(_ppsSize);
            memcpy(_pps, &frame[4], _ppsSize);
        default:
            if ([self initXTHWDecoder]) {
                pixelBuffer = [self decode:frame size:frameSize];
            }
            break;
    }
    
    
}

- (CVPixelBufferRef)decode:(uint8_t *)frame size:(uint32_t)frameSize {
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(NULL, (void *)frame, frameSize, kCFAllocatorNull, NULL, 0, frameSize, FALSE, &blockBuffer);
    
    if (status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuf = NULL;
        const size_t sampleSizeArray[] = {frameSize};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, _decodeFormatDesc, 1, 0, NULL, 1, sampleSizeArray, &sampleBuf);
        if (status == kCMBlockBufferNoErr && sampleBuf) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagout = 0;
            
            OSStatus decodeStatus = decodeStatus = VTDecompressionSessionDecodeFrame(_decoderSession, sampleBuf, flags, &outputPixelBuffer, &flagout);
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
            }
            CFRelease(sampleBuf);
        }
         CFRelease(blockBuffer);
    }
    return outputPixelBuffer;
}

- (void)endDecode {
    if (_decoderSession) {
        VTDecompressionSessionInvalidate(_decoderSession);
        CFRelease(_decoderSession);
        _decoderSession = NULL;
    }
    
    if (_decodeFormatDesc) {
        CFRelease(_decodeFormatDesc);
        _decodeFormatDesc = NULL;
    }
    if (_sps) {
        free(_sps);
        _sps = NULL;
    }
    
    if (_pps) {
        free(_pps);
        _pps = NULL;
    }
}


@end
