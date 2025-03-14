//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const net = std.net;
const testing = std.testing;

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub const EVersion = enum {
    V1_1,
    V2_0,

    pub fn toString(self: EVersion) []const u8 {
        return switch (self) {
            .V1_1 => "HTTP/1.1",
            .V2_0 => "HTTP/2.0"
        };
    }
};

pub const EMethod = enum {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    HEAD,
    OPTIONS,
    TRACE,

    pub fn toString(self: EMethod) []const u8 {
        return switch (self) {
            .GET => "GET",
            .POST => "POST",
            .PUT => "PUT",
            .DELETE => "DELETE",
            .PATCH => "PATCH",
            .HEAD => "HEAD",
            .OPTIONS => "OPTIONS",
            .TRACE => "TRACE",
        };
    }
};

pub const Headers = struct {
    Accept: []const u8 = "*/*",
    Accept_Charset: ?[]const u8 = null,
    Accept_Encoding: ?[]const u8 = null,
    Accept_Language: ?[]const u8 = null,
    Accept_Datetime: ?[]const u8 = null,
    Authorization: ?[]const u8 = null,
    Cache_Control: ?[]const u8 = null,
    Connection: []const u8 = "close",
    Content_Length: ?[]const u8 = null,
    Content_Type: ?[]const u8 = null,
    Date: ?[]const u8 = null,
    Expect: ?[]const u8 = null,
    From: ?[]const u8 = null,
    Host: ?[]const u8 = null,
    If_Match: ?[]const u8 = null,
    If_Modified_Since: ?[]const u8 = null,
    If_None_Match: ?[]const u8 = null,
    If_Range: ?[]const u8 = null,
    If_Unmodified_Since: ?[]const u8 = null,
    Max_Forwards: ?[]const u8 = null,
    Origin: ?[]const u8 = null,
    Pragma: ?[]const u8 = null,
    Proxy_Authorization: ?[]const u8 = null,
    Range: ?[]const u8 = null,
    Referer: ?[]const u8 = null,
    TE: ?[]const u8 = null,
    User_Agent: []const u8 = null,
    Upgrade: ?[]const u8 = null,
    Via: ?[]const u8 = null,
    Warning: ?[]const u8 = null,
};

pub const Payload = struct {
    method: EMethod = EMethod.GET,
    version: EVersion = EVersion.V1_1,
    path: []const u8 = "/",
    parameters: ?std.AutoHashMap([]const u8, []const u8) = null,
    headers: Headers = Headers{},
    body: ?[]const u8 = null,
};

pub const Client = struct {
    payload: ?[]const u8 = null,

    pub fn createPayload(self: *Client, payload: Payload) std.mem.Allocator.Error!void {
        const page_alloc = std.heap.page_allocator;
        var encoder = std.ArrayList(u8).init(page_alloc);
        defer encoder.deinit();
        encoder.appendSlice(payload.method.toString()) catch |err| {return err;};
        encoder.appendSlice(" ") catch |err| {return err;};
        encoder.appendSlice(payload.path) catch |err| {return err;};
        if (payload.parameters) |params| {
            encoder.appendSlice("?") catch |err| {return err;};
            var iterator = params.iterator();
            while (iterator.next()) |entry| {
                encoder.appendSlice(entry.key_ptr.*) catch |err| {return err;};
                encoder.appendSlice("=") catch |err| {return err;};
                encoder.appendSlice(entry.value_ptr.*) catch |err| {return err;};
                if (iterator.next()) |_| {
                    encoder.appendSlice("&") catch |err| {return err;};
                }
            }
        }
        encoder.appendSlice(" ") catch |err| {return err;};
        encoder.appendSlice(payload.version.toString()) catch |err| {return err;};
        encoder.appendSlice("\r\n") catch |err| {return err;};
        const headers_fields = std.meta.fields(Headers);
        inline for (headers_fields) |field| {
            const value: ?[]const u8 = @field(payload.headers, field.name);
            if (value) |v| {
                encoder.appendSlice(field.name) catch |err| {return err;};
                encoder.appendSlice(": ") catch |err| {return err;};
                encoder.appendSlice(v) catch |err| {return err;};
                encoder.appendSlice("\r\n") catch |err| {return err;};
            }
        }
        encoder.appendSlice("\r\n") catch |err| {return err;};
        if (payload.body) |body| {
            encoder.appendSlice(body) catch |err| {return err;};
        }
        self.payload = encoder.toOwnedSlice() catch |err| {return err;};
    }
};

test "http_test" {
    try testing.expect(add(3, 7) == 10);
    var http_client: Client = .{};
    try http_client.createPayload(Payload {
        .body = "Hello, world!"
    });
    std.debug.print("{s}\n", .{http_client.payload.?});
    //const allocator = std.heap.GeneralPurposeAllocator(.{}).init;
    //const address = try net.Address.parseIp4("127.0.0.1", 3000);
    //const client = try net.tcpConnectToAddress(address);
    //defer client.close();
    //const reader = client.reader();
    //var buff = [_]u8{0} ** 256;
    //while (reader.read(&buff)) |size| {
    //    std.debug.print("Received: {s}\n", .{buff[0..size]});

    //    _ = try writer.write(buff[0..size]);
    //} else |err| {
    //    std.debug.print("Error: {any}\n", .{err});
    //    return err;
    //}

    //std.debug.print("Connection closed.\n");
}
