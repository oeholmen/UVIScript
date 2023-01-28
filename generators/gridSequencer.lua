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

local playModes = {"->", "<-", "-><-", "<-->", "Follow ->", "Follow <-"}
local isPlaying = false
local sequencerResolution = 0.25 -- Fallback value
local paramsPerFragment = {} -- Holds the rythmic fragments
local scaleIncrementDefinition = {} -- Holds the increment definition for scales
local degreeDefinition = {} -- Holds the definition for degrees on the y-axis
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
  chord = false,
  randomProbability = 0, -- Probability that position will be selected by random
  advanceProbability = 100, -- Probability that a new position for the axis will be selected by the play mode
  mustAdvance = true, -- Set true to ensure pos is moved to within the selected area even if advanceProbability = 0
  offset = 2,
  size = 8,
  max = 12
})

-- Y Axis (index 2)
table.insert(gridXY, {
  pos = 0,
  direction = 1,
  playMode = playModes[1],
  chord = false,
  randomProbability = 0, -- Probability that position will be selected by random
  advanceProbability = 100, -- Probability that a new position for the axis will be selected by the play mode
  mustAdvance = true, -- Set true to ensure pos is moved to within the selected area even if advanceProbability = 0
  offset = 2,
  size = 3,
  max = 9
})

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

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

local function toggleNoteInputs(enabled)
  for i,v in ipairs(grid) do
    v.enabled = enabled
  end
end

local function showListeners(show)
  for i,v in ipairs(grid) do
    if show then
      v.width = 30
      v.x = listeners[i].x + listeners[i].width
    else
      v.width = 42
      v.x = listeners[i].x
    end
    listeners[i].visible = show
  end
end

local function isAxisWithinSelectedGrid(axis, i)
  return axis > gridXY[i].offset and axis <= gridXY[i].offset + gridXY[i].size
end

local function isWithinSelectedGrid(x, y)
  return isAxisWithinSelectedGrid(x, 1) and isAxisWithinSelectedGrid(y, 2)
end

local function recalculateGrid()
  local i = 1
  for y=1,gridXY[2].max do
    for x=1,gridXY[1].max do
      if isWithinSelectedGrid(x, y) then
        grid[i].textColour = "green"
        grid[i].backgroundColour = "052525"
      else
        grid[i].textColour = menuTextColour
        grid[i].backgroundColour = menuBackgroundColour
      end
      i = gem.inc(i)
    end
  end
end

local function flashNote(noteInput, duration)
  noteInput.textColour = "yellow"
  waitBeat(duration)
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
    axis.pos = gem.inc(axis.offset)
  elseif axis.pos <= axis.offset then
    axis.pos = axis.offset + axis.size
  end
end

-- playModes = {"->", "<-", "-><-", "<-->", "Follow ->", "Follow <-"}
local function advanceByPlayMode(v, i)
  local bothAxisAreFollow = string.sub(gridXY[1].playMode, 1, 6) == "Follow" and string.sub(gridXY[2].playMode, 1, 6) == "Follow"
  local otherAxis = 1
  if i == otherAxis then
    otherAxis = 2
  end
  local otherAxisIsFollow = string.sub(gridXY[otherAxis].playMode, 1, 6) == "Follow"
  if gem.getRandomBoolean(v.randomProbability) then
    if v.size > 1 then
      v.pos = gem.getRandom(v.offset + 1, v.offset + v.size)
    else
      v.pos = v.offset + v.size
    end
    if otherAxisIsFollow then
      handleFollow(otherAxis)
    end
  elseif v.playMode == "->" or bothAxisAreFollow then
    v.pos = gem.inc(v.pos, v.direction)
    if v.pos > v.offset + v.size or v.pos > v.max then
      v.pos = gem.inc(v.offset)
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  elseif v.playMode == "<-" then
    v.pos = gem.inc(v.pos, v.direction)
    if v.pos <= v.offset then
      v.pos = v.offset + v.size
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  elseif v.playMode == "-><-" or v.playMode == "<-->" then
    v.pos = gem.inc(v.pos, v.direction)
    if v.pos <= v.offset then
      v.direction = 1
      v.pos = v.offset + 1
      if v.size > 1 then
        v.pos = v.pos + 1 -- To avoid repeat
      end
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    elseif v.pos > v.offset + v.size or v.pos > v.max then
      v.direction = -1
      v.pos = v.offset + v.size
      if v.size > 1 then
        v.pos = v.pos - 1 -- To avoid repeat
      end
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  end
  v.pos = math.min(v.max, math.max(v.offset + 1, v.pos))
end

local function getNotes()
  local cells = {}

  for i,v in ipairs(gridXY) do
    if (v.mustAdvance or gem.getRandomBoolean(v.advanceProbability)) then
      advanceByPlayMode(v, i)
      v.mustAdvance = false
    end
  end

  if gridXY[1].chord or gridXY[2].chord then
    for i,v in ipairs(gridXY) do
      if v.chord then
        local startPos = v.offset + 1
        local endPos = math.min(v.max, v.offset + v.size)
        --print("axis, startPos, endPos", i, startPos, endPos)
        for pos=1, endPos do
          --print("isAxisWithinSelectedGrid(pos, i)", pos, i, isAxisWithinSelectedGrid(pos, i))
          if isAxisWithinSelectedGrid(pos, i) then
            local cell
            if i == 1 then
              local yPos = gridXY[2].pos
              --print("getCell @ axis, pos, yPos", i, pos, yPos)
              cell = getCell(pos, yPos, "Note", grid)
            else
              local xPos = gridXY[1].pos
              --print("getCell @ axis, xPos, pos", i, xPos, pos)
              cell = getCell(xPos, pos, "Note", grid)
            end
            table.insert(cells, cell)
          end
        end
      end
    end
  else
    -- No chord, just get the one note
    table.insert(cells, getCell(gridXY[1].pos, gridXY[2].pos, "Note", grid))
  end

  --print("Returning cells", #cells)
  return cells
end

local function resetGridPos()
  for axis=1,2 do
    if gridXY[axis].direction == 1 then
      gridXY[axis].pos = gridXY[axis].offset
    elseif string.sub(gridXY[axis].playMode, 1, 6) == "Follow" then
      gridXY[axis].pos = gridXY[axis].offset + gridXY[axis].size
    else
      gridXY[axis].pos = gridXY[axis].offset + gridXY[axis].size + 1
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
    local noteInputs = getNotes() -- The notes to play
    local notesPlaying = {} -- Holds the playing notes, to avoid duplicates
    local velocity = 64 -- Default velocity - override in velocity event processor if required
    -- Get resolution from fragments
    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = rythmicFragments.getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
    if type(duration) == "nil" then
      -- Fallback to the default resolution if not found in fragment
      duration = sequencerResolution
    end
    if #noteInputs > 0 and rest == false then
      for _,noteInput in ipairs(noteInputs) do
        local playDuration = rythmicFragments.resolutions.getPlayDuration(duration, getGate())
        local note = noteInput.value
        if gem.tableIncludes(notesPlaying, note) == false then
          playNote(note, velocity, beat2ms(playDuration))
          table.insert(notesPlaying, note)
        end
        spawn(flashNote, noteInput, playDuration)
      end
      if type(activeFragment) == "table" then
        for i,v in ipairs(paramsPerFragment) do
          if activeFragment.i == i then
            spawn(rythmicFragments.flashFragmentActive, v.fragmentActive, duration)
          end
        end
      end
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

local function createTableFromText(text)
  local theTable = {}
  if string.len(text) > 0 then
    for w in string.gmatch(text, "[^,]+") do
      table.insert(theTable, tonumber(gem.trimStartAndEnd(w)))
    end
  end
  return theTable
end

local function setScale(rootNote, scale, startOctave, octaves)
  rootNote = (rootNote - 1) + ((startOctave + 2) * 12)
  local scaleDefinitions = scales.getScaleDefinitions()
  local maxNote = rootNote + (octaves * 12)
  local scale = scales.createScale(scaleDefinitions[scale], rootNote, math.min(128, maxNote))
  local scalePos = 1
  local scaleIncrementDefinitionPos = 1
  local degreeDefinitionPos = 0
  local degreeOctave = 0
  for i,v in ipairs(grid) do
    -- Check if we have a degreeDefinition and are at the start of the x axis
    if #degreeDefinition > 0 and (i - 1) % gridXY[1].max == 0 then
      -- Increment degree position
      degreeDefinitionPos = gem.inc(degreeDefinitionPos, 1, #degreeDefinition)
      -- Set the scale pos to the selected degree if within the scale
      if degreeDefinition[degreeDefinitionPos] <= #scale then
        scalePos = degreeDefinition[degreeDefinitionPos]
      end
      -- Increment degree octave on pos 1
      if i > 1 and degreeDefinitionPos == 1 then
        degreeOctave = gem.inc(degreeOctave, 1, (octaves - 1), 0)
        print("Increment degreeOctave", degreeOctave)
      end
    end

    -- Set the note for this cell
    local noteNumber = math.min(127, scale[scalePos] + (degreeOctave * 12))
    v:setValue(noteNumber)

    -- Get next scale position
    scalePos = gem.inc(scalePos, scaleIncrementDefinition[scaleIncrementDefinitionPos], #scale)

    -- Get next scale increment position
    scaleIncrementDefinitionPos = gem.inc(scaleIncrementDefinitionPos, 1, #scaleIncrementDefinition)
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
rythmPanel.height = 120

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

local manualInputButton = sequencerPanel:OnOffButton("ManualInputButton", false)
local showListenersButton = sequencerPanel:OnOffButton("ShowListeners", false)
local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
local playButton = sequencerPanel:OnOffButton("Play", false)

manualInputButton.backgroundColourOff = backgroundColourOff
manualInputButton.backgroundColourOn = backgroundColourOn
manualInputButton.textColourOff = textColourOff
manualInputButton.textColourOn = textColourOn
manualInputButton.displayName = "Manual Input"
manualInputButton.tooltip = "Make all note inputs available for direct edit or note listen"
manualInputButton.size = {100,22}
manualInputButton.x = sequencerPanel.width - (manualInputButton.width * 4) - 15
manualInputButton.y = 5
manualInputButton.changed = function(self)
  showListenersButton.enabled = self.value
  if self.value == false then
    showListenersButton:setValue(false)
  end
  settingsPanel.enabled = self.value == false
  toggleNoteInputs(self.value)
end

showListenersButton.enabled = false
showListenersButton.backgroundColourOff = backgroundColourOff
showListenersButton.backgroundColourOn = backgroundColourOn
showListenersButton.textColourOff = textColourOff
showListenersButton.textColourOn = textColourOn
showListenersButton.displayName = "Show Listeners"
showListenersButton.tooltip = "Show listeners for each note - only available in manual input mode"
showListenersButton.size = {100,22}
showListenersButton.x = manualInputButton.x + manualInputButton.width + 5
showListenersButton.y = manualInputButton.y
showListenersButton.changed = function(self)
  showListeners(self.value)
end

autoplayButton.backgroundColourOff = backgroundColourOff
autoplayButton.backgroundColourOn = backgroundColourOn
autoplayButton.textColourOff = textColourOff
autoplayButton.textColourOn = textColourOn
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = showListenersButton.size
autoplayButton.x = showListenersButton.x + showListenersButton.width + 5
autoplayButton.y = showListenersButton.y

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
local noteListen = false
local noteIndex = 0

for y=1,gridXY[2].max do
  for x=1,gridXY[1].max do
    local listen = notePanel:OnOffButton("Listen" .. x .. '_' .. y)
    listen.visible = false
    listen.displayName = "L"
    listen.tooltip = "Note learn - check multiple listeners to set same note on several inputs"
    listen.persistent = false
    listen.textColourOff = "white"
    listen.backgroundColourOn = "green"
    listen.height = 24
    listen.width = 14
    listen.x = (colSpacing * 1) + (columnCounter * (42 + colSpacing))
    listen.y = (rowSpacing * 1.5) + ((listen.height + rowSpacing) * rowCounter)
    listen.changed = function(self)
      if self.value then
        noteListen = true
      end
    end
    table.insert(listeners, listen)

    local gridCell = notePanel:NumBox("Note" .. x .. '_' .. y, noteIndex + 12, 0, 127, true)
    gridCell.enabled = false
    gridCell.showLabel = false
    gridCell.displayName = "Note"
    gridCell.tooltip = "The note to trigger in cell x:" .. x .. ', y:' .. y
    gridCell.unit = Unit.MidiKey
    gridCell.backgroundColour = menuBackgroundColour
    gridCell.textColour = menuTextColour
    gridCell.height = 24
    gridCell.width = 42
    gridCell.x = listen.x
    gridCell.y = listen.y
    table.insert(grid, gridCell)

    noteIndex = gem.inc(noteIndex)
    columnCounter = gem.inc(columnCounter)
    if columnCounter >= gridXY[1].max then
      columnCounter = 0
      rowCounter = gem.inc(rowCounter, -1)
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
-- Note Selection
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

local scaleIncrementInput = settingsPanel:Label("ScaleIncrementInput")
scaleIncrementInput.text = "1"
scaleIncrementInput.tooltip = "Set scale increments on the x axis - default is to increment by one step per cell. Increments are separated by comma, and will repeat until all cells are set."
scaleIncrementInput.editable = true
scaleIncrementInput.backgroundColour = colours.labelTextColour
scaleIncrementInput.backgroundColourWhenEditing = "white"
scaleIncrementInput.textColour = "white"
scaleIncrementInput.textColourWhenEditing = colours.labelTextColour
scaleIncrementInput.height = startOctave.height
scaleIncrementInput.width = startOctave.width
scaleIncrementInput.x = startOctave.x
scaleIncrementInput.y = startOctave.y + startOctave.height + 5
scaleIncrementInput.changed = function(self)
  scaleIncrementDefinition = createTableFromText(self.text)
  setScale(keyMenu.value, scaleMenu.value, startOctave.value, octaves.value)
end

local degreeInput = settingsPanel:Label("DegreeInput")
degreeInput.text = ""
degreeInput.tooltip = "Degree definition: if set, the scale increment input will reset at the start of each row (y-axis), setting the degree as the root note. 1 = root. Degrees are separated by comma."
degreeInput.editable = true
degreeInput.backgroundColour = colours.labelTextColour
degreeInput.backgroundColourWhenEditing = "white"
degreeInput.textColour = "white"
degreeInput.textColourWhenEditing = colours.labelTextColour
degreeInput.height = startOctave.height
degreeInput.width = startOctave.width
degreeInput.x = octaves.x
degreeInput.y = scaleIncrementInput.y
degreeInput.changed = function(self)  
  degreeDefinition = createTableFromText(self.text)
  setScale(keyMenu.value, scaleMenu.value, startOctave.value, octaves.value)
end

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
-- Axis Settings
--------------------------------------------------------------------------------

local xSpacing = 5

-- X Axis

local axisLabelX = axisPanel:Label("AxisLabelX")
axisLabelX.text = "X"
axisLabelX.tooltip = "Settings for the x-axis (horizontal)"
axisLabelX.textColour = labelBackgoundColour
axisLabelX.backgroundColour = labelTextColour
axisLabelX.fontSize = 22
axisLabelX.height = 40
axisLabelX.width = 23
axisLabelX.x = 5
axisLabelX.y = 5

local gridOffsetX = axisPanel:Slider("GridOffsetX", gridXY[1].offset, 0, gridXY[1].max - 1)
gridOffsetX.displayName = "Offset"
gridOffsetX.tooltip = "Offset of x axis"
gridOffsetX.backgroundColour = menuBackgroundColour
gridOffsetX.textColour = menuTextColour
gridOffsetX.height = 45
gridOffsetX.width = 60
gridOffsetX.x = axisLabelX.x + axisLabelX.width + xSpacing
gridOffsetX.y = 0
gridOffsetX.changed = function(self)
  gridXY[1].offset = gem.round(self.value)
  gridXY[1].mustAdvance = true
  recalculateGrid()
end

local gridLengthX = axisPanel:Slider("GridSizeX", gridXY[1].size, 1, gridXY[1].max)
gridLengthX.displayName = "Length"
gridLengthX.tooltip = "Length of x axis"
gridLengthX.backgroundColour = menuBackgroundColour
gridLengthX.textColour = menuTextColour
gridLengthX.height = gridOffsetX.height
gridLengthX.width = gridOffsetX.width
gridLengthX.x = gridOffsetX.x + gridOffsetX.width + xSpacing
gridLengthX.y = gridOffsetX.y
gridLengthX.changed = function(self)
  gridXY[1].size = gem.round(self.value)
  gridXY[1].mustAdvance = true
  recalculateGrid()
end

local seqPlayModeX = axisPanel:Menu("SequencerPlayModeX", playModes)
seqPlayModeX.displayName = "Mode"
seqPlayModeX.tooltip = "The sequencer play mode for the x axis (horizontal)"
seqPlayModeX.x = gridLengthX.x + gridLengthX.width + xSpacing
seqPlayModeX.y = gridLengthX.y
seqPlayModeX.height = gridLengthX.height
seqPlayModeX.width = gridLengthX.width
seqPlayModeX.backgroundColour = menuBackgroundColour
seqPlayModeX.textColour = menuTextColour
seqPlayModeX.arrowColour = menuArrowColour
seqPlayModeX.outlineColour = menuOutlineColour
seqPlayModeX.changed = function(self)
  setPlayMode(1, self.text)
end
seqPlayModeX:changed()

local chordButtonX = axisPanel:OnOffButton("ChordX", false)
chordButtonX.backgroundColourOff = backgroundColourOff
chordButtonX.backgroundColourOn = backgroundColourOn
chordButtonX.textColourOff = textColourOff
chordButtonX.textColourOn = textColourOn
chordButtonX.displayName = "Poly"
chordButtonX.tooltip = "Play all notes on this axis at once"
chordButtonX.size = {39,21}
chordButtonX.x = seqPlayModeX.x + seqPlayModeX.width + xSpacing
chordButtonX.y = seqPlayModeX.y + 24
chordButtonX.changed = function(self)
  gridXY[1].chord = self.value
end

local advanceProbabilityX = axisPanel:Knob("AdvanceProbabilityX", gridXY[1].advanceProbability, 0, 100, true)
advanceProbabilityX.unit = Unit.Percent
--advanceProbabilityX.showLabel = false
--advanceProbabilityX.showValue = false
advanceProbabilityX.displayName = "Advance"
advanceProbabilityX.tooltip = "Set the probability that the position will advance on the x axis (horizontal)."
advanceProbabilityX.backgroundColour = widgetBackgroundColour
advanceProbabilityX.fillColour = knobFillColour
advanceProbabilityX.outlineColour = labelBackgoundColour
advanceProbabilityX.showPopupDisplay = true
advanceProbabilityX.height = 39
advanceProbabilityX.width = 90
advanceProbabilityX.y = 10
advanceProbabilityX.x = chordButtonX.x + chordButtonX.width + xSpacing
advanceProbabilityX.changed = function(self)
  gridXY[1].advanceProbability = self.value
end

local randomProbabilityX = axisPanel:Knob("RandomProbabilityX", gridXY[1].randomProbability , 0, 100, true)
randomProbabilityX.unit = Unit.Percent
--randomProbabilityX.showLabel = false
--randomProbabilityX.showValue = false
randomProbabilityX.displayName = "Random"
randomProbabilityX.tooltip = "Set the probability that the position on the x axis (horizontal) will be selected using the Random play mode."
randomProbabilityX.backgroundColour = widgetBackgroundColour
randomProbabilityX.fillColour = knobFillColour
randomProbabilityX.outlineColour = labelBackgoundColour
randomProbabilityX.showPopupDisplay = true
randomProbabilityX.height = advanceProbabilityX.height
randomProbabilityX.width = advanceProbabilityX.width
randomProbabilityX.y = 10
randomProbabilityX.x = advanceProbabilityX.x + advanceProbabilityX.width
randomProbabilityX.changed = function(self)
  gridXY[1].randomProbability = self.value
end

-- Y Axis

local axisLabelY = axisPanel:Label("AxisLabelY")
axisLabelY.text = "Y"
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
  gridXY[2].mustAdvance = true
  recalculateGrid()
end

local gridLengthY = axisPanel:Slider("GridSizeY", gridXY[2].size, 1, gridXY[2].max)
gridLengthY.displayName = "Length"
gridLengthY.tooltip = "Length of y axis"
gridLengthY.backgroundColour = menuBackgroundColour
gridLengthY.textColour = menuTextColour
gridLengthY.height = gridLengthX.height
gridLengthY.width = gridLengthX.width
gridLengthY.x = gridOffsetY.x + gridOffsetY.width + xSpacing
gridLengthY.y = gridOffsetY.y
gridLengthY.changed = function(self)
  gridXY[2].size = gem.round(self.value)
  gridXY[2].mustAdvance = true
  recalculateGrid()
end

local seqPlayModeY = axisPanel:Menu("SequencerPlayModeY", playModes)
seqPlayModeY.displayName = "Mode"
seqPlayModeY.tooltip = "The sequencer play mode for the y axis (vertical)"
seqPlayModeY.x = gridLengthY.x + gridLengthY.width + xSpacing
seqPlayModeY.y = gridLengthY.y
seqPlayModeY.height = gridLengthY.height
seqPlayModeY.width = seqPlayModeX.width
seqPlayModeY.backgroundColour = menuBackgroundColour
seqPlayModeY.textColour = menuTextColour
seqPlayModeY.arrowColour = menuArrowColour
seqPlayModeY.outlineColour = menuOutlineColour
seqPlayModeY.changed = function(self)
  setPlayMode(2, self.text)
end
seqPlayModeY:changed()

local chordButtonY = axisPanel:OnOffButton("ChordY", false)
chordButtonY.backgroundColourOff = backgroundColourOff
chordButtonY.backgroundColourOn = backgroundColourOn
chordButtonY.textColourOff = textColourOff
chordButtonY.textColourOn = textColourOn
chordButtonY.displayName = "Poly"
chordButtonY.tooltip = "Play all notes on this axis at once"
chordButtonY.size = {39,21}
chordButtonY.x = seqPlayModeY.x + seqPlayModeY.width + xSpacing
chordButtonY.y = seqPlayModeY.y + 24
chordButtonY.changed = function(self)
  gridXY[2].chord = self.value
end

local advanceProbabilityY = axisPanel:Knob("AdvanceProbabilityY", gridXY[2].advanceProbability, 0, 100, true)
advanceProbabilityY.unit = Unit.Percent
--advanceProbabilityY.showLabel = false
--advanceProbabilityY.showValue = false
advanceProbabilityY.displayName = "Advance"
advanceProbabilityY.tooltip = "Set the probability that the position will advance on the y axis (vertical)."
advanceProbabilityY.backgroundColour = widgetBackgroundColour
advanceProbabilityY.fillColour = knobFillColour
advanceProbabilityY.outlineColour = labelBackgoundColour
advanceProbabilityY.showPopupDisplay = true
advanceProbabilityY.height = advanceProbabilityX.height
advanceProbabilityY.width = advanceProbabilityX.width
advanceProbabilityY.y = advanceProbabilityY.y + advanceProbabilityY.height + 15
advanceProbabilityY.x = chordButtonY.x + chordButtonY.width + xSpacing
advanceProbabilityY.changed = function(self)
  gridXY[2].advanceProbability = self.value
end

local randomProbabilityY = axisPanel:Knob("RandomProbabilityY", gridXY[2].randomProbability, 0, 100, true)
randomProbabilityY.unit = Unit.Percent
--randomProbabilityY.showLabel = false
--randomProbabilityY.showValue = false
randomProbabilityY.displayName = "Random"
randomProbabilityY.tooltip = "Set the probability that the position on the y axis (verical) will be selected using the Random play mode."
randomProbabilityY.backgroundColour = widgetBackgroundColour
randomProbabilityY.fillColour = knobFillColour
randomProbabilityY.outlineColour = labelBackgoundColour
randomProbabilityY.showPopupDisplay = true
randomProbabilityY.height = advanceProbabilityY.height
randomProbabilityY.width = advanceProbabilityY.width
randomProbabilityY.y = advanceProbabilityY.y
randomProbabilityY.x = advanceProbabilityY.x + advanceProbabilityY.width
randomProbabilityY.changed = function(self)
  gridXY[2].randomProbability = self.value
end

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythm"
rythmLabel.alpha = 0.75
rythmLabel.width = 120
rythmLabel.height = 30
rythmLabel.x = 15
rythmLabel.y = 0

gateInput = rythmPanel:NumBox("GateInput", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.displayName = "Gate"
gateInput.tooltip = "Set the gate length"
gateInput.backgroundColour = menuBackgroundColour
gateInput.textColour = menuTextColour
gateInput.size = {120,20}
gateInput.x = 448
gateInput.y = 5
gateInput.changed = function(self)
  gate = self.value
end

gateRandomization = rythmPanel:NumBox("GateRandomization", 25, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = menuTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.size = gateInput.size
gateRandomization.x = gateInput.x + gateInput.width + 10
gateRandomization.y = gateInput.y

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, rythmLabel, colours, 2)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onNote(e)
  if noteListen then
    for i,v in ipairs(grid) do
      if listeners[i].value then
        v:setValue(e.note)
        listeners[i]:setValue(false)
      end
    end
    noteListen = false
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

  return {fragmentInputData, scaleIncrementInput.text, degreeInput.text}
end

function onLoad(data)
  local fragmentInputData = data[1]
  scaleIncrementInput.text = data[2]
  degreeInput.text = data[3]

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end
end
