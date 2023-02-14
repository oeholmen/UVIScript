--------------------------------------------------------------------------------
-- Velocity Sequencer
--------------------------------------------------------------------------------

local gem = require "includes.common"

local backgroundColour = "595959" -- Light or Dark
local labelTextColour = "15133C" -- Dark
local labelBackgoundColour = "66ff99" -- Light
local sliderColour = "5FB5FF"
local menuBackgroundColour = "01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "66" .. labelTextColour

local velocityPos = 1
local velocity = 90
local channels = {"Omni"}
for j=1,16 do
  table.insert(channels, "" .. j)
end

setBackgroundColour(backgroundColour)

local panel = Panel("VelocitySequencer")
panel.tooltip = "A sequencer that sets a velocity pattern on incoming notes"
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 100

local label = panel:Label("Label")
label.text = "Velocity Sequencer"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {162,25}
label.y = 0
label.x = 0

local positionTable = panel:Table("Position", 8, 0, 0, 1, true)
positionTable.enabled = false
positionTable.persistent = false
positionTable.fillStyle = "solid"
positionTable.sliderColour = labelBackgoundColour
positionTable.width = panel.width
positionTable.height = 3
positionTable.x = 5
positionTable.y = label.y + label.height + 10

local seqVelTable = panel:Table("Velocity", 8, velocity, 1, 127, true)
seqVelTable.tooltip = "Set the velocity pattern"
seqVelTable.showPopupDisplay = true
seqVelTable.fillStyle = "solid"
seqVelTable.sliderColour = sliderColour
seqVelTable.width = positionTable.width
seqVelTable.height = 60
seqVelTable.x = positionTable.x
seqVelTable.y = positionTable.y + positionTable.height + 1

local channelInput = panel:Menu("ChannelInput", channels)
channelInput.displayName = "Channel"
channelInput.showLabel = false
channelInput.tooltip = "Only adjust the velocity in this channel"
channelInput.arrowColour = menuArrowColour
channelInput.backgroundColour = menuBackgroundColour
channelInput.textColour = menuTextColour
channelInput.width = 60
channelInput.height = 20
channelInput.x = label.x + label.width + 165
channelInput.y = label.y + 5

local velocityTableLength = panel:NumBox("VelocityTableLength", 8, 1, 128, true)
velocityTableLength.displayName = "Pattern Length"
velocityTableLength.tooltip = "Length of velocity pattern table"
velocityTableLength.width = 150
velocityTableLength.height = channelInput.height
velocityTableLength.x = channelInput.x + channelInput.width + 5
velocityTableLength.y = channelInput.y
velocityTableLength.backgroundColour = menuBackgroundColour
velocityTableLength.textColour = menuTextColour
velocityTableLength.changed = function(self)
  seqVelTable.length = self.value
  positionTable.length = self.value
end

local velocityRandomization = panel:NumBox("VelocityRandomization", 15, 0, 100, true)
velocityRandomization.unit = Unit.Percent
velocityRandomization.displayName = "Randomization"
velocityRandomization.tooltip = "Amount of radomization applied to the velocity"
velocityRandomization.width = velocityTableLength.width
velocityRandomization.height = velocityTableLength.height
velocityRandomization.x = velocityTableLength.x + velocityTableLength.width + 5
velocityRandomization.y = velocityTableLength.y
velocityRandomization.backgroundColour = menuBackgroundColour
velocityRandomization.textColour = menuTextColour

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

local function getVelocity(pos)
  return seqVelTable:getValue(pos), gem.inc(pos, 1, seqVelTable.length)
end

local function randomizeVelocity(velocity)
  return gem.randomizeValue(velocity, seqVelTable.min, seqVelTable.max, velocityRandomization.value)
end

local function isTrigger(e)
  local channel = channelInput.value - 1
  return channel == 0 or channel == e.channel
end

function onNote(e)
  if isTrigger(e) then
    for i=1,velocityTableLength.value do
      local val = 0
      if i == velocityPos then
        val = 1
      end
      positionTable:setValue(i, val)
    end  
    velocity, velocityPos = getVelocity(velocityPos)
    e.velocity = randomizeVelocity(velocity)
  end
  postEvent(e)
end

function onTransport(start)
  velocityPos = 1 -- Reset pos
  for i=1,velocityTableLength.value do
    positionTable:setValue(i, 0)
  end  
end
