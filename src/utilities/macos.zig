const std = @import("std");
pub const c = @cImport({
    @cInclude("CoreGraphics/CoreGraphics.h");
});

pub fn getDPI(fallback: f32) f32 {
    var dpi = fallback;
    var display: c.CGDirectDisplayID = c.CGMainDisplayID(); // default display
    var display_count: u32 = 0;
    if (c.CGGetActiveDisplayList(0, null, &display_count) == c.kCGErrorSuccess and display_count > 1) {
        const MAX_DISPLAYS = 4;
        var displays: [MAX_DISPLAYS]c.CGDirectDisplayID = undefined;
        if (c.CGGetActiveDisplayList(MAX_DISPLAYS, &displays, &display_count) == c.kCGErrorSuccess) {
            if (c.CGWindowListCopyWindowInfo(c.kCGWindowListOptionOnScreenOnly | c.kCGWindowListExcludeDesktopElements, c.kCGNullWindowID)) |list| {
                defer c.CFRelease(list);
                if (c.CFArrayGetCount(list) > 0) {
                    const focused_window = c.CFArrayGetValueAtIndex(list, 0);
                    if (@as(c.CFDictionaryRef, @ptrCast(focused_window))) |dict| {
                        if (c.CFDictionaryGetValue(dict, c.kCGWindowBounds)) |bounds_value| {
                            const bounds_dict = @as(c.CFDictionaryRef, @ptrCast(bounds_value));
                            var window_bounds: c.CGRect = undefined;
                            if (c.CGRectMakeWithDictionaryRepresentation(bounds_dict, &window_bounds)) {
                                for (displays[0..display_count]) |d| {
                                    if (c.CGRectIntersectsRect(c.CGDisplayBounds(d), window_bounds)) { // find the display with the focused window
                                        display = d;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if (display != 0) {
        if (c.CGDisplayCopyDisplayMode(display)) |mode| {
            defer c.CGDisplayModeRelease(mode);
            const width_px = @as(f32, @floatFromInt(c.CGDisplayModeGetPixelWidth(mode)));
            const width_mm = @as(f32, @floatCast(c.CGDisplayScreenSize(display).width));
            if (width_mm != 0) dpi = std.math.round(width_px / width_mm * 25.4);
        }
    }
    return dpi;
}
