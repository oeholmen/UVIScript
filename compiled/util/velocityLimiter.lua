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
-- Velocity Limiter
--------------------------------------------------------------------------------



local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "15133C" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour

setBackgroundColour(backgroundColour)

local panel = Panel("Limiter")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 40

local label = panel:Label("Label")
label.text = "Velocity Limiter"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {140,25}
label.y = 5

local velMin = panel:NumBox("VelMin", 1, 1, 127, true)
velMin.backgroundColour = widgetBackgroundColour
velMin.textColour = widgetTextColour
velMin.displayName = "Min"
velMin.x = label.x + label.width + 150
velMin.y = label.y

local velMax = panel:NumBox("VelMax", 127, 1, 127, true)
velMax.backgroundColour = widgetBackgroundColour
velMax.textColour = widgetTextColour
velMax.displayName = "Max"
velMax.x = velMin.x + velMin.width + 10
velMax.y = velMin.y

local velRandomization = panel:NumBox("VelocityRandomization", 0, 0, 100, true)
velRandomization.displayName = "Randomize"
velRandomization.tooltip = "Amount of radomization applied to velocity"
velRandomization.unit = Unit.Percent
velRandomization.backgroundColour = widgetBackgroundColour
velRandomization.textColour = widgetTextColour
velRandomization.x = velMax.x + velMax.width + 10
velRandomization.y = velMax.y

-- Avoid range crossing
velMin.changed = function(self)
  velMax:setRange((self.value), 127)
end

velMax.changed = function(self)
  velMin:setRange(1, (self.value))
end

function adjust(velocity)
  local velocityWasAdjusted = false
  if velocity < velMin.value then
    print("velocity < velMin.value", velocity, velMin.value)
    velocity = velMin.value
    velocityWasAdjusted = true
  elseif velocity > velMax.value then
    print("velocity > velMax.value", velocity, velMax.value)
    velocity = velMax.value
    velocityWasAdjusted = true
  end

  -- Randomize velocity if there was an adjustment made
  -- This is done to avoid a "hard" velocity limit
  local velRandomization = velRandomization.value
  if velocityWasAdjusted and velRandomization > 0 then
    local changeMax = gem.getChangeMax(velMax.value, velRandomization)
    local min = velocity - changeMax
    local max = velocity + changeMax
    if min < velMin.value then
      min = velMin.value
    end
    if max > velMax.value then
      max = velMax.value
    end
    print("Before randomize velocity", velocity)
    velocity = gem.getRandom(min, max)
    print("After randomize velocity/changeMax/min/max", velocity, changeMax, min, max)
  end

  return velocity
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  e.velocity = adjust(e.velocity)
  postEvent(e)
end
