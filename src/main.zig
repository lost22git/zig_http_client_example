const std = @import("std");
const debug = std.debug;
const heap = std.heap;
const http = std.http;
const Uri = std.Uri;

pub fn main() anyerror!void {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = http.Client{
        .allocator = allocator,
    };

    const uri = Uri.parse("https://pkmn.li") catch unreachable;

    var headers = http.Headers{ .allocator = allocator };
    defer headers.deinit();
    try headers.append("accept", "*/*");
    try headers.append("user-agent", "curl/8.0.1");

    var req = try client.request(.GET, uri, headers, .{});
    defer req.deinit();

    // I'm making a GET request, so do I don't need this, but I'm sure someone will.
    // req.transfer_encoding = .chunked;

    // send the request and headers to the server.
    try req.start();

    // try req.writer().writeAll("Hello, World!\n");
    // try req.finish();

    // wait for the server to send use a response
    try req.wait();

    // get response
    const res = req.response;

    // print response headers
    const content_length = res.content_length;
    debug.print("Content-Length: {?d}\n", .{content_length});
    const transfer_encoding = res.transfer_encoding;
    debug.print("Transfer-Encoding: {?}\n", .{transfer_encoding});
    const content_encoding = res.transfer_compression;
    debug.print("Content-Encoding: {?}\n", .{content_encoding});
    const content_type = res.headers.getFirstValue("Content-Type");
    debug.print("Content-Type: {?s}\n", .{content_type});

    debug.print("\n", .{});

    // read the entire response body, but only allow it to allocate 8kb of memory
    const body = req.reader().readAllAlloc(allocator, 100 * 1024) catch unreachable;
    defer allocator.free(body);

    // print body
    debug.print("{s}\n", .{body});
}
