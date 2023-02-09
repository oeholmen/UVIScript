-- util/sieve -- 
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

local gem = {
  inc = inc,
  round = round,
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
-- Sieve
--------------------------------------------------------------------------------
-- Set the probability that incomming notes will pass through the sieve
--------------------------------------------------------------------------------



local backgroundColour = "202020" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "3EC1D3" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

setBackgroundColour(backgroundColour)

local panel = Panel("Sieve")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 40

local label = panel:Label("Label")
label.text = "Sieve"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {55,25}

local sieveProbability = panel:NumBox("SieveProbability", 50, 0, 100, true)
sieveProbability.unit = Unit.Percent
sieveProbability.backgroundColour = widgetBackgroundColour
sieveProbability.textColour = widgetTextColour
sieveProbability.displayName = "Probability"
sieveProbability.tooltip = "Set the probability that incomming notes will pass through the sieve"

local noteMin = panel:NumBox("NoteMin", 0, 0, 127, true)
noteMin.unit = Unit.MidiKey
noteMin.backgroundColour = widgetBackgroundColour
noteMin.textColour = widgetTextColour
noteMin.displayName = "Min"
noteMin.tooltip = "Lowest note - notes below this are passed through"

local noteMax = panel:NumBox("NoteMax", 127, 0, 127, true)
noteMax.unit = Unit.MidiKey
noteMax.backgroundColour = widgetBackgroundColour
noteMax.textColour = widgetTextColour
noteMax.displayName = "Max"
noteMax.tooltip = "Highest note - notes above this are passed through"

local sieveButton = panel:Button("SieveButton")
sieveButton.displayName = " "
sieveButton.tooltip = "Shows current state"
sieveButton.backgroundColourOff = "red"
sieveButton.backgroundColourOn = "green"
sieveButton.size = {20,20}
sieveButton.x = panel.width - 40

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  if e.note <= noteMin.value or e.note >= noteMax.value or gem.getRandomBoolean(sieveProbability.value) then
    print("Passing through", e.note)
    sieveButton.backgroundColourOff = "green"
    postEvent(e)
  else
    print("Stopping", e.note)
    sieveButton.backgroundColourOff = "red"
  end
end

function onRelease(e)
  e.velocity = 0
  postEvent(e)
end
