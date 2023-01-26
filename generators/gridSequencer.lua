--------------------------------------------------------------------------------
-- Grid Sequencer
--------------------------------------------------------------------------------

local buttonAlpha = 0.9
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local buttonBackgroundColourOff = "#ff084486"
local buttonBackgroundColourOn = "#ff02ACFE"
local buttonTextColourOff = "#ff22FFFF"
local buttonTextColourOn = "#efFFFFFF"
local backgroundColour = "202020" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "CFFFFE" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Includes
--------------------------------------------------------------------------------

local gem = require "includes.common"
local resolutions = require "includes.resolutions"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local playModes = {"Random", "->", "<-", "-><-", "<-->"}
local isPlaying = false
local defaultResolution = 23
local sequencerResolution
local grid = {} -- Holds the note inputs
local gridXY = {} -- Holds x and y axis positon and other settings
local startNote = 24 -- The start note for the grid

-- X Axis (index 1)
table.insert(gridXY, {
  pos = 0,
  direction = 1,
  playMode = playModes[1],
  size = 8,
  offset = 2,
  max = 12
})

-- Y Axis (index 2)
table.insert(gridXY, {
  pos = 0,
  direction = 1,
  playMode = playModes[1],
  size = 3,
  offset = 2,
  max = 8
})

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

--[[ local function getEnabledCells()
  local enabledCells = {}
  for _,v in ipairs(grid) do
    if v.enabled then
      table.insert(enabledCells, v)
    end
  end
  return enabledCells
end ]]

local function getGridCell(x, y)
  --print("Get grid cell x, y", x, y)
  --[[ local index = x * y -- TODO Find index using a formula
  return grid[index] ]]
  local cellName = "Cell" .. x .. '_' .. y
  for _,v in ipairs(grid) do
    if v.name == cellName then
      return v
    end
  end
end

local function flashNote(noteInput, duration)
  noteInput.textColour = "yellow"
  waitBeat(duration)
  noteInput.textColour = menuTextColour
end

local function setPlayMode(axis, playMode)
  gridXY[axis].playMode = playMode

  if playMode == "<-" or playMode == "<-->" then
    gridXY[axis].direction = -1
  else
    gridXY[axis].direction = 1
  end

  --print("axis, playMode, direction", axis, gridXY[axis].playMode, gridXY[axis].direction)
end

-- playModes = {"Random", "->", "<-", "-><-", "<-->"}
local function getNote()
  for i,v in ipairs(gridXY) do
    if v.playMode == "Random" then
      if v.size > 1 then
        v.pos = gem.getRandom(v.offset + 1, v.offset + v.size)
      else
        v.pos = v.offset + v.size
      end
    elseif v.playMode == "->" then
      v.pos = v.pos + v.direction
      if v.pos > v.offset + v.size or v.pos > v.max then
        v.pos = v.offset + 1
      end
    elseif v.playMode == "<-" then
      v.pos = v.pos + v.direction
      if v.pos <= v.offset then
        v.pos = v.offset + v.size
      end
    elseif v.playMode == "-><-" or v.playMode == "<-->" then
      v.pos = v.pos + v.direction
      if v.pos <= v.offset then
        v.direction = 1
        v.pos = v.offset + 1
      elseif v.pos > v.offset + v.size or v.pos > v.max then
        v.direction = -1
        v.pos = v.offset + v.size
      end
    end
    v.pos = math.min(v.max, v.pos)
  end

  local noteInput = getGridCell(gridXY[1].pos, gridXY[2].pos)
  if type(noteInput) == "nil" then
    -- Failsafe
    noteInput = grid[1]
  end
  return noteInput
end

local function resetGridPos()
  gridXY[1].pos = gridXY[1].offset
  gridXY[2].pos = gridXY[2].offset
end

local function sequenceRunner()
  isPlaying = true
  while isPlaying do
    local noteInput = getNote()
    local note = noteInput.value
    local velocity = 64 -- TODO Param
    local gate = 90 -- TODO Param
    local duration = sequencerResolution -- TODO Get resolution for the selected note/step
    local playDuration = resolutions.getPlayDuration(duration, gate)
    --print("Playing note", note)
    playNote(note, velocity, beat2ms(playDuration))
    spawn(flashNote, noteInput, playDuration)
    waitBeat(duration)
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  run(sequenceRunner)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetGridPos()
end

local function getEnabledStatus(x, y)
  local enabledX = x > gridXY[1].offset and x <= gridXY[1].offset + gridXY[1].size
  local enabledY = y > gridXY[2].offset and y <= gridXY[2].offset + gridXY[2].size
  return enabledX and enabledY
end

local function recalculateGrid()
  local i = 1
  for y=1,gridXY[2].max do
    for x=1,gridXY[1].max do
      grid[i].enabled = getEnabledStatus(x, y)
      i = i + 1
    end
  end  
end

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

local sequencerPanel = Panel("GridSequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 36

local settingsPanel = Panel("Settings")
settingsPanel.backgroundColour = "404040"
settingsPanel.x = 0
settingsPanel.y = sequencerPanel.y + sequencerPanel.height
settingsPanel.width = 720
settingsPanel.height = 60

local notePanel = Panel("Notes")
notePanel.backgroundColour = "black"
notePanel.x = 0
notePanel.y = settingsPanel.y + settingsPanel.height
notePanel.width = 720
notePanel.height = 240

--------------------------------------------------------------------------------
-- Widgets
--------------------------------------------------------------------------------

local spacing = 20

local sequencerLabel = sequencerPanel:Label("Label")
sequencerLabel.text = "Grid Sequencer"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.position = {0,0}
sequencerLabel.size = {135,25}

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = backgroundColourOff
autoplayButton.backgroundColourOn = backgroundColourOn
autoplayButton.textColourOff = textColourOff
autoplayButton.textColourOn = textColourOn
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = {100,22}
autoplayButton.x = sequencerPanel.width - (autoplayButton.width * 2) - 10
autoplayButton.y = 5

local playButton = sequencerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = backgroundColourOff
playButton.backgroundColourOn = backgroundColourOn
playButton.textColourOff = textColourOff
playButton.textColourOn = textColourOn
playButton.displayName = "Play"
playButton.size = autoplayButton.size
playButton.x = autoplayButton.x + autoplayButton.width + 5
playButton.y = autoplayButton.y
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

local seqResolution = settingsPanel:Menu("SequencerResolution", resolutions.getResolutionNames())
--seqResolution.showLabel = false
seqResolution.displayName = "Resolution"
seqResolution.tooltip = "The resolution to use"
seqResolution.selected = defaultResolution
seqResolution.x = 5
seqResolution.y = 5
seqResolution.height = 45
seqResolution.width = 90
seqResolution.backgroundColour = menuBackgroundColour
seqResolution.textColour = menuTextColour
seqResolution.arrowColour = menuArrowColour
seqResolution.outlineColour = menuOutlineColour
seqResolution.changed = function(self)
  sequencerResolution = resolutions.getResolution(self.value)
  --print("sequencerResolution", sequencerResolution)
end
seqResolution:changed()

-- X Axis

local axisLabelX = settingsPanel:Label("AxisLabelX")
axisLabelX.text = "X-axis"
axisLabelX.tooltip = "Settings for the x-axis (horizontal)"
axisLabelX.textColour = labelBackgoundColour
axisLabelX.backgroundColour = labelTextColour
axisLabelX.fontSize = 18
axisLabelX.height = seqResolution.height
axisLabelX.width = 45
axisLabelX.x = seqResolution.x + seqResolution.width + 20
axisLabelX.y = seqResolution.y

local gridOffsetX = settingsPanel:Slider("GridOffsetX", gridXY[1].offset, 0, gridXY[1].max - 1)
gridOffsetX.displayName = "Offset"
gridOffsetX.tooltip = "Offset of x axis"
gridOffsetX.backgroundColour = menuBackgroundColour
gridOffsetX.textColour = menuTextColour
gridOffsetX.height = 45
gridOffsetX.width = 75
gridOffsetX.x = axisLabelX.x + axisLabelX.width + 5
gridOffsetX.y = seqResolution.y
gridOffsetX.changed = function(self)
  gridXY[1].offset = gem.round(self.value)
  resetGridPos()
  recalculateGrid()
end

local gridSizeX = settingsPanel:Slider("GridSizeX", gridXY[1].size, 1, gridXY[1].max)
gridSizeX.displayName = "Length"
gridSizeX.tooltip = "Length of x axis"
gridSizeX.backgroundColour = menuBackgroundColour
gridSizeX.textColour = menuTextColour
gridSizeX.height = gridOffsetX.height
gridSizeX.width = 75
gridSizeX.x = gridOffsetX.x + gridOffsetX.width + 5
gridSizeX.y = gridOffsetX.y
gridSizeX.changed = function(self)
  gridXY[1].size = gem.round(self.value)
  recalculateGrid()
end

local seqPlayModeX = settingsPanel:Menu("SequencerPlayModeX", playModes)
--seqPlayModeX.showLabel = false
seqPlayModeX.displayName = "Playmode"
seqPlayModeX.tooltip = "The sequencer play mode for the x (horizontal) axis"
seqPlayModeX.x = gridSizeX.x + gridSizeX.width + 5
seqPlayModeX.y = seqResolution.y
seqPlayModeX.height = seqResolution.height
seqPlayModeX.width = gridSizeX.width
seqPlayModeX.backgroundColour = menuBackgroundColour
seqPlayModeX.textColour = menuTextColour
seqPlayModeX.arrowColour = menuArrowColour
seqPlayModeX.outlineColour = menuOutlineColour
seqPlayModeX.changed = function(self)
  setPlayMode(1, self.text)
end
seqPlayModeX:changed()

-- Y Axis

local axisLabelY = settingsPanel:Label("AxisLabelY")
axisLabelY.text = "Y-axis"
axisLabelY.tooltip = "Settings for the y-axis (vertical)"
axisLabelY.fontSize = 18
axisLabelY.textColour = labelBackgoundColour
axisLabelY.backgroundColour = labelTextColour
axisLabelY.height = seqPlayModeX.height
axisLabelY.width = axisLabelX.width
axisLabelY.x = seqPlayModeX.x + seqPlayModeX.width + 20
axisLabelY.y = seqResolution.y

local gridOffsetY = settingsPanel:Slider("GridOffsetY", gridXY[2].offset, 0, gridXY[2].max - 1)
gridOffsetY.displayName = "Offset"
gridOffsetY.tooltip = "Offset of y axis"
gridOffsetY.backgroundColour = menuBackgroundColour
gridOffsetY.textColour = menuTextColour
gridOffsetY.height = gridOffsetX.height
gridOffsetY.width = gridOffsetX.width
gridOffsetY.x = axisLabelY.x + axisLabelY.width + 5
gridOffsetY.y = gridOffsetX.y
gridOffsetY.changed = function(self)
  gridXY[2].offset = gridXY[2].max - gem.round(self.value) - 1
  resetGridPos()
  recalculateGrid()
end

local gridLengthY = settingsPanel:Slider("GridSizeY", gridXY[2].size, 1, gridXY[2].max)
gridLengthY.displayName = "Length"
gridLengthY.tooltip = "Length of y axis"
gridLengthY.backgroundColour = menuBackgroundColour
gridLengthY.textColour = menuTextColour
gridLengthY.height = gridOffsetY.height
gridLengthY.width = gridOffsetY.width
gridLengthY.x = gridOffsetY.x + gridOffsetY.width + 5
gridLengthY.y = gridOffsetY.y
gridLengthY.changed = function(self)
  gridXY[2].size = gem.round(self.value)
  recalculateGrid()
end

local seqPlayModeY = settingsPanel:Menu("SequencerPlayModeY", playModes)
--seqPlayModeY.showLabel = false
seqPlayModeY.displayName = "Playmode"
seqPlayModeY.tooltip = "The sequencer play mode for the y (vertical) axis"
seqPlayModeY.x = gridLengthY.x + gridLengthY.width + 5
seqPlayModeY.y = seqResolution.y
seqPlayModeY.height = seqResolution.height
seqPlayModeY.width = gridLengthY.width
seqPlayModeY.backgroundColour = menuBackgroundColour
seqPlayModeY.textColour = menuTextColour
seqPlayModeY.arrowColour = menuArrowColour
seqPlayModeY.outlineColour = menuOutlineColour
seqPlayModeY.changed = function(self)
  setPlayMode(2, self.text)
end
seqPlayModeY:changed()

--------------------------------------------------------------------------------
-- Note Grid
--------------------------------------------------------------------------------

local rowCounter = 0
local columnCounter = 0
local colSpacing = 10
local rowSpacing = 5

for y=1,gridXY[2].max do
  for x=1,gridXY[1].max do
    --print("x, y, note", x, y, startNote)
    local gridCell = notePanel:NumBox("Cell" .. x .. '_' .. y, startNote, 0, 127, true)
    gridCell.enabled = getEnabledStatus(x, y)
    gridCell.showLabel = false
    gridCell.displayName = "Note"
    gridCell.tooltip = "The note to trigger in this cell"
    gridCell.unit = Unit.MidiKey
    gridCell.backgroundColour = menuBackgroundColour
    gridCell.textColour = menuTextColour
    gridCell.height = 22
    gridCell.width = 33
    gridCell.x = (colSpacing * 1.5) + (columnCounter * (gridCell.width + colSpacing))
    gridCell.y = (rowSpacing * 3) + ((gridCell.height + rowSpacing) * rowCounter)
    table.insert(grid, gridCell)
    startNote = startNote + 1
    columnCounter = columnCounter + 1
    if columnCounter >= gridXY[1].max then
      columnCounter = 0
      rowCounter = rowCounter + 1
    end
  end
end

local xyOffset = notePanel:XY('GridOffsetX', 'GridOffsetY')
xyOffset.bounds = {540, 6, 168, 112}
xyOffset.tooltip = "Adjust offset"

local xySize = notePanel:XY('GridSizeX', 'GridSizeY')
xySize.bounds = {xyOffset.x, xyOffset.y+xyOffset.height+3, xyOffset.width, xyOffset.height}
xyOffset.tooltip = "Adjust length"

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

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
