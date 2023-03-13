mask:   u8 = 15,
a:      u8 = 0,
b:      u8 = 0,
output: []u8,

pub fn swapTwoBit (t: *@This()) void {
    //
    const a: u3 = @truncate(u3, t.a);
    const b: u3 = @truncate(u3, t.b);
    
    // save bits with swap
    const tmp_a = (t.mask & (@as(u8, 1) << a)) >> a << b;
    const tmp_b = (t.mask & (@as(u8, 1) << b)) >> b << a;
    const tmp   = tmp_a | tmp_b;
    
    // clear bits
    t.mask &= 255 - (@as(u8, 1) << a);
    t.mask &= 255 - (@as(u8, 1) << b);
    
    // set last bits
    t.mask |= tmp;
}

pub fn doBit      (t: *@This(), bit:  u1) void {
    const bb: u8 = @as(u8, 2) - bit;
    for(t.output) |*output_byte| {
        t.a +%= output_byte.*;
        t.b +%= bb;
        t.swapTwoBit();
        output_byte.* +%= t.mask;
    }
}

pub fn doByte     (t: *@This(), byte: u8) void {
    var pos: u3 = 0;
    while(true) {
        const bit = @truncate(u1, byte >> pos); // & 1;
        t.doBit(bit);
        if (pos == 7) break;
        pos += 1;
    }
}

pub fn do         (t: *@This(), bytes: []const u8) void {
    for (bytes) |byte| {
        t.doByte(byte);
    }
}

pub fn reset      (t: *@This()) void {
    t.mask = 15;
    t.a = 0;
    t.b = 0;
    for (t.output) |*b| b.* = 0;
}