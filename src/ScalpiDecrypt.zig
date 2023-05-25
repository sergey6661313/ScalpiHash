// TODO default password "Scalpi"

pub const Hasher = @import("ScalpiHash.zig");
pub var   hasher: Hasher = .{.output = undefined};

pub fn main      () !void {
    try Zig.init();
    
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
    
    const password  = arg; arg = arg_iter.next() orelse {try showUsage(); return;};
    const file_name = arg;
    
    // open donor file
    var cwd  = ZigP.std.fs.cwd(); // get current working directory
    var donor_file = cwd.openFile(file_name,.{}) catch |err| {
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
    const metadata  = try donor_file.metadata();
    const file_size = metadata.size();
    defer donor_file.close();
    
    // create target_file_name
    var target_file_name_buffer: [1024]u8 = undefined;
    var ch: LibP.Mem.CopyHelper = .{.dest = target_file_name_buffer[0..]};
    _= try ch.write(file_name);
    _= try ch.write(".decrypted\x00");
    var target_file_name = try ch.get();
    
    // open target_file
    var target_file = try cwd.createFileZ(@ptrCast([*:0]const u8, target_file_name), .{}); 
    defer target_file.close();
    var writer = target_file.writer();
    
    // open donor file
    var file_data = try Zig.allocator.alloc(u8, size_to_allocate); // block size of hasher buffer
    var reader    = donor_file.reader();
    
    // loop
    var read_counter: usize = 0;
    while (true) {
        try Zig.out.writeAll("\r\x1B[0K"); // clear line
        const procent = @intToFloat(f32, read_counter) / @intToFloat(f32, file_size);
        try Zig.out.print("{}/{} ({d:.1}%)",.{read_counter, file_size, procent});
        
        // create new hash
        hasher.do(password);
        const mask = hasher.output[0..];
        
        // try read
        var readed_size = try reader.read(file_data);
        if (readed_size == 0) break;
        
        var readed = file_data[0..readed_size];
        for(readed, 0..) |donor_byte, pos| { // xor loop
            const byte = donor_byte -% mask[pos];
            try writer.writeByte(byte);
        }
        read_counter += readed_size;
    }
    try Zig.out.writeAll("\r\x1B[0K"); // clear line
}

pub const ZigP   = struct {
    pub const std    = @import("std");
};
pub const Zig    = struct {
    pub const Out  = ZigP.std.io.Writer(ZigP.std.fs.File, ZigP.std.os.WriteError, ZigP.std.fs.File.write);
    pub var   heap = ZigP.std.heap.GeneralPurposeAllocator(.{}){};
    
    pub var allocator: ZigP.std.mem.Allocator = undefined;
    pub var out:       Out               = undefined;
    
    pub fn init() !void {
        allocator = heap.allocator();
        out       = ZigP.std.io.getStdOut().writer();
    }
};
pub const LibP   = @import("LibP.zig");

pub fn showUsage () !void {
    try Zig.out.writeAll("  usage: $ ScalpiDecrypt -i hash_size PASSWORD FILE_NAME\r\n");
    try Zig.out.writeAll("  \r\n");
}