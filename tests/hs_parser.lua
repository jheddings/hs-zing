-- Integration test for Zing

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

-- Verify parameters with special characters
function testSpecialCharacters()
    local url = "https://example.com/SpecialCharacters?q=%1"
    local parsed = parser:parse(url, "@+#$?%^&*()=")

    -- Hammerspoon only encodes %?=&+
    lu.assertEquals(parsed, "https://example.com/SpecialCharacters?q=@%2B%23$%3F%25%5E%26*()%3D")
end

-- Test with UTF-8 characters
function testUTF8Characters()
    local url = "https://example.com/UTF8Characters?q=%1"
    local parsed = parser:parse(url, "你好")
    lu.assertEquals(parsed, "https://example.com/UTF8Characters?q=%E4%BD%A0%E5%A5%BD")
end

-- Test a multi-param template with special characters
function testComplexQuery()
    local url = "testMultiParamQuery/q=%@"
    local parsed = parser:parse(url, "project", "=", "NW")
    lu.assertEquals(parsed, "testMultiParamQuery/q=project%20%3D%20NW")
end
