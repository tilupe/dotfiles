local M = {}

---@class DateObject
---@field year string 4-digit year (e.g., "2023")
---@field month string Month (01-12)
---@field day string Day (01-31)
---@field hour string Hour (00-23)
---@field min string Minute (00-59)
---@field sec string Second (00-59)
---@field as_datetime function(self:DateObject):string Returns formatted date-time string (YYYY-MM-DD HH:MM:SS)
---@field as_id function(self:DateObject):string Returns condensed date-time identifier (YYYYMMDDHHMMSS)
---@field as_title function(self:DateObject):string Returns formatted date-time for title (YYYY-MM-DD_HH)
---@field as_file_name function(self:DateObject):string Returns formatted date-time for file names (YYYY_MM_DD_HH_MM_SS)
---@return DateObject date object with formatted time methods

---@return DateObject
function M.get_date_object()
  local date = {
    year = os.date '%Y',
    month = os.date '%m',
    day = os.date '%d',
    hour = os.date '%H',
    min = os.date '%M',
    sec = os.date '%S',
  }

  -- Method to format as datetime string
  function date:as_datetime()
    return self.year .. '-' .. self.month .. '-' .. self.day .. ' ' .. self.hour .. ':' .. self.min .. ':' .. self.sec
  end

  -- Method to format as ID
  function date:as_id()
    return self.year .. self.month .. self.day .. self.hour .. self.min .. self.sec
  end

  -- Method to format as title
  function date:as_title()
    return self.year .. '-' .. self.month .. '-' .. self.day .. '_' .. self.hour
  end

  function date:as_file_name()
    return self.year .. '_' .. self.month .. '_' .. self.day .. '_' .. self.hour .. '_' .. self.min .. '_' .. self.sec
  end

  return date
end

return M
