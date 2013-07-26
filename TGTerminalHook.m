//
//  TGTerminalHook.m
//  TerminalColorsFromUserHost
//
//  Created by Tom Gidden on 26/07/2013.
//  Copyright (c) 2013 Tom Gidden. All rights reserved.
//

#import "JRSwizzle.h"
#import "TGTerminalHook.h"
#import <objc/objc-class.h>

@implementation NSObject (TGTerminalHook)

BOOL changeColorComponents(float *cr, float *cg, float *cb, float *ca, float r, float g, float b, float a)
{
  BOOL ret = FALSE;
  if(*cr != r) {
    *cr = r;
    ret |= TRUE;
  }
  if(*cg != g) {
    *cg = g;
    ret |= TRUE;
  }
  if(*cb != b) {
    *cb = b;
    ret |= TRUE;
  }
  if(*ca != a) {
    *ca = a;
    ret |= TRUE;
  }
  return ret;
}

-(id)TGTerminalHook_get
{
  // This regular expression is for parsing the window/tab title
  // which should start with username@host , if the recommended
  // shell configuration is set up.  This should be common to all
  // tabs and is thread-safe (apparently), so a static should be okay.
  static NSRegularExpression *regex = NULL;
  
  // Initialise the regexp.
  if(!regex) {
    NSError *error;
    regex = [NSRegularExpression
             regularExpressionWithPattern:@"^(\\w+)@(\\S+)"
             options:NSRegularExpressionCaseInsensitive
             error:&error];
    
    if(error)
      NSLog(@"Error initialising regexp: %@", [error description]);
  }
  
  // If still no regex, then just return the default. Since this is swizzled,
  // the call to (apparently) this method actually calls the original method
  // that we're overriding.
  if(!regex)
    return [self TGTerminalHook_get];
  
  // Get the title of the current tab
  NSString *ntitle = [self valueForKey:@"title"];
  
  // Parse the tab title for the username@host
  NSTextCheckingResult *res = [regex firstMatchInString:ntitle
                                                options:NSMatchingAnchored
                                                  range:NSMakeRange(0, [ntitle length])];
  
  // Load the TTProfile, which should be the thing that has the colors in it.
  // Note, apparently this is meant to be done via settings, and these script
  // entries (intended for AppleScript) might be deprecated. Screw it. This is easier.
  id profile = [self valueForKey:@"profile"];
  
  // No point in tweaking if there's no change, so keep track of modifications.
  BOOL fchange = FALSE;
  BOOL bchange = FALSE;
  
  // Get the current color from the tab
  NSColor *fcol = [profile valueForKey:@"scriptNormalTextColor"];
  NSColor *bcol = [profile valueForKey:@"scriptBackgroundColor"];
  
  // Convert to plain floats to make life easier
  float fr = fcol.redComponent;
  float fg = fcol.greenComponent;
  float fb = fcol.blueComponent;
  float fa = fcol.alphaComponent;
  
  float br = bcol.redComponent;
  float bg = bcol.greenComponent;
  float bb = bcol.blueComponent;
  float ba = bcol.alphaComponent;
  
  // If the regexp worked, then act on the username/host combo
  if(res) {
    
    // Get the user and host from the regex results
    NSString *user = [ntitle substringWithRange:[res rangeAtIndex:1]];
    NSString *host = [ntitle substringWithRange:[res rangeAtIndex:2]];
    
    NSLog(@"TGTerminalHook_get: %@ / %@", user, host);

    // Change the foreground color based on username
    if([user isEqualTo:@"root"]) {
      fchange |= changeColorComponents(&fr, &fg, &fb, &fa, 1, 0.6, 0.6, 1);
    }
    else if([user isEqualTo:@"gid"]) {
      fchange |= changeColorComponents(&fr, &fg, &fb, &fa, 1, 1, 1, 1);
    }
    else {
      fchange |= changeColorComponents(&fr, &fg, &fb, &fa, 0.8, 0.9, 1, 1);
    }
    
    // Change the background color based on hostname
    if([host isEqualTo:@"pile"]) {
      bchange |= changeColorComponents(&br, &bg, &bb, &ba, 0, 0, 0, 1);
    }
    else if([host isEqualTo:@"mini"]) {
      bchange |= changeColorComponents(&br, &bg, &bb, &ba, 0, 0.2, 0, 1);
    }
    else {
      bchange |= changeColorComponents(&br, &bg, &bb, &ba, 0.2, 0, 0, 1);
    }
  }
  else {
    // The regexp didn't work, so the title's weird. Reset to defaults.
    fchange |= changeColorComponents(&fr, &fg, &fb, &fa, 1, 1, 1, 1);
    bchange |= changeColorComponents(&br, &bg, &bb, &ba, 0, 0, 0, 1);
  }

  // If the foreground color has changed, then set it for the tab
  if(fchange) {
    fcol = [NSColor colorWithCalibratedRed:fr green:fg blue:fb alpha:fa];
    [profile setValue:fcol forKey:@"scriptNormalTextColor"];
    [profile setValue:fcol forKey:@"scriptBoldTextColor"];
  }
  
  // If the background color has changed, then set it for the tab
  if(bchange) {
    bcol = [NSColor colorWithCalibratedRed:br green:bg blue:bb alpha:ba];
    [profile setValue:bcol forKey:@"scriptBackgroundColor"];
  }
  
  // Call the original method so the call to customTabTitle still works.
  // Since this is swizzled, the call to (apparently) this method actually
  // calls the original method that we're overriding.

  return [self TGTerminalHook_get];
}

@end

@implementation TGTerminalHook

/**
 * A special method called by SIMBL once the application has started and all classes are initialized.
 */
+ (void) load
{
  TGTerminalHook* plugin = [TGTerminalHook sharedInstance];
  
  [NSClassFromString(@"TTTabController")
   jr_swizzleMethod:@selector(customTabTitle)
   withMethod:@selector(TGTerminalHook_get) error:NULL];
}

/**
 * @return the single static instance of the plugin object
 */
+ (TGTerminalHook*) sharedInstance
{
  static TGTerminalHook* plugin = nil;
  
  if (plugin == nil)
    plugin = [[TGTerminalHook alloc] init];
  
  return plugin;
}

@end
