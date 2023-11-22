------------------------------------------------------------------------
-- The midi control script sends midi cc to the selected midi channel
------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

local numControls = 1 -- Number of routers
local panelHeight = 50 -- Height of each router panel
local channels = widgets.channels()

widgets.panel({
  width = 720,
  height = panelHeight * numControls
})

local y = 18
local routers = {}
for i=1,numControls do
  widgets.setSection({
    width = 120,
    cols = 8,
    x = 12,
    y = y,
    xSpacing = 12,
    ySpacing = 5,
  })

  y = y + 24 -- Increment y pos

  local label = widgets.label("Midi CC " .. i, {
    name = "router" .. i,
    tooltip = "Edit to set a label for this router.",
    width = 240,
    alpha = 0.75,
    fontSize = 24,
    backgroundColour = "transparent",
    backgroundColourWhenEditing = "white",
    textColourWhenEditing = "black",
    textColour = "865DFF",
    editable = true
  })

  local channelOut = widgets.menu("Midi Channel", channels, {
    name = "outchannel" .. i,
    tooltip = "Midi out",
    showLabel = false,
    width = 60,
  })

  local controllerOut = widgets.numBox('CC', 101 + i, {
    name = "outcc" .. i,
    tooltip = "The midi control number to route to",
    min = 0,
    max = 127,
    integer = true,
  })

  local value = widgets.numBox('Value', 0, {
    name = "value" .. i,
    tooltip = "Send cc to the selected control number by changing this value.",
    unit = Unit.Percent,
    changed = function(self)
      local v = gem.round(gem.mapValueBetweenRanges(self.value, self.min, self.max, 0, 127))
      controlChange(controllerOut.value, v, (channelOut.value-1))
    end
  })

  local bipolar = widgets.button('Bipolar', false, {
    name = "bipolar" .. i,
    tooltip = "Set biploar mode",
    width = 60,
    changed = function(self)
      if self.value == true then
        value:setRange(-100,100)
      else
        if value.value < 0 then
          value.value = 0
        end
        value:setRange(0, 100)
      end
    end
  })

  local learn = widgets.button('L', false, {
    name = "learn" .. i,
    tooltip = "Learn controller",
    width = 24
  })

  table.insert(routers, {label=label,controllerOut=controllerOut,value=value,bipolar=bipolar,learn=learn})
end

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function flashLabel(i)
  local flashDuration = 250
  routers[i].label.textColour = "yellow"
  wait(flashDuration)
  routers[i].label.textColour = "865DFF"
end

function onController(e)
  for i,v in ipairs(routers) do
    if v.learn.value then
      v.learn:setValue(false)
      v.controllerOut:setValue(e.controller)
    end
  end
  postEvent(e)
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local labelData = {}
  for _,v in ipairs(routers) do
    table.insert(labelData, v.label.text)
  end
  return {labelData}
end

function onLoad(data)
  local labelData = data[1]
  for i,v in ipairs(routers) do
    v.label.text = labelData[i]
  end
end
