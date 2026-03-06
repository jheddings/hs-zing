# Zing Shortcuts Design

## Summary

Expand Zing from a bookmark-only launcher into a general-purpose command palette by renaming `bookmarks` to `shortcuts`, supporting richer shortcut definitions with optional descriptions, and handling non-URL function returns gracefully.

## Motivation

Zing's `bookmarks` table already supports functions that can do anything (run commands, launch apps), but the naming and error handling assume URL-only results. Functions returning `nil` or non-URL values trigger "Invalid query" errors. Renaming to `shortcuts` better reflects the broader purpose, and fixing nil-return handling unblocks use cases like running shell commands, launching workflows, or future integrations.

## Design

### Shortcut Formats

A shortcut entry can be any of:

| Format | Example | Resolved canonical form |
|--------|---------|------------------------|
| String | `"https://google.com/{%?q=%@%}"` | `{url="https://...", desc="google.com"}` |
| Function | `function(h) ... end` | `{fn=function, desc="Shortcut"}` |
| Table with `url` | `{url="https://...", desc="Search"}` | as-is, desc defaults to domain |
| Table with `fn` | `{fn=function, desc="Open Terminal"}` | as-is, desc defaults to "Shortcut" |

### `_resolveShortcut(key)` Method

New method that normalizes any shortcut format into the canonical `{url, fn, desc}` table. Returns `nil` if the key doesn't exist. All internal methods use this instead of accessing `self.shortcuts[key]` directly.

### Nil-Return Handling

When a function shortcut returns `nil`, Zing treats it as "handled" (silent success). The function is responsible for its own side effects and user feedback.

Flow in `_completionCallback`:
```lua
local is_shortcut = self:_isShortcut(text)
local url = self:_handleQueryText(text)

if url then
    hs.urlevent.openURL(url)
elseif not is_shortcut then
    hs.alert.show("Invalid query")
end
-- else: shortcut handled itself
```

### Backward Compatibility

- `obj.bookmarks` still works
- At `start()` time, if `bookmarks` is non-empty and `shortcuts` is empty, copy bookmarks into shortcuts and log a deprecation warning
- Internal code uses `shortcuts` exclusively

### Rename Map

| Old | New |
|-----|-----|
| `obj.bookmarks` | `obj.shortcuts` |
| `_parseBookmark` | `_parseShortcut` |
| `_isBookmark` | `_isShortcut` |
| `_handleBookmark` | `_handleShortcut` |
| `_createBookmarkChoice` | `_createShortcutChoice` |

### Chooser UI

- `_createShortcutChoice` uses the resolved `desc` field as subText
- Placeholder text: "Enter URL, shortcut, or search query"

### User Config Example

```lua
zing.shortcuts = {
    ["gpt"] = "https://chatgpt.com/{%?q=%@%}",

    ["wiki"] = {
        url = "https://en.wikipedia.org/wiki/{%Special:Search?search=%@%}",
        desc = "Search Wikipedia"
    },

    ["cmd"] = {
        fn = function(...)
            local args = {...}
            local command = table.concat(args, " ")
            if command == "" then
                hs.application.launchOrFocus("Terminal")
            else
                hs.applescript('tell application "Terminal" to do script "' .. command .. '"')
                hs.application.launchOrFocus("Terminal")
            end
        end,
        desc = "Run in Terminal"
    },

    -- Plain functions still work
    ["gh"] = function(owner, repo) ... end,
}
```

### Testing

- Update existing tests to use `shortcuts` naming
- Test `_resolveShortcut` for all four input formats
- Test nil-return from function shortcuts
- Test backward compat with `bookmarks`

### Version

Bump to v1.2.
