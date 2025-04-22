-- Unit tests for the parser module
 
local lu = require("luaunit")
local TemplateParser = require("src.parser")

-- Mock required dependencies
--
-- NOTE: do not rely on this mock for test cases that require real hs modules
_G.hs = {
    http = {
        encodeForQuery = function(str) return str end
    },
}

-- Mock the logger
local logger = {
    v = function(...) end,
    d = function(...) end,
    e = function(...) end,
    i = function(...) end,
    w = function(...) end
}

-- Create a test suite
TestParser = {}

-- Set up the test environment before each test
function TestParser:setUp()
    self.parser = TemplateParser:new(logger)
end

-- Test escape characters in the template
function TestParser:testEscapeCharacters()
    local singleEscape = self.parser:parse("%%")
    lu.assertEquals(singleEscape, "%")

    local doubleEscape = self.parser:parse("%%%%")
    lu.assertEquals(doubleEscape, "%%")
end

-- Basic test for multiple placeholders
function TestParser:testMultiplePlaceholders()
    local url = "https://example.com/MultiplePlaceholders?q=%1&lang=%2"
    local parsed = self.parser:parse(url, "test", "en")
    lu.assertEquals(parsed, "https://example.com/MultiplePlaceholders?q=test&lang=en")
end

-- Test placeholder out of range
function TestParser:testPlaceholderOutOfRange()
    local url = "https://example.com/PlaceholderOutOfRange?q=%1&lang=%3"
    local parsed = self.parser:parse(url, "test", "en")
    lu.assertEquals(parsed, "https://example.com/PlaceholderOutOfRange?q=test&lang=")
end

-- Basic URL template with all-args placeholder
function TestParser:testAllArgsTemplate()
    local url = "https://example.com/AllArgsTemplate?q=%@"
    local parsed = self.parser:parse(url, "test")
    lu.assertEquals(parsed, "https://example.com/AllArgsTemplate?q=test")
end

-- Verify all-args placeholder with multiple params
function TestParser:testAllArgsTemplateMultipleTerms()
    local url = "https://example.com/AllArgsTemplateMultipleTerms?q=%@"
    local parsed = self.parser:parse(url, "test", "query")
    lu.assertEquals(parsed, "https://example.com/AllArgsTemplateMultipleTerms?q=test%20query")
end

-- Make sure template regions are removed when no params are passed
function TestParser:testTemplateRegionRemoval()
    local url = "https://example.com/TemplateRegionRemoval{%?q=%@%}"
    local parsed = self.parser:parse(url)
    lu.assertEquals(parsed, "https://example.com/TemplateRegionRemoval")
end

-- Make sure multiple template regions are removed when no params are passed
function TestParser:testMultiTemplateRegionRemoval()
    local url = "https://example.com/MultiTemplateRegionRemoval{%?q=%1%}{%&lang=%2%}"
    local parsed = self.parser:parse(url)
    lu.assertEquals(parsed, "https://example.com/MultiTemplateRegionRemoval")
end

-- Test for an empty template region with and without params
function TestParser:testEmptyTemplateRegion()
    local url = "testEmptyTemplateRegion-{%%}"
    local parsed = self.parser:parse(url)
    lu.assertEquals(parsed, "testEmptyTemplateRegion-")
end

-- Test multiple template regions
function TestParser:testMultipleTemplateRegions()
    local url = "https://example.com/MultipleTemplateRegions{%?q=%1%}{%&lang=%2%}"

    local parsed = self.parser:parse(url, "test", "en")
    lu.assertEquals(parsed, "https://example.com/MultipleTemplateRegions?q=test&lang=en")

    -- Test with no params
    local noParams = self.parser:parse(url)
    lu.assertEquals(noParams, "https://example.com/MultipleTemplateRegions")
end

-- Test a multi-param template with special characters
function TestParser:testMultiParamQuery()
    local url = "testMultiParamQuery/q=%@"
    local parsed = self.parser:parse(url, "project", "NW")
    lu.assertEquals(parsed, "testMultiParamQuery/q=project%20NW")
end

function TestParser:testNilParam()
    -- XXX this is not a valid use case for Zing, but we should handle it gracefully
    local url = "https://example.com/NilParam?q=%1&lang=%2"
    local parsed = self.parser:parse(url, nil, "en")
    lu.assertEquals(parsed, "https://example.com/NilParam?q=&lang=en")
end

-- Run the tests
os.exit(lu.LuaUnit.run())
