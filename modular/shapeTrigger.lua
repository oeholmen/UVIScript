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

-- TODO Create a variant with a 16x16 that only use shapes

local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local channel = 1
local gate = 90 -- TODO Param?
local ruleWidgets = {}
local resolutionNames = resolutions.getResolutionNames()
local resolution = 20 -- The default resolution
local velocity = 64
local rows = 8 -- Number of rows in the board
local cols = 8 -- Number of columns in the board
local cells = {} -- Holds the cell widgets
local evolve = false -- Every generation changes the base resolution to the resolution that was selected by chance
local dead = true -- Dead cells are played as pause - add an option for min live cells before accepting dead?
local locked = true -- Board is locked to move through all live cells before next gen - it starts locked to not kill the initial state
local currentRowIndex = 1
local currentColIndex = 1
local liveCells = 0 -- Holds the current live cells until next iteration
local fill = true
local shapeMenu
local shapeNames = shapes.getShapeNames()
local shapeMenuItems = {"Empty Board"}
for _,v in ipairs(shapeNames) do
  table.insert(shapeMenuItems, v)
end

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
      -- If evolve is active, and the sequencer is playing, cells preserve their resolution
      local preserve = isPlaying and evolve
      if preserve == false then
        cells[i][j].displayName = resolutionNames[resolution]
        cells[i][j].tooltip = resolutions.getResolution(resolution) .. ""
      end
    end
  end
end

local function loadShape(shapeIndex)
  if type(shapeIndex) == "nil" then
    shapeIndex = gem.getRandom(#shapeNames)
    shapeMenu:setValue(shapeIndex + 1, false) 
  end
  print("--- NEW SHAPE ---", shapeIndex)
  clearCells() -- Deactivate all cells
  local values = shapes.get(shapeIndex, {min=1,max=rows,length=cols})
  for col = 1, cols do
    local value = math.ceil(values[col])
    for row = 1, rows do
      cells[row][col].value = value == row or (fill and value > row)
    end
  end
  locked = true -- Lock to preserve the shape
end

-- Returns a random resolution from the live cells
local function getCell()
  local cell = cells[currentRowIndex][currentColIndex]

  if type(cell) == "nil" then
    locked = false
    print("No cell")
    return
  end

  print("Found cell.value @ currentRowIndex, currentColIndex", cell.value, currentRowIndex, currentColIndex)

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
  elseif dead then
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

local function seq(uniqueId)
  local note = 0
  locked = true -- Ensure the board is locked when starting to preserve the current state
  while isPlaying and seqIndex == uniqueId do
    -- When board has been unlocked, we can move one generation ahead
    if liveCells == 0 then
      countLiveCells()
    end
    if locked == false then
      loadShape()
    end
    local cell = getCell() -- Get cell at current pos
    if type(cell) ~= "nil" then
      local duration = tonumber(cell.tooltip)
      if cell.value then
        playNote(note, velocity, beat2ms(resolutions.getPlayDuration(duration, gate)), nil, channel)
        print("playNote", duration)
      end
      if cell.value or (cell.value == false and dead) then
        print("waitBeat", duration)
        waitBeat(duration)
      end
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
  width = 90,
  height = 22,
  x = 153,
  y = 5,
  cols = 10
})

shapeMenu = widgets.menu("Shape", shapeMenuItems, {
  tooltip = "If the board is empty or stale, a random shape will be selected",
  showLabel = false,
  width = 117,
  changed = function(self)
    clearCells()
    local shapeIndex = self.value - 1
    if shapeIndex > 0 then
      loadShape(shapeIndex)
    end
  end
})

widgets.button('Fill', fill, {
  tooltip = "Fill shape instead of drawing just the line",
  changed = function(self)
    fill = self.value
    shapeMenu:changed()
  end
})

widgets.menu("Base Resolution", resolution, resolutionNames, {
  tooltip = "Set the base resolution",
  showLabel = false,
  width = 60,
  changed = function(self)
    resolution = self.value
    clearCells()
    loadShape()
  end
})

widgets.numBox('Ch', channel, {
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
  end
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
