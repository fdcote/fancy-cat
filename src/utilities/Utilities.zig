const builtin = @import("builtin");
const utilities = struct {
    pub const macos = @import("./macos.zig");
};

pub fn getDPI(fallback: f32) f32 {
    return switch (builtin.os.tag) {
        .macos => utilities.macos.getDPI(fallback),
        // TODO Linux DPI detection
        else => fallback,
    };
}
