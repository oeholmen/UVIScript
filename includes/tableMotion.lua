--------------------------------------------------------------------------------
-- Common functions for processors using table motion
--------------------------------------------------------------------------------

local gem = require "includes.common"

local directionStartModes = {"Up", "Down", "Even Up", "Even Down", "Odd Up", "Odd Down", "Random"}
local speedTypes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Random"}
local startModes = {"Ramp Up", "Ramp Down", "Triangle", "Sine", "Cosine", "Tangent", "Even", "Odd", "Zero", "Min", "Max", "Keep State", "Random"}

local motionOptions = {
  factor = 2,
  factorMin = 0,
  factorMax = 4,
  moveSpeed = 25,
  moveSpeedMin = 5,
  moveSpeedMax = 500,
  speedType = speedTypes[1],
  startMode = startModes[1],
  directionStartMode = directionStartModes[1],
  speedRandomizationAmount = 0,
  tableLength = 32,
}

local function getStartDirection(i)
  local direction = 1
  if motionOptions.directionStartMode == "Down" then
    direction = -1
  elseif motionOptions.directionStartMode == "Even Up" then
    if i % 2 == 0 then
      direction = 1
    else
      direction = -1
    end
  elseif motionOptions.directionStartMode == "Even Down" then
    if i % 2 == 0 then
      direction = -1
    else
      direction = 1
    end
  elseif motionOptions.directionStartMode == "Odd Up" then
    if i % 2 == 0 then
      direction = -1
    else
      direction = 1
    end
  elseif motionOptions.directionStartMode == "Odd Down" then
    if i % 2 == 0 then
      direction = 1
    else
      direction = -1
    end
  elseif motionOptions.directionStartMode == "Random" then
    if gem.getRandomBoolean() then
      direction = 1
    else
      direction = -1
    end
  end
  return direction
end

local function setTableZero(theTable)
    for i=1,theTable.length do
      theTable:setValue(i, 0)
    end  
end

local function setStartMode(theTable)
  -- Reset table according to start mode
  local values = {}
  if motionOptions.startMode == "Keep State" then
    return
  elseif motionOptions.startMode == "Ramp Up" then
    values = gem.rampUp(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Ramp Down" then
    values = gem.rampDown(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Triangle" then
    values = gem.triangle(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Sine" then
    values = gem.shape(theTable.min, theTable.max, theTable.length, 'sin')
  elseif motionOptions.startMode == "Cosine" then
    values = gem.shape(theTable.min, theTable.max, theTable.length, 'cos')
  elseif motionOptions.startMode == "Tangent" then
    values = gem.shape(theTable.min, theTable.max, theTable.length, 'tan')
  elseif motionOptions.startMode == "Random" then
    for i=1,theTable.length do
      table.insert(values, gem.getRandom(theTable.min, theTable.max))
    end
  elseif motionOptions.startMode == "Min" then
    for i=1,theTable.length do
      table.insert(values, theTable.min)
    end
  elseif motionOptions.startMode == "Max" then
    for i=1,theTable.length do
      table.insert(values, theTable.max)
    end
  elseif motionOptions.startMode == "Even" then
    local minValue = theTable.min
    local maxValue = theTable.max
    for i=1,theTable.length do
      local val = minValue
      if i % 2 == 0 then
        val = maxValue
      end
      table.insert(values, val)
    end
  elseif motionOptions.startMode == "Odd" then
    local minValue = theTable.min
    local maxValue = theTable.max
    for i=1,theTable.length do
      local val = maxValue
      if i % 2 == 0 then
        val = minValue
      end
      table.insert(values, val)
    end
  else
    setTableZero(theTable)
    return
  end
  for i,v in ipairs(values) do
    theTable:setValue(i, math.floor(v))
  end
end

local function moveTable(theTable, i, value, direction)
  local middle = math.floor(theTable.length / 2)
  -- Increment value
  local amount = i - 1
  if (i > middle and motionOptions.speedType == "Triangle") or motionOptions.speedType == "Ramp Down" then
    amount = theTable.length - i
  elseif motionOptions.speedType == "Random" then
    amount = gem.getRandom(theTable.length) - 1
  elseif (motionOptions.speedType == "Even" and i % 2 == 0) or (motionOptions.speedType == "Odd" and i % 2 > 0) then
    amount = 0
  elseif motionOptions.speedType == "Even" and i == 1 then
    amount = i
  end
  local min = theTable.min
  local max = theTable.max
  local duration = gem.randomizeValue(motionOptions.moveSpeed, motionOptions.moveSpeedMin, motionOptions.moveSpeedMax, motionOptions.speedRandomizationAmount) + (amount * motionOptions.factor) -- TODO Param for operator?
  theTable:setValue(i, value)
  value = gem.inc(value, direction)
  if value < min then
    if true or gem.getRandomBoolean() then
      value = min
      direction = 1
      --print("Change direction", direction)
    else
      value = max
    end
    --print("Reset value", value)
  elseif value > max then
    if true or gem.getRandomBoolean() then
      value = max
      direction = -1
      --print("Change direction", direction)
    else
      value = min
    end
    --print("Reset value", value)
  end
  local valueBeforeWait = theTable:getValue(i)
  wait(duration)
  -- If value has been manually changed during the wait, we continue from that value
  if valueBeforeWait ~= theTable:getValue(i) then
    value = theTable:getValue(i)
  end
  return value, direction
end

return {--tableMotion--
  setRange = function(theTable, tableRange, bipolar)
    if bipolar then
      theTable:setRange(-tableRange, tableRange)
    else
      theTable:setRange(0, tableRange)
    end
  end,
  getStartDirection = getStartDirection,
  moveTable = moveTable,
  setStartMode = setStartMode,
  setTableZero = setTableZero,
  directionStartModes = directionStartModes,
  speedTypes = speedTypes,
  startModes = startModes,
  options = motionOptions
}
