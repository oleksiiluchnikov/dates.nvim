local Dates = {}

--[[ Performance Optimizations ]]

-- Cache for days in month (avoid repeated calculations)
local DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

-- Cache for generated dates (key: year_beginning, value: dates array)
local dates_cache = {}
local MAX_CACHE_SIZE = 50 -- Prevent memory bloat

-- Pre-compute leap year check inline for speed
local function is_leap_year(year)
	return (year % 4 == 0) and (year % 100 ~= 0 or year % 400 == 0)
end

-- Fast days-in-month lookup
local function get_days_in_month(year, month)
	if month == 2 then
		return is_leap_year(year) and 29 or 28
	end
	return DAYS_IN_MONTH[month]
end

--[[ Public API - BACKWARD COMPATIBLE ]]

---Check if a date is valid
---@param year number
---@param month number
---@param day number
---@return boolean
function Dates.is_valid(year, month, day)
	-- Fast path: basic range checks
	if month < 1 or month > 12 or day < 1 then
		return false
	end

	-- Use optimized days-in-month check
	return day <= get_days_in_month(year, month)
end

---Get all valid dates for a given year beginning (OPTIMIZED + CACHED)
---@param year_beginning string -- like 20 or 202 or 2021
---@return table date_endings Array of date strings
function Dates.get_dates(year_beginning)
	-- CACHE HIT: Return cached result
	if dates_cache[year_beginning] then
		return dates_cache[year_beginning]
	end

	local date_endings = {}
	local len = #year_beginning

	-- FAST FAIL: Invalid input
	if len < 2 or len > 4 then
		return {}
	end

	-- Determine year range based on prefix length
	local year_ending_min, year_ending_max
	if len == 2 then
		year_ending_min, year_ending_max = 0, 99
	elseif len == 3 then
		year_ending_min, year_ending_max = 0, 9
	else -- len == 4
		year_ending_min, year_ending_max = 0, 0
	end

	-- Pre-calculate multipliers (avoid repeated calculations)
	local year_base = tonumber(year_beginning)
	local year_multiplier
	if len == 2 then
		year_multiplier = 100
	elseif len == 3 then
		year_multiplier = 10
	else
		year_multiplier = 1
	end

	-- OPTIMIZED LOOP: Generate only valid dates
	for year_ending = year_ending_min, year_ending_max do
		local year = year_base * year_multiplier + year_ending

		for month = 1, 12 do
			-- Get max days for this month (fast lookup)
			local max_day = get_days_in_month(year, month)

			-- Only loop through valid days (no validation needed)
			for day = 1, max_day do
				-- Use indexed insertion (faster than table.insert)
				date_endings[#date_endings + 1] = string.format("%04d-%02d-%02d", year, month, day)
			end
		end
	end

	-- CACHE RESULT: Store for future use
	if vim.tbl_count(dates_cache) >= MAX_CACHE_SIZE then
		-- Clear oldest entries (simple strategy: clear all)
		dates_cache = {}
	end
	dates_cache[year_beginning] = date_endings

	return date_endings
end

---Get date suggestions for a given prefix (OPTIMIZED)
---@param prefix_to_filter string -- like 202 or 19 or 20 or 2021-0 or 2021-01 or 2021-01-0 or 2021-01-01
---@return table dates Array of matching date strings
function Dates.get(prefix_to_filter)
	-- DEFENSIVE: Return empty table instead of error (safer for completions)
	if prefix_to_filter == nil or prefix_to_filter == "" then
		return {}
	end

	-- Extract year prefix (first 2-4 digits)
	local year_prefix_len = math.min(#prefix_to_filter, 4)
	local year_prefix = prefix_to_filter:sub(1, year_prefix_len)

	-- Get all dates for this year prefix (uses cache)
	local endings = Dates.get_dates(year_prefix)

	-- OPTIMIZATION: Early return for exact year match (no filtering needed)
	if #prefix_to_filter <= 4 then
		return endings
	end

	-- OPTIMIZED FILTERING: Use string.find instead of string.match
	local dates = {}
	local pattern = "^" .. prefix_to_filter:gsub("-", "%%-")

	for i = 1, #endings do
		local ending = endings[i]
		-- string.find is faster than string.match for simple prefix checks
		if string.find(ending, pattern) then
			dates[#dates + 1] = ending
		end
	end

	return dates
end

---Get the weekday of a given date (SAFE + OPTIMIZED)
---@param date string|table -- like "2021-01-01" or { year = 2021, month = 1, day = 1 }
---@return string|nil weekday Weekday name or nil on error
function Dates.get_weekday(date)
	local year, month, day

	-- Handle both string and table input
	if type(date) == "string" then
		-- FAST EXTRACTION: Direct substring (faster than pattern matching)
		if #date < 10 then
			return nil
		end
		year = tonumber(date:sub(1, 4))
		month = tonumber(date:sub(6, 7))
		day = tonumber(date:sub(9, 10))
	elseif type(date) == "table" then
		year = date.year
		month = date.month
		day = date.day
	else
		return nil
	end

	-- VALIDATE: Ensure we have valid numbers
	if not year or not month or not day then
		return nil
	end

	-- VALIDATE: Check date validity (prevents os.time errors)
	if not Dates.is_valid(year, month, day) then
		return nil
	end

	-- Calculate weekday (wrapped in pcall for safety)
	local ok, weekday = pcall(function()
		return os.date("%A", os.time({ year = year, month = month, day = day }))
	end)

	return ok and weekday or nil
end

---Get the dates from to (OPTIMIZED)
---@param date_from string -- like 2023-11-01
---@param date_to string -- like 2023-11-08
---@return table dates Array of dates in range
function Dates.from_to(date_from, date_to)
	-- DEFENSIVE: Validate input
	if not date_from or not date_to then
		return {}
	end

	-- OPTIMIZATION: Find common prefix efficiently
	local min_len = math.min(#date_from, #date_to)
	local intersection = ""

	for i = 1, min_len do
		local c1 = date_from:sub(i, i)
		if c1 ~= date_to:sub(i, i) then
			break
		end
		intersection = intersection .. c1
	end

	-- DEFENSIVE: Handle empty intersection (very different dates)
	if #intersection < 2 then
		return {}
	end

	-- Get all dates in range (uses cache)
	local raw_dates = Dates.get(intersection)

	-- OPTIMIZATION: Find indices with early exit
	local date_from_index = 1
	local date_to_index = #raw_dates
	local found_from = false

	for i = 1, #raw_dates do
		local raw_date = raw_dates[i]
		if not found_from and raw_date == date_from then
			date_from_index = i
			found_from = true
		end
		if raw_date == date_to then
			date_to_index = i
			break -- Early exit once we find to_date
		end
	end

	-- Extract range using indexed insertion
	local dates = {}
	for i = date_from_index, date_to_index do
		dates[#dates + 1] = raw_dates[i]
	end

	return dates
end

--[[ Cache Management (Optional - Advanced Users) ]]

---Clear the internal date cache
---@return nil
function Dates.clear_cache()
	dates_cache = {}
end

---Get cache statistics (for debugging/monitoring)
---@return table stats { entries: number, total_dates_cached: number, keys: string[] }
function Dates.get_cache_stats()
	local keys = {}
	local total_dates = 0

	for k, v in pairs(dates_cache) do
		keys[#keys + 1] = k
		total_dates = total_dates + #v
	end

	return {
		entries = #keys,
		total_dates_cached = total_dates,
		keys = keys,
	}
end

return Dates
