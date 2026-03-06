-- Unit tests for the _resolveShortcut method

local lu = require("luaunit")

-- Implementation of _resolveShortcut
-- Normalizes any shortcut format into a canonical {url, fn, desc} table.
local function _resolveShortcut(obj, key)
    local entry = obj.shortcuts[key]
    if entry == nil then
        return nil
    end

    if type(entry) == "string" then
        local domain = entry:match("://([^/]+)") or entry
        return { url = entry, desc = domain }
    end

    if type(entry) == "function" then
        return { fn = entry, desc = "Shortcut" }
    end

    if type(entry) == "table" then
        local resolved = {}
        for k, v in pairs(entry) do
            resolved[k] = v
        end

        if resolved.url and not resolved.desc then
            resolved.desc = resolved.url:match("://([^/]+)") or resolved.url
        end

        if resolved.fn and not resolved.desc then
            resolved.desc = "Shortcut"
        end

        return resolved
    end

    return nil
end

-- Create a test suite
TestResolveShortcut = {}

function TestResolveShortcut:setUp()
    self.obj = {
        shortcuts = {},
        _resolveShortcut = _resolveShortcut,
    }
end

-- String shortcut resolves to {url=..., desc=domain}
function TestResolveShortcut:testStringShortcut()
    self.obj.shortcuts["g"] = "https://google.com/?q=%@"
    local result = self.obj:_resolveShortcut("g")
    lu.assertNotNil(result)
    lu.assertEquals(result.url, "https://google.com/?q=%@")
    lu.assertEquals(result.desc, "google.com")
    lu.assertNil(result.fn)
end

-- Function shortcut resolves to {fn=..., desc="Shortcut"}
function TestResolveShortcut:testFunctionShortcut()
    local fn = function() end
    self.obj.shortcuts["t"] = fn
    local result = self.obj:_resolveShortcut("t")
    lu.assertNotNil(result)
    lu.assertEquals(result.fn, fn)
    lu.assertEquals(result.desc, "Shortcut")
    lu.assertNil(result.url)
end

-- Table with url and custom desc preserves both
function TestResolveShortcut:testTableUrlWithDesc()
    self.obj.shortcuts["s"] = { url = "https://example.com/search", desc = "Search" }
    local result = self.obj:_resolveShortcut("s")
    lu.assertNotNil(result)
    lu.assertEquals(result.url, "https://example.com/search")
    lu.assertEquals(result.desc, "Search")
end

-- Table with url and no desc defaults desc to domain
function TestResolveShortcut:testTableUrlWithoutDesc()
    self.obj.shortcuts["s"] = { url = "https://example.com/search" }
    local result = self.obj:_resolveShortcut("s")
    lu.assertNotNil(result)
    lu.assertEquals(result.url, "https://example.com/search")
    lu.assertEquals(result.desc, "example.com")
end

-- Table with fn and custom desc preserves both
function TestResolveShortcut:testTableFnWithDesc()
    local fn = function() end
    self.obj.shortcuts["t"] = { fn = fn, desc = "Open Terminal" }
    local result = self.obj:_resolveShortcut("t")
    lu.assertNotNil(result)
    lu.assertEquals(result.fn, fn)
    lu.assertEquals(result.desc, "Open Terminal")
end

-- Table with fn and no desc defaults desc to "Shortcut"
function TestResolveShortcut:testTableFnWithoutDesc()
    local fn = function() end
    self.obj.shortcuts["t"] = { fn = fn }
    local result = self.obj:_resolveShortcut("t")
    lu.assertNotNil(result)
    lu.assertEquals(result.fn, fn)
    lu.assertEquals(result.desc, "Shortcut")
end

-- Non-existent key returns nil
function TestResolveShortcut:testNonExistentKey()
    local result = self.obj:_resolveShortcut("nonexistent")
    lu.assertNil(result)
end

-- Run the tests
os.exit(lu.LuaUnit.run())
