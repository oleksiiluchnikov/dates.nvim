-- test_dates.lua - Neovim-safe version
local dates = require("dates")

local PASSED = 0
local FAILED = 0
local tests = {}

-- Use Neovim's timer if available, fallback to os.clock
local function get_time()
	if vim and vim.loop then
		return vim.loop.hrtime() / 1e9
	else
		return os.clock()
	end
end

local function assert_eq(actual, expected, msg)
	if type(actual) == "table" and type(expected) == "table" then
		if #actual ~= #expected then
			error(string.format("%s\nExpected length %d, got %d", msg or "", #expected, #actual))
		end
		for i = 1, #actual do
			if actual[i] ~= expected[i] then
				error(
					string.format(
						"%s\nAt index %d: expected %s, got %s",
						msg or "",
						i,
						tostring(expected[i]),
						tostring(actual[i])
					)
				)
			end
		end
	elseif actual ~= expected then
		error(string.format("%s\nExpected: %s\nGot: %s", msg or "", tostring(expected), tostring(actual)))
	end
end

local function test(name, fn)
	tests[#tests + 1] = { name = name, fn = fn }
end

local function run_tests()
	print(string.format("\n🧪 Running %d tests...\n", #tests))

	for _, t in ipairs(tests) do
		local success, err = pcall(t.fn)
		if success then
			PASSED = PASSED + 1
			print(string.format("✅ %s", t.name))
		else
			FAILED = FAILED + 1
			print(string.format("❌ %s", t.name))
			print(string.format("   Error: %s", err))
		end
	end

	print(string.format("\n%s %d passed, %d failed\n", FAILED == 0 and "✅" or "❌", PASSED, FAILED))
	return FAILED == 0
end

-- Test Suite

test("is_valid: valid dates", function()
	assert_eq(dates.is_valid(2024, 1, 1), true)
	assert_eq(dates.is_valid(2024, 12, 31), true)
	assert_eq(dates.is_valid(2024, 2, 29), true)
	assert_eq(dates.is_valid(2023, 2, 28), true)
end)

test("is_valid: invalid dates", function()
	assert_eq(dates.is_valid(2024, 2, 30), false)
	assert_eq(dates.is_valid(2023, 2, 29), false)
	assert_eq(dates.is_valid(2024, 13, 1), false)
	assert_eq(dates.is_valid(2024, 0, 1), false)
	assert_eq(dates.is_valid(2024, 1, 0), false)
	assert_eq(dates.is_valid(2024, 4, 31), false)
end)

test("is_valid_string: valid strings", function()
	assert_eq(dates.is_valid_string("2024-01-01"), true)
	assert_eq(dates.is_valid_string("2024-12-31"), true)
	assert_eq(dates.is_valid_string("2024-02-29"), true)
end)

test("is_valid_string: invalid strings", function()
	assert_eq(dates.is_valid_string("2024-02-30"), false)
	assert_eq(dates.is_valid_string("not-a-date"), false)
	assert_eq(dates.is_valid_string("2024-1-1"), false)
	assert_eq(dates.is_valid_string("24-01-01"), false)
end)

test("complete: year prefix", function()
	local results = dates.complete("2024")
	assert_eq(#results, 366, "2024 is leap year")
	assert_eq(results[1], "2024-01-01")
	assert_eq(results[#results], "2024-12-31")
end)

test("complete: year-month prefix", function()
	local results = dates.complete("2024-01")
	assert_eq(#results, 31)
	assert_eq(results[1], "2024-01-01")
	assert_eq(results[#results], "2024-01-31")
end)

test("complete: year-month-day prefix", function()
	local results = dates.complete("2024-01-0")
	assert_eq(#results, 9)
	assert_eq(results[1], "2024-01-01")
	assert_eq(results[#results], "2024-01-09")

	results = dates.complete("2024-01-1")
	print(vim.inspect(results))
	assert_eq(#results, 10)
	assert_eq(results[1], "2024-01-01")
	assert_eq(results[#results], "2024-01-19")
end)

test("complete: exact date", function()
	local results = dates.complete("2024-01-01")
	assert_eq(#results, 1)
	assert_eq(results[1], "2024-01-01")
end)

test("complete: invalid prefix", function()
	assert_eq(#dates.complete(""), 0)
	assert_eq(#dates.complete("abcd"), 0)
	assert_eq(#dates.complete("2024-13"), 0)
end)

test("add_days: basic", function()
	assert_eq(dates.add_days("2024-01-01", 1), "2024-01-02")
	assert_eq(dates.add_days("2024-01-01", 31), "2024-02-01")
	assert_eq(dates.add_days("2024-01-31", 1), "2024-02-01")
	assert_eq(dates.add_days("2024-02-28", 1), "2024-02-29")
	assert_eq(dates.add_days("2023-02-28", 1), "2023-03-01")
end)

test("add_days: negative", function()
	assert_eq(dates.add_days("2024-01-02", -1), "2024-01-01")
	assert_eq(dates.add_days("2024-02-01", -1), "2024-01-31")
end)

test("subtract_days", function()
	assert_eq(dates.subtract_days("2024-01-02", 1), "2024-01-01")
	assert_eq(dates.subtract_days("2024-02-01", 1), "2024-01-31")
end)

test("add_months: basic", function()
	assert_eq(dates.add_months("2024-01-15", 1), "2024-02-15")
	assert_eq(dates.add_months("2024-01-15", 12), "2025-01-15")
	assert_eq(dates.add_months("2024-01-31", 1), "2024-02-29")
	assert_eq(dates.add_months("2024-03-31", 1), "2024-04-30")
end)

test("add_months: negative", function()
	assert_eq(dates.add_months("2024-02-15", -1), "2024-01-15")
	assert_eq(dates.add_months("2025-01-15", -12), "2024-01-15")
end)

test("subtract_months", function()
	assert_eq(dates.subtract_months("2024-02-15", 1), "2024-01-15")
	assert_eq(dates.subtract_months("2025-01-15", 12), "2024-01-15")
end)

test("add_years: basic", function()
	assert_eq(dates.add_years("2024-01-15", 1), "2025-01-15")
	assert_eq(dates.add_years("2024-02-29", 1), "2025-02-28")
	assert_eq(dates.add_years("2020-02-29", 4), "2024-02-29")
end)

test("add_years: negative", function()
	assert_eq(dates.add_years("2024-01-15", -1), "2023-01-15")
end)

test("diff_days", function()
	assert_eq(dates.diff_days("2024-01-01", "2024-01-01"), 0)
	assert_eq(dates.diff_days("2024-01-01", "2024-01-02"), 1)
	assert_eq(dates.diff_days("2024-01-01", "2024-01-31"), 30)
	assert_eq(dates.diff_days("2024-01-01", "2024-12-31"), 365)
	assert_eq(dates.diff_days("2024-01-02", "2024-01-01"), -1)
end)

test("compare", function()
	assert_eq(dates.compare("2024-01-01", "2024-01-02"), -1)
	assert_eq(dates.compare("2024-01-02", "2024-01-01"), 1)
	assert_eq(dates.compare("2024-01-01", "2024-01-01"), 0)
end)

test("is_before", function()
	assert_eq(dates.is_before("2024-01-01", "2024-01-02"), true)
	assert_eq(dates.is_before("2024-01-02", "2024-01-01"), false)
	assert_eq(dates.is_before("2024-01-01", "2024-01-01"), false)
end)

test("is_after", function()
	assert_eq(dates.is_after("2024-01-02", "2024-01-01"), true)
	assert_eq(dates.is_after("2024-01-01", "2024-01-02"), false)
	assert_eq(dates.is_after("2024-01-01", "2024-01-01"), false)
end)

test("range", function()
	local results = dates.range("2024-01-01", "2024-01-03")
	assert_eq(results, { "2024-01-01", "2024-01-02", "2024-01-03" })

	results = dates.range("2024-01-31", "2024-02-02")
	assert_eq(results, { "2024-01-31", "2024-02-01", "2024-02-02" })

	results = dates.range("2024-01-01", "2024-01-01")
	assert_eq(results, { "2024-01-01" })
end)

test("weekday", function()
	assert_eq(dates.weekday("2024-01-01"), "Monday")
	assert_eq(dates.weekday("2024-01-06"), "Saturday")
	assert_eq(dates.weekday("2024-01-07"), "Sunday")
end)

test("is_weekend", function()
	assert_eq(dates.is_weekend("2024-01-01"), false)
	assert_eq(dates.is_weekend("2024-01-06"), true)
	assert_eq(dates.is_weekend("2024-01-07"), true)
end)

test("quarter", function()
	assert_eq(dates.quarter("2024-01-15"), 1)
	assert_eq(dates.quarter("2024-04-15"), 2)
	assert_eq(dates.quarter("2024-07-15"), 3)
	assert_eq(dates.quarter("2024-10-15"), 4)
end)

test("month_name", function()
	assert_eq(dates.month_name("2024-01-15"), "January")
	assert_eq(dates.month_name("2024-12-15"), "December")
end)

test("format", function()
	assert_eq(dates.format("2024-01-15", "%d/%m/%Y"), "15/01/2024")
	assert_eq(dates.format("2024-01-15", "%B %d, %Y"), "January 15, 2024")
end)

test("iso_week", function()
	local week = dates.iso_week("2024-01-01")
	assert_eq(week, 1)
end)

test("day_of_year", function()
	assert_eq(dates.day_of_year("2024-01-01"), 1)
	assert_eq(dates.day_of_year("2024-12-31"), 366)
end)

test("start_of_month", function()
	assert_eq(dates.start_of_month("2024-01-15"), "2024-01-01")
	assert_eq(dates.start_of_month("2024-12-31"), "2024-12-01")
end)

test("end_of_month", function()
	assert_eq(dates.end_of_month("2024-01-15"), "2024-01-31")
	assert_eq(dates.end_of_month("2024-02-15"), "2024-02-29")
	assert_eq(dates.end_of_month("2023-02-15"), "2023-02-28")
end)

test("edge: leap year century rules", function()
	assert_eq(dates.is_valid(2000, 2, 29), true)
	assert_eq(dates.is_valid(1900, 2, 29), false)
	assert_eq(dates.is_valid(2100, 2, 29), false)
end)

test("edge: month boundaries", function()
	assert_eq(dates.add_days("2024-01-31", 1), "2024-02-01")
	assert_eq(dates.add_days("2024-02-29", 1), "2024-03-01")
	assert_eq(dates.add_days("2023-02-28", 1), "2023-03-01")
end)

test("edge: year boundaries", function()
	assert_eq(dates.add_days("2023-12-31", 1), "2024-01-01")
	assert_eq(dates.subtract_days("2024-01-01", 1), "2023-12-31")
end)

test("edge: large date ranges", function()
	local diff = dates.diff_days("2020-01-01", "2024-12-31")
	assert_eq(diff, 1826)
end)

test("edge: invalid inputs return nil", function()
	assert_eq(dates.add_days("invalid", 1), nil)
	assert_eq(dates.weekday("2024-02-30"), nil)
	assert_eq(dates.diff_days("invalid", "2024-01-01"), nil)
end)

-- Performance benchmarks (reduced iterations)
local function benchmark(name, fn, iterations)
	iterations = iterations or 100
	collectgarbage("collect")

	local start = get_time()
	for i = 1, iterations do
		fn()
	end
	local elapsed = get_time() - start

	local per_op = (elapsed / iterations) * 1000000
	return per_op, elapsed
end

local function run_benchmarks()
	print("\n🚀 Performance Benchmarks\n")

	local benches = {
		{
			"is_valid",
			function()
				dates.is_valid(2024, 1, 15)
			end,
			1000,
		},
		{
			"complete: full year",
			function()
				dates.complete("2024")
			end,
			100,
		},
		{
			"complete: month",
			function()
				dates.complete("2024-01")
			end,
			100,
		},
		{
			"complete: day prefix",
			function()
				dates.complete("2024-01-1")
			end,
			100,
		},
		{
			"add_days",
			function()
				dates.add_days("2024-01-15", 30)
			end,
			1000,
		},
		{
			"add_months",
			function()
				dates.add_months("2024-01-15", 3)
			end,
			1000,
		},
		{
			"diff_days",
			function()
				dates.diff_days("2024-01-01", "2024-12-31")
			end,
			1000,
		},
		{
			"range: 30 days",
			function()
				dates.range("2024-01-01", "2024-01-30")
			end,
			100,
		},
		{
			"weekday",
			function()
				dates.weekday("2024-01-15")
			end,
			1000,
		},
	}

	for _, bench in ipairs(benches) do
		local per_op, elapsed = benchmark(bench[1], bench[2], bench[3])
		print(string.format("  %-25s %.2f μs/op (%d iter, %.3fs)", bench[1], per_op, bench[3], elapsed))
	end

	print()
end

-- Run tests
local all_passed = run_tests()

-- Run benchmarks (safely)
local bench_success, bench_err = pcall(run_benchmarks)
if not bench_success then
	print("⚠️  Benchmarks failed: " .. tostring(bench_err))
end

-- Summary
if all_passed then
	print("✅ All tests passed!\n")
	if vim then
		vim.notify("All tests passed!", vim.log.levels.INFO)
	end
else
	print("❌ Some tests failed\n")
	if vim then
		vim.notify("Some tests failed!", vim.log.levels.ERROR)
	end
end
