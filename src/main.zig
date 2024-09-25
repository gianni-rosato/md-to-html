const std = @import("std");
const parse = @import("parse.zig").parse;

const print = std.debug.print;
const eql = std.mem.eql;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2 or args.len > 3) {
        print("Usage: md-to-html [input.md] [output.html]\n", .{});
        print("Help: md-to-html -h\n", .{});
        return;
    }

    if ((eql(u8, args[1], "-h") or
        eql(u8, args[1], "--help")) and
        args.len == 2)
    {
        _ = try printHelp();
        return;
    }

    print("\x1b[33mConverting\x1b[0m {s} \x1b[33mto\x1b[0m {s} \x1b[33m...\x1b[0m ", .{ args[1], args[2] });
    try parse(args[1], args[2], allocator);
    print("\x1b[32mSuccess!\x1b[0m\n", .{});
}

fn printHelp() !void {
    print("Markdown to HTML Converter in \x1b[33mZig\x1b[0m\n", .{});
    print("Example usage: md-to-html [input.md] [output.html]\n", .{});
    print("Markdown features supported:\n", .{});
    const supported_features =
        \\    - Headers
        \\    - Headings (H1 to H4)
        \\    - Bold & italicized text
        \\    - Unordered lists
        \\    - Code blocks with language-specific syntax highlighting
        \\    - Links
        \\    - Images
        \\    - Inline code
    ;
    print("{s}\n", .{supported_features});
}
