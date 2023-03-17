------------------------------------------------------------------
-- Cointoss - Use bias to select between two sources (channels)
------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

local channels = {1,2}
local channelWidgets = {}
local bias = 50
local bufferActive = false
local eventBuffer = {}
local bufferMs = 3

widgets.panel({
  width = 720,
  height = 50,
})

widgets.label("Cointoss", {
  width = 110,
  height = 50,
  x = 15,
  y = 0,
  alpha = 0.75,
  fontSize = 30,
  backgroundColour = "transparent",
  textColour = "865DFF"
})

widgets.setSection({
  x = 200,
  y = 5,
  width = 120,
  height = 20,
  xSpacing = 5,
  ySpacing = 5,
})

table.insert(channelWidgets, widgets.numBox('Channel A', channels[1], {
  min = 1,
  max = 16,
  y = 18,
  integer = true,
  changed = function(self) channels[1] = self.value end
}))

widgets.col(1, 60)

widgets.knob("Bias", bias, {
  unit = Unit.Percent,
  changed = function(self) bias = self.value end
})

table.insert(channelWidgets, widgets.numBox('Channel B', channels[2], {
  min = 1,
  max = 16,
  y = 18,
  integer = true,
  changed = function(self) channels[2] = self.value end
}))

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function bufferIncludesChannel(e)
  for _,v in pairs(eventBuffer) do
    if v.channel == e.channel then
      --print("Channel already included", e.channel)
      return true
    end
  end
  return false
end

local function getEventBufferIndex()
  local cointoss = gem.getRandomBoolean(bias)
  for i,v in pairs(eventBuffer) do
    if (v.channel == channels[2] and cointoss == true) or (v.channel == channels[1] and cointoss == false) then
      --print("getEventBufferIndex, channel, index, cointoss, bias", v.channel, i, cointoss, bias)
      return i
    end
  end
  return 1
end

local function shouldBuffer(e)
  return e.channel == channels[1] or e.channel == channels[2]
end

function onNote(e)
  if shouldBuffer(e) == false then
    --print("No need to buffer channel", e.channel)
    postEvent(e)
    return
  end

  -- Add to buffer, unless duplicate
  if bufferIncludesChannel(e) == false then
    table.insert(eventBuffer, e)
    --print("Added note/channel to buffer", e.note, e.channel)
  end

  if bufferActive then
    --print("Buffer active...")
    return
  else
    bufferActive = true
    --print("Start buffering")
    wait(bufferMs)
    --print("Buffering finished")
  end

  --print("#eventBuffer", #eventBuffer)
  local eventBufferIndex = getEventBufferIndex()
  for i,v in ipairs(channels) do
    if v == eventBuffer[eventBufferIndex].channel then
      channelWidgets[i].textColour = "yellow"
    else
      channelWidgets[i].textColour = widgets.getColours().widgetTextColour
    end
  end
  postEvent(eventBuffer[eventBufferIndex])

  bufferActive = false -- Reset buffer
  eventBuffer = {} -- Reset event buffer
end
