const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vulkan = b.addTranslateC(.{
        .root_source_file = b.addWriteFiles().add("c.h",
            \\#include <vulkan/vulkan.h>
        ),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    }).createModule();
    vulkan.linkSystemLibrary("vulkan", .{});

    const wio = b.dependency("wio", .{
        .target = target,
        .optimize = optimize,
    }).module("wio");

    const mod = b.addModule("engine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "vk", .module = vulkan },
            .{ .name = "wio", .module = wio },
        },
    });

    const exe = b.addExecutable(.{
        .name = "engine",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "engine", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
