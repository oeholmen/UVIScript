-- util/velocitySequencer -- 
--------------------------------------------------------------------------------
-- Common methods
--------------------------------------------------------------------------------

local function getRandom(min, max, factor)
  if type(min) == "number" and type(max) == "number" and min < max then
    return math.random(min, max)
  elseif type(min) == "number" then
    return math.random(min)
  end
  local value = math.random()
  if type(factor) == "number" then
    value = value * factor
  end
  return value
end

local function getRandomBoolean(probability)
  -- Default probability of getting true is 50%
  if type(probability) ~= "number" then
    probability = 50
  end
  return getRandom(100) <= probability
end

local function getChangeMax(max, probabilityLevel)
  return math.ceil(max * (probabilityLevel / 100))
end

local function getIndexFromValue(value, selection)
  for i,v in ipairs(selection) do
    if v == value then
      return i
    end
  end
  return nil
end

local function randomizeValue(value, limitMin, limitMax, randomizationAmount)
  if randomizationAmount > 0 then
    local limitRange = limitMax - limitMin
    local changeMax = getChangeMax(limitRange, randomizationAmount)
    local min = math.max(limitMin, (value - changeMax))
    local max = math.min(limitMax, (value + changeMax))
    --print("Before randomize value", value)
    value = getRandom(min, max)
    --print("After randomize value/changeMax/min/max", value, changeMax, min, max)
  end
  return value
end

local function round(value)
  local int, frac = math.modf(value)
  --print("int/frac", int, frac)
  if math.abs(frac) < 0.5 then
    value = int
  elseif value < 0 then
    value = int - 1
  else
    value = int + 1
  end
  return value
end

local function tableIncludes(theTable, theItem)
  return type(getIndexFromValue(theItem, theTable)) == "number"
end

local function getRandomFromTable(theTable, except)
  if #theTable == 0 then
    return nil
  end
  if #theTable == 1 then
    return theTable[1]
  end
  local index = getRandom(#theTable)
  local value = theTable[index]
  --print("getRandomFromTable index, value", index, value)
  if type(except) ~= "nil" then
    local maxRounds = 10
    while value == except and maxRounds > 0 do
      value = theTable[getRandom(#theTable)]
      maxRounds = maxRounds - 1
      --print("getRandomFromTable except, maxRounds", except, maxRounds)
    end
  end
  return value
end

local function trimStartAndEnd(s)
  return s:match("^%s*(.-)%s*$")
end

local function getChangePerStep(valueRange, numSteps)
  return valueRange / (numSteps - 1)
end

local function inc(val, inc, max, reset)
  if type(inc) ~= "number" then
    inc = 1
  end
  if type(reset) ~= "number" then
    reset = 1
  end
  val = val + inc
  if type(max) == "number" and val > max then
    val = reset
  end
  return val
end

local function triangle(minValue, maxValue, numSteps)
  local rising = true
  local numStepsUpDown = round(numSteps / 2)
  local valueRange = maxValue - minValue
  local changePerStep = valueRange / numStepsUpDown
  local startValue = minValue
  local tri = {}
  for i=1,numSteps do
    table.insert(tri, startValue)
    if rising then
      startValue = startValue + changePerStep
      if startValue >= maxValue then
        rising = false
      end
    else
      startValue = startValue - changePerStep
    end
  end
  return tri
end

local function rampUp(minValue, maxValue, numSteps)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numSteps)
  local startValue = minValue
  local ramp = {}
  for i=1,numSteps do
    table.insert(ramp, startValue)
    startValue = inc(startValue, changePerStep)
  end
  return ramp
end

local function rampDown(minValue, maxValue, numSteps)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numSteps)
  local startValue = maxValue
  local ramp = {}
  for i=1,numSteps do
    table.insert(ramp, startValue)
    startValue = inc(startValue, -changePerStep)
  end
  return ramp
end

local gem = {
  inc = inc,
  round = round,
  triangle = triangle,
  rampUp = rampUp,
  rampDown = rampDown,
  getRandom = getRandom,
  getChangeMax = getChangeMax,
  tableIncludes = tableIncludes,
  randomizeValue = randomizeValue,
  trimStartAndEnd = trimStartAndEnd,
  getRandomBoolean = getRandomBoolean,
  getIndexFromValue = getIndexFromValue,
  getRandomFromTable = getRandomFromTable,
}

--------------------------------------------------------------------------------
-- Velocity Sequencer
--------------------------------------------------------------------------------

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
panel.height = 90

local label = panel:Label("Label")
label.text = "Velocity Sequencer"
label.editable = true
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
seqVelTable.height = 45
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

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  return {label.text}
end

function onLoad(data)
  label.text = data[1]
end
