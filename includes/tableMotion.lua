--------------------------------------------------------------------------------
-- Common functions for processors using table motion
--------------------------------------------------------------------------------

local gem = require "includes.common"
local shapes = require "includes.shapes"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

local directionStartModes = {"Up", "Down", "Even Up", "Even Down", "Odd Up", "Odd Down", "Random"}
local speedTypes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Random"}
local startModes = shapes.getShapeNames({"Keep State"})
local movementTypes = {"Evolve", "Morph", "Manual"}
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local morphSeqIndex = 0 -- Holds the unique id for the morphing sequencer
local movingCells = {}
local isTableMotionActive = false
local shapeWidgets = {} -- Holds the widgets for controlling shape
local resolutionNames = resolutions.getResolutionNames()

local motionOptions = {
  factor = 2,
  factorMin = 0,
  factorMax = 10,
  moveSpeed = gem.getIndexFromValue("1/16", resolutionNames),
  moveSpeedMin = 1,
  moveSpeedMax = #resolutionNames,
  speedType = speedTypes[1],
  startMode = 1,
  movementType = movementTypes[1],
  directionStartMode = directionStartModes[1],
  speedRandomizationAmount = 0,
  tableLength = 32,
}

local shapeOptions = {
    z = 1,
    phase = -1,
    factor = 1,
}

local function getSpeedSpreadWidget(width)
  return widgets.menu("Speed Spread", speedTypes, {
    width = width,
    tooltip = "The speed spread works with the speed factor to control speed variations across the table. Ramp Up means fast -> slower, Triangle means slower in the center. (Note: Only used for motion type 'evolve')",
    changed = function(self) motionOptions.speedType = self.selectedText end
  })
end

local function getStartDirectionWidget(width)
  return widgets.menu("Start Direction", directionStartModes, {
    width = width,
    tooltip = "Select start direction for the bars",
    changed = function(self) motionOptions.directionStartMode = self.selectedText end
  })
end

local function getMotionSpeedWidget(width)
  local motionResolutionMenu
  local motionResolutionInput

  motionResolutionMenu = widgets.menu("Motion Speed", motionOptions.moveSpeed, resolutionNames, {
    width = width,
    tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller",
    changed = function(self) motionResolutionInput:setValue(self.value) end
  })

  motionResolutionInput = widgets.numBox("Motion Resolution", motionOptions.moveSpeed, {
    visible = false,
    increment = false,
    min = 1,
    max = #resolutionNames,
    changed = function(self)
      motionOptions.moveSpeed = gem.round(self.value)
      motionResolutionMenu:setValue(motionOptions.moveSpeed)
    end
  })

  return motionResolutionMenu
end

local function getSpeedFactorWidget(width)
  return widgets.numBox("Speed Factor", motionOptions.factor, {
    width = width,
    mapper = Mapper.Cubic,
    min = motionOptions.factorMin,
    max = motionOptions.factorMax,
    tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. When using morph, this controls phase amount. Controlled by the Y-axis on the XY controller",
    changed = function(self) motionOptions.factor = self.value end
  })
end

local function getSpeedRandWidget(width)
  return widgets.numBox("Speed Rand", motionOptions.speedRandomizationAmount, {
    tooltip = "Set the radomization amount applied to speed",
    width = width,
    unit = Unit.Percent,
    integer = false,
    mapper = Mapper.Quadratic,
    changed = function(self) motionOptions.speedRandomizationAmount = self.value end
  })
end

local function getStartShapeWidget(width)
  return widgets.menu("Start Shape", startModes, {
    width = width,
    tooltip = "Set how the table will look when starting.",
  })
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

local function updateShapeWidgets()
  -- Update widgets with values from the shape
  local callChanged = false
  shapeWidgets.phase:setValue(shapeOptions.phase, callChanged)
  shapeWidgets.factor:setValue(shapeOptions.factor, callChanged)
  shapeWidgets.z:setValue(shapeOptions.z, callChanged)
end

local function setStartMode(theTable, loadShape, stateFunction)
  -- Reset table according to start mode (unless keep state is selected)
  if motionOptions.startMode < #startModes then
    local values = {}
    local shapeIndex = motionOptions.startMode
    --print("Calling shapeFunc", shapeFunc)
    if type(loadShape) == "table" then
      -- Load the shape with the settings provided
      values = shapes.get(shapeIndex, theTable, loadShape)
    elseif loadShape == true then
      -- Load the shape without settings to get the original form of the shape
      values, shapeOptions = shapes.get(shapeIndex, theTable)
    else
      -- Load the shape with the default settings
      values, shapeOptions = shapes.get(shapeIndex, theTable, shapeOptions)
    end
    for i,v in ipairs(values) do
      local value = v
      --[[ if shapeFunc == "sine" then
        -- Sine prefers round
        value = gem.round(v)
      else ]]if v > 1 then
        value = math.ceil(v)
      else
        value = math.floor(v)
      end
      --print("Set value, i", value, i)
      theTable:setValue(i, value)
      if type(stateFunction) == "function" then
        --print("Calling stateFunc")
        stateFunction(i, value)
      end
    end
    if type(loadShape) ~= "table" then
      updateShapeWidgets()
    end
  end
end

local function getWaitDuration()
  local resolutionIndex = gem.randomizeValue(motionOptions.moveSpeed, motionOptions.moveSpeedMin, motionOptions.moveSpeedMax, motionOptions.speedRandomizationAmount)
  return beat2ms(resolutions.getResolution(resolutionIndex))
end

local function advanceValue(theTable, value, min, max, direction)
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

local function morph(theTable, uniqueId, stateFunction)
  print("startMorphing")
  local direction = getStartDirection()
  local morphSettings = {
    z = {
      value = shapeWidgets.z.value,
      min = shapeWidgets.z.min,
      max = shapeWidgets.z.max,
      direction = direction,
    },
    phase = {
      value = shapeWidgets.phase.value,
      min = shapeWidgets.phase.min,
      max = shapeWidgets.phase.max,
      direction = direction,
    }
  }
  while isTableMotionActive and motionOptions.movementType == "Morph" and morphSeqIndex == uniqueId do
    morphSettings.z.value, morphSettings.z.direction = advanceValue(theTable, morphSettings.z.value, morphSettings.z.min, morphSettings.z.max, morphSettings.z.direction)
    if motionOptions.factor > 0 then
      local factor = motionOptions.factor / motionOptions.factorMax
      local range = morphSettings.phase.max - morphSettings.phase.min
      local min = morphSettings.phase.min
      local max = min + (range * factor)
      if shapeWidgets.phase.value > min then
        range = (range / 2) * factor
        min = shapeWidgets.phase.value - range
        max = shapeWidgets.phase.value + range
      end
      morphSettings.phase.value, morphSettings.phase.direction = advanceValue(theTable, morphSettings.phase.value, min, max, morphSettings.phase.direction)
    end
    local options = {
      z = morphSettings.z.value,
      phase = morphSettings.phase.value,
      factor = shapeOptions.factor,
    }
    setStartMode(theTable, options, stateFunction)
    wait(getWaitDuration())
  end
end

local function move(theTable, i, uniqueId, stateFunction)
  local direction = getStartDirection(i)
  local value = theTable:getValue(i)
  while isTableMotionActive and movingCells[i] == uniqueId do
    if type(stateFunction) == "function" then
      stateFunction(i, value)
    end
    value, direction = moveTable(theTable, i, value, direction)
    -- Wait happens in moveTable
  end
end

local function startMoving(theTable, stateFunction)
  if isTableMotionActive == false then
    return
  end
  -- Reset index to stop motion
  morphSeqIndex = gem.inc(morphSeqIndex)
  movingCells = {}
  if motionOptions.movementType == "Manual" then
    print("In Manual Mode")
    return -- Nothing needs to be done in manual mode
  elseif motionOptions.movementType == "Morph" then
    print("spawn morph")
    spawn(morph, theTable, morphSeqIndex, stateFunction)
  else
    print("spawn move")
    for i=1,theTable.length do
      table.insert(movingCells, uniqueIndex)
      spawn(move, theTable, i, uniqueIndex, stateFunction)
      uniqueIndex = gem.inc(uniqueIndex)
    end
  end
end

return {--tableMotion--
  setRange = function(theTable, tableRange, bipolar)
    if bipolar then
      theTable:setRange(-tableRange, tableRange)
    else
      theTable:setRange(0, tableRange)
    end
  end,
  getSpeedSpreadWidget = getSpeedSpreadWidget,
  getStartShapeWidget = getStartShapeWidget,
  getStartDirectionWidget = getStartDirectionWidget,
  getMotionSpeedWidget = getMotionSpeedWidget,
  getSpeedFactorWidget = getSpeedFactorWidget,
  getSpeedRandWidget = getSpeedRandWidget,
  startMoving = startMoving,
  isMoving = function() return isTableMotionActive == true end,
  isNotMoving = function() return isTableMotionActive == false end,
  setMoving = function(m) isTableMotionActive = m ~= false end,
  resetUniqueIndex = function() uniqueIndex = 1 end,
  setShapeWidgets = function(widgets) shapeWidgets = widgets end,
  getShapeWidgets = function() return shapeWidgets end,
  getShapeOptions = function() return shapeOptions end,
  getStartDirection = getStartDirection,
  moveTable = moveTable,
  advanceValue = advanceValue,
  getWaitDuration = getWaitDuration,
  setStartMode = setStartMode,
  setTableZero = setTableZero,
  directionStartModes = directionStartModes,
  speedTypes = speedTypes,
  startModes = startModes,
  movementTypes = movementTypes,
  options = motionOptions,
}
