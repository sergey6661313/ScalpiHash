pub fn size       () !void {
    try g.out.writeAll("sizeCheck\r\n");
    try g.out.writeAll("for text \"testftagn\": ");
    for (hash_buffer[0..16]) |_, id| {
        hasher = .{.output = hash_buffer[0..id + 1]};
        hasher.reset();
        hasher.do("test"); 
        hasher.do("ftagn");
        try printHash();
        try g.out.writeAll("\r\n");
    }
    try g.out.writeAll("end of test \r\n");
}
pub fn ftagn      () !void {
    const secret = "testftagn";
    try g.out.writeAll("ftagnCheck for text \"" ++ secret ++ "\": " ++ "\r\n");
    hasher = .{.output = hash_buffer[0..8]};
    hasher.reset();
    var r: i32 = 0;
    const r_as_bytes = @ptrCast(*[4]u8, &r);
    _ = "loop 10 times"; {
        var i: usize = 0;
        while(i < 10):(i += 1){
            hasher.do(secret); 
            for (hasher.output[0..4]) |byte, id| {
                r_as_bytes[id] = byte;
            }
            try g.out.print("val = {d}\r\n", .{r});
        }    
    }
    try g.out.writeAll("end of test \r\n");
}
pub fn oneBit     () !void {
    try g.out.writeAll("oneBitCheck\r\n");
    hasher = .{.output = hash_buffer[0..16]};
    var input = "he".*;
    var i: usize = 33;
    while(i <= 64) {
        input[1] = @intCast(u8, i);
        hasher.reset();
        hasher.do(input[0..]);
        try g.out.print("input is: \"{s}\" out is: ", .{input});
        try printHash();
        try g.out.writeAll("\n");
        i += 1;
    }
    try g.out.writeAll("end of test \r\n");
}
pub fn speed      () !void {
    try g.out.writeAll("speedCheck\r\n");
    hasher = .{.output = hash_buffer[0..256]};
    var timer = try std.time.Timer.start();
    hasher.reset();
    const iteration_count = 1000;
    var i: usize = 0;
    while(i <= iteration_count) {
        hasher.doByte(@intCast(u8, i & 0xFF));
        i += 1;
    }
    var time = timer.lap();
    try g.out.print("speed test with {d} iter:  {d}\n", .{iteration_count, time});
    time = time / iteration_count;
    try g.out.print("for one iter:  {d}\n", .{time});
    try g.out.writeAll("end of test \r\n");
}
pub fn haos       () !void {
    try g.out.writeAll("haosCheck\r\n");
    hasher = .{.output = hash_buffer[0..16]};
    hasher.reset();
    var results: [256]usize = undefined;
    for (results) |*r| r.* = 0;
    
    var ni: numberIterator.init(usize) = .{.last = 255*255};
    var rnd = std.rand.DefaultPrng.init(0);
    while (ni.next()) |_| {
        const nu8 = rnd.random().int(u8);
        hasher.doByte(nu8);
        const h = hash_buffer[0];
        //try g.out.print("iter: {}: {}\r\n",.{id, h});
        results[h] += 1;
    }
    for (results) |*r, id| try g.out.print("{d}: {}\r\n",.{id, r.*});
    try g.out.writeAll("end of test \r\n");
}
pub fn aaaaab     () !void {
    var array: [6][6]u8 = [6][6]u8{
        "aaaaab".*,
        "aaaaba".*,
        "aaabaa".*,
        "aabaaa".*,
        "abaaaa".*,
        "baaaaa".*
    };
    
    try g.out.writeAll("aaaaab check\r\n");
    for (array) |text| {
        try g.out.print("for text \"{s}\": ",.{text});
        hasher = .{.output = hash_buffer[0..16]};
        hasher.reset();
        hasher.do(text[0..]); 
        try printHash();
        try g.out.writeAll("\r\n");
    }
    try g.out.writeAll("end of test \r\n");
}
pub fn doByte     () !void {
    try g.out.writeAll("byteCheck\r\n");
    var ni: numberIterator.init(u8) = .{.last = 255};
    hasher = .{.output = hash_buffer[0..1]};
    while (ni.next()) |num| {
        const n8 = @truncate(u8, num);
        hasher.reset();
        hasher.doByte(n8); 
        try g.out.print("{d}: ",.{num});
        try printHash();
        try g.out.writeAll("\r\n");
    }
    try g.out.writeAll("end of test \r\n");
}
pub fn do         () !void {
    try size();
    try ftagn();
    try oneBit();
    try speed();
    try haos();
    try aaaaab();
    try doByte();
}
