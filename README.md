# 📅 Dates

An utility plugin to manage and process dates for Neovim.

## ✨ Features

- **Check Validity:** Check if a date is valid.
- **Generate Dates:** Retrieve valid dates starting from a given year's beginning.
- **Get Weekday:** Obtain the weekday for a specified date.

## 🚀 Usage

### API

Check if a date is valid:
```lua
---@return boolean
function require('dates').is_valid(year, month, day)
```

Get dates for a given prefix:
```lua
---@param prefix_to_filter string -- e.g., 2021-01 or 20.
---@return table -- array of suggested date strings
function require('dates').get(prefix_to_filter)
```

Get the weekday of a given date:
```lua
---@param date string -- e.g., 2021-01-01
---@return string -- the weekday of the given date.
function require('dates').get_weekday(date)
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
```

## License

[MIT](https://choosealicense.com/licenses/mit/)
