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
local knobFillColour = "E6D5B8" -- Light

local colours = {
  backgroundColour = backgroundColour,
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = labelTextColour,
  menuBackgroundColour = menuBackgroundColour,
  menuArrowColour = menuArrowColour,
  menuOutlineColour = menuOutlineColour,
  backgroundColourOff = backgroundColourOff,
  backgroundColourOn = backgroundColourOn,
  textColourOff = textColourOff,
  textColourOn = textColourOn,
}

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Includes
--------------------------------------------------------------------------------

local gem = require "includes.common"
local scales = require "includes.scales"
local notes = require "includes.notes"
local rythmicFragments = require "includes.rythmicFragments"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local playModes = {"Random", "->", "<-", "-><-", "<-->", "Follow ->", "Follow <-"}
local isPlaying = false
local sequencerResolution = 0.25 -- Fallback value
local paramsPerFragment = {} -- Holds the rythmic fragments
local grid = {} -- Holds the note inputs
local listeners = {} -- Holds the note listeners
local gridXY = {} -- Holds x and y axis positon and other settings
local gateInput
local gateRandomization

-- X Axis (index 1)
table.insert(gridXY, {
  pos = 0,
  direction = 1,
  playMode = playModes[1],
  probability = 100,
  size = 8,
  offset = 2,
  max = 12
})

-- Y Axis (index 2)
table.insert(gridXY, {
  pos = 0,
  direction = 1,
  playMode = playModes[1],
  probability = 100,
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

local function getCell(x, y, prefix, table)
  --print("Get grid cell x, y", x, y)
  --[[ local index = x * y -- TODO Find index using a formula
  return grid[index] ]]
  local cellName = prefix .. x .. '_' .. y
  for _,v in ipairs(table) do
    if v.name == cellName then
      return v
    end
  end
end

local function showListeners(show)
  for i,v in ipairs(grid) do
    if show then
      v.width = 30
    else
      v.width = 42
    end
    listeners[i].visible = show
  end
end

local function isWithinSelectedGrid(x, y)
  local enabledX = x > gridXY[1].offset and x <= gridXY[1].offset + gridXY[1].size
  local enabledY = y > gridXY[2].offset and y <= gridXY[2].offset + gridXY[2].size
  return enabledX and enabledY
end

local function recalculateGrid()
  local i = 1
  for y=1,gridXY[2].max do
    for x=1,gridXY[1].max do
      if isWithinSelectedGrid(x, y) then
        grid[i].textColour = "green"
        grid[i].backgroundColour = "052525"
        --grid[i].enabled = true
      else
        grid[i].textColour = menuTextColour
        grid[i].backgroundColour = menuBackgroundColour
        --grid[i].enabled = false
      end
      i = i + 1
    end
  end  
end

local function flashNote(noteInput, duration)
  noteInput.textColour = "yellow"
  waitBeat(duration)
  --noteInput.textColour = "green"
  recalculateGrid()
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
local function advanceByPlayMode(v, i)
  local bothAxisAreFollow = string.sub(gridXY[1].playMode, 1, 6) == "Follow" and string.sub(gridXY[2].playMode, 1, 6) == "Follow"
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
      if otherAxisIsFollow then
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

local function getNote()
  for i,v in ipairs(gridXY) do
    if gem.getRandomBoolean(v.probability) then
      advanceByPlayMode(v, i)
    end
  end

  return getCell(gridXY[1].pos, gridXY[2].pos, "Note", grid)
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

local function getGate()
  return gem.randomizeValue(gateInput.value, gateInput.min, gateInput.max, gateRandomization.value)
end

local function sequenceRunner()
  resetGridPos()
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatCount = 0
  local fragmentRepeatProbability = 0
  local duration = nil
  local reverseFragment = false
  local rest = false
  isPlaying = true
  while isPlaying do
    local noteInput = getNote()
    local velocity = 64 -- Default velocity - override in velocity event processor if required
    -- Get resolution from fragments
    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = rythmicFragments.getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
    if type(duration) == "nil" then
      -- Fallback to the default resolution if not found in fragment
      duration = sequencerResolution
    end
    if type(noteInput) ~= "nil" and rest == false then
      local note = noteInput.value
      local playDuration = rythmicFragments.resolutions.getPlayDuration(duration, getGate())
      playNote(note, velocity, beat2ms(playDuration))
      if type(activeFragment) == "table" then
        for i,v in ipairs(paramsPerFragment) do
          if activeFragment.i == i then
            spawn(rythmicFragments.flashFragmentActive, v.fragmentActive, duration)
          end
        end
      end
      spawn(flashNote, noteInput, playDuration)
    end
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
      --[[ if bgColour == menuBackgroundColour then
        bgColour = "01012F"
      else
        bgColour = menuBackgroundColour
      end ]]
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

local notePanel = Panel("Notes")
notePanel.backgroundColour = "black"
notePanel.x = 0
notePanel.y = sequencerPanel.y + sequencerPanel.height
notePanel.width = 720
notePanel.height = 240

local settingsPanel = Panel("Scale")
settingsPanel.backgroundColour = "404040"
settingsPanel.x = 5
settingsPanel.y = notePanel.y + notePanel.height + 5
settingsPanel.width = 244
settingsPanel.height = 105

local axisPanel = Panel("AxisPanel")
axisPanel.backgroundColour = "404040"
axisPanel.x = settingsPanel.x + settingsPanel.width + 5
axisPanel.y = settingsPanel.y
axisPanel.width = 460
axisPanel.height = 105

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "404040"
rythmPanel.x = settingsPanel.x
rythmPanel.y = settingsPanel.y + settingsPanel.height + 5
rythmPanel.width = 710
rythmPanel.height = settingsPanel.height

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

local showListenersButton = sequencerPanel:OnOffButton("ShowListeners", false)
showListenersButton.backgroundColourOff = backgroundColourOff
showListenersButton.backgroundColourOn = backgroundColourOn
showListenersButton.textColourOff = textColourOff
showListenersButton.textColourOn = textColourOn
showListenersButton.displayName = "Show Listeners"
showListenersButton.tooltip = "Show listeners for each note"
showListenersButton.size = {100,22}
showListenersButton.x = sequencerPanel.width - (showListenersButton.width * 3) - 10
showListenersButton.y = 5
showListenersButton.changed = function(self)
  showListeners(self.value)
end

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = backgroundColourOff
autoplayButton.backgroundColourOn = backgroundColourOn
autoplayButton.textColourOff = textColourOff
autoplayButton.textColourOn = textColourOn
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = showListenersButton.size
autoplayButton.x = showListenersButton.x + showListenersButton.width + 5
autoplayButton.y = showListenersButton.y

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
-- Note Grid
--------------------------------------------------------------------------------

local rowCounter = gridXY[2].max - 1
local columnCounter = 0
local colSpacing = 3
local rowSpacing = 2
local noteListen = nil
local noteIndex = 0

for y=1,gridXY[2].max do
  for x=1,gridXY[1].max do
    --print("x, y, note", x, y, startNote)
    local gridCell = notePanel:NumBox("Note" .. x .. '_' .. y, noteIndex, 0, 127, true)
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

    local listen = notePanel:OnOffButton("Listen" .. x .. '_' .. y)
    listen.visible = false
    listen.displayName = "L"
    listen.tooltip = "Note learn"
    listen.persistent = false
    listen.textColourOff = "white"
    listen.backgroundColourOn = "green"
    listen.height = gridCell.height
    listen.width = 14
    listen.x = gridCell.x + 30
    listen.y = gridCell.y
    listen.changed = function(self)
      if self.value then
        noteListen = {x,y}
        print("noteListen", x, y)
      else
        noteListen = nil
      end
    end
    table.insert(listeners, listen)

    noteIndex = noteIndex + 1
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
-- Axis Settings
--------------------------------------------------------------------------------

local xSpacing = 10

-- X Axis

local axisLabelX = axisPanel:Label("AxisLabelX")
axisLabelX.text = "X-axis"
axisLabelX.tooltip = "Settings for the x-axis (horizontal)"
axisLabelX.textColour = labelBackgoundColour
axisLabelX.backgroundColour = labelTextColour
axisLabelX.fontSize = 22
axisLabelX.height = 40
axisLabelX.width = 60
axisLabelX.x = 5
axisLabelX.y = 5

local gridOffsetX = axisPanel:Slider("GridOffsetX", gridXY[1].offset, 0, gridXY[1].max - 1)
gridOffsetX.displayName = "Offset"
gridOffsetX.tooltip = "Offset of x axis"
gridOffsetX.backgroundColour = menuBackgroundColour
gridOffsetX.textColour = menuTextColour
gridOffsetX.height = 45
gridOffsetX.width = 75
gridOffsetX.x = axisLabelX.x + axisLabelX.width + xSpacing
gridOffsetX.y = 0
gridOffsetX.changed = function(self)
  gridXY[1].offset = gem.round(self.value)
  recalculateGrid()
end

local gridSizeX = axisPanel:Slider("GridSizeX", gridXY[1].size, 1, gridXY[1].max)
gridSizeX.displayName = "Length"
gridSizeX.tooltip = "Length of x axis"
gridSizeX.backgroundColour = menuBackgroundColour
gridSizeX.textColour = menuTextColour
gridSizeX.height = gridOffsetX.height
gridSizeX.width = 75
gridSizeX.x = gridOffsetX.x + gridOffsetX.width + xSpacing
gridSizeX.y = gridOffsetX.y
gridSizeX.changed = function(self)
  gridXY[1].size = gem.round(self.value)
  recalculateGrid()
end

local seqPlayModeX = axisPanel:Menu("SequencerPlayModeX", playModes)
seqPlayModeX.displayName = "Mode"
seqPlayModeX.tooltip = "The sequencer play mode for the x axis (horizontal)"
seqPlayModeX.x = gridSizeX.x + gridSizeX.width + xSpacing
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

local probabilityX = axisPanel:Knob("ProbabilityX", 100, 0, 100, true)
probabilityX.unit = Unit.Percent
probabilityX.displayName = "Probability X"
probabilityX.tooltip = "Set the probability that the position will advance on the x axis (horizontal)"
probabilityX.backgroundColour = widgetBackgroundColour
probabilityX.fillColour = knobFillColour
probabilityX.outlineColour = labelBackgoundColour
probabilityX.showPopupDisplay = true
probabilityX.height = 39
probabilityX.width = 120
probabilityX.y = 10
probabilityX.x = seqPlayModeX.x + seqPlayModeX.width + xSpacing
probabilityX.changed = function(self)
  gridXY[1].probability = self.value
end

-- Y Axis

local axisLabelY = axisPanel:Label("AxisLabelY")
axisLabelY.text = "Y-axis"
axisLabelY.tooltip = "Settings for the y-axis (vertical)"
axisLabelY.fontSize = axisLabelX.fontSize
axisLabelY.textColour = labelBackgoundColour
axisLabelY.backgroundColour = labelTextColour
axisLabelY.height = axisLabelX.height
axisLabelY.width = axisLabelX.width
axisLabelY.x = axisLabelX.x
axisLabelY.y = axisLabelX.y + axisLabelX.height + 15

local gridOffsetY = axisPanel:Slider("GridOffsetY", gridXY[2].offset, 0, gridXY[2].max - 1)
gridOffsetY.displayName = "Offset"
gridOffsetY.tooltip = "Offset of y axis"
gridOffsetY.backgroundColour = menuBackgroundColour
gridOffsetY.textColour = menuTextColour
gridOffsetY.height = gridOffsetX.height
gridOffsetY.width = gridOffsetX.width
gridOffsetY.x = axisLabelY.x + axisLabelY.width + xSpacing
gridOffsetY.y = gridOffsetX.y + gridOffsetX.height + 10
gridOffsetY.changed = function(self)
  gridXY[2].offset = gem.round(self.value)
  recalculateGrid()
end

local gridLengthY = axisPanel:Slider("GridSizeY", gridXY[2].size, 1, gridXY[2].max)
gridLengthY.displayName = "Length"
gridLengthY.tooltip = "Length of y axis"
gridLengthY.backgroundColour = menuBackgroundColour
gridLengthY.textColour = menuTextColour
gridLengthY.height = gridOffsetY.height
gridLengthY.width = gridOffsetY.width
gridLengthY.x = gridOffsetY.x + gridOffsetY.width + xSpacing
gridLengthY.y = gridOffsetY.y
gridLengthY.changed = function(self)
  gridXY[2].size = gem.round(self.value)
  recalculateGrid()
end

local seqPlayModeY = axisPanel:Menu("SequencerPlayModeY", playModes)
seqPlayModeY.displayName = "Mode"
seqPlayModeY.tooltip = "The sequencer play mode for the y axis (vertical)"
seqPlayModeY.x = gridLengthY.x + gridLengthY.width + xSpacing
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

local probabilityY = axisPanel:Knob("ProbabilityY", 100, 0, 100, true)
probabilityY.unit = Unit.Percent
probabilityY.displayName = "Probability Y"
probabilityY.tooltip = "Set the probability that the position will advance on the y axis (vertical)"
probabilityY.backgroundColour = widgetBackgroundColour
probabilityY.fillColour = knobFillColour
probabilityY.outlineColour = labelBackgoundColour
probabilityY.showPopupDisplay = true
probabilityY.height = 39
probabilityY.width = 120
probabilityY.y = probabilityX.y + probabilityX.height + 15
probabilityY.x = probabilityX.x
probabilityY.changed = function(self)
  gridXY[2].probability = self.value
end

--------------------------------------------------------------------------------
-- Resolution and Scale
--------------------------------------------------------------------------------

local keyMenu = settingsPanel:Menu("Key", notes.getNoteNames())
keyMenu.displayName = "Key"
keyMenu.tooltip = "The key to set for the notes in the grid"
keyMenu.showLabel = true
keyMenu.width = 108
keyMenu.x = 10
keyMenu.y = 3
keyMenu.backgroundColour = menuBackgroundColour
keyMenu.textColour = menuTextColour
keyMenu.arrowColour = menuArrowColour
keyMenu.outlineColour = menuOutlineColour

local scalesNames = scales.getScaleNames()
local scaleMenu = settingsPanel:Menu("Scale", scalesNames)
scaleMenu.selected = #scalesNames
scaleMenu.displayName = "Scale"
scaleMenu.tooltip = "The scale to set for the notes in the grid"
scaleMenu.showLabel = true
scaleMenu.width = 108
scaleMenu.x = keyMenu.x + keyMenu.width + 9
scaleMenu.y = keyMenu.y
scaleMenu.backgroundColour = menuBackgroundColour
scaleMenu.textColour = menuTextColour
scaleMenu.arrowColour = menuArrowColour
scaleMenu.outlineColour = menuOutlineColour

local startOctave = settingsPanel:NumBox("StartOctave", -1, -2, 7, true)
startOctave.displayName = "Start octave"
startOctave.tooltip = "The octave to start from when creating the scale"
startOctave.backgroundColour = menuBackgroundColour
startOctave.textColour = menuTextColour
startOctave.height = 20
startOctave.width = 108
startOctave.x = keyMenu.x
startOctave.y = scaleMenu.y + scaleMenu.height + 5

local octaves = settingsPanel:NumBox("Octaves", 9, 1, 9, true)
octaves.displayName = "Octaves"
octaves.tooltip = "Set the octave range"
octaves.backgroundColour = menuBackgroundColour
octaves.textColour = menuTextColour
octaves.height = startOctave.height
octaves.width = startOctave.width
octaves.x = scaleMenu.x
octaves.y = startOctave.y

gateInput = settingsPanel:NumBox("GateInput", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.displayName = "Gate"
gateInput.tooltip = "Set the gate length"
gateInput.backgroundColour = menuBackgroundColour
gateInput.textColour = menuTextColour
gateInput.height = octaves.height
gateInput.width = octaves.width
gateInput.x = startOctave.x
gateInput.y = octaves.y + octaves.height + 5
gateInput.changed = function(self)
  gate = self.value
end

gateRandomization = settingsPanel:NumBox("GateRandomization", 25, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = menuTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.size = gateInput.size
gateRandomization.x = scaleMenu.x
gateRandomization.y = gateInput.y

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
recalculateGrid()

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythm"
rythmLabel.alpha = 0.75
rythmLabel.width = 45
rythmLabel.y = 1

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, rythmLabel, colours, 2)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onNote(e)
  if type(noteListen) == "table" then
    print("noteListen", noteListen[1], noteListen[2])
    getCell(noteListen[1], noteListen[2], "Note", grid):setValue(e.note)
    getCell(noteListen[1], noteListen[2], "Listen", listeners):setValue(false)
  end
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

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local fragmentInputData = {}

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  return {fragmentInputData}
end

function onLoad(data)
  local fragmentInputData = data[1]

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end
end
