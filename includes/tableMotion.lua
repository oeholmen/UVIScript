--------------------------------------------------------------------------------
-- Common functions for processors using table motion
--------------------------------------------------------------------------------

local gem = require "includes.common"
local shapes = require "includes.shapes"
local widgets = require "includes.widgets"

local directionStartModes = {"Up", "Down", "Even Up", "Even Down", "Odd Up", "Odd Down", "Random"}
local speedTypes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Random"}
local startModes = shapes.getShapeNames({"Keep State"})

local motionOptions = {
  factor = 2,
  factorMin = 0,
  factorMax = 8,
  moveSpeed = 25,
  moveSpeedMin = 5,
  moveSpeedMax = 500,
  speedType = speedTypes[1],
  startMode = startModes[1],
  directionStartMode = directionStartModes[1],
  speedRandomizationAmount = 0,
  tableLength = 32,
  useMorph = false,
}

local shapeOptions = {
    z = 1,
    stepRange = 2,
    phase = -1,
    factor = 1,
}

local function getShapeWidgets(width, showLabel)
  -- Widgets for controlling shape
  if type(width) == "nil" then
    width = 30
  end
  return {
    stepRange = widgets.numBox("Step Range", shapeOptions.stepRange, {
      name = "ShapePhaseStepRange",
      tooltip = "Set step range for the shape. Mostly affects polarity of the shape.",
      width = width,
      showLabel = showLabel == true,
      min = 0,
      max = 4,
    }),
    phase = widgets.numBox("Shape Phase", shapeOptions.phase, {
      name = "ShapePhase",
      tooltip = "Set the phase applied to the shape (move left/right).",
      width = width,
      showLabel = showLabel == true,
      min = -1,
      max = 1,
    }),
    factor = widgets.numBox("Shape Factor", shapeOptions.factor, {
      name = "ShapeFactor",
      tooltip = "Set the factor (multiplier) applied to the value of each step.",
      width = width,
      showLabel = showLabel == true,
      min = -8,
      max = 8,
    }),
    z = widgets.numBox("Shape Morph", shapeOptions.z, {
      name = "ShapeZValue",
      tooltip = "Set the morph value. This value is mostly assigned to amplitude, but it depends on the shape.",
      width = width,
      showLabel = showLabel == true,
      min = -1,
      max = 1,
    })
  }
end

local function getStartDirection(i)
  if type(i) == "nil" then
    i = 1
  end
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

local function setStartMode(theTable, options, stateFunction)
  -- Reset table according to start mode (unless keep state is selected)
  if motionOptions.startMode ~= "Keep State" then
    local values = {}
    local shapeIndex = gem.getIndexFromValue(motionOptions.startMode, shapes.getShapeNames())
    local shapeFunc = shapes.getShapeFunction(shapeIndex)
    --print("Calling shapeFunc", shapeFunc)
    values, shapeOptions = shapes[shapeFunc](theTable, options)
    for i,v in ipairs(values) do
      --theTable:setValue(i, math.floor(v))
      local value = gem.round(v)
      theTable:setValue(i, value)
      if type(stateFunction) == "function" then
        stateFunction(i, value)
      end
    end
  end
  return shapeOptions
end

local function getWaitDuration()
  return gem.randomizeValue(motionOptions.moveSpeed, motionOptions.moveSpeedMin, motionOptions.moveSpeedMax, motionOptions.speedRandomizationAmount)
end

local function advanceMorphValue(theTable, value, min, max, direction)
  -- Advance shape morph widget value
  local valueRange = theTable.max - theTable.min
  local changeFactor = max - min
  local changePerStep = gem.getChangePerStep(changeFactor, valueRange)

  if direction < 0 then
    changePerStep = -changePerStep
  end

  value = gem.inc(value, changePerStep)
  if value > max then
    direction = -1
    value = max
  elseif value < min then
    direction = 1
    value = min
  end
  return value, direction
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
  local duration = getWaitDuration() + (amount * motionOptions.factor) -- TODO Param for operator?
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
  getShapeWidgets = getShapeWidgets,
  getStartDirection = getStartDirection,
  moveTable = moveTable,
  advanceMorphValue = advanceMorphValue,
  getWaitDuration = getWaitDuration,
  setStartMode = setStartMode,
  setTableZero = setTableZero,
  directionStartModes = directionStartModes,
  speedTypes = speedTypes,
  startModes = startModes,
  options = motionOptions,
  shapeOptions = shapeOptions,
}
