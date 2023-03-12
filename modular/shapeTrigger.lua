--------------------------------------------------------------------------------
-- Life Trigger - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local shapes = require "includes.shapes"
local resolutions = require "includes.resolutions"

local backgroundColour = "404040"
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local channel = 1
local gate = 90
local gateRandomization = 0
local resolutionNames = resolutions.getResolutionNames()
local resolution = 20 -- The default resolution
local velocity = 64
local rows = 8 -- Number of rows in the board
local cols = 8 -- Number of columns in the board
local cells = {} -- Holds the cell widgets
local locked = true -- Board is locked to move through all live cells before next gen - it starts locked to not kill the initial state
local currentRowIndex = 1
local currentColIndex = 1
local liveCells = 0 -- Holds the current live cells until next iteration
local fillProbability = 75
local morphSettings
local shapeWidgets = {}
local shapeOptions = shapes.getShapeOptions()
local shapeIndex
local shapeMenu
local shapeNames = shapes.getShapeNames()
local shapeMenuItems = {"Random Shape"}
for _,v in ipairs(shapeNames) do
  table.insert(shapeMenuItems, v)
end

local morphSteps = {
  z = rows,
  phase = 1,
  factor = 1,
  amount = 1,
}

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function clearCells()
  --print("Clear cells")
  currentRowIndex = 1
  currentColIndex = 1 -- Reset
  liveCells = 0 -- Reset
  for i = 1, rows do
    for j = 1, cols do
      cells[i][j].value = false
      cells[i][j].backgroundColourOn = widgets.getColours().backgroundColourOn
      cells[i][j].backgroundColourOff = widgets.getColours().backgroundColourOff
      cells[i][j].displayName = resolutionNames[resolution]
      cells[i][j].tooltip = resolutions.getResolution(resolution) .. ""
    end
  end
end

local function updateShapeWidgets()
  -- Update widgets with values from the shape
  local callChanged = false
  shapeWidgets.phase:setValue(shapeOptions.phase, callChanged)
  shapeWidgets.factor:setValue(shapeOptions.factor, callChanged)
  shapeWidgets.z:setValue(shapeOptions.z, callChanged)
  shapeWidgets.amount:setValue(shapeOptions.amount, callChanged)
end

local function isFilled(row, value)
  return row == value or (row < value and gem.getRandomBoolean(fillProbability))
end

local function loadShape(options)
  local shape = shapeIndex
  if type(shape) == "nil" then
    shape = gem.getRandom(#shapeNames)
  end
  --print("--- NEW SHAPE ---", shape)
  clearCells() -- Deactivate all cells
  local bounds = {
    min=1,
    max=rows,
    length=cols,
  }
  local values, shapeOptions = shapes.get(shape, bounds, options)
  for col = 1, cols do
    local value = math.ceil(values[col])
    for row = 1, rows do
      cells[row][col].value = isFilled(row, value)
    end
  end
  locked = true -- Lock to preserve the shape
  if type(options) == "nil" then
    updateShapeWidgets() -- Update the widgets
  end
end

local function advanceShape()
  if type(morphSettings) == "nil" then
    morphSettings = {
      z = {
        value = shapeWidgets.z.value,
        min = shapeWidgets.z.min,
        max = shapeWidgets.z.max,
        steps = morphSteps.z,
        direction = -1,
      },
      phase = {
        value = shapeWidgets.phase.value,
        min = shapeWidgets.phase.min,
        max = shapeWidgets.phase.max,
        steps = morphSteps.phase,
        direction = 1,
      },
      factor = {
        value = shapeWidgets.factor.value,
        min = shapeWidgets.factor.min,
        max = shapeWidgets.factor.max,
        steps = morphSteps.factor,
        direction = 1,
      },
      amount = {
        value = shapeWidgets.amount.value,
        min = shapeWidgets.amount.min,
        max = shapeWidgets.amount.max,
        steps = morphSteps.amount,
        direction = -1,
      },
    }
  end

  for _,v in pairs(morphSettings) do
    if v.steps > 1 then
      v.value, v.direction = gem.advanceValue({min=1,max=v.steps}, v.value, v.min, v.max, v.direction)
    end
  end

  local options = {
    z = morphSettings.z.value,
    phase = morphSettings.phase.value,
    factor = morphSettings.factor.value,
    amount = morphSettings.amount.value,
  }

  loadShape(options)
end

-- Returns a random resolution from the live cells
local function getCell()
  local cell = cells[currentRowIndex][currentColIndex]

  if type(cell) == "nil" then
    locked = false
    print("No cell")
    return
  end

  currentColIndex = gem.inc(currentColIndex)

  if currentColIndex > cols then
    currentColIndex = 1 -- Reset
    currentRowIndex = gem.inc(currentRowIndex)
    if currentRowIndex > rows then
      -- Round complete - unlock board!
      currentRowIndex = 1 -- Reset
      locked = false
    end
  end

  if cell.value then
    cell.backgroundColourOn = "orange"
  else
    cell.backgroundColourOff = "505050"
  end
  return cell
end

local function countLiveCells()
  for i = 1, rows do
    for j = 1, cols do
      if cells[i][j].value then
        liveCells = gem.inc(liveCells)
      end
    end
  end
  --print("Found #liveCells", #liveCells)
  currentRowIndex = 1 -- Reset row position
  currentColIndex = 1 -- Reset col position
  locked = liveCells > 0
end

local function getGate()
  return gem.randomizeValue(gate, 0, 100, gateRandomization)
end

local function seq(uniqueId)
  local note = 0
  locked = true -- Ensure the board is locked when starting to preserve the current state
  while isPlaying and seqIndex == uniqueId do
    -- When board has been unlocked, we can move one generation ahead
    if liveCells == 0 then
      countLiveCells()
    end
    if locked == false then
      if liveCells == 0 or type(shapeIndex) == "nil" then
        loadShape() -- Load a fresh shape if no live cells are present, or we are in random shape mode
      else
        advanceShape()
      end
    end
    local cell = getCell() -- Get cell at current pos
    if type(cell) ~= "nil" then
      local duration = tonumber(cell.tooltip)
      if cell.value then
        playNote(note, velocity, beat2ms(resolutions.getPlayDuration(duration, getGate())), nil, channel)
        --print("playNote", duration)
      end
      waitBeat(duration)
    end
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(seq, seqIndex)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
end

--------------------------------------------------------------------------------
-- Header Panel
--------------------------------------------------------------------------------

widgets.panel({
  width = 720,
  height = 30,
})

widgets.setSection({
  xSpacing = 5,
  ySpacing = 5,
})

widgets.label("Shape Trigger", {
  tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to",
  width = widgets.getPanel().width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 110,
  height = 22,
  x = 375,
  y = 5,
  cols = 10
})

widgets.numBox('Channel', channel, {
  tooltip = "Send note events starting on this channel",
  min = 1,
  max = 16,
  integer = true,
  changed = function(self) channel = self.value end
})

local autoplayButton = widgets.button('Auto Play', true, {
  tooltip = "Play automatically on transport",
})

local playButton = widgets.button('Play', false, {
  changed = function(self)
    if self.value == true then
      startPlaying()
    else
      stopPlaying()
    end
  end
})

--------------------------------------------------------------------------------
-- Board
--------------------------------------------------------------------------------

widgets.setSection({
  xSpacing = 0,
  ySpacing = 0,
})

widgets.panel({
  backgroundColour = backgroundColour,
  x = widgets.getPanel().x,
  y = widgets.posUnder(widgets.getPanel()),
  width = widgets.getPanel().width,
  height = 320,
})

widgets.setSection({
  width = (widgets.getPanel().width - ((cols+1) * 5)) / cols,
  height = (widgets.getPanel().height - ((rows+1) * 5)) / rows,
  x = 5,
  y = 5,
  xSpacing = 5,
  ySpacing = 5,
  rowDirection = -1,
  row = rows - 1,
  cols = cols,
})

-- Create the cells
for i = 1, rows do
  cells[i] = {}
  for j = 1, cols do
    cells[i][j] = widgets.button(resolutionNames[resolution])
    --cells[i][j] = widgets.button(i .. '-' .. j)
  end
end

--------------------------------------------------------------------------------
-- Setting Panel
--------------------------------------------------------------------------------

widgets.panel({
  --backgroundColour = backgroundColour,
  x = 5,
  y = widgets.posUnder(widgets.getPanel()) - 5,
  width = widgets.getPanel().width - 10,
  height = 60,
})

widgets.setSection({
  height = 22,
  width = 60,
  cols = 8,
})

widgets.label("Shape", {
  width = 42,
  backgroundColour = "transparent",
  textColour = "silver"
})

shapeMenu = widgets.menu("Shape", shapeMenuItems, {
  tooltip = "Select a shape, or choose 'Random Shape' to change shapes between round",
  width = 123,
  showLabel = false,
  changed = function(self)
    morphSettings = nil -- Reset
    clearCells()
    shapeIndex = self.value - 1
    if shapeIndex == 0 then
      shapeIndex = nil
    else
      loadShape()
    end
  end
})

widgets.numBox('Fill', fillProbability, {
  tooltip = "Set a fill probability for the selected shape. If fill is 0, the shape is drawn as a line, if fill is 100 it will be drawn solid.",
  unit = Unit.Percent,
  width = 120,
  changed = function(self)
    fillProbability = self.value
    shapeMenu:changed()
  end
})

widgets.col(1,7)

widgets.label("Resolution", {
  width = 66,
  backgroundColour = "transparent",
  textColour = "silver"
})

widgets.menu("Resolution", resolution, resolutionNames, {
  tooltip = "Set the sequencer resolution",
  width = 90,
  showLabel = false,
  changed = function(self)
    resolution = self.value
    clearCells()
    if type(shapeIndex) == "number" then
      loadShape(shapeOptions)
    else
      clearCells()
    end
  end
})

widgets.numBox("Gate", gate, {
  tooltip = "Set the gate value",
  width = 108,
  unit = Unit.Percent,
  changed = function(self)
    gate = self.value
  end
})

widgets.numBox("Gate Rnd", gateRandomization, {
  tooltip = "Set gate randomization amount",
  width = 108,
  unit = Unit.Percent,
  changed = function(self)
    gateRandomization = self.value
  end
})

widgets.setSection({
  y = widgets.posUnder(shapeMenu),
  height = 20,
  width = 167,
  xSpacing = 10,
  cols = 8,
})

shapeWidgets = shapes.getWidgets()
shapeWidgets.amount = shapes.getAmountWidget()

for k,v in pairs(shapeWidgets) do
  v.width = v.width - 30
  v.changed = function(self)
    morphSettings = nil -- Reset
    shapeOptions[k] = self.value
    if type(shapeIndex) == "number" then
      loadShape(shapeOptions)
    end
  end

  widgets.numBox(k, morphSteps[k], {
    tooltip = "Number of rounds to morph across",
    x = widgets.posSide(v) - 9,
    min = 1,
    max = rows * 2,
    integer = true,
    width = 30,
    showLabel = false,
    changed = function(self)
      morphSettings = nil -- Reset
      morphSteps[k] = self.value
      if type(shapeIndex) == "number" then
        loadShape(shapeOptions)
      end
    end
  })
end

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
  clearCells()
end

function onNote(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(true)
  end
end

function onRelease(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(false)
  end
end

function onTransport(start)
  if autoplayButton.value == true then
    playButton:setValue(start)
  end
end
