const std = @import("std");

pub fn build(b: *std.Build) void {
    const target  = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ScalpiGetHash = b.addExecutable(.{
        .name             = "ScalpiGetHash",
        .root_source_file = .{ .path = "src/ScalpiGetHash.zig" },
        .target           = target,
        .optimize         = optimize,
    });
    ScalpiGetHash.install();

    const ScalpiDecrypt = b.addExecutable(.{
        .name             = "ScalpiDecript",
        .root_source_file = .{ .path = "src/ScalpiDecrypt.zig" },
        .target           = target,
        .optimize         = optimize,
    });
    ScalpiDecrypt.install();

    const ScalpiEncript = b.addExecutable(.{
        .name             = "ScalpiEncript",
        .root_source_file = .{ .path = "src/ScalpiEncript.zig" },
        .target           = target,
        .optimize         = optimize,
    });
    ScalpiEncript.install();
}
