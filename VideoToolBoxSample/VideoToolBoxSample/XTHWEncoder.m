//
//  XTHWEncoder.m
//  VideoToolBoxSample
//
//  Created by 陈耀武 on 2020/8/3.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "XTHWEncoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface XTHWEncoder () {
    uint64_t  _frameNo; // 帧号
    dispatch_queue_t _encodeQueue;
    VTCompressionSessionRef _encodeSession;
}

@end

@implementation XTHWEncoder

- (instancetype)init {
    if (self = [super init]) {
        _frameNo = 0;
        _encodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer) {
    
    NSLog(@"didCompressH264 called with status %d infoFlags %d", (int)status, (int)infoFlags);
    if (status != 0) {
        return;
    }
    
    XTHWEncoder *encode = (__bridge XTHWEncoder *)outputCallbackRefCon;
    CFArrayRef arrRef = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    bool keyFrame = !CFDictionaryContainsKey(CFArrayGetValueAtIndex(arrRef, 0), kCMSampleAttachmentKey_NotSync);
    
    // 判断当前帧是否为关键帧
    // 获取sps & pps数据
    if (keyFrame) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, NULL);
        if (status == noErr) {
             // 获得了sps，再获取pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, NULL);
            if (status == noErr) {
                // 获取SPS和PPS data
                NSData *sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                NSLog(@"%@", sps);
                NSLog(@"%@", pps);
                if (encode.delegate && [encode.delegate respondsToSelector:@selector(gotSpsPps:pps:)]) {
                    [encode.delegate gotSpsPps:sps pps:pps];
                }
            }
        }
    }
    
    CMBlockBufferRef dataRef = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length , totalLength;
    
    char *dataPointer;
    
    OSStatus statusCode = CMBlockBufferGetDataPointer(dataRef, 0, &length, &totalLength, &dataPointer);
    
    if (statusCode == noErr) {
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4; //返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            uint32_t NALUnitLength = 0;
            
            memcpy(&NALUnitLength, dataPointer+bufferOffset, AVCCHeaderLength);
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            
            if (encode.delegate && [encode.delegate respondsToSelector:@selector(gotEncodedData:isKeyFrame:)]) {
                NSData *data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
                [encode.delegate gotEncodedData:data isKeyFrame:YES];
            }
            
            // 移动到下一个NALU单元
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
        
    }
    
}

- (void)startEncoder:(int32_t)width height:(int32_t)height {
    
    __weak typeof(self) ws = self;
    dispatch_async(_encodeQueue, ^{
        __strong typeof(ws) self = ws;
        if (self == nil) {
            return;
        }
        OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void *)self, &self->_encodeSession);
        
        if (status) {
            NSLog(@"H264 VTCompressionSessionCreate failed : %d", status);
            return;
        }
        
        status = VTSessionSetProperty(self->_encodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        NSLog(@"H264 VTSessionSetProperty kVTCompressionPropertyKey_RealTime : %d", status);
        VTSessionSetProperty(self->_encodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
        NSLog(@"H264 VTSessionSetProperty kVTCompressionPropertyKey_ProfileLevel : %d", status);
        
        int32_t frameInterval = 24;
        CFNumberRef frameIntervalRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
        VTSessionSetProperty(self->_encodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, frameIntervalRef);
        
        int32_t fps = 24;
        CFNumberRef fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fpsRef);
        VTSessionSetProperty(self->_encodeSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
        
        int bitRate = width * height * 3 * 4 * 8;
        CFNumberRef bitrateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
        VTSessionSetProperty(self->_encodeSession, kVTCompressionPropertyKey_AverageBitRate, bitrateRef);
        
        int bitRateLimit = width * height * 3 * 4;
        CFNumberRef bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRateLimit);
        VTSessionSetProperty(self->_encodeSession, kVTCompressionPropertyKey_DataRateLimits, bitRateLimitRef);
        
        VTCompressionSessionPrepareToEncodeFrames(self->_encodeSession);
    });
}


- (void)encode:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imgBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CMTime pts = CMTimeMake(_frameNo++, 1000);
    
    VTEncodeInfoFlags flags;
    OSStatus status = VTCompressionSessionEncodeFrame(_encodeSession, imgBuffer, pts, kCMTimeInvalid, NULL, NULL, &flags);
    
    NSLog(@"H264: VTCompressionSessionEncodeFrame status : %d", (int)status);
    if (status != noErr) {
        
        if (_encodeSession) {
            VTCompressionSessionInvalidate(_encodeSession);
            CFRelease(_encodeSession);
            _encodeSession = NULL;
        }
    }
}

- (void)stopEncode {
    if (_encodeSession) {
        VTCompressionSessionCompleteFrames(_encodeSession, kCMTimeInvalid);
        VTCompressionSessionInvalidate(_encodeSession);
        CFRelease(_encodeSession);
        _encodeSession = NULL;
        _frameNo = 0;
    }
}
@end
