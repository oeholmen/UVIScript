-------------------------------------------------------------------------------------------------------------------------------
-- This script listens to specific notes on specific midi channels and route to a midi control value using the given strategy
-------------------------------------------------------------------------------------------------------------------------------

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
    cols = 10,
    x = 12,
    y = y,
    xSpacing = 12,
    ySpacing = 5,
  })

  y = y + 24 -- Increment y pos

  local label = widgets.label("Note " .. i, {
    name = "router" .. i,
    tooltip = "Edit to set a label for this router.",
    width = 72,
    alpha = 0.75,
    fontSize = 24,
    backgroundColour = "transparent",
    backgroundColourWhenEditing = "white",
    textColourWhenEditing = "black",
    textColour = "865DFF",
    editable = true,
  })

  local channelIn = widgets.menu("Midi Channel In", channels, {
    name = "inchannel" .. i,
    tooltip = "Listen on midi in channel",
    showLabel = false,
    width = 54,
  })

  local channelOut = widgets.menu("Midi Channel Out", channels, {
    name = "outchannel" .. i,
    tooltip = "Route to midi out channel",
    showLabel = false,
    width = channelIn.width,
  })

  local noteIn = widgets.numBox('Note', i-1, {
    name = "notein" .. i,
    tooltip = "The note to listen for",
    unit = Unit.MidiKey,
    min = 0,
    max = 127,
    integer = true,
  })

  local controllerOut = widgets.numBox('CC', i-1, {
    name = "outcc" .. i,
    tooltip = "The midi control number to route to",
    min = 0,
    max = 127,
    integer = true,
  })

  local strategies = {"Toggle", "Hold"} -- TODO Add other strategies (Swipe?)
  local ccStrategy = widgets.menu("Strategy", strategies, {
    name = "ccstrategy" .. i,
    tooltip = "The strategy to use",
    showLabel = false,
    width = 60,
  })

  local valMin = widgets.numBox('Min', 0, {
    name = "valuemin" .. i,
    tooltip = "The value to send when for off",
    min = 0,
    max = 127,
    integer = true,
  })

  local valMax = widgets.numBox('Max', 127, {
    name = "valuemax" .. i,
    tooltip = "The value to send for on",
    min = 0,
    max = 127,
    integer = true,
  })

  local learn = widgets.button('L', false, {
    name = "learn" .. i,
    tooltip = "Learn controller",
    width = 24,
  })

  local isOn = false

  table.insert(routers, {label=label,controllerOut=controllerOut,channelIn=channelIn,channelOut=channelOut,noteIn=noteIn,ccStrategy=ccStrategy,valMin=valMin,valMax=valMax,learn=learn,isOn=isOn})
end

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function toggleLabel(i, on)
  if on then
    routers[i].label.textColour = "yellow"
  else
    routers[i].label.textColour = "865DFF"
  end
end

function onNote(e)
  local eventWasFound = false
  for i,v in ipairs(routers) do
    if v.learn.value then
      v.learn:setValue(false)
      v.noteIn:setValue(e.note)
    end

    local useVelocity = false -- TODO Activate to map note velocity to cc value. Param?
    local channelIn = v.channelIn.value - 1
    local isListenChannel = channelIn == 0 or channelIn == e.channel
    if e.note == v.noteIn.value and isListenChannel then
      eventWasFound = true
      if v.isOn then
        if v.ccStrategy.text == "Toggle" then
          controlChange(v.controllerOut.value, v.valMin.value, (v.channelOut.value-1))
          v.isOn = false
        end
      else
        v.isOn = true
        if useVelocity then
          controlChange(v.controllerOut.value, e.velocity, (v.channelOut.value-1))
        else
          controlChange(v.controllerOut.value, v.valMax.value, (v.channelOut.value-1))
        end
      end
      toggleLabel(i, v.isOn)
    end
  end
  if eventWasFound == false then
    postEvent(e)
  end
end

function onRelease(e)
  local eventWasFound = false
  for i,v in ipairs(routers) do
    local channelIn = v.channelIn.value - 1
    local isListenChannel = channelIn == 0 or channelIn == e.channel
    if e.note == v.noteIn.value and isListenChannel then
      eventWasFound = true
      if v.isOn then
        if v.ccStrategy.text == "Hold" then
          -- If note was held and is now released, we turn it off
          controlChange(v.controllerOut.value, v.valMin.value, (v.channelOut.value-1))
          v.isOn = false
          toggleLabel(i, false)
        end
      end
    end
  end
  if eventWasFound == false then
    postEvent(e)
  end
end

function onPolyAfterTouch(e)
  local eventWasFound = false
  for i,v in ipairs(routers) do
    local channelIn = v.channelIn.value - 1
    local isListenChannel = channelIn == 0 or channelIn == e.channel
    if e.note == v.noteIn.value and isListenChannel then
      eventWasFound = true
      -- TODO Param to disable?
      if v.isOn and v.ccStrategy.text == "Hold" then
        controlChange(v.controllerOut.value, e.value, (v.channelOut.value-1))
      end
    end
  end
  if eventWasFound == false then
    postEvent(e)
  end
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
