--------------------------------------------------------------------------------
-- Functions for creating an positioning widgets
--------------------------------------------------------------------------------

local widgetNameIndex = 1

local widgetDefaults = {
  panel = nil,
  width = 100,
  height = 20,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 5,
  ySpacing = 5,
}

local widgetColours = {
  backgroundColour = "202020",
  widgetBackgroundColour = "01011F", -- Dark
  menuBackgroundColour = "01011F", -- widgetBackgroundColour
  widgetTextColour = "9f02ACFE", -- Light
  labelTextColour = "black", -- Light
  labelBackgoundColour = "CFFFFE",
  menuArrowColour = "66AEFEFF", -- labelTextColour
  menuOutlineColour = "5f9f02ACFE", -- widgetTextColour
  menuTextColour = "#9f02ACFE",
  backgroundColourOff = "ff084486",
  backgroundColourOn = "ff02ACFE",
  textColourOff = "ff22FFFF",
  textColourOn = "efFFFFFF",
}

local function getWidgetValue(value, default)
  if type(value) == "nil" then
    return default
  end
  return value
end

local function setPanel(panel)
  widgetDefaults.panel = panel
end

local function xOffset(val)
  widgetDefaults.xOffset = val
end

local function yOffset(val)
  widgetDefaults.yOffset = val
end

local function xSpacing(val)
  widgetDefaults.xSpacing = val
end

local function ySpacing(val)
  widgetDefaults.ySpacing = val
end

local function widthDefault(val)
  widgetDefaults.width = val
end

local function heightDefault(val)
  widgetDefaults.height = val
end

local function setColour(key, color)
  widgetColours[key] = color
end

local function getColour(key)
  return widgetColours[key]
end

local function posSide(widget)
  return widget.x + widget.width + widgetDefaults.xSpacing
end

local function posUnder(widget)
  return widget.y + widget.height + widgetDefaults.ySpacing
end

local function setWidgetDefaults(settings)
  widgetDefaults.width = getWidgetValue(settings.width, widgetDefaults.width)
  widgetDefaults.height = getWidgetValue(settings.height, widgetDefaults.height)
  widgetDefaults.xOffset = getWidgetValue(settings.xOffset, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getWidgetValue(settings.yOffset, widgetDefaults.yOffset)
  widgetDefaults.xSpacing = getWidgetValue(settings.xSpacing, widgetDefaults.xSpacing)
  widgetDefaults.ySpacing = getWidgetValue(settings.ySpacing, widgetDefaults.ySpacing)
end

local function getWidgetName(name)
  if type(name) == "nil" then
    name = "Widget" .. widgetNameIndex
    widgetNameIndex = widgetNameIndex + 1
  end
  return name
end

local function getWidgetX(options)
  if type(options.x) == "number" then
    return options.x
  end

  if type(options.col) == "number" then
    -- Calculate widget x position
    local col = options.col - 1
    local width = col * widgetDefaults.width
    local xSpacing = col * widgetDefaults.xSpacing
    return widgetDefaults.xOffset + width + xSpacing
  end

  return widgetDefaults.xSpacing
end

local function getWidgetY(options)
  if type(options.y) == "number" then
    return options.y
  end

  if type(options.row) == "number" then
    -- Calculate widget y position
    local row = options.row - 1
    local height = row * widgetDefaults.height
    local ySpacing = row * widgetDefaults.ySpacing
    return widgetDefaults.yOffset + height + ySpacing
  end

  return widgetDefaults.yOffset + widgetDefaults.ySpacing
end

local function getWidgetBounds(options)
  local x = getWidgetX(options)
  local y = getWidgetY(options)
  local w = getWidgetValue(options.width, widgetDefaults.width)
  local h = getWidgetValue(options.height, widgetDefaults.height)
  return {x, y, w, h}
end

local function getWidgetOptions(displayName, default, col, row, options)
  if type(default) == "table" then
    options = default
  else
    if type(options) == "nil" then
      options = {}
    end
    options.default = getWidgetValue(default, options.default)
    options.col = getWidgetValue(col, options.col)
    options.row = getWidgetValue(row, options.row)
  end
  options.name = getWidgetName(options.name)
  options.displayName = getWidgetValue(displayName, options.name)
  options.unit = getWidgetValue(options.unit, Unit.Generic)
  options.tooltip = getWidgetValue(options.tooltip, options.displayName)
  options.integer = getWidgetValue(options.integer, (unit == Unit.Percent))
  options.min = getWidgetValue(options.min, 0)
  options.default = getWidgetValue(options.default, options.min)
  if options.unit == Unit.Percent then
    options.max = getWidgetValue(options.max, 100)
  else
    options.max = getWidgetValue(options.max, 1)
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
  if type(options.showLabel) == "boolean" then
    widget.showLabel = options.showLabel
  end
  if type(options.persistent) == "boolean" then
    widget.persistent = options.persistent
  end
end

local function numBox(displayName, default, col, row, options)
  options = getWidgetOptions(displayName, default, col, row, options)
  local widget = widgetDefaults.panel:NumBox(options.name, options.default, options.min, options.max, options.integer)
  widget.displayName = options.displayName
  widget.tooltip = options.tooltip
  widget.unit = options.unit
  widget.backgroundColour = widgetColours.widgetBackgroundColour
  widget.textColour = widgetColours.widgetTextColour
  widget.bounds = getWidgetBounds(options)
  setOptional(widget, options)
  return widget
end

local function menu(displayName, default, items, col, row, options)
  options = getWidgetOptions(displayName, default, col, row, options)
  local widget = widgetDefaults.panel:Menu(options.name, items)
  widget.selected = options.default
  widget.displayName = options.displayName
  widget.tooltip = options.tooltip
  widget.backgroundColour = widgetColours.menuBackgroundColour
  widget.textColour = widgetColours.menuTextColour
  widget.arrowColour = widgetColours.menuArrowColour
  widget.outlineColour = widgetColours.menuOutlineColour
  widget.bounds = getWidgetBounds(options)
  setOptional(widget, options)
  return widget
end

local function button(displayName, default, col, row, options)
  options = getWidgetOptions(displayName, default, col, row, options)
  local widget = widgetDefaults.panel:OnOffButton(options.name, (options.default == true))
  widget.backgroundColourOff = widgetColours.backgroundColourOff
  widget.backgroundColourOn = widgetColours.backgroundColourOn
  widget.textColourOff = widgetColours.textColourOff
  widget.textColourOn = widgetColours.textColourOn
  widget.displayName = options.displayName
  widget.tooltip = options.tooltip
  widget.unit = options.unit
  widget.bounds = getWidgetBounds(options)
  setOptional(widget, options)
  return widget
end

local function label(displayName, col, row, options)
  options = getWidgetOptions(displayName, nil, col, row, options)
  local widget = widgetDefaults.panel:Label("Label")
  widget.text = options.displayName
  widget.tooltip = options.tooltip
  widget.backgroundColour = widgetColours.labelBackgoundColour
  widget.textColour = widgetColours.labelTextColour
  widget.bounds = getWidgetBounds(options)
  setOptional(widget, options)
  return widget
end

return {--widgets--
  setColour = setColour,
  getColour = getColour,
  setPanel = setPanel,
  setWidgetDefaults = setWidgetDefaults,
  xOffset = xOffset,
  yOffset = yOffset,
  xSpacing = xSpacing,
  ySpacing = ySpacing,
  widthDefault = widthDefault,
  heightDefault = heightDefault,
  posSide = posSide,
  posUnder = posUnder,
  button = button,
  label = label,
  menu = menu,
  numBox = numBox,
}
