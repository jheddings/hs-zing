-- Integration test for Zing

hs.loadSpoon("Zing")
local zing = spoon.Zing

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
