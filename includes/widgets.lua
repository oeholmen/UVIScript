--------------------------------------------------------------------------------
-- Functions for creating an positioning widgets
--------------------------------------------------------------------------------

local panelNameIndex = 1
local widgetNameIndex = 1
local currentX = 0
local currentY = 0

local widgetDefaults = {
  panel = Panel("DefaultPanel"),
  width = 120,
  height = 20,
  menuHeight = 45,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
  col = 0,
  row = 0,
  cols = 6
}

local widgetColours = {
  backgroundColour = "202020",
  widgetBackgroundColour = "01011F", -- Dark
  menuBackgroundColour = "01011F", -- widgetBackgroundColour
  widgetTextColour = "9f02ACFE", -- Light
  tableBackgroundColour = "191E25",
  sliderColour = "5FB5FF", -- Table slider colour
  labelTextColour = "black", -- Light
  labelBackgroundColour = "CFFFFE",
  menuArrowColour = "66AEFEFF", -- labelTextColour
  menuOutlineColour = "5f9f02ACFE", -- widgetTextColour
  menuTextColour = "9f02ACFE",
  backgroundColourOff = "ff084486",
  backgroundColourOn = "ff02ACFE",
  textColourOff = "ff22FFFF",
  textColourOn = "efFFFFFF",
}

local function getValueOrDefault(value, default)
  if type(value) == "nil" then
    return default
  end
  return value
end

local function setColours(colours)
  widgetColours.backgroundColour = getValueOrDefault(colours.backgroundColour, widgetColours.backgroundColour)
  widgetColours.widgetBackgroundColour = getValueOrDefault(colours.widgetBackgroundColour, widgetColours.widgetBackgroundColour)
  widgetColours.menuBackgroundColour = getValueOrDefault(colours.menuBackgroundColour, widgetColours.menuBackgroundColour)
  widgetColours.widgetTextColour = getValueOrDefault(colours.widgetTextColour, widgetColours.widgetTextColour)
  widgetColours.tableBackgroundColour = getValueOrDefault(colours.tableBackgroundColour, widgetColours.tableBackgroundColour)
  widgetColours.sliderColour = getValueOrDefault(colours.sliderColour, widgetColours.sliderColour)
  widgetColours.labelTextColour = getValueOrDefault(colours.labelTextColour, widgetColours.labelTextColour)
  widgetColours.labelBackgroundColour = getValueOrDefault(colours.labelBackgroundColour, widgetColours.labelBackgroundColour)
  widgetColours.menuArrowColour = getValueOrDefault(colours.menuArrowColour, widgetColours.menuArrowColour)
  widgetColours.menuOutlineColour = getValueOrDefault(colours.menuOutlineColour, widgetColours.menuOutlineColour)
  widgetColours.menuTextColour = getValueOrDefault(colours.menuTextColour, widgetColours.menuTextColour)
  widgetColours.backgroundColourOff = getValueOrDefault(colours.backgroundColourOff, widgetColours.backgroundColourOff)
  widgetColours.backgroundColourOn = getValueOrDefault(colours.backgroundColourOn, widgetColours.backgroundColourOn)
  widgetColours.textColourOff = getValueOrDefault(colours.textColourOff, widgetColours.textColourOff)
  widgetColours.textColourOn = getValueOrDefault(colours.textColourOn, widgetColours.textColourOn)
end

local function setSection(settings)
  if type(settings) ~= "table" then
    settings = {}
  end
  widgetDefaults.width = getValueOrDefault(settings.width, widgetDefaults.width)
  widgetDefaults.height = getValueOrDefault(settings.height, widgetDefaults.height)
  widgetDefaults.menuHeight = getValueOrDefault(settings.menuHeight, widgetDefaults.menuHeight)
  widgetDefaults.xOffset = getValueOrDefault(settings.xOffset, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getValueOrDefault(settings.yOffset, widgetDefaults.yOffset)
  widgetDefaults.xOffset = getValueOrDefault(settings.x, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getValueOrDefault(settings.y, widgetDefaults.yOffset)
  widgetDefaults.xSpacing = getValueOrDefault(settings.xSpacing, widgetDefaults.xSpacing)
  widgetDefaults.ySpacing = getValueOrDefault(settings.ySpacing, widgetDefaults.ySpacing)
  widgetDefaults.cols = getValueOrDefault(settings.cols, widgetDefaults.cols)
  widgetDefaults.col = getValueOrDefault(settings.col, 0)
  widgetDefaults.row = getValueOrDefault(settings.row, 0)
  setColours(settings)
  currentX = widgetDefaults.xOffset
  currentY = widgetDefaults.yOffset
end

local function getWidgetName(name, displayName, useDisplayNameAsWidgetName, panel)
  if panel then
    name = getValueOrDefault(name, "Panel" .. panelNameIndex)
    panelNameIndex = panelNameIndex + 1
  elseif type(name) == "nil" then
    name = ""
    if useDisplayNameAsWidgetName and type(displayName) == "string" then
      name = string.gsub(displayName, "[^a-zA-Z]+", "")
    end
    if string.len(name) == 0 then
      name = "Widget" .. widgetNameIndex
      widgetNameIndex = widgetNameIndex + 1
    end
  end
  --print("Widget name", name)
  return name
end

local function incrementRow(row, h)
  if type(row) == "nil" then
    row = 1
  end
  if type(h) == "nil" then
    h = widgetDefaults.height
  end
  widgetDefaults.row = widgetDefaults.row + row
  widgetDefaults.col = 0
  currentX = widgetDefaults.xOffset

  local height = math.max(1, row) * h
  local ySpacing = math.max(1, row) * widgetDefaults.ySpacing
  currentY = currentY + height + ySpacing
end

local function incrementCol(col, w, h)
  if type(col) == "nil" then
    col = 1
  end
  if type(w) == "nil" then
    w = widgetDefaults.width
  end

  local width = math.max(1, col) * w
  local xSpacing = math.max(1, col) * widgetDefaults.xSpacing
  currentX = currentX + width + xSpacing

  widgetDefaults.col = widgetDefaults.col + col
  if widgetDefaults.col >= widgetDefaults.cols then
    incrementRow(1, h)
  end
end

local function getWidgetBounds(options, increment)
  local x = getValueOrDefault(options.x, currentX)
  local y = getValueOrDefault(options.y, currentY)
  local w = getValueOrDefault(options.width, widgetDefaults.width)
  local h = getValueOrDefault(options.height, widgetDefaults.height)

  -- Increment position
  if increment then
    if type(options.increment) == "boolean" then
      if options.increment then
        options.increment = 1
      else
        options.increment = 0
      end
    end
    local i = getValueOrDefault(options.increment, 1)
    incrementCol(i, w, h)
  end

  return {x, y, w, h}
end

local function getWidgetOptions(options, displayName, default, panel)
  if type(options) ~= "table" then
    options = {}
  end
  options.default = getValueOrDefault(default, options.default)
  options.name = getWidgetName(options.name, displayName, type(default) ~= "nil", panel)
  options.displayName = getValueOrDefault(displayName, options.name)
  options.tooltip = getValueOrDefault(options.tooltip, options.displayName)
  options.integer = getValueOrDefault(options.integer, (options.unit == Unit.Percent or options.unit == Unit.MidiKey))
  options.min = getValueOrDefault(options.min, 0)
  options.default = getValueOrDefault(options.default, options.min)
  if options.unit == Unit.MidiKey then
    options.max = getValueOrDefault(options.max, 127)
  elseif options.unit == Unit.Percent then
    options.max = getValueOrDefault(options.max, 100)
  else
    options.max = getValueOrDefault(options.max, 1)
  end
  return options
end

local function setOptional(widget, options)
  if type(options.changed) == "function" then
    widget.changed = options.changed
  end
  if type(options.alpha) == "number" then
    widget.alpha = options.alpha
  end
  if type(options.fontSize) == "number" then
    widget.fontSize = options.fontSize
  end
  if type(options.unit) == "number" then
    widget.unit = options.unit
  end
  if type(options.mapper) == "number" then
    widget.mapper = options.mapper
  end
  if type(options.showLabel) == "boolean" then
    widget.showLabel = options.showLabel
  end
  if type(options.persistent) == "boolean" then
    widget.persistent = options.persistent
  end
  if type(options.enabled) == "boolean" then
    widget.enabled = options.enabled
  end
  if type(options.showPopupDisplay) == "boolean" then
    widget.showPopupDisplay = options.showPopupDisplay
  end
  if type(options.hierarchical) == "boolean" then
    widget.hierarchical = options.hierarchical
  end
  if type(options.editable) == "boolean" then
    widget.editable = options.editable
  end
  if type(options.visible) == "boolean" then
    widget.visible = options.visible
  end
  if type(options.backgroundColour) == "string" then
    widget.backgroundColour = options.backgroundColour
  end
  if type(options.fillStyle) == "string" then
    widget.fillStyle = options.fillStyle
  end
  if type(options.sliderColour) == "string" then
    widget.sliderColour = options.sliderColour
  end
  if type(options.backgroundColourWhenEditing) == "string" then
    widget.backgroundColourWhenEditing = options.backgroundColourWhenEditing
  end
  if type(options.textColourWhenEditing) == "string" then
    widget.textColourWhenEditing = options.textColourWhenEditing
  end
  if type(options.textColour) == "string" then
    widget.textColour = options.textColour
  end
  if type(options.backgroundColourOff) == "string" then
    widget.backgroundColourOff = options.backgroundColourOff
  end
  if type(options.backgroundColourOn) == "string" then
    widget.backgroundColourOn = options.backgroundColourOn
  end
  if type(options.textColourOff) == "string" then
    widget.textColourOff = options.textColourOff
  end
  if type(options.textColourOn) == "string" then
    widget.textColourOn = options.textColourOn
  end
end

return {--widgets--
  setColours = setColours,
  setSection = setSection,
  channels = function()
    local channels = {"Omni"}
    for j=1,16 do
      table.insert(channels, "" .. j)
    end
    return channels
  end,
  getColours = function() return widgetColours end,
  getPanel = function() return widgetDefaults.panel end,
  getSectionValue = function(k) return widgetDefaults[k] end,
  xOffset = function(val) widgetDefaults.xOffset = val end,
  yOffset = function(val) widgetDefaults.yOffset = val end,
  x = function(val) widgetDefaults.xOffset = val end,
  y = function(val) widgetDefaults.yOffset = val end,
  xSpacing = function(val) widgetDefaults.xSpacing = val end,
  ySpacing = function(val) widgetDefaults.ySpacing = val end,
  posSide = function(widget) return widget.x + widget.width + widgetDefaults.xSpacing end,
  posUnder = function(widget) return widget.y + widget.height + widgetDefaults.ySpacing end,
  width = function(val) widgetDefaults.width = val end,
  height = function(val) widgetDefaults.height = val end,
  col = function(i, w, h) incrementCol(i, w, h) end,
  row = function(i, h) incrementRow(i, h) end,
  panel = function(options)
    if type(options) ~= "table" then
      options = {}
    end
    -- The first time, we use the default panel
    local create = panelNameIndex > 1
    if create == false then
      options.name = widgetDefaults.panel.name
    end
    options = getWidgetOptions(options, nil, nil, true)
    if create then
      widgetDefaults.panel = Panel(options.name)
      --print("Created panel", options.name)
    end
    widgetDefaults.panel.backgroundColour = widgetColours.backgroundColour
    widgetDefaults.panel.bounds = getWidgetBounds(options, false)
    setOptional(widgetDefaults.panel, options)
    return widgetDefaults.panel
  end,
  button = function(displayName, default, options)
    local isOnOff = true
    if type(default) == "table" then
      options = default
      default = nil
      isOnOff = false
    end
    options = getWidgetOptions(options, displayName, default)
    local widget
    if isOnOff then
      widget = widgetDefaults.panel:OnOffButton(options.name, (options.default == true))
    else
      widget = widgetDefaults.panel:Button(options.name)
    end
    widget.backgroundColourOff = widgetColours.backgroundColourOff
    widget.backgroundColourOn = widgetColours.backgroundColourOn
    widget.textColourOff = widgetColours.textColourOff
    widget.textColourOn = widgetColours.textColourOn
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  label = function(displayName, options)
    options = getWidgetOptions(options, displayName)
    local widget = widgetDefaults.panel:Label("Label")
    widget.text = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.labelBackgroundColour
    widget.textColour = widgetColours.labelTextColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  menu = function(displayName, default, items, options)
    if type(default) == "table" then
      options = items
      items = default
      default = 1
    end
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:Menu(options.name, items)
    widget.selected = options.default
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.menuBackgroundColour
    widget.textColour = widgetColours.menuTextColour
    widget.arrowColour = widgetColours.menuArrowColour
    widget.outlineColour = widgetColours.menuOutlineColour
    setOptional(widget, options)
    if widget.showLabel == true then
      options.height = getValueOrDefault(options.height, widgetDefaults.menuHeight)
    end
    widget.bounds = getWidgetBounds(options, true)
    return widget
  end,
  numBox = function(displayName, default, options)
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:NumBox(options.name, options.default, options.min, options.max, options.integer)
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.widgetBackgroundColour
    widget.textColour = widgetColours.widgetTextColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  table = function(displayName, default, size, options)
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:Table(options.name, size, options.default, options.min, options.max, options.integer)
    widget.fillStyle = "solid"
    widget.backgroundColour = widgetColours.tableBackgroundColour
    widget.sliderColour = widgetColours.sliderColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
}
