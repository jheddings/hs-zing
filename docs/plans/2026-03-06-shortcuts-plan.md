# Shortcuts Feature Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rename `bookmarks` to `shortcuts`, support table-format entries with optional descriptions, and handle nil returns from function shortcuts gracefully.

**Architecture:** Add a `_resolveShortcut(key)` normalization method that converts any shortcut format (string, function, table) into a canonical `{url, fn, desc}` table. All internal methods use this resolver. Backward compatibility with `bookmarks` is handled in `start()`.

**Tech Stack:** Lua, Hammerspoon, luaunit for tests

---

### Task 1: Add `_resolveShortcut` with tests

**Files:**
- Modify: `src/init.lua` (add `_resolveShortcut` method)
- Modify: `tests/test_parser.lua` (add resolve tests — this file contains the unit tests)

**Step 1: Write the failing tests**

Add to `tests/test_parser.lua` — but since `_resolveShortcut` lives in `init.lua` (which requires Hammerspoon), we need a separate unit test file. Create a new test file that tests the resolver in isolation.

Create: `tests/test_resolve.lua`

```lua
-- Unit tests for shortcut resolution

local lu = require("luaunit")

-- Minimal mock of the Zing object with _resolveShortcut
-- We'll extract _resolveShortcut as a standalone function for testability,
-- but it lives as a method on obj in init.lua. For unit testing, we replicate
-- the method here and test it directly.

-- Mock logger
local logger = {
    v = function(...) end,
    d = function(...) end,
    e = function(...) end,
    i = function(...) end,
    w = function(...) end
}

-- Load the resolve function by creating a minimal obj
local obj = { shortcuts = {}, logger = logger }

-- Copy the _resolveShortcut implementation (will be added in Step 3)
-- For now, this will fail because the function doesn't exist yet
function obj:_resolveShortcut(key)
    error("not implemented")
end

TestResolve = {}

function TestResolve:setUp()
    obj.shortcuts = {}
end

function TestResolve:testStringShortcut()
    obj.shortcuts["g"] = "https://google.com/?q=%@"
    local resolved = obj:_resolveShortcut("g")
    lu.assertNotNil(resolved)
    lu.assertEquals(resolved.url, "https://google.com/?q=%@")
    lu.assertNil(resolved.fn)
    lu.assertEquals(resolved.desc, "google.com")
end

function TestResolve:testFunctionShortcut()
    local myFn = function() return "https://example.com" end
    obj.shortcuts["cmd"] = myFn
    local resolved = obj:_resolveShortcut("cmd")
    lu.assertNotNil(resolved)
    lu.assertNil(resolved.url)
    lu.assertEquals(resolved.fn, myFn)
    lu.assertEquals(resolved.desc, "Shortcut")
end

function TestResolve:testTableWithUrl()
    obj.shortcuts["wiki"] = {
        url = "https://en.wikipedia.org/wiki/%@",
        desc = "Search Wikipedia"
    }
    local resolved = obj:_resolveShortcut("wiki")
    lu.assertNotNil(resolved)
    lu.assertEquals(resolved.url, "https://en.wikipedia.org/wiki/%@")
    lu.assertEquals(resolved.desc, "Search Wikipedia")
end

function TestResolve:testTableWithUrlDefaultDesc()
    obj.shortcuts["wiki"] = {
        url = "https://en.wikipedia.org/wiki/%@"
    }
    local resolved = obj:_resolveShortcut("wiki")
    lu.assertEquals(resolved.desc, "en.wikipedia.org")
end

function TestResolve:testTableWithFn()
    local myFn = function() end
    obj.shortcuts["term"] = {
        fn = myFn,
        desc = "Open Terminal"
    }
    local resolved = obj:_resolveShortcut("term")
    lu.assertNotNil(resolved)
    lu.assertEquals(resolved.fn, myFn)
    lu.assertEquals(resolved.desc, "Open Terminal")
end

function TestResolve:testTableWithFnDefaultDesc()
    local myFn = function() end
    obj.shortcuts["term"] = { fn = myFn }
    local resolved = obj:_resolveShortcut("term")
    lu.assertEquals(resolved.desc, "Shortcut")
end

function TestResolve:testNonExistentKey()
    local resolved = obj:_resolveShortcut("nonexistent")
    lu.assertNil(resolved)
end

os.exit(lu.LuaUnit.run())
```

**Step 2: Run tests to verify they fail**

Run: `lua tests/test_resolve.lua`
Expected: FAIL with "not implemented"

**Step 3: Implement `_resolveShortcut` in the test file**

Replace the placeholder `_resolveShortcut` in `tests/test_resolve.lua` with the real implementation:

```lua
function obj:_resolveShortcut(key)
    local entry = self.shortcuts[key]
    if entry == nil then
        return nil
    end

    local kind = type(entry)

    if kind == "string" then
        local domain = entry:match("://([^/]+)") or entry
        return { url = entry, desc = domain }
    end

    if kind == "function" then
        return { fn = entry, desc = "Shortcut" }
    end

    if kind == "table" then
        if entry.url then
            local desc = entry.desc or entry.url:match("://([^/]+)") or entry.url
            return { url = entry.url, desc = desc }
        end
        if entry.fn then
            local desc = entry.desc or "Shortcut"
            return { fn = entry.fn, desc = desc }
        end
    end

    return nil
end
```

**Step 4: Run tests to verify they pass**

Run: `lua tests/test_resolve.lua`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add tests/test_resolve.lua
git commit -m "Add unit tests and implementation for _resolveShortcut"
```

---

### Task 2: Rename bookmarks to shortcuts in init.lua

**Files:**
- Modify: `src/init.lua`

**Step 1: Rename the property and all internal methods**

In `src/init.lua`, make these changes:

1. Line 8: `BOOKMARK_PATTERN` — keep the variable name (it's internal), but update the comment
2. Line 63: `obj.bookmarks = { }` → `obj.shortcuts = { }`
3. Line 97-103: Rename `_parseBookmark` → `_parseShortcut`, change `self.bookmarks[bookmark]` → `self.shortcuts[bookmark]`
4. Line 114-117: Rename `_isBookmark` → `_isShortcut`, change internal call to `_parseShortcut`
5. Line 148-168: Rename `_handleBookmark` → `_handleShortcut`, change internal call to `_parseShortcut`
6. Line 240-256: Rename `_createBookmarkChoice` → `_createShortcutChoice`, change `self.bookmarks[key]` reference
7. Line 220: `self:_isBookmark` → `self:_isShortcut`
8. Line 221: `self:_handleBookmark` → `self:_handleShortcut`
9. Line 310: `self:_createBookmarkChoice` → `self:_createShortcutChoice`
10. Line 309: `pairs(self.bookmarks)` → `pairs(self.shortcuts)`
11. Line 371: Placeholder text: change "bookmark" to "shortcut"
12. All docstring references to "bookmark" → "shortcut"

**Step 2: Run existing tests to verify nothing broke**

Run: `make preflight`
Expected: All tests PASS (existing parser tests don't depend on init.lua)

**Step 3: Commit**

```bash
git add src/init.lua
git commit -m "Rename bookmarks to shortcuts throughout init.lua"
```

---

### Task 3: Add `_resolveShortcut` to init.lua and wire it up

**Files:**
- Modify: `src/init.lua`

**Step 1: Add the `_resolveShortcut` method to init.lua**

Add after `_isShortcut` (around line 117):

```lua
--- Zing:_resolveShortcut(key)
--- Method
--- Resolves a shortcut entry into a canonical form
---
--- Parameters:
---  * key - The shortcut key to resolve
---
--- Returns:
---  * A table with {url, fn, desc} fields, or nil if key doesn't exist
function obj:_resolveShortcut(key)
    local entry = self.shortcuts[key]
    if entry == nil then
        return nil
    end

    local kind = type(entry)

    if kind == "string" then
        local domain = entry:match("://([^/]+)") or entry
        return { url = entry, desc = domain }
    end

    if kind == "function" then
        return { fn = entry, desc = "Shortcut" }
    end

    if kind == "table" then
        if entry.url then
            local desc = entry.desc or entry.url:match("://([^/]+)") or entry.url
            return { url = entry.url, desc = desc }
        end
        if entry.fn then
            local desc = entry.desc or "Shortcut"
            return { fn = entry.fn, desc = desc }
        end
    end

    return nil
end
```

**Step 2: Update `_handleShortcut` to use `_resolveShortcut`**

Replace the body of `_handleShortcut`:

```lua
function obj:_handleShortcut(text)
    local name, rest = self:_parseShortcut(text)

    if not name then
        return nil
    end

    local shortcut = self:_resolveShortcut(name)
    if not shortcut then
        return nil
    end

    local params = hs.fnutils.split(rest, "%s+")

    if shortcut.fn then
        self.logger.d("Executing function shortcut:", name)
        return shortcut.fn(table.unpack(params))
    end

    if shortcut.url then
        self.logger.d("Processing URL shortcut:", name, "->", shortcut.url)
        return self:_processTemplate(shortcut.url, table.unpack(params))
    end

    return nil
end
```

**Step 3: Update `_createShortcutChoice` to use `_resolveShortcut`**

Replace the body of `_createShortcutChoice`:

```lua
function obj:_createShortcutChoice(key)
    local shortcut = self:_resolveShortcut(key)
    if not shortcut then
        return nil
    end

    return {
        ["text"] = key,
        ["subText"] = shortcut.desc
    }
end
```

**Step 4: Run tests**

Run: `make preflight`
Expected: PASS

**Step 5: Commit**

```bash
git add src/init.lua
git commit -m "Add _resolveShortcut and wire into handler and chooser"
```

---

### Task 4: Handle nil returns from function shortcuts

**Files:**
- Modify: `src/init.lua`

**Step 1: Update `_completionCallback`**

Replace the body of `_completionCallback`:

```lua
function obj:_completionCallback(choice)
    if not choice then
        self.logger.w("No choice selected")
        return false
    end

    local text = choice.text
    local is_shortcut = self:_isShortcut(text)
    local url = self:_handleQueryText(text)

    if url and type(url) == "string" then
        self.logger.d("Opening URL:", url)
        hs.urlevent.openURL(url)
    elseif not is_shortcut then
        hs.alert.show("Invalid query")
        return false
    end

    return true
end
```

**Step 2: Run tests**

Run: `make preflight`
Expected: PASS

**Step 3: Commit**

```bash
git add src/init.lua
git commit -m "Handle nil returns from function shortcuts gracefully"
```

---

### Task 5: Add backward compatibility for bookmarks

**Files:**
- Modify: `src/init.lua`

**Step 1: Keep `obj.bookmarks` as an empty table**

After `obj.shortcuts = { }`, add:

```lua
obj.bookmarks = { }
```

**Step 2: Add migration logic in `start()`**

At the beginning of `start()`, before `self.chooser:width(...)`:

```lua
-- Backward compatibility: migrate bookmarks to shortcuts
if next(self.bookmarks) ~= nil and next(self.shortcuts) == nil then
    self.logger.w("Zing.bookmarks is deprecated, use Zing.shortcuts instead")
    for k, v in pairs(self.bookmarks) do
        self.shortcuts[k] = v
    end
end
```

**Step 3: Run tests**

Run: `make preflight`
Expected: PASS

**Step 4: Commit**

```bash
git add src/init.lua
git commit -m "Add backward compatibility for deprecated bookmarks property"
```

---

### Task 6: Update README and bump version

**Files:**
- Modify: `README.md`
- Modify: `src/init.lua` (version bump)

**Step 1: Update version in init.lua**

Change line 19: `obj.version = "1.1"` → `obj.version = "1.2"`

**Step 2: Update README.md**

- Replace all `bookmarks` references with `shortcuts`
- Update configuration example to show both plain and table formats
- Add a note about backward compatibility
- Update the function bookmark example to show nil-return pattern

**Step 3: Run tests**

Run: `make preflight`
Expected: PASS

**Step 4: Commit**

```bash
git add src/init.lua README.md
git commit -m "Update docs and bump version to 1.2"
```

---

### Task 7: Final verification

**Step 1: Run full test suite**

Run: `make test`
Expected: All unit tests pass. Integration tests may be skipped if Hammerspoon CLI is not available.

**Step 2: Review all changes**

Run: `git log --oneline -7`
Verify 6 clean commits for the feature.

**Step 3: Build**

Run: `make build`
Expected: Spoon builds successfully into `build/Zing.spoon/`
