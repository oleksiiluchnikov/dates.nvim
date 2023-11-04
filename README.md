# 📅 Dates

An utility plugin to manage and process dates for Neovim.

## ✨ Features

- **Check validity:** Check if a date is valid.
- **Generate dates:** Retrieve valid dates starting from a given year's beginning.
- **Get weekday:** Obtain the weekday for a specified date.
- **Get dates from date to date:** Retrieve all dates between two given dates.

## 🚀 Usage

### API

Check if a date is valid:
```lua
---@return boolean
require('dates').is_valid(year, month, day)
```

Get dates for a given prefix:
```lua
---@param prefix_to_filter string -- e.g., 2021-01 or 20.
---@return table -- array of suggested date strings
require('dates').get(prefix_to_filter)
```

Get the weekday of a given date:
```lua
---@param date string -- e.g., 2021-01-01
---@return string -- the weekday of the given date.
require('dates').get_weekday(date)
```

Get dates from date to date:
```lua
---@param from_date string -- e.g., 2021-01-01
---@param to_date string -- e.g., 2021-01-31
---@return table -- array of suggested date strings
require('dates').get_dates(from_date, to_date)
```

### Example

```lua
-- Check if a date is valid
assert(require('dates').is_valid(2024, 8, 31) == true)
assert(require('dates').is_valid(2024, 2, 31) == false)

-- Get dates for a given prefix
assert(require('dates').get("2024-01-0") == {
  "2024-01-01",
  "2024-01-02",
  "2024-01-03",
  "2024-01-04",
  "2024-01-05",
  "2024-01-06",
  "2024-01-07",
  "2024-01-08",
  "2024-01-09",
})

-- Get the weekday of a given date
assert(require('dates').get_weekday("2024-01-01") == "Monday")

-- Get dates from date to date
assert(require('dates').get_dates("2024-01-01", "2024-01-03") == {
  "2024-01-01",
  "2024-01-02",
  "2024-01-03",
})
```

## License

[MIT](https://choosealicense.com/licenses/mit/)
