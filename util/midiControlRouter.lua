---------------------------------------------------------------------------------
-- The midi control router, routes incoming midi cc to the selected midi channel
---------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

local numRouters = 1 -- Number of routers
local panelHeight = 50 -- Height of each router panel
local channels = widgets.channels()

widgets.panel({
  width = 720,
  height = panelHeight * numRouters
})

local y = 18
local routers = {}
for i=1,numRouters do
  widgets.setSection({
    width = 90,
    x = 15,
    y = y,
    xSpacing = 5,
    ySpacing = 5,
  })

  y = y + 24 -- Increment y pos

  local label = widgets.label("Router " .. i, {
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

  local channelIn = widgets.menu("Channel In", channels, {
    name = "inchannel" .. i,
    tooltip = "Midi in",
    showLabel = false,
    width = 75,
  })

  local channelOut = widgets.menu("Channel Out", channels, {
    name = "outchannel" .. i,
    tooltip = "Midi out",
    showLabel = false,
    width = 75,
  })

  local controllerIn = widgets.numBox('CC In', 101 + i, {
    name = "incc" .. i,
    tooltip = "The midi control number to listen on",
    min = 0,
    max = 127,
    integer = true,
  })

  local controllerOut = widgets.numBox('CC Out', 101 + i, {
    name = "outcc" .. i,
    tooltip = "The midi control number to route to",
    min = 0,
    max = 127,
    integer = true,
  })

  local value = widgets.numBox('Value', 0, {
    name = "value" .. i,
    tooltip = "Shows the current value. You can send cc to the selected channel and control number by changing this value manually.",
    min = 0,
    max = 127,
    integer = true,
    changed = function(self)
      controlChange(controllerOut.value, self.value, (channelOut.value-1))
    end
  })

  table.insert(routers, {label=label,channelIn=channelIn,channelOut=channelOut,controllerIn=controllerIn,controllerOut=controllerOut,value=value})
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
    local channelIn = v.channelIn.value - 1
    local channelOut = v.channelOut.value - 1
    local isListenChannel = channelIn == 0 or channelIn == e.channel
    if e.controller == v.controllerIn.value and isListenChannel then
      if isListenChannel and e.channel ~= channelOut and channelIn ~= channelOut then
        print("Routing from channel to channel", e.channel, channelOut)
        e.channel = channel
      end
      print("Routing from controller to controller", e.controller, v.controllerOut.value)
      e.controller = v.controllerOut.value
      v.value:setValue(e.value, false)
      spawn(flashLabel, i)
      break
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
