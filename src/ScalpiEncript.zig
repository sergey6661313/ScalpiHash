pub const std    = @import("std");
pub const G      = struct {
    pub const Out               = std.io.Writer(std.fs.File, std.os.WriteError, std.fs.File.write);
    pub var   allocator_wrapper = std.heap.GeneralPurposeAllocator(.{}){};
    
    allocator: std.mem.Allocator = undefined,
    out:       Out               = undefined,
    
    pub fn init(t: *@This()) !void {
        t.allocator = allocator_wrapper.allocator();
        t.out = std.io.getStdOut().writer();
    }
};
pub const lib    = struct {
    pub const mem            = struct {
        pub const CopyHelper = struct {
            pos:  usize = 0,
            dest: []u8,
            const hex_table = "0123456789ABCDEF";
            const hex_table_reverse = [_]u8{
                0, // 0 NUL
                0, // 1 SOH
                0, // 2 STX
                0, // 3 ETX
                0, // 4 EOT
                0, // 5 ENQ
                0, // 6 ACK
                0, // 7 BEL
                0, // 8 BS
                0, // 9 HT
                0, // 10 LF
                0, // 11 VT
                0, // 12 FF
                0, // 13 CR
                0, // 14 SO
                0, // 15 SI
                0, // 16 DLE
                0, // 17 DC1
                0, // 18 DC2
                0, // 19 DC3
                0, // 20 DC4
                0, // 21 NAK
                0, // 22 SYN
                0, // 23 ETB
                0, // 24 CAN
                0, // 25 EM
                0, // 26 SUB
                0, // 27 ESC
                0, // 28 FS
                0, // 29 GS
                0, // 30 RS
                0, // 31 US
                0, // 32 " "
                0, // 33 !
                0, // 34 "\""
                0, // 35 #
                0, // 36 $
                0, // 37 %
                0, // 38 &
                0, // 39 '
                0, // 40 (
                0, // 41 )
                0, // 42 *
                0, // 43 +
                0, // 44 ,
                0, // 45 -
                0, // 46 .
                0, // 47 /
                0, // 48 0
                1 , // 49 1
                2 , // 50 2
                3 , // 51 3
                4 , // 52 4
                5 , // 53 5
                6 , // 54 6
                7 , // 55 7
                8 , // 56 8
                9 , // 57 9
                0, // 58 :
                0, // 59 ;
                0, // 60 <
                0, // 61 =
                0, // 62 >
                0, // 63 ?
                0, // 64 @
                10, // 65 A
                11, // 66 B
                12, // 67 C
                13, // 68 D
                14, // 69 E
                15, // 70 F
                0, // 71 G
                0, // 72 H
                0, // 73 I
                0, // 74 J
                0, // 75 K
                0, // 76 L
                0, // 77 M
                0, // 78 N
                0, // 79 O
                0, // 80 P
                0, // 81 Q
                0, // 82 R
                0, // 83 S
                0, // 84 T
                0, // 85 U
                0, // 86 V
                0, // 87 W
                0, // 88 X
                0, // 89 Y
                0, // 90 Z
                0, // 91 [
                0, // 92 \
                0, // 93 ]
                0, // 94 ^
                0, // 95 _
                0, // 96 `
                10, // 97 a
                11, // 98 b
                12, // 99 c
                13, // 100 d
                14, // 101 e
                15, // 102 f
                0, // 103 g
                0, // 104 h
                0, // 105 i
                0, // 106 j
                0, // 107 k
                0, // 108 l
                0, // 109 m
                0, // 110 n
                0, // 111 o
                0, // 112 p
                0, // 113 q
                0, // 114 r
                0, // 115 s
                0, // 116 t
                0, // 117 u
                0, // 118 v
                0, // 119 w
                0, // 120 x
                0, // 121 y
                0, // 122 z
                0, // 123 {
                0, // 124 |
                0, // 125 }
                0, // 126 ~
                0, // 127 DEL
            };
            pub const WriteError = anyerror || error {
                CursorOverflow,
            };
            const Writer = std.io.Writer(*@This(), WriteError, write);
            
            pub fn reset              (t: *@This(), dest: []u8) void {
                t.dest = dest;
                t.pos  = 0;
            }
            pub fn write              (t: *@This(), from: []const u8) !usize {
                // try define destination mem
                if (t.pos > t.dest.len - 1) return error.Overflow;
                var dest = t.dest[t.pos .. ];
                
                // try copy
                if (from.len > dest.len) return error.Overflow;
                std.mem.copy(u8, dest, from);
                
                t.pos += from.len;
                return from.len;
            }
            pub fn skip               (t: *@This(), size: usize) ![]u8 {
                if (t.pos + size > t.dest.len) return error.Overflow;
                var out = t.dest[t.pos .. t.pos + size];
                t.pos += size;
                return out;
            }
            pub fn get                (t: *@This()) ![]u8 {
                if (t.pos > t.dest.len) return error.Overflow;
                return t.dest[0..t.pos];
            }
            pub fn writeByte          (t: *@This(), byte: u8) !void {
                if (t.pos > t.dest.len - 1) return error.Overflow;
                t.dest[t.pos] = byte;
                t.pos += 1;
            }
            pub fn writeReedableByte  (t: *@This(), byte: u8) !void {
                switch(byte) {
                    30...126  => {try t.writeByte(byte);},
                    else      => {
                        try t.write("\\x");
                        try t.writeHexByte(byte);
                    }
                }
            }
            pub fn writeHex           (t: *@This(), bytes: []const u8) !void {
                for (bytes) |byte| {
                    try t.writeHexByte(byte);
                }
            }
            pub fn writeHexByte       (t: *@This(), byte:  u8) !void {
                const b_F0 = hex_table[byte >> 4];
                const b_0F = hex_table[byte & 0x0F];
                try t.writeByte(b_F0);
                try t.writeByte(b_0F);
            }
            pub fn writeBytesFromHex  (t: *@This(), hex:   []const u8) !void {
                //try g.out.print("bytes: {d}\r\n", .{hex});
                if (hex.len == 0) return error.Empty;
                if (hex.len & 1 != 0) return error.NotEvenSize;
                var pos: usize = 0;
                while (true) {
                    const b_F0 = hex_table_reverse[hex[pos]] << 4;
                    const b_0F = hex_table_reverse[hex[pos + 1]];
                    const byte = b_F0 | b_0F;
                    //try g.out.print("byte: {d}\r\n", .{byte});
                    try t.writeByte(byte);
                    if (pos == hex.len - 2) break;
                    pos += 2;
                }
            }
            pub fn writer             (t: *@This()) Writer {
                return .{.context = t};
            }
        };
        
        pub const mb_size   = kb_size * 1024;
        pub const kb_size   = 1024;
        pub const CmpResult = enum {
            Equal,
            Various,
        };
        
        pub fn findDiff (buff: []const u8, target: []const u8) ?usize {
            if(buff.len != target.len) unreachable;
            var pos: usize = 0;
            while(pos < buff.len) : (pos += 1) {
                if (buff[pos] != target[pos]) return pos;
            }
            return null;
        }
        pub fn cmp      (buff: []const u8, target: []const u8) CmpResult {
            if(buff.len != target.len) unreachable;
            if(findDiff(buff, target)) |_| return .Various;
            return .Equal;
        }
        pub fn copy     (dest: []u8, from: []const u8) !void {
            const fptr = @ptrToInt(from.ptr);
            const dptr = @ptrToInt(dest.ptr);
            if (from.len > dest.len)  {return error.Overflow;}
            if (fptr == dptr)         {return error.Unexpected;}
            else if (fptr < dptr) {std.mem.copyBackwards(u8, dest, from);} 
            else {std.mem.copy(u8, dest, from);}
        }
        pub fn xor      (dest: []u8, a: []const u8, b: []const u8) void {
            if(a.len != dest.len) unreachable;
            var ai: usize = 0; // simple iterator
            var bi: usize = 0; // cyclical iterator
            while (ai < a.len) {
                dest[ai] = a[ai] ^ b[bi];
                ai += 1; if(ai == a.len) return;
                bi += 1; if(bi == b.len) bi = 0;
            }
        }
    };
    pub const text           = struct {
        pub const CmpResult       = enum { 
            equal, 
            various,
        };
        pub const CharsDecFromU64 = struct {
            const expect = std.testing.expect;
            
            pub const MAX_LEN    = "18446744073709551615".len; // UINT64_MAX
            pub const last_digit = MAX_LEN - 1;
            pub const hex_table  = "0123456789abcdef".*;
            pub const zeroed     = "00000000000000000000";
            
            buff:  [MAX_LEN]u8 = zeroed.*,
            start: usize       = last_digit,
            end:   usize       = last_digit,
            
            pub fn reset      (t: *@This()) void {
                t.* = .{};
            }
            pub fn set        (t: *@This(), _num: u64) void {
                t.reset();
                var num = _num;
                while (true) {
                    const remainder = @truncate(u8, num % 10);
                    t.buff[t.start] = hex_table[remainder];
                    num = num / 10;
                    if (num == 0) break;
                    t.start -= 1;
                }
            }
            pub fn get        (t: *@This()) []u8 {
                if (t.start > t.end)      unreachable;
                if (t.end   > last_digit) unreachable;
                return t.buff[t.start .. t.end + 1];
            }
            pub fn do         (t: *@This(), _num: u64) []u8 {
                t.set(_num);
                return t.get();
            }
            pub fn getDigit   (t: *@This(), wigth: usize) []u8 {
                if (t.start > t.end)      unreachable;
                if (t.end   > last_digit) unreachable;
                if (wigth   > MAX_LEN)    unreachable;
                return t.buff[MAX_LEN - wigth .. MAX_LEN];
            }
            pub fn getMinWidth(t: *@This(), wigth: usize) []u8 {
                if (wigth < t.end - t.start + 1) return t.get();
                return t.getDigit(wigth);
            }
            fn printedTest    (expected: []const u8, data: u64) !void {
                var itoa: @This() = undefined;
                const result = itoa.do(data);
                g.out.print("expected {s} received {s}", .{expected, result});
                try expect(std.mem.eql(u8, expected, result));
            }
            pub fn tests() !void {
                try printedTest("0", 0);
                try printedTest("1", 1);
                try printedTest("10", 10);
                try printedTest("2", 2);
                try printedTest("20", 20);
                try printedTest("200", 200);
                try printedTest("8", 8);
                try printedTest("16", 16);
                try printedTest("32", 32);
                try printedTest("64", 64);
                try printedTest("128", 128);
                try printedTest("256", 256);
                try printedTest("9223372036854775807", 9223372036854775807);
                try printedTest("9223372036854775808", 9223372036854775808);
                try printedTest("18446744073709551615", 18446744073709551615);
            }
        };
        pub const CharsDecFromI64 = struct {
            const expect = std.testing.expect;
            
            pub const MAX_LEN    = "-9223372036854775808".len; // INT64_MIN
            pub const last_digit = MAX_LEN - 1;
            pub const hex_table  = "0123456789abcdef".*;
            pub const zeroed     = "00000000000000000000";
            
            buff:   [MAX_LEN]u8 = zeroed.*,
            start:  usize       = last_digit, 
            end:    usize       = last_digit,
            
            pub fn reset       (t: *@This()) void {
                t.* = .{};
            }
            pub fn set         (t: *@This(), _num: i64) void {
                t.reset();
                
                var num: u64 = std.math.absCast(_num);
                while(true) {
                    const remainder = @truncate(u8, num % 10);
                    t.buff[t.start] = hex_table[remainder];
                    num = num / 10;
                    if (num == 0) break;
                    t.start -= 1;
                }
                
                if(_num < 0) {
                    t.start -= 1;
                    t.buff[t.start] = '-';
                }
            }
            pub fn get         (t: *@This()) []u8 {
                if (t.start > t.end)      unreachable;
                if (t.end   > last_digit) unreachable;
                return t.buff[t.start .. t.end + 1];
            }
            pub fn do          (t: *@This(), _num: i64) []u8 {
                t.set(_num);
                return t.get();
            }
            pub fn getDigit    (t: *@This(), wigth: usize) []u8 {
                if (t.start > t.end)      unreachable;
                if (t.end   > last_digit) unreachable;
                if (wigth   > MAX_LEN)    unreachable;
                return t.buff[MAX_LEN - wigth .. MAX_LEN];
            }
            pub fn getMinWidth (t: *@This(), wigth: usize) []u8 {
                if (wigth < t.end - t.start + 1) return t.get();
                return t.getDigit(wigth);
            }
            fn printedTest     (expected: []const u8, data: i64) !void {
                var itoa: @This() = undefined;
                const result = itoa.do(data);
                g.out.print("expected {s} received {s}", .{expected, result});
                try expect(std.mem.eql(u8, expected, result));
            }
            test "using CharsDecFromU64" {
                try printedTest(   "0",  0);
                try printedTest(   "1",  1);
                try printedTest(  "10",  10);
                try printedTest(  "-2",  -2);
                try printedTest( "-20",  -20);
                try printedTest("-200",  -200);
                try printedTest(   "8",  8);
                try printedTest(  "16",  16);
                try printedTest(  "32",  32);
                try printedTest(  "64",  64);
                try printedTest( "128",  128);
                try printedTest( "256",  256);
                try printedTest("-9223372036854775807", -9223372036854775807);
                try printedTest("-9223372036854775808", -9223372036854775808);
                try printedTest( "9223372036854775807",  9223372036854775807);
            }
        };
        pub const RangeU          = struct {
            start: usize = 0,
            end:   usize = 0,
            
            /// len maybe eq than usize.max + 1
            pub fn countLen    (t: *const @This()) !usize {
                var delta: usize = 0;
                //g.out.print("range = {}\r\n",.{t}) catch {};
                if (t.isReversed()) {delta = t.start - t.end;}
                else {delta = t.end - t.start;}
                if (delta == std.math.maxInt(usize)) {return error.OverFlow;}
                else {return delta + 1;}
            }
            pub fn isReversed  (t: *const @This()) bool {
                if(t.start > t.end) {
                    //g.out.print("this IS reversed\r\n",.{}) catch {};
                    return true;
                }
                else {
                    //g.out.print("this is NOT reversed\r\n",.{}) catch {};
                    return false;
                }
            }
            pub fn cutLeft     (t: *const @This(), pos: usize) !@This() {
                // cheks
                const len = t.countLen() catch pos - 1;
                if(len <= pos) return error.Overflow;
                
                var ret   = t.*;
                ret.start = t.start + pos;
                return ret;
            }
            pub fn cutRight    (t: *const @This(), pos: usize) !@This() {
                const len = t.countLen() catch pos - 1;
                if(len <= pos) return error.Overflow;
                
                var ret = t.*;
                ret.end = t.start + pos;
                return ret;
            }
            pub fn cut         (t: *const @This(), start: usize, end: usize) !@This() {
                var ret = t.*;
                ret = try ret.cutRight(end);
                ret = try ret.cutLeft (start);
                return ret;
            }
            pub fn cutRange    (t: *const @This(), target: *const @This()) !@This() {
                var ret = t.*;
                ret = try ret.cutRight(target.end);
                ret = try ret.cutLeft (target.start);
                return ret;
            }
            pub fn shiftRight  (t: *const @This(), pos: usize) !@This() {
                if (pos > std.math.maxInt(usize) - t.end) return error.Overflow;
                var new: @This() = t.*;
                new.start  += pos;
                new.end    += pos;
                return new;
            }
            pub fn shiftLeft   (t: *const @This(), pos: usize) !@This() {
                if (t.start < pos) return error.Overflow;
                var new: @This() = t.*;
                new.start -= pos;
                new.end   -= pos;
                return new;
            }
            pub fn move        (t: *const @This(), pos: usize) !@This() {
                const min = @min(t.start, t.end);
                var new: @This() = t.*;
                new.start  += pos - min;
                new.end    += pos - min;
                return new;
            }
        };
        
        pub const SplitByRuneIterator = struct {
            const SI = @This();
            
            delimiter:     u8,
            text:          []const u8,
            pos:           ?usize = 0,
            pub fn next(si: *SI) ?[]const u8 {
                var n = si.pos orelse return null;
                var start = n;
                while(true) {
                    if (si.text.len - n < 1) {
                        si.pos = null;
                        return si.text[start .. si.text.len];
                    }
                    if (si.text[n] == si.delimiter) {
                        si.pos = n + 1;
                        return si.text[start..n];
                    }
                    n += 1;
                }
            }
        };
        pub const SplitIterator       = struct {
            const SI = @This();
            
            text:          []const u8,
            delimiter:     []const u8,
            pos:           ?usize = 0,
            pub fn next(si: *SI) ?[]const u8 {
                var n = si.pos orelse return null;
                var start = n;
                while(true) {
                    if (si.text.len - n < si.delimiter.len) {
                        si.pos = null;
                        return si.text[start..];
                    }
                    const ranged_slice = si.text[n..n+si.delimiter.len];
                    if (std.mem.eql(u8, ranged_slice, si.delimiter)) {
                        si.pos = n + si.delimiter.len;
                        return si.text[start..n];
                    }
                    n += 1;
                }
            }
        };
        pub const FindRuneIterator    = struct {
            const FR = @This();
            text:  []const u8,
            rune:  u8,
            pos:   ?usize = 0,
            pub fn next(fr: *FR) ?usize {
                var n = fr.pos orelse return null;
                while(true) {
                    if (fr.text.len - n < 1) return null;
                    if (fr.text[n] == fr.rune) {
                        fr.pos = n + 1;
                        return n;
                    }
                    n += 1;
                }
            }
        };
        pub const FindIterator        = struct {
            const FR = @This();
            text:    []const u8,
            desired: []const u8,
            pos:     ?usize = 0,
            pub fn next(fr: *FR) ?usize {
                var n = fr.pos orelse return null;
                while(true) {
                    if (fr.text.len - n < fr.desired.len) return null;
                    const ranged_slice = fr.text[n..n+fr.desired.len];
                    if (std.mem.eql(u8, ranged_slice, fr.desired)) {
                        fr.pos = n + fr.desired.len;
                        return n;
                    }
                    n += 1;
                }
            }
        };
        
        pub fn cmp         (t: []const u8, target: []const u8) CmpResult {
            if (t.len != target.len) return .various;
            var pos: usize = 0;
            const last = t.len - 1;
            while (true) {
                if (t[pos] != target[pos]) return .various;
                if (pos == last) return .equal;
                pos += 1;
            }
        }
        
        pub fn findRune    (t: []const u8, rune: u8) FindRuneIterator {
            return .{
                .text = t,
                .rune = rune,
            };
        }
        pub fn find        (t: []const u8, desired: []const u8) FindIterator {
            return .{
                .text = t,
                .desired = desired,
            };
        }
        
        pub fn splitByRune (t: []const u8, rune: u8) SplitByRuneIterator {
            return .{
                .text = t,
                .delimiter = rune, 
            };
        }
        pub fn split       (t: []const u8, delimiter: []const u8) SplitIterator {
            return .{
                .text = t,
                .delimiter = delimiter, 
            };
        }
        
        // counts
        pub fn countSymbol          (t: []const u8, symbol: u8) usize {
            var count: usize = 0;
            for(t) |rune| {
                if (rune == symbol) count += 1;
            }
            return count;
        }
        pub fn countLines           (t: []const u8) usize {
            return countNewLinesSymbols(t) + 1;
        }
        pub fn countNewLinesSymbols (t: []const u8) usize {
            var num: usize = 0;
            for (t) |rune| {
                if (rune == '\n') {num += 1;}
            }
            return num;
        }
        
        pub fn cutIndents           (comptime TT: type, from: TT) !TT {
            if (from.len == 0) unreachable;
            
            // cut from left
            var start: usize = 0;
            while(true) {
                if (start >= from.len) return error.TextIsEmpty;
                const rune = from[start];
                if (rune != ' ') {break;}
                start += 1;
            }
            
            // cut from right
            var end: usize = from.len - 1;
            while(true) {
                const rune = from[end];
                if (rune != ' ') {break;}
                end -= 1;
            }
            
            return from[start .. end + 1];
        }
        pub fn u64FromCharsDec      (from: []const u8) error{NotNumber, Unexpected,}!u64 {
            const MAX_LEN = "18446744073709551615".len; // UINT64_MAX
            if (from.len > MAX_LEN) return error.Unexpected;
            var result: u64 = 0;
            var numerical_place: usize = 1;
            var pos: usize = from.len - 1; // last symbol
            while(true) {
                const value: usize = switch(from[pos]) {
                    '0' => 0,
                    '1' => 1,
                    '2' => 2,
                    '3' => 3,
                    '4' => 4,
                    '5' => 5,
                    '6' => 6,
                    '7' => 7,
                    '8' => 8,
                    '9' => 9,
                    else => return error.NotNumber,
                };
                result += value * numerical_place;
                if (pos == 0) return result;
                numerical_place *= 10;
                pos -= 1;
            }
        }
        
        pub fn u8ToSlice  (num: *u8) []u8 {
            return @ptrCast([1]u8, num)[0..1];
        }
        const non_letter_table = [_]u8{
            0, // 0 NUL
            0, // 1 SOH
            0, // 2 STX
            0, // 3 ETX
            0, // 4 EOT
            0, // 5 ENQ
            0, // 6 ACK
            0, // 7 BEL
            0, // 8 BS
            1, // 9 HT
            1, // 10 LF
            0, // 11 VT
            0, // 12 FF
            1, // 13 CR
            0, // 14 SO
            0, // 15 SI
            0, // 16 DLE
            0, // 17 DC1
            0, // 18 DC2
            0, // 19 DC3
            0, // 20 DC4
            0, // 21 NAK
            0, // 22 SYN
            0, // 23 ETB
            0, // 24 CAN
            0, // 25 EM
            0, // 26 SUB
            0, // 27 ESC
            0, // 28 FS
            0, // 29 GS
            0, // 30 RS
            0, // 31 US
            1, // 32 " "
            1, // 33 !
            1, // 34 "\""
            1, // 35 #
            1, // 36 $
            1, // 37 %
            1, // 38 &
            1, // 39 '
            1, // 40 (
            1, // 41 )
            1, // 42 *
            1, // 43 +
            1, // 44 ,
            1, // 45 -
            1, // 46 .
            1, // 47 /
            0, // 48 0
            0, // 49 1
            0, // 50 2
            0, // 51 3
            0, // 52 4
            0, // 53 5
            0, // 54 6
            0, // 55 7
            0, // 56 8
            0, // 57 9
            1, // 58 :
            1, // 59 ;
            1, // 60 <
            1, // 61 =
            1, // 62 >
            1, // 63 ?
            1, // 64 @
            0, // 65 A
            0, // 66 B
            0, // 67 C
            0, // 68 D
            0, // 69 E
            0, // 70 F
            0, // 71 G
            0, // 72 H
            0, // 73 I
            0, // 74 J
            0, // 75 K
            0, // 76 L
            0, // 77 M
            0, // 78 N
            0, // 79 O
            0, // 80 P
            0, // 81 Q
            0, // 82 R
            0, // 83 S
            0, // 84 T
            0, // 85 U
            0, // 86 V
            0, // 87 W
            0, // 88 X
            0, // 89 Y
            0, // 90 Z
            1, // 91 [
            1, // 92 \
            1, // 93 ]
            1, // 94 ^
            0, // 95 _
            1, // 96 `
            0, // 97 a
            0, // 98 b
            0, // 99 c
            0, // 100 d
            0, // 101 e
            0, // 102 f
            0, // 103 g
            0, // 104 h
            0, // 105 i
            0, // 106 j
            0, // 107 k
            0, // 108 l
            0, // 109 m
            0, // 110 n
            0, // 111 o
            0, // 112 p
            0, // 113 q
            0, // 114 r
            0, // 115 s
            0, // 116 t
            0, // 117 u
            0, // 118 v
            0, // 119 w
            0, // 120 x
            0, // 121 y
            0, // 122 z
            1, // 123 {  //}
            1, // 124 |
            1, // 125 }  //{
            1, // 126 ~
            1, // 127 DEL
        };
        pub fn isLetter   (rune: u8) bool {
            if (rune > 127) return true;
            if (non_letter_table[rune] == 0) return true; 
            return false;
        }
        const hex_table_reverse = [_]u8{
            0, // 0 NUL
            0, // 1 SOH
            0, // 2 STX
            0, // 3 ETX
            0, // 4 EOT
            0, // 5 ENQ
            0, // 6 ACK
            0, // 7 BEL
            0, // 8 BS
            0, // 9 HT
            0, // 10 LF
            0, // 11 VT
            0, // 12 FF
            0, // 13 CR
            0, // 14 SO
            0, // 15 SI
            0, // 16 DLE
            0, // 17 DC1
            0, // 18 DC2
            0, // 19 DC3
            0, // 20 DC4
            0, // 21 NAK
            0, // 22 SYN
            0, // 23 ETB
            0, // 24 CAN
            0, // 25 EM
            0, // 26 SUB
            0, // 27 ESC
            0, // 28 FS
            0, // 29 GS
            0, // 30 RS
            0, // 31 US
            0, // 32 " "
            0, // 33 !
            0, // 34 "\""
            0, // 35 #
            0, // 36 $
            0, // 37 %
            0, // 38 &
            0, // 39 '
            0, // 40 (
            0, // 41 )
            0, // 42 *
            0, // 43 +
            0, // 44 ,
            0, // 45 -
            0, // 46 .
            0, // 47 /
            0, // 48 0
            1 , // 49 1
            2 , // 50 2
            3 , // 51 3
            4 , // 52 4
            5 , // 53 5
            6 , // 54 6
            7 , // 55 7
            8 , // 56 8
            9 , // 57 9
            0, // 58 :
            0, // 59 ;
            0, // 60 <
            0, // 61 =
            0, // 62 >
            0, // 63 ?
            0, // 64 @
            10, // 65 A
            11, // 66 B
            12, // 67 C
            13, // 68 D
            14, // 69 E
            15, // 70 F
            0, // 71 G
            0, // 72 H
            0, // 73 I
            0, // 74 J
            0, // 75 K
            0, // 76 L
            0, // 77 M
            0, // 78 N
            0, // 79 O
            0, // 80 P
            0, // 81 Q
            0, // 82 R
            0, // 83 S
            0, // 84 T
            0, // 85 U
            0, // 86 V
            0, // 87 W
            0, // 88 X
            0, // 89 Y
            0, // 90 Z
            0, // 91 [
            0, // 92 \
            0, // 93 ]
            0, // 94 ^
            0, // 95 _
            0, // 96 `
            10, // 97 a
            11, // 98 b
            12, // 99 c
            13, // 100 d
            14, // 101 e
            15, // 102 f
            0, // 103 g
            0, // 104 h
            0, // 105 i
            0, // 106 j
            0, // 107 k
            0, // 108 l
            0, // 109 m
            0, // 110 n
            0, // 111 o
            0, // 112 p
            0, // 113 q
            0, // 114 r
            0, // 115 s
            0, // 116 t
            0, // 117 u
            0, // 118 v
            0, // 119 w
            0, // 120 x
            0, // 121 y
            0, // 122 z
            0, // 123 {  //}
            0, // 124 |
            0, // 125 }  //{
            0, // 126 ~
            0, // 127 DEL
        };
        pub fn hexToU64 (bytes: []const u8) !u64 {
            var ret: u64 = 0;
            var ret_as_slice = std.mem.asBytes(&ret);
            if (bytes.len == 0) return error.Empty;
            if (bytes.len & 1 != 0) return error.NotEvenSize;
            var ret_pos:   usize = (bytes.len - 1) >> 1; // len/2
            var bytes_pos: usize = 0;
            while (true) {
                const b_F0 = hex_table_reverse[bytes[bytes_pos]] << 4;
                const b_0F = hex_table_reverse[bytes[bytes_pos + 1]];
                ret_as_slice[ret_pos]  = b_F0 | b_0F;
                
                if (ret_pos == 0) break;
                ret_pos -= 1;
                if (bytes_pos == bytes.len - 2) break;
                bytes_pos += 2;
            }
            return ret;
        }
        
    };
    pub const numberIterator = struct {
        pub fn init(comptime TT: type) type {
            return struct {
                const This = @This();
                
                current: ?TT = 0,
                first:   TT  = 0,
                last:    TT  = 0,
                step:    TT  = 1,
                
                pub fn next  (t: *This) ?TT {
                    const current = t.current orelse return null;
                    const space   = t.last - current;
                    if (t.step > space) {t.current = null;}
                    else {t.current = current + t.step;}
                    return current;
                }
                pub fn reset (t: *This) void {
                    t.current = t.first;
                }
            };
        }
    }; 
    pub fn printByte (byte: u8) !void {
        if (byte > 0x0F) {
            try g.out.print("{x}",.{byte});
        }
        else {
            try g.out.writeAll("0");
            try g.out.print("{x}",.{byte});
        }
    }
    pub fn printHash () !void {
        for (hasher.output) |byte| try printByte(byte);
    }
};
pub const Hasher = @import("ScalpiHash.zig");

var g:      G      = .{};
var hasher: Hasher = .{.output = undefined};

pub fn showUsage () !void {
    try g.out.writeAll("  usage: $ ScalpiEncrypt -i hash_size PASSWORD FILE_NAME\r\n");
    try g.out.writeAll("  \r\n");
}
pub fn main      () !void {
    try g.init();
    
    var arg_iter = try std.process.ArgIterator.initWithAllocator(g.allocator);
    _ = arg_iter.skip(); // skip name of programm
    
    //{ prepare hash buffer
        var size_to_allocate: usize = 16;
        
        var arg = arg_iter.next() orelse {try showUsage(); return;};
        if (std.mem.eql(u8, arg, "-i")) {
            const size_as_text = arg_iter.next() orelse {try showUsage(); return;};
            size_to_allocate   = try lib.text.u64FromCharsDec(size_as_text);
            arg = arg_iter.next() orelse {try showUsage(); return;};
        }
        
        const allocated_hasher_buffer = try g.allocator.alloc(u8, size_to_allocate);
        defer g.allocator.free(allocated_hasher_buffer);
        
        hasher.output = allocated_hasher_buffer[0..];
    //}
    hasher.reset();
    
    const password  = arg; arg = arg_iter.next() orelse {try showUsage(); return;};
    const file_name = arg;
    
    // open donor file
    var cwd  = std.fs.cwd(); // get current working directory
    var donor_file = cwd.openFile(file_name,.{}) catch |err| {
        switch (err) {
            error.FileNotFound => {
                try g.out.print   ("  error: {s}\r\n",.{@errorName(err)});
                try g.out.writeAll("  \r\n");
                try g.out.writeAll("  Insert coin and try again!\r\n");
                try g.out.writeAll("  \r\n");
                return;
            },
            else => {return err;},
        }
    };
    defer donor_file.close();
    
    // create target_file_name
    var target_file_name_buffer: [1024]u8 = undefined;
    var ch: lib.mem.CopyHelper = .{.dest = target_file_name_buffer[0..]};
    _= try ch.write(file_name);
    _= try ch.write(".encrypted\x00");
    var target_file_name = try ch.get();
    
    // open target_file
    var target_file = try cwd.createFileZ(@ptrCast([*:0]const u8, target_file_name), .{}); 
    defer target_file.close();
    var writer = target_file.writer();
    
    // open donor file
    var file_data = try g.allocator.alloc(u8, size_to_allocate); // block size of hasher buffer
    var reader    = donor_file.reader();
    
    // loop
    while (true) {
        // create new hash
        hasher.do(password);
        const mask = hasher.output[0..];
        
        // try read
        var readed_size = try reader.read(file_data);
        if (readed_size == 0) break;
        
        var readed = file_data[0..readed_size];
        for(readed) |donor_byte, pos| { // xor loop
            const byte = donor_byte +% mask[pos];
            try writer.writeByte(byte);
        }
    }
}