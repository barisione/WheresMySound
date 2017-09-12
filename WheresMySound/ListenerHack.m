//
//  ListenerHack.m
//  WheresMySound
//
//  Created by Marco Barisione on 11/09/2017.
//  Copyright © 2017 Marco Barisione. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ListenerHack.h"

@interface HackAudioBlock ()

@property (nonatomic, readonly, strong) AudioObjectPropertyListenerBlock block;

@end

@implementation HackAudioBlock

- (instancetype)initWithBlock:(AudioObjectPropertyListenerBlock)block {
    self = [super init];
    if (self) {
        self->_block = block;
    }

    return self;
}

@end


OSStatus  hackAudioObjectAddPropertyListenerBlock(AudioObjectID deviceID,
                                                  const AudioObjectPropertyAddress *address,
                                                  dispatch_queue_t __nullable queue,
                                                  HackAudioBlock *listener) {
    return AudioObjectAddPropertyListenerBlock(deviceID,
                                               address,
                                               queue,
                                               listener.block);
}

OSStatus hackAudioObjectRemovePropertyListenerBlock(AudioObjectID deviceID,
                                                    const AudioObjectPropertyAddress *address,
                                                    dispatch_queue_t __nullable queue,
                                                    HackAudioBlock *listener) {
    return AudioObjectRemovePropertyListenerBlock(deviceID,
                                                  address,
                                                  queue,
                                                  listener.block);
}
