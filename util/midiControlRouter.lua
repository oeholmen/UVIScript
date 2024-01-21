---------------------------------------------------------------------------------
-- The midi control router, routes incoming midi cc to the selected midi channel
---------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

local numRouters = 1 -- Number of routers
local panelHeight = 24 -- Height of each router panel
local channels = widgets.channels()

widgets.panel({
  width = 720,
  height = panelHeight + (panelHeight * numRouters)
})

local y = 18
local routers = {}
for i=1,numRouters do
  widgets.setSection({
    width = 84,
    cols = 8,
    x = 15,
    y = y,
    xSpacing = 5,
    ySpacing = 5,
  })

  y = y + 24 -- Increment y pos

  local label = widgets.label("Router " .. i, {
    name = "router" .. i,
    tooltip = "Edit to set a label for this router.",
    width = 200,
    alpha = 0.75,
    fontSize = 24,
    backgroundColour = "transparent",
    backgroundColourWhenEditing = "white",
    textColourWhenEditing = "black",
    textColour = "865DFF",
    editable = true
  })

  local channelIn = widgets.menu("Channel In", channels, {
    name = "inchannel" .. i,
    tooltip = "Listen on midi in channel",
    showLabel = false,
    width = 54,
  })

  local channelOut = widgets.menu("Channel Out", channels, {
    name = "outchannel" .. i,
    tooltip = "Route to midi out channel",
    showLabel = false,
    width = channelIn.width,
  })

  local controllerIn = widgets.numBox('CC In', i-1, {
    name = "incc" .. i,
    tooltip = "Listen on midi control number",
    min = 0,
    max = 127,
    integer = true,
  })

  local controllerOut = widgets.numBox('CC Out', i-1, {
    name = "outcc" .. i,
    tooltip = "Route to midi control number",
    min = 0,
    max = 127,
    integer = true,
    enabled = false,
  })

  widgets.button('Route CC Out', false, {
    name = "mapoutcc" .. i,
    tooltip = "Toggle midi cc out routing",
    min = 0,
    max = 127,
    integer = true,
    width = 75,
    changed = function(self)
      controllerOut.enabled = self.value
    end
  })

  local value = widgets.numBox('Value', 0, {
    name = "value" .. i,
    tooltip = "Shows the current value. You can send cc to the selected channel and control number by changing this value manually.",
    min = 0,
    max = 127,
    integer = true,
    changed = function(self)
      local ccValue = controllerIn.value
      if controllerOut.enabled then
        ccValue = controllerOut.value
      end
      controlChange(ccValue, self.value, (channelOut.value-1))
    end
  })

  local learn = widgets.button('L', false, {
    name = "learn" .. i,
    tooltip = "Learn controller in",
    width = 24
  })

  table.insert(routers, {label=label,channelIn=channelIn,channelOut=channelOut,controllerIn=controllerIn,controllerOut=controllerOut,value=value,learn=learn})
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
  local ccWasSent = false
  for i,v in ipairs(routers) do
    if v.learn.value then
      v.learn:setValue(false)
      v.controllerIn:setValue(e.controller)
    end
    local channelIn = v.channelIn.value - 1
    local isListenChannel = channelIn == 0 or channelIn == e.channel
    if e.controller == v.controllerIn.value and isListenChannel then
      v.value:setValue(e.value) -- This triggers changed event that sends the cc value
      spawn(flashLabel, i)
      ccWasSent = true
    end
  end
  if ccWasSent == false then
    postEvent(e)
  end
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
