# Zing

A Hammerspoon Spoon that manages bookmarks and makes searching the web snappy.

## Installation

1. Download the latest release from the releases page or build from source
2. Unzip the file (if you downloaded a release)
3. Double-click the `Zing.spoon` file to install it into your Hammerspoon Spoons directory
4. Add the following to your Hammerspoon config:

```lua
hs.loadSpoon("Zing")

-- Bind a hotkey to show the Zing interface
spoon.Zing:bindHotKey({"ctrl", "cmd", "alt"}, "space")

-- Start the Zing service
spoon.Zing:start()
```

## Usage

Zing provides a quick input interface for:
- Searching the web
- Opening bookmarked URLs with optional parameters
- Opening direct URLs

### Configuration

```lua
-- Set width of the input field (optional; default - 20)
spoon.Zing.inputWidth = 30

-- Configure default search engine (optional; default - Google)
spoon.Zing.searchEngine = "https://duckduckgo.com/{%?q=%@%}"

-- Configure default URL scheme (optional; default - https)
spoon.Zing.defaultScheme = "https"

-- Configure bookmarks
spoon.Zing.bookmarks = {
    ["g"] = "https://google.com/{%?q=%@%}",
    ["gh"] = "https://github.com/{%%1/%2%}",
    ["wiki"] = "https://en.wikipedia.org/wiki/{%Special:Search?search=%@%}",
    ["yt"] = "https://youtube.com/{%results?search_query=%@%}",
    ["map"] = "https://www.google.com/maps/{%?q=%@%}",
    
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

### Query

1. **Direct search**: Simply type your search query and press Enter
   - This will use your configured search engine

2. **URL navigation**: Type a URL (with or without `http://` prefix) and press Enter
   - `www.example.com` → opens `https://example.com`
   - `http://example.org` → opens as specified

3. **Bookmark usage**: Type a bookmark name followed by parameters
   - `g hammerspoon` → searches Google for "hammerspoon"
   - `gh jheddings hs-zing` → go to `jheddings hs-zing` repo on GitHub
   - `wiki lua` → searches Wikipedia for "lua"
   - `tz 3` → shows time conversion 3 hours from now

_NOTE_ if no parameters are specified, the template regions will be removed and the
bookmark will open as normal.

### Template Syntax

When defining URL templates for bookmarks, you can use these placeholder patterns:

- `%@` - Replaced with all parameters joined by spaces
- `%1`, `%2`, etc. - Replaced with the parameter at that position
- `%%` - Outputs a literal % character
- `{%...%}` - Content inside braces is only included if parameters are provided

## Advanced Usage

```lua
-- Change the log level for additional feedback
spoon.Zing.logger.setLogLevel('debug')
```

### API Methods

```lua
-- Initialize the Zing chooser
spoon.Zing:init()

-- Start Zing and enable hotkeys
spoon.Zing:start()

-- Stop Zing and disable hotkeys
spoon.Zing:stop()

-- Show the Zing chooser interface
spoon.Zing:show()

-- Bind a hotkey to show the Zing interface
spoon.Zing:bind({"ctrl", "cmd", "alt"}, "space")
```

## Development

### Building from Source

1. Clone the repository
2. Run make build to build the Spoon
3. The built Spoon will be available in the build directory


### Running Tests

```shell
# Run basic checks
make preflight

# Run all tests
make test
```
