const std = @import("std");

const Options = struct {
    target:   std.zig.CrossTarget,
    optimize: std.builtin.OptimizeMode,
};

pub fn compile(b: *std.Build, options: *Options) void {
    const ScalpiGetHash = b.addExecutable(.{
        .name             = "ScalpiGetHash",
        .root_source_file = .{ .path = "src/ScalpiGetHash.zig" },
        .target           = options.target,
        .optimize         = options.optimize,
    });
    b.installArtifact(ScalpiGetHash);
    
    const ScalpiDecrypt = b.addExecutable(.{
        .name             = "ScalpiDecript",
        .root_source_file = .{ .path = "src/ScalpiDecrypt.zig" },
        .target           = options.target,
        .optimize         = options.optimize,
    });
    b.installArtifact(ScalpiDecrypt);
    
    const ScalpiEncript = b.addExecutable(.{
        .name             = "ScalpiEncript",
        .root_source_file = .{ .path = "src/ScalpiEncript.zig" },
        .target           = options.target,
        .optimize         = options.optimize,
    });
    b.installArtifact(ScalpiEncript);
}

pub fn build(b: *std.Build) void {
    var base_options: Options = .{
        .target   = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    };
    base_options.target.cpu_model = .baseline;
    base_options.optimize = .ReleaseFast;
    
    var windows_options = base_options;
    windows_options.target.os_tag = .windows;
    
    var linux_options = base_options;
    linux_options.target.abi = .musl;
    
    compile(b, &windows_options);
    compile(b, &linux_options);
}
