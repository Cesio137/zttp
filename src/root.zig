//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const net = std.net;
const testing = std.testing;

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub const Version = enum {
    V1_1,
    V2_0,

    pub fn toString(self: Version) []const u8 {
        return switch (self) {
            .V1_1 => "HTTP/1.1",
            .V2_0 => "HTTP/2.0"
        };
    }
};

pub const Method = enum {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    HEAD,
    OPTIONS,
    TRACE,

    pub fn toString(self: Method) []const u8 {
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
    User_Agent: []const u8 = "HTTPZ",
    Upgrade: ?[]const u8 = null,
    Via: ?[]const u8 = null,
    Warning: ?[]const u8 = null,
};


pub const Client = struct {
    method: Method = Method.GET,
    version: Version = Version.V1_1,
    path: []const u8 = "/",
    parameters: ?std.AutoHashMap([]const u8, []const u8) = null,
    headers: Headers = Headers{},
    body: ?[]const u8 = null,
    payload: ?[]const u8 = null,

    pub fn setMethod(self: *Client, method: Method) void {
        self.method = method;
    }

    pub fn serVersion(self: *Client, version: Version) void {
        self.version = version;
    }

    pub fn setPath(self: *Client, path: []const u8) void {
        self.path = path;
    }

    pub fn setHeaders(self: *Client, headers: Headers) void {
        self.headers = headers;
    }

    pub fn setParameters(self: *Client, parameters: std.AutoHashMap([]const u8, []const u8)) void {
        self.parameters = parameters;
    }

    pub fn setBody(self: *Client, body: []const u8) void {
        self.body = body;
    }

    pub fn setPayload(self: *Client, payload: []const u8) void {
        self.payload = payload;
    }

    pub fn preparePayload(self: *Client) std.mem.Allocator.Error!void {
        const page_alloc = std.heap.page_allocator;
        var payload = std.ArrayList(u8).init(page_alloc);
        defer payload.deinit();
        payload.appendSlice(self.method.toString()) catch |err| {return err;};
        payload.appendSlice(" ") catch |err| {return err;};
        payload.appendSlice(self.path) catch |err| {return err;};
        if (self.parameters) |params| {
            payload.appendSlice("?") catch |err| {return err;};
            var iterator = params.iterator();
            while (iterator.next()) |entry| {
                payload.appendSlice(entry.key_ptr.*) catch |err| {return err;};
                payload.appendSlice("=") catch |err| {return err;};
                payload.appendSlice(entry.value_ptr.*) catch |err| {return err;};
                if (iterator.next()) |_| {
                    payload.appendSlice("&") catch |err| {return err;};
                }
            }
        }
        payload.appendSlice(" ") catch |err| {return err;};
        payload.appendSlice(self.version.toString()) catch |err| {return err;};
        payload.appendSlice("\r\n") catch |err| {return err;};
        const headers_fields = std.meta.fields(Headers);
        inline for (headers_fields) |field| {
            const value: ?[]const u8 = @field(self.headers, field.name);
            if (value) |v| {
                payload.appendSlice(field.name) catch |err| {return err;};
                payload.appendSlice(": ") catch |err| {return err;};
                payload.appendSlice(v) catch |err| {return err;};
                payload.appendSlice("\r\n") catch |err| {return err;};
            }
        }
        payload.appendSlice("\r\n") catch |err| {return err;};
        if (self.body) |body| {
            payload.appendSlice(body) catch |err| {return err;};
        }
        self.setPayload(payload.toOwnedSlice() catch |err| {return err;});
    }
};

test "http_test" {
    try testing.expect(add(3, 7) == 10);
    var http_client: Client = .{};
    http_client.setBody("Hello, world!");
    try http_client.preparePayload();
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
