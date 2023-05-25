pub const Hasher = @import("ScalpiHash.zig");
var hasher: Hasher = .{.output = undefined};

pub fn showUsage () !void {
    try Zig.out.writeAll("  usage: $ ScalpiGetHash -i hash_size FILE_NAME\r\n");
    try Zig.out.writeAll("  \r\n");
}
pub fn main      () !void {
    try Zig.init();
    
    if (false) { // tesings...
        var tmp_buff: [16]u8 = undefined;
        hasher.output = tmp_buff[0..];
        hasher.reset();
        hasher.do("testftagn");
        try Zig.out.print("output: {any}",.{tmp_buff});
        if (true) return;
    }
    
    var arg_iter = try ZigP.std.process.ArgIterator.initWithAllocator(Zig.allocator);
    _ = arg_iter.skip(); // skip name of programm
    
    //{ prepare hash buffer
        var size_to_allocate: usize = 16;
        
        var arg = arg_iter.next() orelse {try showUsage(); return;};
        if (ZigP.std.mem.eql(u8, arg, "-i")) {
            const size_as_text = arg_iter.next() orelse {try showUsage(); return;};
            size_to_allocate   = try LibP.Text.u64FromCharsDec(size_as_text);
            arg = arg_iter.next() orelse {try showUsage(); return;};
        }
        
        const allocated_hasher_buffer = try Zig.allocator.alloc(u8, size_to_allocate);
        defer Zig.allocator.free(allocated_hasher_buffer);
        
        hasher.output = allocated_hasher_buffer[0..];
    //}
    hasher.reset();
    
    // open file
    var cwd  = ZigP.std.fs.cwd(); // get current working directory
    var file = cwd.openFile(arg,.{}) catch |err| {
        switch (err) {
            error.FileNotFound => {
                try Zig.out.print   ("  error: {s}\r\n",.{@errorName(err)});
                try Zig.out.writeAll("  \r\n");
                try Zig.out.writeAll("  Insert coin and try again!\r\n");
                try Zig.out.writeAll("  \r\n");
                return;
            },
            else => {return err;},
        }
    };
    defer file.close();
    var file_data = try Zig.allocator.alloc(u8, 4 * 1024); // 4 kb
    var reader    = file.reader();
    while (true) {
        var readed_size = try reader.read(file_data);
        if (readed_size == 0) break;
        var readed = file_data[0..readed_size];
        hasher.do(readed);
    }
    try LibP.printHex(hasher.output);
}

pub const ZigP   = struct {
    pub const std = @import("std");
};

pub const Zig    = struct {
    pub var allocator_wrapper = ZigP.std.heap.GeneralPurposeAllocator(.{}){};
    pub var allocator: ZigP.std.mem.Allocator = undefined;
    
    pub const Out = ZigP.std.io.Writer(ZigP.std.fs.File, ZigP.std.os.WriteError, ZigP.std.fs.File.write);
    pub var out: Out = undefined;
    
    pub fn init() !void {
        allocator = allocator_wrapper.allocator();
        out       = ZigP.std.io.getStdOut().writer();
    }
};
pub const LibP   = @import("LibP.zig");