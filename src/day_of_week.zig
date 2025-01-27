const std = @import("std");
const epoch = std.time.epoch;

pub const DayOfWeek = enum(u3) {
    sun = 0,
    mon,
    tue,
    wed,
    thu,
    fri,
    sat,

    /// return the numeric calendar value for the given day of the week
    /// i.e. sun=0, mon=1,... sat=6
    pub fn numeric(self: DayOfWeek) u3 {
        return @intFromEnum(self);
    }

    /// Calculate the day of the week for the given date
    /// using Zeller's congruence
    pub fn fromDate(year: epoch.Year, month: epoch.Month, day: u8) DayOfWeek {
        var m: i32 = @intCast(month.numeric());
        var y: i32 = @intCast(year);

        if (m == 1 or m == 2) {
            m += 12;
            y -= 1;
        }

        const q: i32 = day;
        const K: i32 = @mod(y, 100);
        const J: i32 = @divFloor(y, 100);

        // Zeller's formula
        const h = @mod(q + (@divFloor((13 * (m + 1)), 5)) + K + @divFloor(K, 4) + @divFloor(J, 4) + (5 * J), 7);

        return switch (h) {
            0 => .sat,
            1 => .sun,
            2 => .mon,
            3 => .tue,
            4 => .wed,
            5 => .thu,
            6 => .fri,
            else => unreachable,
        };
    }
};

test "DayOfWeek.fromDate" {
    const testCases = [_]struct {
        year: epoch.Year,
        month: epoch.Month,
        day: u8,
        expected: DayOfWeek,
    }{
        .{ .year = 1970, .month = .jan, .day = 1, .expected = .thu },
        .{ .year = 2024, .month = .dec, .day = 31, .expected = .tue },
        .{ .year = 2025, .month = .jan, .day = 25, .expected = .sat },
    };

    inline for (testCases) |tc| {
        const actual = DayOfWeek.fromDate(tc.year, tc.month, tc.day);
        try std.testing.expectEqual(tc.expected, actual);
    }
}
