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

    try parse(args[1], args[2], allocator);
}

fn printHelp() !void {
    print("Markdown to HTML Converter in \x1b[33mZig\x1b[0m\n", .{});
    print("Example usage: md-to-html [input.md] [output.html]\n", .{});
    print("Markdown features supported:\n", .{});
    print("\t- Headings\n", .{});
    print("\t- Bold and italic text\n", .{});
    print("\t- Lists\n", .{});
    print("\t- Code blocks\n", .{});
    print("\t- Links\n", .{});
    print("\t- Images\n", .{});
}
