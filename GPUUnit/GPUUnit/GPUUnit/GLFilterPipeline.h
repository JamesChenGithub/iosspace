//
//  GLFilterPipeline.h
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/28.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLOutput.h"

@interface GLFilterPipeline : NSObject
{
    NSString *_stringValue;
}

@property (nonatomic, strong) NSMutableArray *filters;

@property (nonatomic, strong) GLOutput *input;
@property (nonatomic, strong) id<GLInput> output;

- (id) initWithOrderedFilters:(NSArray*) filters input:(GLOutput *)input output:(id <GLInput>)output;
- (id) initWithConfiguration:(NSDictionary*) configuration input:(GLOutput*)input output:(id <GLInput>)output;
- (id) initWithConfigurationFile:(NSURL*) configuration input:(GLOutput*)input output:(id <GLInput>)output;

- (void) addFilter:(GLOutput<GLInput> *)filter;
- (void) addFilter:(GLOutput<GLInput> *)filter atIndex:(NSUInteger)insertIndex;
- (void) replaceFilterAtIndex:(NSUInteger)index withFilter:(GLOutput<GLInput> *)filter;
- (void) replaceAllFilters:(NSArray *) newFilters;
- (void) removeFilter:(GLOutput<GLInput> *)filter;
- (void) removeFilterAtIndex:(NSUInteger)index;
- (void) removeAllFilters;

- (UIImage *) currentFilteredFrame;
- (UIImage *) currentFilteredFrameWithOrientation:(UIImageOrientation)imageOrientation;
- (CGImageRef) newCGImageFromCurrentFilteredFrame;

@end

