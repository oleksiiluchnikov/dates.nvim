# dates.nvim

A lightweight, zero-dependency Lua library for date manipulation in Neovim.

## What it does

Manipulates dates in `YYYY-MM-DD` format. That's it. No timezones, no time-of-day, no external dependencies.

## Installation

```lua
-- lazy.nvim
{ "oleksiiluchnikov/dates.nvim" }

-- packer.nvim
use "oleksiiluchnikov/dates.nvim"
```

## Quick Start

```lua
local dates = require("dates")

-- Validation
dates.is_valid(2024, 2, 29)        -- true (leap year)
dates.is_valid(2023, 2, 29)        -- false

-- Arithmetic
dates.add_days("2024-01-15", 30)   -- "2024-02-14"
dates.add_months("2024-01-31", 1)  -- "2024-02-29" (handles overflow)
dates.add_years("2024-02-29", 1)   -- "2025-02-28" (handles leap years)

-- Comparisons
dates.diff_days("2024-01-01", "2024-12-31")  -- 365
dates.is_before("2024-01-01", "2024-12-31")  -- true

-- Ranges
dates.range("2024-01-01", "2024-01-03")
-- { "2024-01-01", "2024-01-02", "2024-01-03" }

-- Utilities
dates.today()                      -- "2024-12-28"
dates.weekday("2024-01-01")        -- "Monday"
dates.is_weekend("2024-01-06")     -- true
```

## API Reference

### Validation

#### `is_valid(year, month, day)`

Check if a date is valid.

```lua
dates.is_valid(2024, 2, 29)  -- true
dates.is_valid(2024, 2, 30)  -- false
```

#### `is_valid_string(date_str)`

Check if a date string is valid.

```lua
dates.is_valid_string("2024-02-29")  -- true
dates.is_valid_string("2024-02-30")  -- false
```

### Date Arithmetic

#### `add_days(date_str, days)`

Add or subtract days (use negative numbers to subtract).

```lua
dates.add_days("2024-01-01", 1)   -- "2024-01-02"
dates.add_days("2024-01-01", -1)  -- "2023-12-31"
```

#### `subtract_days(date_str, days)`

Subtract days (convenience wrapper).

```lua
dates.subtract_days("2024-01-02", 1)  -- "2024-01-01"
```

#### `add_months(date_str, months)`

Add or subtract months. Handles day overflow intelligently.

```lua
dates.add_months("2024-01-31", 1)   -- "2024-02-29" (Feb has fewer days)
dates.add_months("2024-03-31", 1)   -- "2024-04-30" (April has 30 days)
dates.add_months("2024-02-15", -1)  -- "2024-01-15"
```

#### `subtract_months(date_str, months)`

Subtract months (convenience wrapper).

```lua
dates.subtract_months("2024-02-15", 1)  -- "2024-01-15"
```

#### `add_years(date_str, years)`

Add or subtract years. Handles leap year edge cases.

```lua
dates.add_years("2024-02-29", 1)   -- "2025-02-28" (not a leap year)
dates.add_years("2020-02-29", 4)   -- "2024-02-29" (both leap years)
```

### Comparisons

#### `diff_days(date_str1, date_str2)`

Get the number of days between two dates. Positive if `date_str2` is later.

```lua
dates.diff_days("2024-01-01", "2024-01-31")  -- 30
dates.diff_days("2024-01-31", "2024-01-01")  -- -30
```

#### `compare(date_str1, date_str2)`

Compare two dates. Returns `-1` (before), `0` (equal), or `1` (after).

```lua
dates.compare("2024-01-01", "2024-01-02")  -- -1
dates.compare("2024-01-01", "2024-01-01")  --  0
dates.compare("2024-01-02", "2024-01-01")  --  1
```

#### `is_before(date_str1, date_str2)`

```lua
dates.is_before("2024-01-01", "2024-01-02")  -- true
```

#### `is_after(date_str1, date_str2)`

```lua
dates.is_after("2024-01-02", "2024-01-01")  -- true
```

### Ranges & Iteration

#### `range(date_from, date_to)`

Generate all dates between two dates (inclusive).

```lua
dates.range("2024-01-01", "2024-01-03")
-- { "2024-01-01", "2024-01-02", "2024-01-03" }
```

### Date Information

#### `weekday(date_str)`

Get the day of the week.

```lua
dates.weekday("2024-01-01")  -- "Monday"
```

#### `is_weekend(date_str)`

```lua
dates.is_weekend("2024-01-06")  -- true (Saturday)
dates.is_weekend("2024-01-01")  -- false (Monday)
```

#### `quarter(date_str)`

Get the quarter (1-4).

```lua
dates.quarter("2024-01-15")  -- 1
dates.quarter("2024-07-15")  -- 3
```

#### `month_name(date_str)`

```lua
dates.month_name("2024-01-15")  -- "January"
```

#### `day_of_year(date_str)`

Get the day number in the year (1-366).

```lua
dates.day_of_year("2024-01-01")  -- 1
dates.day_of_year("2024-12-31")  -- 366 (leap year)
```

#### `iso_week(date_str)`

Get the ISO 8601 week number.

```lua
dates.iso_week("2024-01-01")  -- 1
```

### Month Boundaries

#### `start_of_month(date_str)`

```lua
dates.start_of_month("2024-01-15")  -- "2024-01-01"
```

#### `end_of_month(date_str)`

```lua
dates.end_of_month("2024-02-15")  -- "2024-02-29" (leap year)
```

### Formatting

#### `format(date_str, format_string)`

Format using `os.date` format codes.

```lua
dates.format("2024-01-15", "%d/%m/%Y")       -- "15/01/2024"
dates.format("2024-01-15", "%B %d, %Y")      -- "January 15, 2024"
```

### Convenience Functions

#### `today()`

```lua
dates.today()  -- "2024-12-28"
```

#### `yesterday()`

```lua
dates.yesterday()  -- "2024-12-27"
```

#### `tomorrow()`

```lua
dates.tomorrow()  -- "2024-12-29"
```

### Autocomplete (for completion plugins)

#### `complete(prefix)`

Generate date completions. Useful for nvim-cmp or blink.cmp.

```lua
dates.complete("2024")        -- All 366 dates in 2024
dates.complete("2024-01")     -- All 31 dates in January 2024
dates.complete("2024-01-1")   -- Dates from 01 to 19
dates.complete("2024-01-0")   -- Dates from 01 to 09
```

## Edge Cases & Behavior

### Leap Years

Handled correctly, including century rules:

```lua
dates.is_valid(2000, 2, 29)  -- true  (divisible by 400)
dates.is_valid(1900, 2, 29)  -- false (divisible by 100 but not 400)
dates.is_valid(2024, 2, 29)  -- true  (divisible by 4)
```

### Month Overflow

When adding months, if the resulting day doesn't exist, it's clamped to the last valid day:

```lua
dates.add_months("2024-01-31", 1)  -- "2024-02-29" (not March 2nd)
```

### Invalid Inputs

Most functions return `nil` for invalid inputs:

```lua
dates.add_days("invalid", 1)     -- nil
dates.weekday("2024-02-30")      -- nil (invalid date)
```

## Performance

Benchmarked on typical operations (see `scripts/test_dates.lua`):

```
is_valid               ~0.5 μs/op
complete: full year    ~500 μs/op   (generates 366 dates)
complete: month        ~50 μs/op    (generates ~30 dates)
add_days               ~1.5 μs/op
add_months             ~1.2 μs/op
diff_days              ~2.0 μs/op
range: 30 days         ~50 μs/op
weekday                ~1.5 μs/op
```

Fast enough for interactive use. All operations are O(1) except `range()` and `complete()` which are O(n) on the number of dates generated.

## Testing

Run the test suite:

```bash
nvim --headless -c "luafile scripts/test_dates.lua" -c "qa"
```

Or from within Neovim:

```vim
:luafile scripts/test_dates.lua
```

61 tests covering validation, arithmetic, comparisons, edge cases, and performance.

## Why This Exists

I needed simple date math for a Neovim plugin. Most date libraries are too heavy or assume you want timezone support. This is just dates. ISO 8601 format. Nothing fancy.

## Limitations

- **No timezone support** - all calculations are naive
- **No time-of-day** - only dates (YYYY-MM-DD)
- **Year range:** 1900-2100 (arbitrary but reasonable)
- **Format:** ISO 8601 only (`YYYY-MM-DD`)

If you need more than this, use a proper date library.

## License

[MIT](https://opensource.org/licenses/MIT)
