# Zing

A Hammerspoon Spoon that manages bookmarks and makes searching the web snappy.

## Installation

1. Download the latest release from the releases page or build from source
2. Unzip the file (if you downloaded a release)
3. Double-click the `Zing.spoon` file to install it into your Hammerspoon Spoons directory
4. Add the following to your Hammerspoon config:

```lua
hs.loadSpoon("Zing")
spoon.Zing:bindHotkeys({
    show = {{"cmd", "alt"}, "z"} -- Customize this hotkey as desired
})
spoon.Zing:start()
```

## Usage

Zing provides a quick input interface for:
- Searching the web
- Opening bookmarked URLs with optional parameters
- Opening direct URLs

### Configuration

```lua
-- Set width of the input field (optional)
spoon.Zing.inputWidth = 30  -- Default is 20

-- Configure default search engine (optional)
spoon.Zing.searchEngine = "https://duckduckgo.com/{%?q=%@%}"  -- Default is Google

-- Configure default URL scheme (optional)
spoon.Zing.defaultScheme = "https"  -- Default is https

-- Configure bookmarks
spoon.Zing.bookmarks = {
    ["g"] = "https://google.com/{%?q=%@%}",
    ["gh"] = "https://github.com/{%search?q=%@%}",
    ["wiki"] = "https://en.wikipedia.org/wiki/{%Special:Search?search=%@%}",
    ["yt"] = "https://youtube.com/{%results?search_query=%@%}",
    ["map"] = "https://www.google.com/maps/{%?q=%@%}",
    ["translate"] = "https://translate.google.com/{%?sl=%1&tl=%2&text=%3%}",
    
    -- Example of a function-based bookmark
    ["tz"] = function(hour)
        local myTime = os.time()
        if hour and hour ~= "" then
            myTime = myTime + (tonumber(hour) * 3600)
        end
        local timestamp = os.date("!%Y%m%dT%H%M%S", myTime)
        return "https://www.timeanddate.com/worldclock/converter.html?&p1=75&p2=136&iso=" .. timestamp
    end
}
```

### Examples

1. **Direct search**: Simply type your search query and press Enter
   - This will use your configured search engine

2. **URL navigation**: Type a URL (with or without `http://` prefix) and press Enter
   - `example.com` → opens `https://example.com`
   - `http://example.org` → opens as specified

3. **Bookmark usage**: Type a bookmark name followed by parameters
   - `g hammerspoon` → searches Google for "hammerspoon"
   - `wiki lua` → searches Wikipedia for "lua"
   - `translate en es hello` → translates "hello" from English to Spanish
   - `tz 3` → shows time conversion 3 hours from now

### Template Syntax

When defining URL templates for bookmarks, you can use these placeholder patterns:

- `%@` - Replaced with all parameters joined by spaces
- `%1`, `%2`, etc. - Replaced with the parameter at that position
- `%%` - Outputs a literal % character
- `{%...%}` - Content inside braces is only included if parameters are provided

## Advanced Usage

### Logging

You can adjust the logging level for debugging:

```lua
spoon.Zing.logger.setLogLevel('debug')  -- Options: 'verbose', 'debug', 'info', 'warning', 'error'
```
