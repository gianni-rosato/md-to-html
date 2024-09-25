const std = @import("std");
const main = @import("main.zig");

const ArrayList = std.ArrayList;
const print = std.debug.print;
const eql = std.mem.eql;
const Allocator = std.mem.Allocator;

pub fn parse(input: []u8, output: []u8, allocator: Allocator) !void {
    const file = try std.fs.cwd().openFile(input, .{ .mode = .read_only });
    defer file.close();

    const markdown = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(markdown);

    var result = ArrayList(u8).init(allocator);
    defer result.deinit();

    var in_code_block = false;
    var is_header = false;
    var header_present = false;

    try result.appendSlice("<!DOCTYPE html>\n");
    try result.appendSlice("<html lang=\"en\">\n");

    var tokens = std.mem.split(u8, markdown, "\n");
    while (tokens.next()) |token| {
        const trimmed = std.mem.trim(u8, token, " ");
        if (trimmed.len == 0) continue;

        if (std.mem.startsWith(u8, trimmed, "---")) {
            is_header = try headToHtml(&result, is_header);
            header_present = true;
            continue;
        } else if (std.mem.startsWith(u8, trimmed, "name: \"")) {
            if (is_header) {
                try result.appendSlice("\t<title>");
                try result.appendSlice(trimmed[7 .. trimmed.len - 1]);
                try result.appendSlice("</title>\n");
                continue;
            }
        } else if (std.mem.startsWith(u8, trimmed, "stylesheet: \"")) {
            if (is_header) {
                try result.appendSlice("\t<link rel=\"stylesheet\" href=\"");
                try result.appendSlice(trimmed[13 .. trimmed.len - 1]);
                try result.appendSlice("\">\n");
                continue;
            }
        }

        if (std.mem.startsWith(u8, trimmed, "```")) {
            in_code_block = try codeToHtml(trimmed, &result, in_code_block);
        } else if (in_code_block) {
            try result.appendSlice(trimmed);
            try result.appendSlice("\n");
        } else if (std.mem.startsWith(u8, trimmed, "#")) {
            try headingToHtml(trimmed, &result);
        } else if (std.mem.startsWith(u8, trimmed, "-")) {
            try result.appendSlice("\t<li>");
            _ = try inlineMarkdownToHTML(trimmed[2..], &result);
            try result.appendSlice("</li>");
        } else if (std.mem.startsWith(u8, trimmed, "[") and std.mem.indexOf(u8, trimmed, "](") != null) {
            try linkToHtml(trimmed, &result);
        } else if (std.mem.startsWith(u8, trimmed, "![") and std.mem.indexOf(u8, trimmed, "](") != null) {
            try imageToHtml(trimmed, &result);
        } else if (std.mem.startsWith(u8, trimmed, "<")) {
            try result.appendSlice("\t");
            try result.appendSlice(trimmed);
        } else {
            try result.appendSlice("\t<p>");
            _ = try inlineMarkdownToHTML(trimmed, &result);
            try result.appendSlice("</p>");
        }
        if (!in_code_block) {
            try result.appendSlice("\n");
        }
    }
    if (header_present) {
        try result.appendSlice("</body>\n");
    }
    try result.appendSlice("</html>");

    const html = try result.toOwnedSlice();
    defer allocator.free(html);

    const outfile = try std.fs.cwd().createFile(output, .{ .truncate = true });
    defer outfile.close();

    _ = try outfile.write(html);
}

fn inlineMarkdownToHTML(line: []const u8, result: *ArrayList(u8)) !void {
    var start: usize = 0;
    var i: usize = 0;
    while (i < line.len) {
        if (std.mem.startsWith(u8, line[i..], "**")) {
            try result.appendSlice(line[start..i]);
            start = i + 2;
            i += 2;
            while (i < line.len and !std.mem.startsWith(u8, line[i..], "**")) : (i += 1) {}
            try result.appendSlice("<strong>");
            try result.appendSlice(line[start..i]);
            try result.appendSlice("</strong>");
            start = i + 2;
            i += 2;
        } else if (std.mem.startsWith(u8, line[i..], "*")) {
            try result.appendSlice(line[start..i]);
            start = i + 1;
            i += 1;
            while (i < line.len and !std.mem.startsWith(u8, line[i..], "*")) : (i += 1) {}
            try result.appendSlice("<em>");
            try result.appendSlice(line[start..i]);
            try result.appendSlice("</em>");
            start = i + 1;
            i += 1;
        } else if (std.mem.startsWith(u8, line[i..], "`")) {
            try result.appendSlice(line[start..i]);
            start = i + 1;
            i += 1;
            while (i < line.len and !std.mem.startsWith(u8, line[i..], "`")) : (i += 1) {}
            try result.appendSlice("<code>");
            try result.appendSlice(line[start..i]);
            try result.appendSlice("</code>");
            start = i + 1;
            i += 1;
        } else if (std.mem.startsWith(u8, line[i..], "[")) {
            try result.appendSlice(line[start..i]);
            const text_end = std.mem.indexOfPos(u8, line, i + 1, "]") orelse break;
            const url_start = text_end + 2; // Skip "]("
            const url_end = std.mem.indexOfPos(u8, line, url_start, ")") orelse break;

            try result.appendSlice("<a href=\"");
            try result.appendSlice(line[url_start..url_end]);
            try result.appendSlice("\">");
            try result.appendSlice(line[i + 1 .. text_end]);
            try result.appendSlice("</a>");

            i = url_end + 1;
            start = i;
        } else if (std.mem.startsWith(u8, line[i..], "![")) {
            try result.appendSlice(line[start..i]);
            const alt_text_end = std.mem.indexOfPos(u8, line, i + 2, "]") orelse break;
            const url_start = alt_text_end + 3; // Skip "]("
            const url_end = std.mem.indexOfPos(u8, line, url_start, ")") orelse break;

            try result.appendSlice("<img src=\"");
            try result.appendSlice(line[url_start..url_end]);
            try result.appendSlice("\" alt=\"");
            try result.appendSlice(line[i + 2 .. alt_text_end]);
            try result.appendSlice("\">");

            i = url_end + 1;
            start = i;
        } else {
            i += 1;
        }
    }
    try result.appendSlice(line[start..]);
}

fn headToHtml(result: *ArrayList(u8), is_header: bool) !bool {
    switch (is_header) {
        false => {
            try result.appendSlice("<head>\n");
            try result.appendSlice("\t<meta charset=\"UTF-8\">\n");
            try result.appendSlice("\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
        },
        true => try result.appendSlice("</head>\n<body>\n"),
    }
    return !is_header;
}

fn codeToHtml(line: []const u8, result: *ArrayList(u8), in_code_block: bool) !bool {
    switch (in_code_block) {
        false => {
            try result.appendSlice("\t<pre><code");
            if (line.len > 3) {
                try result.appendSlice(" class=\"language-");
                try result.appendSlice(line[3..]);
                try result.appendSlice("\"");
            }
            try result.appendSlice(">\n");
        },
        true => try result.appendSlice("\t</code></pre>"),
    }
    return !in_code_block;
}

fn headingToHtml(line: []const u8, result: *ArrayList(u8)) !void {
    var level: u8 = 0;

    while (level < line.len and line[level] == '#') {
        level += 1;
    }

    const tag = switch (level) {
        1 => "h1",
        2 => "h2",
        3 => "h3",
        else => "h4",
    };

    try result.appendSlice("\t<");
    try result.appendSlice(tag);
    try result.appendSlice(">");
    try result.appendSlice(line[(level + 1)..]);
    try result.appendSlice("</");
    try result.appendSlice(tag);
    try result.appendSlice(">");
}

fn linkToHtml(line: []const u8, result: *ArrayList(u8)) !void {
    const text_end = std.mem.indexOf(u8, line, "]").?;
    const url_start = std.mem.indexOf(u8, line, "(").? + 1;
    const url_end = std.mem.lastIndexOf(u8, line, ")").?;

    try result.appendSlice("\t<a href=\"");
    try result.appendSlice(line[url_start..url_end]);
    try result.appendSlice("\">");
    try result.appendSlice(line[1..text_end]);
    try result.appendSlice("</a>");
}

fn imageToHtml(line: []const u8, result: *ArrayList(u8)) !void {
    const alt_end = std.mem.indexOf(u8, line, "]").?;
    const url_start = std.mem.indexOf(u8, line, "(").? + 1;
    const url_end = std.mem.lastIndexOf(u8, line, ")").?;

    try result.appendSlice("\t<img src=\"");
    try result.appendSlice(line[url_start..url_end]);
    try result.appendSlice("\" alt=\"");
    try result.appendSlice(line[2..alt_end]);
    try result.appendSlice("\">");
}
