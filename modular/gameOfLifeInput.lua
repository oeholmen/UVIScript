-----------------------------------------------------------------------------------
-- Game of Life Input - Listens for incoming note events (rythm) on note number 0
-----------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local scales = require "includes.scales"
local shapes = require "includes.shapes"
local modular = require "includes.modular"

local backgroundColour = "404040"
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local title = "Game of Life Input"
local description = "A sequencer that use the rules from game of life to select notes"
local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local startNote = 36
local octaveRange = 2
local evolutionSpeed = 1000 -- Milliseconds
local rows = 8 -- Number of rows in the board
local cols = 12 -- Number of columns in the board
local equalRounds = 6 -- Number of stale rounds before shape is regenerated
local cells = {} -- Holds the cell widgets
local generationCounter = 0
local maxGenerations = 1000 -- Max generations before reset is forced
local shapeIndex
local fillProbability = 50
local generationLabel
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinition = scaleDefinitions[#scaleDefinitions]
local shapeMenu
local activeCells = {} -- Holds the currently active cells
local shapeNames = shapes.getShapeNames()
local shapeWidgets = {}
local shapeOptions = shapes.getShapeOptions()
local shapeMenuItems = {"Random Shape"}
for _,v in ipairs(shapeNames) do
  table.insert(shapeMenuItems, v)
end

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function clearCells()
  local scale = scales.createScale(scaleDefinition, startNote, (startNote+(octaveRange*12)-1))
  local scalePos = 1
  for i = 1, rows do
    for j = 1, cols do
      cells[i][j].enabled = false
      cells[i][j].value = scale[scalePos]
      cells[i][j].textColour = widgets.getColours().widgetTextColour
      scalePos = gem.inc(scalePos, 1, #scale)
    end
  end
end

local function updateShapeWidgets()
  -- Update widgets with values from the shape
  local callChanged = false
  for k,v in pairs(shapeWidgets) do
    v:setValue(shapeOptions[k], callChanged)
  end  
end

local function isFilled(row, value)
  return row == value or (row < value and gem.getRandomBoolean(fillProbability))
end

local function loadShape(options)
  local shape = shapeIndex
  local values
  if type(shape) == "nil" then
    shape = gem.getRandom(#shapeNames)
  end
  clearCells() -- Deactivate all cells
  print("--- NEW SHAPE ---", shape)
  local bounds = {
    min = 1,
    max = rows,
    length = cols,
  }
  values, shapeOptions = shapes.get(shape, bounds, options)
  updateShapeWidgets()
  for col = 1, cols do
    local value = math.ceil(values[col])
    for row = 1, rows do
      cells[row][col].enabled = isFilled(row, value)
    end
  end
end

local changeCount = 0
local previousChangeCount = 0
local equalCount = 0
local function updateBoard()
  -- Create a new board to hold the next generation
  local newGeneration = {}

  generationCounter = gem.inc(generationCounter)
  generationLabel.text = "Gen " .. generationCounter
  print("--- NEXT GENERATION! ---", generationCounter)

  -- Iterate through each cell on the board
  for i = 1, rows do
    newGeneration[i] = {}
    for j = 1, cols do
      local count = 0

      -- Count the number of live neighbors
      for x = -1, 1 do
        for y = -1, 1 do
          if x ~= 0 or y ~= 0 then
            local row = i + x
            local col = j + y

            -- Check if the cell is on the board
            if row >= 1 and row <= rows and col >= 1 and col <= cols then
              local val = 0
              if cells[row][col].enabled == true then
                val = 1
              end
              count = count + val
            end
          end
        end
      end

      -- Apply the rules of the game
      if cells[i][j].enabled == false and count == 3 then
        -- Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
        newGeneration[i][j] = 1
      elseif cells[i][j].enabled == true and count == 2 then
        -- Any live cell with two live neighbours lives on to the next generation.
        newGeneration[i][j] = 2
      elseif cells[i][j].enabled == true and count == 3 then
        -- Any live cell with three live neighbours lives on to the next generation.
        newGeneration[i][j] = 3
      elseif cells[i][j].enabled == true then
        -- All other live cells die in the next generation.
        newGeneration[i][j] = 4
      else
        -- All other dead cells stay dead.
        newGeneration[i][j] = 5
      end
    end
  end

  -- Update the cells for the next generation
  changeCount = 0
  activeCells = {} -- Reset active cells
  for i,v in ipairs(newGeneration) do
    for j,rule in ipairs(v) do
      local alive = rule < 4
      if cells[i][j].enabled ~= alive then
        changeCount = gem.inc(changeCount)
      end
      cells[i][j].enabled = alive
      if alive then
        table.insert(activeCells, cells[i][j])
      end
    end
  end

  if changeCount == previousChangeCount then
    equalCount = gem.inc(equalCount)
  end
  previousChangeCount = changeCount

  -- Reset if stale board
  if changeCount == 0 or #activeCells == 0 or equalCount > equalRounds or generationCounter > maxGenerations then
    print("Stale board...")
     -- Reset counters
    equalCount = 0
    generationCounter = 0
    loadShape()
  end
end

local function evolution(uniqueId)
  loadShape()
  while isPlaying and seqIndex == uniqueId do
    updateBoard()
    wait(evolutionSpeed)
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(evolution, seqIndex)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  clearCells()
end

local function getNote()
  for i = 1, rows do
    for j = 1, cols do
      cells[i][j].textColour = widgets.getColours().widgetTextColour
    end
  end
  if #activeCells == 0 then
    return
  end
  local cell = gem.getRandomFromTable(activeCells)
  cell.textColour = "yellow"
  return cell.value
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

widgets.label(title, {
  tooltip = description,
  width = widgets.getPanel().width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  x = 390,
  y = 5,
  xSpacing = 5,
  ySpacing = 5,
})

generationLabel = widgets.label("Gen " .. generationCounter, {
  tooltip = "Shows the current generation",
  backgroundColour = "transparent",
  textColour = "606060",
  width = 75,
})

modular.getForwardWidget()
modular.getChannelWidget()

--------------------------------------------------------------------------------
-- Board
--------------------------------------------------------------------------------

widgets.setSection({
  xSpacing = 0,
  ySpacing = 0,
})

widgets.panel({
  backgroundColour = backgroundColour,
  x = widgets.getPanel().x + 5,
  y = widgets.posUnder(widgets.getPanel()) + 5,
  width = 380,
  height = 190,
})

local spacing = 2
widgets.setSection({
  width = (widgets.getPanel().width - ((cols+1) * spacing)) / cols,
  height = (widgets.getPanel().height - ((rows+1) * spacing)) / rows,
  x = 2,
  y = 0,
  xSpacing = spacing,
  ySpacing = spacing,
  rowDirection = -1,
  row = rows - 1,
  cols = cols,
})

-- Create the cells
for i = 1, rows do
  cells[i] = {}
  for j = 1, cols do
    cells[i][j] = widgets.numBox("", startNote, {
      name = "r" .. i .. "c" .. j,
      showLabel = false,
      min = 0,
      max = 127,
      integer = true,
      unit = Unit.MidiKey,
    })
  end
end

--------------------------------------------------------------------------------
-- Shape Panel
--------------------------------------------------------------------------------

widgets.panel({
  backgroundColour = "303030",
  x = widgets.posSide(widgets.getPanel()),
  y = widgets.getPanel().y + 3,
  width = 174,
  height = widgets.getPanel().height - 5,
})

widgets.setSection({
  x = 7,
  y = 6,
  width = 160,
  height = 20,
  xSpacing = 5,
  ySpacing = 5,
  cols = 1,
})

shapeMenu = widgets.menu("Start Shape", shapeMenuItems, {
  tooltip = "If the board is empty or stale, the selected shape will be used for starting a new board",
  changed = function(self)
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
  changed = function(self)
    fillProbability = self.value
    shapeMenu:changed()
  end
})

shapeWidgets = shapes.getWidgets()

for k,v in pairs(shapeWidgets) do
  v.changed = function(self)
    shapeOptions[k] = self.value
    if type(shapeIndex) == "number" then
      loadShape(shapeOptions)
    end
  end
end

widgets.numBox('Regeneration Time', evolutionSpeed, {
  tooltip = "Set the time inteval between generations",
  unit = Unit.MilliSeconds,
  mapper = Mapper.Quartic,
  min = evolutionSpeed / 10,
  max = evolutionSpeed * 10,
  integer = true,
  changed = function(self)
    evolutionSpeed = self.value
  end
})

--------------------------------------------------------------------------------
-- Speed Panel
--------------------------------------------------------------------------------

widgets.panel({
  backgroundColour = "505050",
  x = widgets.posSide(widgets.getPanel()),
  y = widgets.getPanel().y,
  width = 147,
  height = widgets.getPanel().height,
})

widgets.setSection({
  x = 5,
  y = 6,
  width = 135,
  height = 20,
  xSpacing = 5,
  ySpacing = 5,
  cols = 1,
})

local scaleMenu = scales.widget()
scaleMenu.persistent = false -- Avoid running changed function on load, overwriting scaleInput

widgets.label("Scale Definition", {
  textColour = "#d0d0d0",
  backgroundColour = "transparent",
})

local scaleInput = scales.inputWidget(scaleDefinition)

scaleMenu.changed = function(self)
  print("scaleMenu.changed", self.selectedText)
  scaleInput.text = scales.getTextFromScaleDefinition(scaleDefinitions[self.value])
end

scaleInput.changed = function(self)
  print("scaleInput.changed", self.text)
  scaleDefinition = scales.getScaleDefinitionFromText(self.text)
  if #scaleDefinition == 0 then
    -- Ensure we have a scale...
    scaleMenu.value = #scaleDefinitions
    return
  end
  self.tooltip = scales.getScaleInputTooltip(scaleDefinition)
  clearCells()
end

widgets.numBox("Base Note", startNote, {
  min = 0,
  max = 127,
  integer = true,
  unit = Unit.MidiKey,
  changed = function(self)
    startNote = self.value
    clearCells()
  end
})

widgets.numBox("Octave Range", octaveRange, {
  min = 1,
  max = 9,
  integer = true,
  changed = function(self)
    octaveRange = self.value
    clearCells()
  end
})

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
  clearCells()
end

function onNote(e)
  if modular.isTrigger(e) then
    print("modular.handleTrigger", e.channel)
    if modular.handleTrigger(e, getNote()) then
      startPlaying()
    end
  else
    postEvent(e)
  end
end

function onRelease(e)
  if modular.isTrigger(e) then
    modular.handleReleaseTrigger(e)
  else
    postEvent(e)
  end
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
  return {scaleInput.text}
end

function onLoad(data)
  -- Check if we find a scale definition that matches the stored definition
  local scaleIndex = scales.getScaleDefinitionIndex(data[1])
  if type(scaleIndex) == "number" then
    print("onLoad, found scale", scaleIndex)
    scaleMenu.value = scaleIndex
  else
    scaleInput.text = data[1]
    scaleInput:changed()
  end
end
