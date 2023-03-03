--------------------------------------------------------------------------------
-- Velocity Sequencer
--------------------------------------------------------------------------------

local gem = require "includes.common"
local shapes = require "includes.shapes"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

local backgroundColour = "595959" -- Light or Dark
local labelTextColour = "15133C" -- Dark
local labelBackgoundColour = "66ff99" -- Light
local sliderColour = "5FB5FF"
local menuBackgroundColour = "01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "66" .. labelTextColour

widgets.setColours({
  backgroundColour = backgroundColour,
  labelTextColour = labelTextColour,
  labelBackgoundColour = labelBackgoundColour,
  sliderColour = sliderColour,
  menuBackgroundColour = menuBackgroundColour,
  menuTextColour = menuTextColour,
  menuArrowColour = menuArrowColour,
})

local isPlaying = false
local positionTable
local sequencerTable
local resolutionNames = resolutions.getResolutionNames({'Follow Input'})
local resolution = #resolutionNames
local shapeAmount = 100
local sequencerPos = 1
local channel = 0 -- 0 = Omni
local shapeMenuItems = {"Select preset..."}
for _,v in ipairs(shapes.getShapeNames()) do
  table.insert(shapeMenuItems, v)
end

local loadShape = function(shapeIndex)
  shapeIndex = shapeIndex - 1
  if shapeIndex == 0 then
    return
  end
  local values = shapes.get(shapeIndex, sequencerTable, {amount=shapeAmount})
  for i,v in ipairs(values) do
    sequencerTable:setValue(i, v)
  end
end

setBackgroundColour(backgroundColour)

widgets.panel({
  tooltip = "A sequencer that sets a velocity pattern on incoming notes",
  width = 700,
  height = 96,
  x = 10,
  y = 10,
})

local sequencerLabel = widgets.label("Velocity Sequencer", {
  editable = true,
  alpha = 0.5,
  fontSize = 22,
  width = 162,
  height = 25,
})

widgets.setSection({
  x = widgets.posSide(sequencerLabel) + 13,
  y = sequencerLabel.y,
  xSpacing = 5,
})

widgets.label("Resolution", {
  width = 63,
  backgroundColour = "transparent",
  textColour = "silver"
})

widgets.menu("Resolution", resolution, resolutionNames, {
  tooltip = "Set the resolution of the sequencer",
  width = 90,
  showLabel = false,
  changed = function(self)
    resolution = self.value
    if isPlaying and resolution == #resolutionNames then
      isPlaying = false
    end
  end
})

local shape = widgets.menu("Start Shape", shapeMenuItems, {
  tooltip = "Set how the table will look when starting.",
  width = 120,
  showLabel = false,
  changed = function(self)
    loadShape(self.value)
  end
})

widgets.numBox("Amount", shapeAmount, {
  tooltip = "Set the shape amount",
  width = 96,
  unit = Unit.Percent,
  changed = function(self)
    shapeAmount = self.value
    loadShape(shape.value)
  end
})

widgets.numBox("Steps", 8, {
  tooltip = "Set the length of velocity pattern",
  width = 78,
  min = 1,
  max = 128,
  integer = true,
  changed = function(self)
    sequencerTable.length = self.value
    positionTable.length = self.value
    if shape.value > 1 then
      loadShape(shape.value)
    end
  end
})

widgets.menu("Channel", widgets.channels(), {
  tooltip = "Only adjust the velocity for events sent on this channel",
  width = 53,
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

widgets.setSection({
  width = 700,
  x = 0,
  y = widgets.posUnder(sequencerLabel) + 5,
  xSpacing = 0,
  ySpacing = 0,
})

positionTable = widgets.table("Position", 0, 8, {
  integer = true,
  enabled = false,
  persistent = false,
  fillStyle = "solid",
  backgroundColour = "404040",
  sliderColour = "66ff99",
  height = 3,
})

widgets.setSection({
  yOffset = widgets.posUnder(positionTable),
  height = 60,
})

sequencerTable = widgets.table("Velocity", 127, 8, {
  tooltip = "Set the velocity pattern",
  showPopupDisplay = true,
  backgroundColour = "191E25",
  min = 1,
  max = 127,
  integer = true,
})

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

local function setPosition()
  print("setPosition", sequencerPos)
  for i=1,sequencerTable.length do
    local val = 0
    if i == sequencerPos then
      val = 1
    end
    positionTable:setValue(i, val)
  end
end

local function sequenceRunner()
  print("Starting sequenceRunner")
  while isPlaying do
    setPosition()
    waitBeat(resolutions.getResolution(resolution))
    if isPlaying then
      sequencerPos = gem.inc(sequencerPos, 1, sequencerTable.length)
    end
  end
end

local function startPlaying()
  if isPlaying or resolution == #resolutionNames then
    return
  end
  isPlaying = true
  run(sequenceRunner)
end

local function stopPlaying()
  isPlaying = false
  sequencerPos = 1
  for i=1,sequencerTable.length do
    positionTable:setValue(i, 0)
  end
end

local function randomizeVelocity(velocity)
  --return gem.randomizeValue(velocity, sequencerTable.min, sequencerTable.max, velocityRandomization.value)
  return velocity
end

local function getVelocity()
  local velocity = sequencerTable:getValue(sequencerPos)
  return randomizeVelocity(velocity)
end

local function isTrigger(e)
  return channel == 0 or channel == e.channel
end

function onNote(e)
  if isTrigger(e) then
    e.velocity = getVelocity()
    if resolution == #resolutionNames then
      setPosition()
      sequencerPos = gem.inc(sequencerPos, 1, sequencerTable.length)
    else
      startPlaying()
    end
  end
  postEvent(e)
end

function onTransport(start)
  if start then
    startPlaying()
  else
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  return {sequencerLabel.text}
end

function onLoad(data)
  sequencerLabel.text = data[1]
end
