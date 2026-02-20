const std = @import("std");
const testing = std.testing;

// using testing allocator for these tests; Zig provides various allocators for
// different use cases; the testing allocator reports memory leaks and other
// misuses, such as double free.
const allocator = testing.allocator;

const TestError = error{
    AnError,
    AnotherError,
};

fn raiseAnError() TestError!void {
    return TestError.AnError;
}

// TODO: demonstrate container variable order flexibility

test "literals" {
    try testing.expectEqual(bool, @TypeOf(true));
    try testing.expectEqual(comptime_int, @TypeOf(42));
    try testing.expectEqual(comptime_float, @TypeOf(3.14159));
    try testing.expectEqual(comptime_int, @TypeOf('a'));
    try testing.expectEqual(*const [3:0]u8, @TypeOf("foo"));

    try testing.expectEqual(255, 0xff); // hex lowercase
    try testing.expectEqual(255, 0xFF); // hex uppercase
    try testing.expectEqual(255, 0o377); // octal
    try testing.expectEqual(255, 0b11111111); // binary
    try testing.expectEqual(1000, 1_000); // underscore separator

    // TODO: 'type' type
}

test "escapes" {
    try testing.expectEqual(9, '\t');
    try testing.expectEqual(10, '\n');
    try testing.expectEqual(13, '\r');
    try testing.expectEqual(39, '\'');
    try testing.expectEqual(34, '\"');
    try testing.expectEqual(92, '\\');
    try testing.expectEqual(96, '\x60'); // hex 60 === dec 96
    try testing.expectEqual(584, '\u{248}'); // UTF-8 encoded

    // raises compile-time error: unicode escape does not correspond to a valid
    // codepoint
    // try testing.expectEqual(1114112, '\u{110000}');
}

test "constants" {
    const immutable: u32 = 42;
    // raises compile-time error: unused local constant
    // const unused: u32 = 23;

    // raises compile-time error: cannot assign to constant
    // immutable = 42;

    try testing.expectEqual(42, immutable);
}

test "variables" {
    var mutable: u32 = 42;
    var addressed: u32 = 2112;
    // raises compile-time error: local variable is never mutated
    // var unused: u32 = 2112;

    mutable = 23;
    // '&' operator avoids compile-time error: local variable is never mutated
    _ = &addressed;

    try testing.expectEqual(23, mutable);
}

// TODO: test undefined values

test "optional values" {
    const value: u8 = 42;
    const fallback: u8 = 23;
    const optional_with_value: ?u8 = value;
    const optional_without_value: ?u8 = null;
    const RequiredType = @TypeOf(value);
    const OptionalType = @TypeOf(optional_with_value);

    // raises compile-time error: expected type 'u8', found '?u8'
    // const required: u8 = optional_with_value;

    try testing.expect(optional_without_value == null);
    try testing.expect(optional_without_value != 0);
    try testing.expectEqual(optional_with_value orelse fallback, value);
    try testing.expectEqual(optional_without_value orelse fallback, fallback);
    try testing.expect(@typeInfo(RequiredType) != .optional);
    try testing.expect(@typeInfo(OptionalType) == .optional);
}

test "integer types" {
    const byte: u8 = 0;
    const word: u16 = byte;
    const dword: u32 = word;
    const qword: u64 = dword;
    const bigint: u128 = qword;
    const octal: u3 = 0; // arbitrarily sized unsigned integer
    const signed: i2 = 0; // arbitrarily sized signed integer

    var bit: u1 = bigint;

    bit = 1;
    // raises compile-time error: type 'u1' cannot represent integer value '2'
    // bit = 2;

    try testing.expectEqual(1, bit);
    try testing.expectEqual(7, std.math.maxInt(@TypeOf(octal)));
    try testing.expectEqual(0, std.math.minInt(@TypeOf(octal)));
    try testing.expectEqual(1, std.math.maxInt(@TypeOf(signed)));
    try testing.expectEqual(-2, std.math.minInt(@TypeOf(signed)));
}

test "float types" {
    // floats conform to IEEE 754

    const half: f16 = 3.14159; // precision loss
    const single: f32 = half;
    const double: f64 = single;
    const extended: c_longdouble = double;
    const quadruple: f128 = extended;

    try testing.expectEqual(3.140625, quadruple);

    try testing.expectEqual(5, std.math.floatExponentBits(f16));
    try testing.expectEqual(8, std.math.floatExponentBits(f32));
    try testing.expectEqual(11, std.math.floatExponentBits(f64));
    try testing.expectEqual(15, std.math.floatExponentBits(c_longdouble));
    try testing.expectEqual(15, std.math.floatExponentBits(f128));

    try testing.expectEqual(10, std.math.floatMantissaBits(f16));
    try testing.expectEqual(23, std.math.floatMantissaBits(f32));
    try testing.expectEqual(52, std.math.floatMantissaBits(f64));
    try testing.expectEqual(64, std.math.floatMantissaBits(c_longdouble));
    try testing.expectEqual(112, std.math.floatMantissaBits(f128));

    try testing.expectEqual(10, std.math.floatFractionalBits(f16));
    try testing.expectEqual(23, std.math.floatFractionalBits(f32));
    try testing.expectEqual(52, std.math.floatFractionalBits(f64));
    try testing.expectEqual(63, std.math.floatFractionalBits(c_longdouble));
    try testing.expectEqual(112, std.math.floatFractionalBits(f128));

    try testing.expectEqual(1e-45, std.math.floatTrueMin(f32));
    try testing.expectEqual(1.1754944e-38, std.math.floatMin(f32));
    try testing.expectEqual(3.4028235e38, std.math.floatMax(f32));
    try testing.expectEqual(1.1920929e-7, std.math.floatEps(f32));
    try testing.expectEqual(1.1920929e-7, std.math.floatEpsAt(f32, 1.0));

    try testing.expectEqual(std.math.inf(f32), std.math.inf(f16));
    try testing.expect(std.math.nan(f32) != std.math.nan(f32));

    // raises compile-time error: division by zero here causes undefined behavior
    // const div0 = 1.0 / 0.0;
}

test "identifiers" {
    const starts_with_alpha: bool = true;
    const _starts_with_underscore: bool = true;
    const contains_1234567890: bool = true;
    const TypesAreCapitalizedByConvention = struct { x: u32, y: u32 };

    // raises compile-time error: expected 'an identifier', found 'a number
    // literal'
    // const 1234567890_cant_start_identifier: bool = false;

    // raises compile-time error: expected '=', found '-'
    // const hyphenated-identifier: bool = false;

    // raises compile-time error: expected 'an identifier', found 'a builtin
    // function'
    // const @reserved: bool = false;

    // raises compile-time error: expected '=', found 'an identifier'
    // const foo bar: bool = false;

    // raises compile-time error: local constant shadows declaration of
    // 'allocator'
    // const allocator: bool = false;

    // use @"..." to define unusual identifiers
    const @"1234567890_cant_start_identifier": bool = true;
    const @"hyphenated-identifier": bool = true;
    const @"@reserved": bool = true;
    const @"foo bar": bool = true;

    // but you still can't shadow an outer declaration
    // raises compile-time error: local constant shadows declaration of
    // 'allocator'
    // const @"allocator": bool = false;

    // avoid compile-time error: unused local constant
    _ = starts_with_alpha;
    _ = _starts_with_underscore;
    _ = contains_1234567890;
    _ = TypesAreCapitalizedByConvention;
    _ = @"1234567890_cant_start_identifier";
    _ = @"hyphenated-identifier";
    _ = @"@reserved";
    _ = @"foo bar";
}

test "static container variables" {
    // q.v. fn nextStatic() u32
    // function declares a const struct, which acts as a static local variable

    try testing.expectEqual(1, nextStatic());
    try testing.expectEqual(2, nextStatic());
}
// used in the previous test to demonstrate thread local storage via container
fn nextStatic() u32 {
    const StaticContainer = struct {
        var id: u32 = 0;
    };
    StaticContainer.id += 1;
    return StaticContainer.id;
}

test "error namespace" {
    try testing.expect(error.AnError == TestError.AnError);
    try testing.expect(error.AnError != TestError.AnotherError);
}

test "returning error" {
    const err = raiseAnError();
    try testing.expectError(TestError.AnError, err);
}

test "array sentinels" {
    // sentinels are special values that mark the end of the array
    // the archetypal example is null-terminated C strings

    const all_sentinels = [_:0]u8{ 0, 0, 0 };
    const with_sentinel = [_:0]u8{ 'f', 'o', 'o' };
    const without_sentinel = [_]u8{ 'f', 'o', 'o' };

    try testing.expectEqual(all_sentinels.len, 3);
    try testing.expectEqual(with_sentinel.len, 3);
    try testing.expectEqual(without_sentinel.len, 3);
    try testing.expectEqual(with_sentinel[3], 0);
    try testing.expectEqual(all_sentinels[3], 0);

    // raises compile-time error: index 3 outside array of length 3
    // _ = without_sentinel[3];

    try testing.expect(std.mem.eql(u8, &with_sentinel, &without_sentinel));
}

test "multiline string literals" {
    const string =
        \\foo\x23
    ;
    const string_with_newlines =
        \\0
        \\2
    ;

    try testing.expectEqual(7, string.len);
    try testing.expectEqual("foo\\x23", string);
    try testing.expectEqual(3, string_with_newlines.len);
    try testing.expectEqual('\n', string_with_newlines[1]);
}

test "memory allocation" {
    var list = std.array_list.Managed(u8).init(allocator);

    try list.append(23);
    try testing.expectEqual(1, list.items.len);

    // avoids run-time error: memory address 0x... leaked:
    list.deinit();
}

test "defer" {
    var list = std.array_list.Managed(u8).init(allocator);
    defer list.deinit(); // more sensible place to put cleanup using 'defer'

    try list.append(23);
    try testing.expectEqual(1, list.items.len);
}

test "thread local variables" {
    // q.v. fn testThreadValue() !void
    // function mutates threadlocal variable; each thread has its own copy
    const t1 = try std.Thread.spawn(.{}, testThreadValue, .{});
    const t2 = try std.Thread.spawn(.{}, testThreadValue, .{});

    testThreadValue() catch {}; // run once in current thread
    t1.join(); // ensure t1 thread is complete
    t2.join(); // ensure t2 thread is complete
}
// these are used in the previous test to demonstrate thread local variables
threadlocal var thread_value: u32 = 0;
fn testThreadValue() !void {
    try testing.expectEqual(0, thread_value);
    thread_value += 1;
    try testing.expectEqual(1, thread_value);
}

// TODO: addition, including wrapping (+/-%), saturating (+/-|), and chaos (+/-)

test "alloc/free" {
    const bytes = try allocator.alloc(u8, 8);
    defer allocator.free(bytes);

    // raises error: ptr must be a single item pointer
    // allocator.destroy(bytes);

    // thread panic: Invalid free
    // allocator.destroy(@as(*u8, @ptrCast(bytes.ptr)));

    try testing.expectEqual([]u8, @TypeOf(bytes));
}

test "create/destroy" {
    const Type = struct { val: usize };
    const object = try allocator.create(Type);
    defer allocator.destroy(object);

    // raises error: Expected pointer, slice, array, or vector type, found '...*Type'
    // allocator.free(object);

    try testing.expectEqual(*Type, @TypeOf(object));
}

test "alloc/destroy" {
    const bytes = try allocator.alloc(u8, @sizeOf(usize));
    defer allocator.destroy(@as(*align(1) usize, @ptrCast(bytes.ptr)));

    // raises error: @ptrCast increases pointer alignment
    // allocator.destroy(@as(*usize, @ptrCast(bytes.ptr)));

    // Segmentation fault at address 0x...
    // allocator.destroy(@as(*usize, @ptrCast(@alignCast(bytes.ptr))));

    try testing.expectEqual([]u8, @TypeOf(bytes));
}

test "create/free" {
    const Type = struct { val: usize };
    const object = try allocator.create(Type);
    defer allocator.free(@as(*align(@sizeOf(Type)) [@sizeOf(Type)]u8, @ptrCast(object)));

    // warning: Allocation alignment 8 does not match free alignment 1. Allocation:...
    // allocator.free(@as(*[@sizeOf(Type)]u8, @ptrCast(object)));

    // warning: Allocation size 8 bytes does not match free size 1. Allocation:...
    // allocator.free(@as(*align(@sizeOf(Type)) [1]u8, @ptrCast(object)));

    try testing.expectEqual(*Type, @TypeOf(object));
}

test "Object.alloc/Object.free w/ extra data" {
    const Type = struct {
        len: usize,

        pub fn alloc(len: usize) !*@This() {
            std.debug.assert(len >= @sizeOf(@This()));

            const bytes = try allocator.alignedAlloc(u8, .of(@This()), len);
            const object: *@This() = @ptrCast(bytes.ptr);

            // raises error: @ptrCast increases pointer alignment
            // const bytes = try allocator.alloc(u8, len);

            // raises error: epected type '...*Type' found '...*align(1) Type'
            // const object: *align(1) @This() = @ptrCast(bytes.ptr);

            object.len = len;

            return object;
        }

        pub fn free(this: *@This()) void {
            allocator.free(@as(*[]align(@alignOf(@This())) u8, @ptrCast(@constCast(&.{
                .ptr = this,
                .len = this.len,
            }))).*);
        }
    };

    const object = try Type.alloc(16);
    defer object.free();

    try testing.expectEqual(*Type, @TypeOf(object));
}
