-----------------------------------------------------------------------------------
-- Game of Life Input - Listens for incoming note events (rythm) on note number 0
-----------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local scales = require "includes.scales"
local shapes = require "includes.shapes"
local modular = require "includes.modular"

setBackgroundColour("404040")

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local title = "Game of Life Input"
local description = "A sequencer that use the rules from game of life to select notes"
local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local checkId = 0 -- Holds the unique id for checking if there are any notes playing
local startNote = 36
local octaveRange = 2
local evolutionSpeed = 1000 -- Milliseconds
local rows = 12 -- Number of rows in the board
local cols = 12 -- Number of columns in the board
local equalRounds = 6 -- Number of stale rounds before shape is regenerated
local cells = {} -- Holds the cell widgets
local generationCounter = 0
local maxGenerations = 1000 -- Max generations before reset is forced
local shapeIndex
local fillProbability = 50
local generationButton
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinition = scaleDefinitions[#scaleDefinitions]
local playPos = {}--0 -- Holds the play position per channel (voice) in the active cells
local changeCount = 0 -- Holds the number of changed cells in the current generation
local previousChangeCount = 0 -- Holds the number of changed cells in the previous generation
local equalCount = 0 -- Holds the count for equal cells between generations
local shapeMenu
local playModes = {"Right", "Left", "Drunk", "Random"}
local playMode = playModes[1]
local activeCells = {} -- Holds the currently active cells
local shapeNames = shapes.getShapeNames()
local shapeWidgets = {}
local shapeOptions = shapes.getShapeOptions()
local shapeMenuItems = {"Random Shape"}
for _,v in ipairs(shapeNames) do
  table.insert(shapeMenuItems, v)
end

--------------------------------------------------------------------------------
-- Cell Colours
--------------------------------------------------------------------------------

local textColourInactive = widgets.getColours().widgetTextColour
local backgroundColourInactive = widgets.getColours().widgetBackgroundColour
local textColourActive = "efefef"
local backgroundColourActive = "009933"
local textColourPlaying = "404040"
local backgroundColourPlaying = "yellow"

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function setScale()
  local scale = scales.createScale(scaleDefinition, startNote, (startNote+(octaveRange*12)-1))
  local scaleIndex = 1
  for i = 1, rows do
    for j = 1, cols do
      cells[i][j].value = scale[scaleIndex]
      scaleIndex = gem.inc(scaleIndex, 1, #scale)
    end
  end
end

local function setInactive(row, col)
  cells[row][col].displayName = "0"
  cells[row][col].textColour = textColourInactive
  cells[row][col].backgroundColour = backgroundColourInactive
end

local function setActive(row, col, populateActiveCells)
  cells[row][col].displayName = "1"
  cells[row][col].textColour = textColourActive
  cells[row][col].backgroundColour = backgroundColourActive
  if populateActiveCells == true then
    table.insert(activeCells, cells[row][col])
  end
end

local function clearCells()
  generationCounter = 0
  generationButton.displayName = "Gen " .. generationCounter
  playPos = {}--0
  activeCells = {}
  for i = 1, rows do
    for j = 1, cols do
      setInactive(i, j)
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

local function loadShape(forceNew)
  local shape = shapeIndex
  local options
  local values
  forceNew = forceNew == true or type(shape) == "nil"
  if forceNew == false then
    options = shapeOptions
  end
  if type(shape) == "nil" then
    shape = gem.getRandom(#shapeNames)
  end
  clearCells() -- Deactivate all cells
  print("--- LOAD SHAPE ---", shape)
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
      if isFilled(row, value) then
        setActive(row, col, true)
      end
    end
  end
end

local function updateBoard()
  -- Create a new board to hold the next generation
  local newGeneration = {}

  generationCounter = gem.inc(generationCounter)
  generationButton.displayName = "Gen " .. generationCounter
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
              count = count + tonumber(cells[row][col].displayName)
            end
          end
        end
      end

      -- Apply the rules of the game
      if cells[i][j].displayName == "0" and count == 3 then
        -- Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
        newGeneration[i][j] = 1
      elseif cells[i][j].displayName == "1" and count == 2 then
        -- Any live cell with two live neighbours lives on to the next generation.
        newGeneration[i][j] = 2
      elseif cells[i][j].displayName == "1" and count == 3 then
        -- Any live cell with three live neighbours lives on to the next generation.
        newGeneration[i][j] = 3
      elseif cells[i][j].displayName == "1" then
        -- All other live cells die in the next generation.
        newGeneration[i][j] = 4
      else
        -- All other dead cells stay dead.
        newGeneration[i][j] = 5
      end
    end
  end

  -- Update the cells for the next generation
  activeCells = {} -- Reset active cells
  changeCount = 0
  for i,v in ipairs(newGeneration) do
    for j,rule in ipairs(v) do
      local alive = rule < 4
      local hasChanged = (cells[i][j].displayName == "1" and alive == false) or (cells[i][j].displayName == "0" and alive == true)
      if hasChanged then
        changeCount = gem.inc(changeCount)
      end
      if alive then
        setActive(i, j, true)
      else
        setInactive(i, j)
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
    generationButton.displayName = "Stale board"
     -- Reset counters
    equalCount = 0
    loadShape()
  end
end

local function evolution(uniqueId)
  print("Start evolution", uniqueId)
  while isPlaying and seqIndex == uniqueId do
    if generationButton.value then
      updateBoard()
    end
    print("evolutionSpeed", evolutionSpeed)
    wait(evolutionSpeed)
  end
end

local function resetCellColours()
  for i = 1, rows do
    for j = 1, cols do
      if cells[i][j].displayName == "1" then
        setActive(i, j)
      else
        setInactive(i, j)
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
  run(evolution, seqIndex)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetCellColours()
end

local function getPlayPos(channel)
  -- Only one cell...
  if #activeCells == 1 then
    return 1
  end

  -- Select a random play position
  if playMode == "Random" then
    return gem.getRandom(#activeCells)
  end

  -- Walk up or down the scale
  local increment = 1
  local resetAt = #activeCells
  local resetTo = 1
  if playMode == "Left" or (playMode == "Drunk" and gem.getRandomBoolean()) then
    increment = -1
    resetAt = 1
    resetTo = #activeCells
  end
  if type(playPos[channel]) == "nil" then
    playPos[channel] = 0
  end
  return gem.inc(playPos[channel], increment, resetAt, resetTo)
end

local function getNote(channel)
  if #activeCells == 0 then
    print("getNote: no active cells")
    return
  end
  if type(channel) == "nil" then
    channel = 1
  end
  resetCellColours()
  playPos[channel] = getPlayPos(channel)
  local cell = activeCells[playPos[channel]]
  if type(cell) == "nil" then
    return
  end
  cell.textColour = textColourPlaying
  cell.backgroundColour = backgroundColourPlaying
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
  x = 240,
  y = 5,
  xSpacing = 5,
  ySpacing = 5,
  width = 75,
})

widgets.label("Play Direction", {
  textColour = "404040",
  backgroundColour = "transparent",
})

widgets.menu("Play Mode", playModes, {
  tooltip = "Set the play direction for the sequencer",
  showLabel = false,
  changed = function(self) playMode = self.selectedText end
})

generationButton = widgets.button("Gen " .. generationCounter, true, {
  tooltip = "Turn off to pause automatic generation",
})

widgets.button("Advance", {
  tooltip = "Advance the board to the next generation",
  changed = function() updateBoard() end
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
  backgroundColour = "404040",
  x = widgets.getPanel().x + 5,
  y = widgets.posUnder(widgets.getPanel()) + 5,
  width = 360,
  height = 200,
})

local spacing = 1
widgets.setSection({
  width = (widgets.getPanel().width - ((cols+1) * spacing)) / cols,
  height = (widgets.getPanel().height - ((rows+1) * spacing)) / rows,
  x = 1,
  y = 1,
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
    cells[i][j] = widgets.numBox("0", startNote, {
      name = "r" .. i .. "c" .. j,
      showLabel = false,
      unit = Unit.MidiKey,
    })
  end
end

--------------------------------------------------------------------------------
-- Shape Panel
--------------------------------------------------------------------------------

widgets.panel({
  backgroundColour = "303030",
  x = widgets.posSide(widgets.getPanel()) + 5,
  y = widgets.getPanel().y,
  width = 180,
  height = widgets.getPanel().height,
})

widgets.setSection({
  x = 7,
  y = 6,
  width = 165,
  height = 20,
  xSpacing = 5,
  ySpacing = 8,
  cols = 1,
})

shapeMenu = widgets.menu("Shape", shapeMenuItems, {
  tooltip = "If the board is empty or stale, the selected shape will be used for starting a new board",
  changed = function(self)
    shapeIndex = self.value - 1
    if shapeIndex == 0 then
      clearCells()
      shapeIndex = nil
    else
      loadShape(true)
    end
  end
})

widgets.numBox('Shape Fill', fillProbability, {
  tooltip = "Set a fill probability for the selected shape. If fill is 0, the shape is drawn as a line, if fill is 100 it will be drawn solid.",
  unit = Unit.Percent,
  changed = function(self)
    fillProbability = self.value
    if type(shapeIndex) == "number" then
      loadShape()
    end
  end
})

shapeWidgets = shapes.getWidgets()

for k,v in pairs(shapeWidgets) do
  v.changed = function(self)
    shapeOptions[k] = self.value
    if type(shapeIndex) == "number" then
      loadShape()
    end
  end
end

widgets.numBox('Regeneration Time', evolutionSpeed, {
  tooltip = "Set the time inteval between generations",
  unit = Unit.MilliSeconds,
  mapper = Mapper.Quartic,
  min = evolutionSpeed / 10,
  max = evolutionSpeed * 100,
  integer = true,
  changed = function(self)
    evolutionSpeed = self.value
  end
})

--------------------------------------------------------------------------------
-- Scale Panel
--------------------------------------------------------------------------------

widgets.panel({
  backgroundColour = "505050",
  x = widgets.posSide(widgets.getPanel()),
  y = widgets.getPanel().y,
  width = 159,
  height = widgets.getPanel().height,
})

widgets.setSection({
  x = 5,
  y = 6,
  width = 147,
  height = 20,
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
  scaleDefinition = scales.handleScaleInputChanged(self, scaleMenu)
  setScale()
end

widgets.button("Random Scale", {
  tooltip = "Create a random scale",
  changed = function()
    scaleInput.text = scales.getTextFromScaleDefinition(scales.createRandomScale())
  end
})

widgets.numBox("Base Note", startNote, {
  min = 0,
  max = 127,
  integer = true,
  unit = Unit.MidiKey,
  changed = function(self)
    startNote = self.value
    setScale()
  end
})

widgets.numBox("Octave Range", octaveRange, {
  min = 1,
  max = 9,
  integer = true,
  changed = function(self)
    octaveRange = self.value
    setScale()
  end
})

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
  setScale() -- TODO This might overwrite manually set notes on load - TEST
end

function onNote(e)
  if modular.isTrigger(e) then
    if modular.handleTrigger(e, getNote(e.channel)) then
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
    scaleMenu:setValue(scaleIndex)
  end
  scaleInput.text = data[1]
  scaleInput:changed()
end
