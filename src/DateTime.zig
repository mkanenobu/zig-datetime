const std = @import("std");
const time = std.time;
const epoch = time.epoch;

nano_timestamp: i128,

const Self = @This();

pub const Year = epoch.Year;
pub const Month = epoch.Month;
pub const Day = u5;
pub const DayOfWeek = @import("./day_of_week.zig").DayOfWeek;

pub fn getEpochDays(self: Self) epoch.EpochDay {
    return epoch.EpochDay{ .day = @as(u47, @intCast(@divFloor(self.nano_timestamp, time.ns_per_day))) };
}
pub fn getEpochSeconds(self: Self) epoch.EpochSeconds {
    return epoch.EpochSeconds{ .secs = @as(u64, @intCast(@divFloor(self.nano_timestamp, time.ns_per_s))) };
}

pub fn fromTimestamp(timestamp: i64) Self {
    return fromNanoTimestamp(@as(i128, @intCast(timestamp)) * time.ns_per_s);
}
pub fn fromMilliTimestamp(milli_timestamp: i64) Self {
    return fromNanoTimestamp(@as(i128, @intCast(milli_timestamp)) * time.ns_per_ms);
}
pub fn fromMicroTimestamp(micro_timestamp: i64) Self {
    return fromNanoTimestamp(@as(i128, @intCast(micro_timestamp)) * time.ns_per_us);
}
pub fn fromNanoTimestamp(nano_timestamp: i128) Self {
    return Self{ .nano_timestamp = nano_timestamp };
}

pub fn fromDateAndTime(datetime: struct { year: Year, month: Month, day: u8, hour: ?u8 = 0, minutes: ?u16 = 0, seconds: ?u8 = 0 }) Self {
    _ = datetime;
    @compileError("not implemented");
}

pub fn getYear(self: Self) Year {
    return self.getEpochDays().calculateYearDay().year;
}

test getYear {
    const testCases = [_]struct {
        timestamp: i64,
        expected: u16,
    }{
        .{ .timestamp = 0, .expected = 1970 },
        .{ .timestamp = 1, .expected = 1970 },
        .{ .timestamp = 31536000, .expected = 1971 },
        .{ .timestamp = 31536000 * 2, .expected = 1972 },
        // 2000/01/01 00:00:00
        .{ .timestamp = 946684800, .expected = 2000 },
        // 2000/12/31 23:59:59
        .{ .timestamp = 978307199, .expected = 2000 },
        // 2000/12/31 23:59:59 + 1sec
        .{ .timestamp = 978307199 + 1, .expected = 2001 },
    };

    inline for (testCases) |tc| {
        const actual = fromTimestamp(tc.timestamp).getYear();
        try std.testing.expectEqual(tc.expected, actual);
    }
}

pub fn isLeapYear(self: Self) bool {
    return epoch.isLeapYear(self.getYear());
}

fn nextMonth(month: Month) Month {
    return @as(Month, @enumFromInt(@mod(month.numeric(), 12) + 1));
}

fn getMonthAndDay(self: Self) struct { month: Month, day: Day } {
    const epoch_day = self.getEpochDays();
    const year_day = epoch_day.calculateYearDay();

    const month_day = year_day.calculateMonthDay();
    const month = month_day.month;
    const day = month_day.day_index + 1;

    return .{ .month = month, .day = day };
}

pub fn getMonth(self: Self) Month {
    return self.getMonthAndDay().month;
}

test getMonth {
    const testCases = [_]struct {
        timestamp: i64,
        expected: Month,
    }{
        .{ .timestamp = 0, .expected = .jan },
        .{ .timestamp = 1, .expected = .jan },
        // 1970/02/01 00:00:00
        .{ .timestamp = 2678400, .expected = .feb },
        // 2000/12/31 23:59:59
        .{ .timestamp = 978307199, .expected = .dec },
        // 2000/12/31 23:59:59 + 1sec
        .{ .timestamp = 978307199 + 1, .expected = .jan },
    };

    inline for (testCases) |tc| {
        const actual = fromTimestamp(tc.timestamp).getMonth();
        try std.testing.expectEqual(tc.expected, actual);
    }
}

pub fn getDay(self: Self) u8 {
    return self.getMonthAndDay().day;
}

test getDay {
    const testCases = [_]struct {
        timestamp: i64,
        expected: u8,
    }{
        .{ .timestamp = 0, .expected = 1 },
        .{ .timestamp = 1, .expected = 1 },
        // 1970/02/01 00:00:00
        .{ .timestamp = 2678400, .expected = 1 },
        // 2000/12/31 23:59:59
        .{ .timestamp = 978307199, .expected = 31 },
        // 2000/12/31 23:59:59 + 1sec
        .{ .timestamp = 978307199 + 1, .expected = 1 },
    };

    inline for (testCases) |testCase| {
        const actual = fromTimestamp(testCase.timestamp).getDay();
        try std.testing.expectEqual(testCase.expected, actual);
    }
}

pub fn getDate(self: Self) struct { year: Year, month: Month, day: Day } {
    const month_and_day = self.getMonthAndDay();
    return .{ .year = self.getYear(), .month = month_and_day.month, .day = month_and_day.day };
}

pub fn getDayOfWeek(self: Self) DayOfWeek {
    const date = self.getDate();
    return DayOfWeek.fromDate(date.year, date.month, date.day);
}

// Time
pub const Hour = u5;
pub const Minutes = u6;
pub const Seconds = u6;

pub fn getTime(self: Self) struct { hour: Hour, minutes: Minutes, seconds: Seconds } {
    const day_seconds = self.getEpochSeconds().getDaySeconds();

    const hour = day_seconds.getHoursIntoDay();
    const minutes = day_seconds.getMinutesIntoHour();
    const seconds = day_seconds.getSecondsIntoMinute();

    return .{ .hour = hour, .minutes = minutes, .seconds = seconds };
}

test getTime {
    const testCases = [_]struct {
        timestamp: i64,
        expected: struct { hour: Hour, minutes: Minutes, seconds: Seconds },
    }{
        .{ .timestamp = 0, .expected = .{ .hour = 0, .minutes = 0, .seconds = 0 } },
        .{ .timestamp = 1, .expected = .{ .hour = 0, .minutes = 0, .seconds = 1 } },
        .{ .timestamp = time.ns_per_day * 2 - 1, .expected = .{ .hour = 23, .minutes = 59, .seconds = 59 } },
    };

    inline for (testCases) |tc| {
        const actual = fromTimestamp(tc.timestamp).getTime();
        try std.testing.expectEqual(tc.expected.hour, actual.hour);
        try std.testing.expectEqual(tc.expected.minutes, actual.minutes);
        try std.testing.expectEqual(tc.expected.seconds, actual.seconds);
    }
}

// Formatting
pub fn formatISO8601DateTime(self: Self, writer: anytype) !void {
    const date = self.getDate();
    const t = self.getTime();

    try std.fmt.format(writer, "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}", .{ date.year, date.month.numeric(), date.day, t.hour, t.minutes, t.seconds });
}

test formatISO8601DateTime {
    const testCases = [_]struct {
        timestamp: i64,
        expected: []const u8,
    }{
        .{ .timestamp = 0, .expected = "1970-01-01T00:00:00" },
        .{ .timestamp = 1, .expected = "1970-01-01T00:00:01" },
        .{ .timestamp = 31536000, .expected = "1971-01-01T00:00:00" },
        .{ .timestamp = 31536000 * 2, .expected = "1972-01-01T00:00:00" },
        // 2000/01/01 00:00:00
        .{ .timestamp = 946684800, .expected = "2000-01-01T00:00:00" },
        // 2000/12/31 23:59:59
        .{ .timestamp = 978307199, .expected = "2000-12-31T23:59:59" },
        // 2000/12/31 23:59:59 + 1sec
        .{ .timestamp = 978307199 + 1, .expected = "2001-01-01T00:00:00" },
    };

    inline for (testCases) |tc| {
        var buf: [32]u8 = undefined;
        var stream = std.io.fixedBufferStream(&buf);
        const writer = stream.writer();

        const timestamp = fromTimestamp(tc.timestamp);
        try timestamp.formatISO8601DateTime(writer);

        const actual = stream.getWritten();
        try std.testing.expectEqualSlices(u8, tc.expected, actual);
    }
}

pub fn format(
    self: Self,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = self;
    _ = fmt;
    _ = options;
    _ = writer;

    @compileError("not implemented");
}
