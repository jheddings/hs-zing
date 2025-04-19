-- Unit tests for Zing

local lu = require("luaunit")

hs.loadSpoon("Zing")
local zing = spoon.Zing
local parser = zing.parser

-- Test isURL function
function testValidURLs()
    lu.assertTrue(isURL("http://example.com"))
    lu.assertTrue(isURL("https://example.com"))
    lu.assertTrue(isURL("ftp://example.com"))
    lu.assertTrue(isURL("www.example.com"))
end

function testInvalidURLs()
    lu.assertFalse(isURL("example.com"))
    lu.assertFalse(isURL("just a search query"))
    lu.assertFalse(isURL("http:example.com"))
    lu.assertFalse(isURL("https:/example.com"))
    lu.assertFalse(isURL("javascript:alert('test')"))
end

function testEmptyURLs()
    lu.assertFalse(isURL(nil))
    lu.assertFalse(isURL(""))
    lu.assertFalse(isURL(0))
end

-- Test escape characters in the template
function testEscapeCharacters()
    local singleEscape = parser:parse("%%")
    lu.assertEquals(singleEscape, "%")

    local doubleEscape = parser:parse("%%%%")
    lu.assertEquals(doubleEscape, "%%")
end

-- Basic test for multiple placeholders
function testMultiplePlaceholders()
    local url = "https://example.com/MultiplePlaceholders?q=%1&lang=%2"
    local parsedURL = parser:parse(url, "test", "en")
    lu.assertEquals(parsedURL, "https://example.com/MultiplePlaceholders?q=test&lang=en")
end

-- Test placeholder out of range
function testPlaceholderOutOfRange()
    local url = "https://example.com/PlaceholderOutOfRange?q=%1&lang=%3"
    local parsedURL = parser:parse(url, "test", "en")
    lu.assertEquals(parsedURL, "https://example.com/PlaceholderOutOfRange?q=test&lang=")
end

-- Basic URL template with all-args placeholrder
function testAllArgsTemplate()
    local url = "https://example.com/AllArgsTemplate?q=%@"
    local parsedURL = parser:parse(url, "test")
    lu.assertEquals(parsedURL, "https://example.com/AllArgsTemplate?q=test")
end

-- Verify all-args placeholder with multiple params
function testAllArgsTemplateMultipleTerms()
    local url = "https://example.com/AllArgsTemplateMultipleTerms?q=%@"
    local parsedURL = parser:parse(url, "test", "query")
    lu.assertEquals(parsedURL, "https://example.com/AllArgsTemplateMultipleTerms?q=test%20query")
end

-- Make sure template regions are removed when no params are passed
function testTemplateRegionRemoval()
    local url = "https://example.com/TemplateRegionRemoval{%?q=%@%}"
    local parsedURL = parser:parse(url)
    lu.assertEquals(parsedURL, "https://example.com/TemplateRegionRemoval")
end

-- Make sure multiple template regions are removed when no params are passed
function testMultiTemplateRegionRemoval()
    local complexUrl = "https://example.com/MultiTemplateRegionRemoval{%?q=%1%}{%&lang=%2%}"
    local parsedComplex = parser:parse(complexUrl)
    lu.assertEquals(parsedComplex, "https://example.com/MultiTemplateRegionRemoval")
end

-- Test for an empty template region with and without params
function testEmptyTemplateRegion()
    local url = "testEmptyTemplateRegion-{%%}"
    local urlNoParams = parser:parse(url)
    lu.assertEquals(urlNoParams, "testEmptyTemplateRegion-")
end

-- Test multiple template regions
function testMultipleTemplateRegions()
    local url = "https://example.com/MultipleTemplateRegions{%?q=%1%}{%&lang=%2%}"
    local parsedURL = parser:parse(url, "test", "en")
    lu.assertEquals(parsedURL, "https://example.com/MultipleTemplateRegions?q=test&lang=en")

    -- Test with no params
    local noParams = parser:parse(url)
    lu.assertEquals(noParams, "https://example.com/MultipleTemplateRegions")
end

-- Verify parameters with special characters
function testSpecialCharacters()
    local url = "https://example.com/SpecialCharacters?q=%1"
    local parsedURL = parser:parse(url, "@+#$?%^&*()=")

    -- Hammerspoon only encodes %?=&+
    lu.assertEquals(parsedURL, "https://example.com/SpecialCharacters?q=@%2B%23$%3F%25%5E%26*()%3D")
end

-- Test a multi-param template with special characters
function testMultiParamQuery()
    local url = "testMultiParamQuery/q=%@"
    local parsedURL = parser:parse(url, "project", "=", "NW")
    lu.assertEquals(parsedURL, "testMultiParamQuery/q=project%20%3D%20NW")
end

function testNilParam()
    -- XXX this is not a valid use case for Zing, but we should handle it gracefully
    local url = "https://example.com/NilParam?q=%1&lang=%2"
    local nilParam = parser:parse(url, nil, "en")
    lu.assertEquals(nilParam, "https://example.com/NilParam?q=&lang=en")
end

-- Test with UTF-8 characters
function testUTF8Characters()
    local url = "https://example.com/UTF8Characters?q=%1"
    local utf8URL = parser:parse(url, "你好")
    lu.assertEquals(utf8URL, "https://example.com/UTF8Characters?q=%E4%BD%A0%E5%A5%BD")
end

-- NOTE: we do not use os.exit() here because it would terminate the Hammerspoon process
lu.LuaUnit.run()
