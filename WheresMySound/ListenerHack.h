//
//  ListenerHack.h
//  WheresMySound
//
//  Created by Marco Barisione on 11/09/2017.
//  Copyright © 2017 Marco Barisione. All rights reserved.
//

#ifndef ListenerHack_h
#define ListenerHack_h

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Wraps a Swift AudioObjectPropertyListenerBlock.
 *
 * When removing a listener using the CoreAudio API, you need to pass the same block which was passed when adding the
 * listener.
 * Unfortunately, when Swift passes the closure, it generates a different block pointer every time so the removal will
 * always have no effect.
 *
 * This class wraps a Swift block which can be later added/removed as property listener. Being held in an Objective-C
 * property, the value won't actually change.
 */
@interface HackAudioBlock : NSObject

+ (instancetype)new __attribute__((unavailable("new not available")));
- (instancetype)init __attribute__((unavailable("init not available")));

- (instancetype)initWithBlock:(AudioObjectPropertyListenerBlock)block;

@end

OSStatus
hackAudioObjectAddPropertyListenerBlock(AudioObjectID deviceID,
                                        const AudioObjectPropertyAddress *address,
                                        dispatch_queue_t __nullable queue,
                                        HackAudioBlock *listener);

OSStatus
hackAudioObjectRemovePropertyListenerBlock(AudioObjectID deviceID,
                                           const AudioObjectPropertyAddress *address,
                                           dispatch_queue_t __nullable queue,
                                           HackAudioBlock *listener);

NS_ASSUME_NONNULL_END

#endif /* ListenerHack_h */
