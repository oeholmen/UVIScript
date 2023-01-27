--------------------------------------------------------------------------------
-- Grid Sequencer
--------------------------------------------------------------------------------

local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
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
local scales = require "includes.scales"
local notes = require "includes.notes"
local resolutions = require "includes.resolutions"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local playModes = {"Random", "->", "<-", "-><-", "<-->", "Follow ->", "Follow <-"}
local isPlaying = false
local defaultResolution = 23
local sequencerResolution
local grid = {} -- Holds the note inputs
local gridXY = {} -- Holds x and y axis positon and other settings
local startNote = 12 -- The start note for the grid - TODO Param?

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
  max = 9
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

  if playMode == "<-" or playMode == "<-->" or playMode == "Follow <-" then
    gridXY[axis].direction = -1
  else
    gridXY[axis].direction = 1
  end
end

local function handleFollow(axis)
  axis = gridXY[axis]
  axis.pos = axis.pos + axis.direction
  if axis.direction == 1 and axis.pos > axis.offset + axis.size or axis.pos > axis.max then
    axis.pos = axis.offset + 1
  elseif axis.pos <= axis.offset then
    axis.pos = axis.offset + axis.size
  end
end

-- playModes = {"Random", "->", "<-", "-><-", "<-->", "Follow ->", "Follow <-"}
local function getNote()
  local bothAxisAreFollow = string.sub(gridXY[1].playMode, 1, 6) == "Follow" and string.sub(gridXY[2].playMode, 1, 6) == "Follow"
  for i,v in ipairs(gridXY) do
    local otherAxis = 1
    if i == otherAxis then
      otherAxis = 2
    end
    local otherAxisIsFollow = string.sub(gridXY[otherAxis].playMode, 1, 6) == "Follow"
    if v.playMode == "Random" then
      if v.size > 1 then
        v.pos = gem.getRandom(v.offset + 1, v.offset + v.size)
      else
        v.pos = v.offset + v.size
      end
      local followProbability = 25 -- TODO Param?
      if otherAxisIsFollow and gem.getRandomBoolean(followProbability) then
        handleFollow(otherAxis)
      end
    elseif v.playMode == "->" or bothAxisAreFollow then
      v.pos = v.pos + v.direction
      if v.pos > v.offset + v.size or v.pos > v.max then
        v.pos = v.offset + 1
        if otherAxisIsFollow and bothAxisAreFollow == false then
          handleFollow(otherAxis)
        end
      end
    elseif v.playMode == "<-" then
      v.pos = v.pos + v.direction
      if v.pos <= v.offset then
        v.pos = v.offset + v.size
        if otherAxisIsFollow then
          handleFollow(otherAxis)
        end
      end
    elseif v.playMode == "-><-" or v.playMode == "<-->" then
      v.pos = v.pos + v.direction
      if v.pos <= v.offset then
        v.direction = 1
        v.pos = v.offset + 1
        if otherAxisIsFollow then
          handleFollow(otherAxis)
        end
      elseif v.pos > v.offset + v.size or v.pos > v.max then
        v.direction = -1
        v.pos = v.offset + v.size
        if otherAxisIsFollow then
          handleFollow(otherAxis)
        end
      end
    end
    v.pos = math.min(v.max, math.max(v.offset + 1, v.pos))
  end

  local noteInput = getGridCell(gridXY[1].pos, gridXY[2].pos)
  if type(noteInput) == "nil" then
    -- Failsafe - get a random input
    noteInput = gem.getRandomFromTable(grid)
  end
  return noteInput
end

local function resetGridPos()
  for axis=1,2 do
    if gridXY[axis].direction == 1 then
      gridXY[axis].pos = gridXY[axis].offset
    else
      gridXY[axis].pos = gridXY[axis].offset + gridXY[axis].size
    end
  end
end

local function sequenceRunner()
  resetGridPos()
  isPlaying = true
  while isPlaying do
    local noteInput = getNote()
    local note = noteInput.value
    local velocity = 64 -- TODO Param?
    local gate = 90 -- TODO Param?
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

local function setScale(rootNote, scale, startOctave, octaves)
  rootNote = rootNote - 1 + ((startOctave + 2) * 12)
  local scaleDefinitions = scales.getScaleDefinitions()
  local maxNote = rootNote + 1 + (octaves * 12)
  local scale = scales.createScale(scaleDefinitions[scale], rootNote, math.min(128, maxNote))
  local scaleIndex = 1
  local bgColour = menuBackgroundColour
  for _,v in ipairs(grid) do
    v:setValue(scale[scaleIndex])
    v.backgroundColour = bgColour
    scaleIndex = scaleIndex + 1
    if scaleIndex > #scale then
      scaleIndex = 1
      if bgColour == menuBackgroundColour then
        bgColour = "01012F"
      else
        bgColour = menuBackgroundColour
      end
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

local scalePanel = Panel("Scale")
scalePanel.backgroundColour = "404040"
scalePanel.x = 0
scalePanel.y = notePanel.y + notePanel.height
scalePanel.width = 720
scalePanel.height = 60

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

-- X Axis

local axisLabelX = settingsPanel:Label("AxisLabelX")
axisLabelX.text = "X-axis"
axisLabelX.tooltip = "Settings for the x-axis (horizontal)"
axisLabelX.textColour = labelBackgoundColour
axisLabelX.backgroundColour = labelTextColour
axisLabelX.fontSize = 28
axisLabelX.height = 45
axisLabelX.width = 75
axisLabelX.x = 7
axisLabelX.y = 7

local gridOffsetX = settingsPanel:Slider("GridOffsetX", gridXY[1].offset, 0, gridXY[1].max - 1)
gridOffsetX.displayName = "Offset"
gridOffsetX.tooltip = "Offset of x axis"
gridOffsetX.backgroundColour = menuBackgroundColour
gridOffsetX.textColour = menuTextColour
gridOffsetX.height = 45
gridOffsetX.width = 75
gridOffsetX.x = axisLabelX.x + axisLabelX.width + 5
gridOffsetX.y = axisLabelX.y
gridOffsetX.changed = function(self)
  gridXY[1].offset = gem.round(self.value)
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
seqPlayModeX.displayName = "Playmode"
seqPlayModeX.tooltip = "The sequencer play mode for the x (horizontal) axis"
seqPlayModeX.x = gridSizeX.x + gridSizeX.width + 5
seqPlayModeX.y = gridSizeX.y
seqPlayModeX.height = gridSizeX.height
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
axisLabelY.fontSize = axisLabelX.fontSize
axisLabelY.textColour = labelBackgoundColour
axisLabelY.backgroundColour = labelTextColour
axisLabelY.height = axisLabelX.height
axisLabelY.width = axisLabelX.width
axisLabelY.x = seqPlayModeX.x + seqPlayModeX.width + 69
axisLabelY.y = seqPlayModeX.y

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
  gridXY[2].offset = gem.round(self.value)
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
seqPlayModeY.displayName = "Playmode"
seqPlayModeY.tooltip = "The sequencer play mode for the y (vertical) axis"
seqPlayModeY.x = gridLengthY.x + gridLengthY.width + 5
seqPlayModeY.y = gridLengthY.y
seqPlayModeY.height = gridLengthY.height
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

local rowCounter = gridXY[2].max - 1
local columnCounter = 0
local colSpacing = 3
local rowSpacing = 2

for y=1,gridXY[2].max do
  for x=1,gridXY[1].max do
    --print("x, y, note", x, y, startNote)
    local gridCell = notePanel:NumBox("Cell" .. x .. '_' .. y, startNote, 0, 127, true)
    gridCell.enabled = getEnabledStatus(x, y)
    gridCell.showLabel = false
    gridCell.displayName = "Note"
    gridCell.tooltip = "The note to trigger in cell x:" .. x .. ', y:' .. y
    gridCell.unit = Unit.MidiKey
    gridCell.backgroundColour = menuBackgroundColour
    gridCell.textColour = menuTextColour
    gridCell.height = 24
    gridCell.width = 42
    gridCell.x = (colSpacing * 1) + (columnCounter * (gridCell.width + colSpacing))
    gridCell.y = (rowSpacing * 1.5) + ((gridCell.height + rowSpacing) * rowCounter)
    table.insert(grid, gridCell)
    startNote = startNote + 1
    columnCounter = columnCounter + 1
    if columnCounter >= gridXY[1].max then
      columnCounter = 0
      rowCounter = rowCounter - 1
    end
  end
end

local xyOffset = notePanel:XY('GridOffsetX', 'GridOffsetY')
xyOffset.bounds = {546, 6, 168, 112}
xyOffset.tooltip = "Adjust offset"

local xySize = notePanel:XY('GridSizeX', 'GridSizeY')
xySize.bounds = {xyOffset.x, xyOffset.y+xyOffset.height+4, xyOffset.width, xyOffset.height}
xyOffset.tooltip = "Adjust length"

--------------------------------------------------------------------------------
-- Resolution and Scale
--------------------------------------------------------------------------------

local seqResolution = scalePanel:Menu("SequencerResolution", resolutions.getResolutionNames())
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
end
seqResolution:changed()

local keyMenu = scalePanel:Menu("Key", notes.getNoteNames())
keyMenu.displayName = "Key"
keyMenu.tooltip = "The key"
keyMenu.showLabel = true
keyMenu.width = 90
keyMenu.x = seqResolution.x + seqResolution.width + 5
keyMenu.y = seqResolution.y
keyMenu.backgroundColour = menuBackgroundColour
keyMenu.textColour = menuTextColour
keyMenu.arrowColour = menuArrowColour
keyMenu.outlineColour = menuOutlineColour

local scalesNames = scales.getScaleNames()
local scaleMenu = scalePanel:Menu("Scale", scalesNames)
scaleMenu.selected = #scalesNames
scaleMenu.displayName = "Scale"
scaleMenu.tooltip = "The scale"
scaleMenu.showLabel = true
scaleMenu.width = 120
scaleMenu.x = keyMenu.x + keyMenu.width + 5
scaleMenu.y = keyMenu.y
scaleMenu.backgroundColour = menuBackgroundColour
scaleMenu.textColour = menuTextColour
scaleMenu.arrowColour = menuArrowColour
scaleMenu.outlineColour = menuOutlineColour

local startOctave = scalePanel:NumBox("StartOctave", -1, -2, 7, true)
startOctave.displayName = "Start octave"
startOctave.tooltip = "The octave to start from when creating the scale"
startOctave.backgroundColour = menuBackgroundColour
startOctave.textColour = menuTextColour
startOctave.height = 20
startOctave.width = scaleMenu.width
startOctave.x = scaleMenu.x + scaleMenu.width + 5
startOctave.y = scaleMenu.y + (scaleMenu.height / 2) + 3

local octaves = scalePanel:NumBox("Octaves", 9, 1, 9, true)
octaves.displayName = "Octaves"
octaves.tooltip = "Set the octave range"
octaves.backgroundColour = menuBackgroundColour
octaves.textColour = menuTextColour
octaves.height = 20
octaves.width = scaleMenu.width
octaves.x = startOctave.x + startOctave.width + 5
octaves.y = startOctave.y

keyMenu.changed = function(self)
  setScale(self.value, scaleMenu.value, startOctave.value, octaves.value)
end

scaleMenu.changed = function(self)
  setScale(keyMenu.value, self.value, startOctave.value, octaves.value)
end

startOctave.changed = function(self)
  setScale(keyMenu.value, scaleMenu.value, self.value, octaves.value)
end

octaves.changed = function(self)
  setScale(keyMenu.value, scaleMenu.value, startOctave.value, self.value)
end

keyMenu:changed()

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
