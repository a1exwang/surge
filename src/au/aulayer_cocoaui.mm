//
//  aulayer_cocoaui.mm
//  surge-au
//
//  Created by Paul Walker on 12/10/18.
//

#include <objc/runtime.h>
#import <CoreFoundation/CoreFoundation.h>
#import <AudioUnit/AUCocoaUIView.h>
#include "aulayer.h"
#include "aulayer_cocoaui.h"


@interface SurgeCocoaUI : NSObject<AUCocoaUIBase>
{
}
@end

@implementation SurgeCocoaUI
- (NSView *) uiViewForAudioUnit: (AudioUnit) inAudioUnit
                       withSize: (NSSize) inPreferredSize
{
    fprintf( stderr, "uiViewForAudioUnit\n" );
    return nil;
}

- (unsigned int)interfaceVersion {
    fprintf( stderr, "interfaceVersion\n" );
    return 0x00010050;
}

@end

static CFBundleRef GetBundleFromExecutable (const char* filepath)
{
    @autoreleasepool {
        NSString* execStr = [NSString stringWithCString:filepath encoding:NSUTF8StringEncoding];
        NSString* macOSStr = [execStr stringByDeletingLastPathComponent];
        NSString* contentsStr = [macOSStr stringByDeletingLastPathComponent];
        NSString* bundleStr = [contentsStr stringByDeletingLastPathComponent];
        return CFBundleCreate (0, (CFURLRef)[NSURL fileURLWithPath:bundleStr isDirectory:YES]);
    }
    
}

ComponentResult aulayer::GetProperty(AudioUnitPropertyID iID, AudioUnitScope iScope, AudioUnitElement iElem, void* outData)
{
    if( iScope == kAudioUnitScope_Global )
    {
        switch( iID )
        {
            case kAudioUnitProperty_CocoaUI:
                // FIXME - this autorelease over-releases so leak a little (we are infrequently called)
                // but definitely come back and fix this!
                //@autoreleasepool
                {
                    auto surgeclass = objc_getClass( "SurgeCocoaUI" );
                    const char* image = class_getImageName ( surgeclass );
                    CFBundleRef bundle = GetBundleFromExecutable (image);
                    CFURLRef url = CFBundleCopyBundleURL (bundle);
                    CFRelease (bundle);

                    
                    AudioUnitCocoaViewInfo* info = static_cast<AudioUnitCocoaViewInfo*> (outData);
                    info->mCocoaAUViewClass[0] = (__bridge CFStringRef)NSStringFromClass( surgeclass );
                    info->mCocoaAUViewBundleLocation = url;

                    return noErr;
                }
        }
    }

    return AUInstrumentBase::GetProperty(iID, iScope, iElem, outData);
}

