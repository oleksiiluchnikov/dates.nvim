local Dates = {}

---Check if a date is valid
---@return boolean
function Dates.is_valid(year, month, day)
	if day > 29 and month == 2 and (year % 4) == 0 then
		return false
	elseif day > 28 and month == 2 and (year % 4) ~= 0 then
		return false
	elseif day > 30 and (month == 4 or month == 6 or month == 9 or month == 11) then
		return false
	end
	return true
end

---Get all valid dates for a given year beginning
---@param year_beginning string -- like 20 or 202 or 2021
function Dates.get_dates(year_beginning)
	local date_endings = {}

	local year_ending_min, year_ending_max = 0, 99
	if #year_beginning == 2 then
		year_ending_min, year_ending_max = 0, 99
	elseif #year_beginning == 3 then
		year_ending_min, year_ending_max = 0, 9
	elseif #year_beginning == 4 then
		year_ending_min, year_ending_max = 0, 0
	end

	for year_ending = year_ending_min, year_ending_max do
		for month = 1, 12 do
			for day = 1, 31 do
				local year
				if #year_beginning == 2 then
					year = tonumber(year_beginning) * 100 + year_ending
				elseif #year_beginning == 3 then
					year = tonumber(year_beginning) * 10 + year_ending
				elseif #year_beginning == 4 then
					year = tonumber(year_beginning)
				end
				if Dates.is_valid(year, month, day) then
					local date = string.format("%04d-%02d-%02d", year, month, day)
					table.insert(date_endings, date)
				end
			end
		end
	end

	return date_endings
end

---Get date suggestions for a given prefix
---@param prefix_to_filter string -- like 202 or 19 or 20 or 2021-0 or 2021-01 or 2021-01-0 or 2021-01-01
---@return table -- like { "2021-01-01", "2021-01-02", "2021-01-03" }
function Dates.get(prefix_to_filter)
	if prefix_to_filter == nil or prefix_to_filter == "" then
		error("prefix_to_filter is nil or empty")
	end
	local dates = {}

	local endings
	if #prefix_to_filter >= 4 then
		endings = Dates.get_dates(prefix_to_filter:sub(1, 4))
	elseif #prefix_to_filter == 3 then
		endings = Dates.get_dates(prefix_to_filter:sub(1, 3))
	elseif #prefix_to_filter == 2 then
		endings = Dates.get_dates(prefix_to_filter:sub(1, 2))
	end

	-- Notice: escape the "-" in the prefix_to_filter
	local pattern = prefix_to_filter:gsub("-", "%%-")
	for _, ending in ipairs(endings) do
		if string.match(ending, "^" .. pattern) then
			table.insert(dates, ending)
		end
	end
	return dates
end

---Get the weekday of a given date
---@param date string -- like 2021-01-01
function Dates.get_weekday(date)
	local weekday = os.date(
		"%A",
		os.time({
			year = string.sub(date, 1, 4),
			month = string.sub(date, 6, 7),
			day = string.sub(date, 9, 10),
		})
	)

	return weekday
end

---Get the dates from to
---@param date_from string -- like 2023-11-01
---@param date_to string -- like 2023-11-08
function Dates.from_to(date_from, date_to)
	local dates = {}

	local intersection = ""
	for i = 1, math.min(#date_from, #date_to) do
		if date_from:sub(i, i) == date_to:sub(i, i) then
			intersection = intersection .. date_from:sub(i, i)
		else
			break
		end
	end

	local raw_dates = Dates.get(intersection)

	local date_from_index = 1
	local date_to_index = #raw_dates
	for i, raw_date in ipairs(raw_dates) do
		if raw_date == date_from then
			date_from_index = i
		end
		if raw_date == date_to then
			date_to_index = i
		end
	end

	for i = date_from_index, date_to_index do
		table.insert(dates, raw_dates[i])
	end

	return dates
end

return Dates
