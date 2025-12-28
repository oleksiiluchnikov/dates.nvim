-- lua/dates/init.lua
local M = {}

-- Constants
local DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local WEEKDAYS = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
local MONTHS = {
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December",
}

-- Utilities
local function is_leap_year(year)
	return (year % 4 == 0) and (year % 100 ~= 0 or year % 400 == 0)
end

local function days_in_month(year, month)
	if month == 2 and is_leap_year(year) then
		return 29
	end
	return DAYS_IN_MONTH[month]
end

local function parse_date(date_str)
	if type(date_str) ~= "string" or #date_str ~= 10 then
		return nil
	end
	local year = tonumber(date_str:sub(1, 4))
	local month = tonumber(date_str:sub(6, 7))
	local day = tonumber(date_str:sub(9, 10))
	if not year or not month or not day then
		return nil
	end
	return year, month, day
end

local function date_to_timestamp(year, month, day)
	return os.time({ year = year, month = month, day = day, hour = 12 })
end

-- Public API

---Check if a date is valid
---@param year number
---@param month number
---@param day number
---@return boolean
function M.is_valid(year, month, day)
	if type(year) ~= "number" or type(month) ~= "number" or type(day) ~= "number" then
		return false
	end
	if month < 1 or month > 12 or day < 1 then
		return false
	end
	return day <= days_in_month(year, month)
end

---Check if a date string is valid
---@param date_str string
---@return boolean
function M.is_valid_string(date_str)
	local year, month, day = parse_date(date_str)
	if not year or not month or not day then
		return false
	end
	return M.is_valid(year, month, day)
end

---Get autocomplete suggestions for date prefix (optimized for blink/nvim-cmp)
---@param prefix string e.g., "2024", "2024-01", "2024-01-0"
---@return string[] Array of matching date strings
function M.complete(prefix)
	if not prefix or prefix == "" then
		return {}
	end

	local results = {}

	-- Parse the prefix to determine what to generate
	local year_str, month_str = prefix:match("^(%d%d%d%d)%-?(%d?%d?)%-?(%d?%d?)$")

	if not year_str then
		-- Invalid format
		return {}
	end

	local year = tonumber(year_str)
	if not year or year < 1900 or year > 2100 then
		return {}
	end

	-- Determine generation scope
	local month_start, month_end = 1, 12

	if month_str and month_str ~= "" then
		if #month_str == 2 then
			-- Full month specified
			local month = tonumber(month_str)
			if not month or month < 1 or month > 12 then
				return {}
			end
			month_start, month_end = month, month
		end
	end

	-- Generate dates and filter by prefix
	for month = month_start, month_end do
		for day = 1, days_in_month(year, month) do
			local date_str = string.format("%04d-%02d-%02d", year, month, day)
			-- Simple prefix match - works correctly for all cases
			if date_str:sub(1, #prefix) == prefix then
				results[#results + 1] = date_str
			end
		end
	end

	return results
end

---Add days to a date
---@param date_str string
---@param days_to_add number
---@return string|nil
function M.add_days(date_str, days_to_add)
	local year, month, day = parse_date(date_str)
	if not year or not month or not day or not M.is_valid(year, month, day) then
		return nil
	end

	local timestamp = date_to_timestamp(year, month, day)
	local new_timestamp = timestamp + (days_to_add * 86400)
	---@type string
	local result = os.date("%Y-%m-%d", new_timestamp)
	return result
end

---Subtract days from a date
---@param date_str string
---@param days_to_subtract number
---@return string|nil
function M.subtract_days(date_str, days_to_subtract)
	return M.add_days(date_str, -days_to_subtract)
end

---Add months to a date
---@param date_str string
---@param months_to_add number
---@return string|nil
function M.add_months(date_str, months_to_add)
	local year, month, day = parse_date(date_str)
	if not year or not month or not day or not M.is_valid(year, month, day) then
		return nil
	end

	local total_months = (year * 12 + month - 1) + months_to_add
	local new_year = math.floor(total_months / 12)
	local new_month = (total_months % 12) + 1

	-- Handle day overflow (e.g., Jan 31 + 1 month = Feb 28/29)
	local max_day = days_in_month(new_year, new_month)
	local new_day = math.min(day, max_day)

	return string.format("%04d-%02d-%02d", new_year, new_month, new_day)
end

---Subtract months from a date
---@param date_str string
---@param months_to_subtract number
---@return string|nil
function M.subtract_months(date_str, months_to_subtract)
	return M.add_months(date_str, -months_to_subtract)
end

---Add years to a date
---@param date_str string
---@param years_to_add number
---@return string|nil
function M.add_years(date_str, years_to_add)
	local year, month, day = parse_date(date_str)
	if not year or not month or not day or not M.is_valid(year, month, day) then
		return nil
	end

	local new_year = year + years_to_add

	-- Handle leap year edge case (Feb 29 -> Feb 28)
	if month == 2 and day == 29 and not is_leap_year(new_year) then
		day = 28
	end

	return string.format("%04d-%02d-%02d", new_year, month, day)
end

---Get difference in days between two dates
---@param date_str1 string
---@param date_str2 string
---@return number|nil Number of days (positive if date2 > date1)
function M.diff_days(date_str1, date_str2)
	local y1, m1, d1 = parse_date(date_str1)
	local y2, m2, d2 = parse_date(date_str2)

	if
		not y1
		or not m1
		or not d1
		or not y2
		or not m2
		or not d2
		or not M.is_valid(y1, m1, d1)
		or not M.is_valid(y2, m2, d2)
	then
		return nil
	end

	local t1 = date_to_timestamp(y1, m1, d1)
	local t2 = date_to_timestamp(y2, m2, d2)

	return math.floor((t2 - t1) / 86400)
end

---Compare two dates
---@param date_str1 string
---@param date_str2 string
---@return number|nil -1 if date1 < date2, 0 if equal, 1 if date1 > date2
function M.compare(date_str1, date_str2)
	local diff = M.diff_days(date_str1, date_str2)
	if not diff then
		return nil
	end
	if diff < 0 then
		return 1
	elseif diff > 0 then
		return -1
	else
		return 0
	end
end

---Check if date1 is before date2
---@param date_str1 string
---@param date_str2 string
---@return boolean|nil
function M.is_before(date_str1, date_str2)
	local cmp = M.compare(date_str1, date_str2)
	return cmp and cmp == -1 or false
end

---Check if date1 is after date2
---@param date_str1 string
---@param date_str2 string
---@return boolean|nil
function M.is_after(date_str1, date_str2)
	local cmp = M.compare(date_str1, date_str2)
	return cmp and cmp == 1 or false
end

---Get all dates in a range (inclusive)
---@param date_from string
---@param date_to string
---@return string[]|nil Array of date strings
function M.range(date_from, date_to)
	local diff = M.diff_days(date_from, date_to)
	if not diff or diff < 0 then
		return nil
	end

	local dates = {}
	for i = 0, diff do
		dates[#dates + 1] = M.add_days(date_from, i)
	end

	return dates
end

---Get the weekday of a date
---@param date_str string
---@return string|nil Weekday name
function M.weekday(date_str)
	local year, month, day = parse_date(date_str)
	if not year or not month or not day or not M.is_valid(year, month, day) then
		return nil
	end

	local timestamp = date_to_timestamp(year, month, day)
	local wday = tonumber(os.date("%w", timestamp)) + 1 -- Convert 0-6 to 1-7
	return WEEKDAYS[wday]
end

---Check if date is a weekend
---@param date_str string
---@return boolean|nil
function M.is_weekend(date_str)
	local wd = M.weekday(date_str)
	if not wd then
		return nil
	end
	return wd == "Saturday" or wd == "Sunday"
end

---Get the quarter of a date
---@param date_str string
---@return number|nil Quarter number (1-4)
function M.quarter(date_str)
	local year, month, day = parse_date(date_str)
	if not year or not month or not day or not M.is_valid(year, month, day) then
		return nil
	end
	return math.ceil(month / 3)
end

---Get month name
---@param date_str string
---@return string|nil
function M.month_name(date_str)
	local year, month, day = parse_date(date_str)
	if not year or not month or not day or not M.is_valid(year, month, day) then
		return nil
	end
	return MONTHS[month]
end

---Format a date
---@param date_str string
---@param format string os.date format string
---@return string|nil
function M.format(date_str, format)
	local year, month, day = parse_date(date_str)
	if not year or not month or not day or not M.is_valid(year, month, day) then
		return nil
	end

	local timestamp = date_to_timestamp(year, month, day)
	---@type string|nil
	local result = os.date(format, timestamp)
	return result
end

---Get today's date
---@return string
function M.today()
	---@type string
	local result = os.date("%Y-%m-%d")
	return result
end

---Get yesterday's date
---@return string
function M.yesterday()
	---@type string
	local result = os.date("%Y-%m-%d", os.time() - 86400)
	return result
end

---Get tomorrow's date
---@return string
function M.tomorrow()
	---@type string
	local result = os.date("%Y-%m-%d", os.time() + 86400)
	return result
end

---Get ISO week number
---@param date_str string
---@return number|nil
function M.iso_week(date_str)
	local year, month, day = parse_date(date_str)
	if not year or not month or not day or not M.is_valid(year, month, day) then
		return nil
	end

	local timestamp = date_to_timestamp(year, month, day)
	return tonumber(os.date("%V", timestamp))
end

---Get day of year
---@param date_str string
---@return number|nil
function M.day_of_year(date_str)
	local year, month, day = parse_date(date_str)
	if not year or not month or not day or not M.is_valid(year, month, day) then
		return nil
	end

	local timestamp = date_to_timestamp(year, month, day)
	return tonumber(os.date("%j", timestamp))
end

---Get start of month
---@param date_str string
---@return string|nil
function M.start_of_month(date_str)
	local year, month, day = parse_date(date_str)
	if not year or not month or not day or not M.is_valid(year, month, day) then
		return nil
	end
	return string.format("%04d-%02d-01", year, month)
end

---Get end of month
---@param date_str string
---@return string|nil
function M.end_of_month(date_str)
	local year, month, day = parse_date(date_str)
	if not year or not month or not day or not M.is_valid(year, month, day) then
		return nil
	end
	local last_day = days_in_month(year, month)
	return string.format("%04d-%02d-%02d", year, month, last_day)
end

-- Backward compatibility aliases
---@deprecated Use M.complete instead
M.get = M.complete
---@deprecated Use M.weekday instead
M.get_weekday = M.weekday
---@deprecated Use M.quarter instead
M.from_to = M.range
---@deprecated Use M.range instead
M.get_dates = M.range

return M
