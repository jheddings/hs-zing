--- TemplateParser
--- Class
--- Parser for handling URL template placeholders
---
--- This class handles the stateful parsing of URL templates with placeholders
local TemplateParser = {}
TemplateParser.__index = TemplateParser

-- Patterns that we use to match placeholders in a URL
local PLACEHOLDER_PERCENT = "%%%%"
local PLACEHOLDER_POSITION = "%%(%d+)"
local PLACEHOLDER_ARGS = "%%@"
local PLACEHOLDER_PARAM = "{%%([^}]*)%%}"

--- encodeParams(...)
--- Function
--- Encodes parameters for URL query, preserving the original index.
function encodeParams(...)
    local params = {}

    for idx, val in pairs({...}) do
        if val then
            params[idx] = hs.http.encodeForQuery(val)
        else
            params[idx] = ""
        end
    end

    return params
end

--- TemplateParser:new(logger)
--- Method
--- Creates a new placeholder parser instance
---
--- Parameters:
---  * logger - The logger instance to use
---
--- Returns:
---  * A new TemplateParser instance
function TemplateParser:new(logger)
    local instance = {
        logger = logger or hs.logger.new("TemplateParser", "warning"),
        replacements = {},
        markerCounter = 0
    }
    return setmetatable(instance, self)
end

--- TemplateParser:_createMarker(prefix)
--- Method
--- Creates a unique marker for placeholder replacement
---
--- Parameters:
---  * prefix - A string prefix for the marker
---
--- Returns:
---  * A unique marker string
function TemplateParser:_createMarker(prefix)
    self.markerCounter = self.markerCounter + 1
    return "__ZING_" .. self.markerCounter .. "_" .. prefix .. "__"
end

--- TemplateParser:_addReplacement(marker, value)
--- Method
--- Adds a marker and its replacement value to the internal mapping
---
--- Parameters:
---  * marker - The marker string to be replaced
---  * value - The value to replace the marker with
function TemplateParser:_addReplacement(marker, value)
    self.replacements[marker] = value
end

--- TemplateParser:parse(text, ...)
--- Method
--- Parses a template string and replaces all placeholders
---
--- Parameters:
---  * text - The template text containing placeholders
---  * ... - Variable number of parameters to use for placeholder replacement (will be URL-encoded)
---
--- Returns:
---  * The expanded text with all placeholders replaced by their values
function TemplateParser:parse(text, ...)
    if not text or type(text) ~= "string" then
        self.logger.w("Invalid template text provided")
        return text or ""
    end

    self.logger.v("Parsing template:", text)

    -- Reset state for new parsing operation
    self.replacements = {}
    self.markerCounter = 0

    -- Encode parameters for URL query
    local params = encodeParams(...)

    -- Build marker template and their replacements
    text = self:_removeTemplateMarkers(text, (#params > 0))
    text = self:_handleEscapedPercent(text)
    text = self:_handleAllArgs(text, params)
    text = self:_handlePositionalArgs(text, params)
    
    -- Apply all replacements
    return self:_applyReplacements(text)
end

--- TemplateParser:_removeTemplateMarkers(text, keep)
--- Method
--- Removes or preserves template parameter markers in the text
---
--- Parameters:
---  * text - The template text containing placeholders
---  * keep - Boolean indicating whether to preserve region content
---
--- Returns:
---  * Text with parameter markers processed according to the keep flag
function TemplateParser:_removeTemplateMarkers(text, keep)
    if keep then
        return text:gsub(PLACEHOLDER_PARAM, "%1")
    end

    return text:gsub(PLACEHOLDER_PARAM, "")
end

--- TemplateParser:_handleEscapedPercent(text)
--- Method
--- Handles escaped percent signs in the template
---
--- Parameters:
---  * text - The template text containing escaped percent signs
---
--- Returns:
---  * Text with escaped percents marked for replacement
function TemplateParser:_handleEscapedPercent(text)
    local marker = self:_createMarker("PCT")
    text = text:gsub(PLACEHOLDER_PERCENT, marker)
    self:_addReplacement(marker, "%")
    return text
end

--- TemplateParser:_handleAllArgs(text, params)
--- Method
--- Handles the %@ placeholder for all arguments
---
--- Parameters:
---  * text - The template text containing %@ placeholders
---  * params - Table of encoded parameter values
---
--- Returns:
---  * Text with all-args placeholder marked for replacement
function TemplateParser:_handleAllArgs(text, params)
    local marker = self:_createMarker("ARGS")
    text = text:gsub(PLACEHOLDER_ARGS, marker)
    self:_addReplacement(marker, table.concat(params, "%20"))
    return text
end

--- TemplateParser:_handlePositionalArgs(text, params)
--- Method
--- Handles positional placeholders like %1, %2, etc.
---
--- Parameters:
---  * text - The template text containing positional placeholders
---  * params - Table of encoded parameter values
---
--- Returns:
---  * Text with positional placeholders marked for replacement
function TemplateParser:_handlePositionalArgs(text, params)
    local parser = self
    return text:gsub(
        PLACEHOLDER_POSITION,
        function(n)
            local index = tonumber(n)
            parser.logger.v("Found placeholder:", index)
            local marker = parser:_createMarker("POS")
            
            if params[index] == nil then
                parser:_addReplacement(marker, "")
            else
                parser:_addReplacement(marker, params[index])
            end
            
            return marker
        end
    )
end

--- TemplateParser:_applyReplacements(text)
--- Method
--- Applies all accumulated replacements to the text
---
--- Parameters:
---  * text - The marked text
---
--- Returns:
---  * Text with all markers replaced by their values
function TemplateParser:_applyReplacements(text)
    self.logger.d("Rendering template:", text)
    
    for marker, value in pairs(self.replacements) do
        -- Escape % in the value to avoid pattern conflicts
        value = value:gsub("%%", "%%%%")
        text = text:gsub(marker, value)
    end
    
    return text
end

return TemplateParser
