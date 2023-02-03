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
local menuSelectedBackgroundColour = "052525"
local menuTextColour = "#9f02ACFE"
local noteSelectedTextColour = "green"
local notePlayingTextColour = "yellow"
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
local xAxis = 1 -- Hold the index for the x axis in the gridXY table
local yAxis = 2 -- Hold the index for the y axis in the gridXY table
local scalesNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local gateInput
local gateRandomization
local rootNote = 1 -- Holds the current root note (key)
local scaleDefinitionIndex = #scalesNames -- Holds the scale definition index
local startOctave = -1 -- Holds the start octave when creating the scale
local octaves = 9 -- Holds the octave range
local noteRandomizationProbability = 0
local manualInput = false

-- X Axis (index 1)
table.insert(gridXY, {
  pos = 0,
  direction = 1,
  increment = 1,
  playMode = playModes[1],
  chord = 1,--false,
  randomChord = false,
  randomProbability = 0, -- Probability that position will be selected by chance
  advanceProbability = 100, -- Probability that a new position for the axis will be selected by the play mode
  mustAdvance = true, -- Set true to ensure pos is moved to within the selected area even if advanceProbability = 0
  hasAdvanced = false,
  offset = 2,
  size = 8,
  max = 12
})

-- Y Axis (index 2)
table.insert(gridXY, {
  pos = 0,
  direction = 1,
  increment = 1,
  playMode = playModes[1],
  chord = 1,--false,
  randomChord = false,
  randomProbability = 0, -- Probability that position will be selected by chance
  advanceProbability = 100, -- Probability that a new position for the axis will be selected by the play mode
  mustAdvance = true, -- Set true to ensure pos is moved to within the selected area even if advanceProbability = 0
  hasAdvanced = false,
  offset = 3,
  size = 3,
  max = 9
})

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function getCell(x, y, prefix, table)
  print("Get grid cell: x, y, floor(x), floor(y)", x, y, math.floor(x), math.floor(y))
  -- Not < 1
  x = math.max(1, math.floor(x))
  y = math.max(1, math.floor(y))
  -- Not > max
  if x > gridXY[xAxis].max then
    x = gridXY[xAxis].max
  end
  if y > gridXY[yAxis].max then
    y = gridXY[yAxis].max
  end
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

local function isPosWithinSelectedAxis(pos, axis)
  return pos > gridXY[axis].offset and pos <= gridXY[axis].offset + gridXY[axis].size
end

local function isWithinSelectedGrid(x, y)
  return isPosWithinSelectedAxis(x, xAxis) and isPosWithinSelectedAxis(y, yAxis)
end

local function setSelectedGrid()
  local i = 1
  for y=1,gridXY[yAxis].max do
    for x=1,gridXY[xAxis].max do
      if isWithinSelectedGrid(x, y) then
        grid[i].textColour = noteSelectedTextColour
        grid[i].backgroundColour = menuSelectedBackgroundColour
      else
        grid[i].textColour = menuTextColour
        grid[i].backgroundColour = menuBackgroundColour
      end
      i = gem.inc(i)
    end
  end
end

local function flashNote(noteInput, duration)
  noteInput.textColour = notePlayingTextColour
  waitBeat(duration)
  if noteInput.backgroundColour == menuSelectedBackgroundColour then
    noteInput.textColour = noteSelectedTextColour
  else
    noteInput.textColour = menuTextColour
  end
end

local function setPlayMode(axis, playMode)
  gridXY[axis].playMode = playMode
  gridXY[axis].increment = math.abs(gridXY[axis].increment)

  if playMode == "<-" or playMode == "<-->" or playMode == "Follow <-" then
    gridXY[axis].direction = -1
    gridXY[axis].increment = -gridXY[axis].increment
  elseif playMode == "->" or playMode == "-><-" or playMode == "Follow ->" then
    gridXY[axis].direction = 1
  end
end

local function handleFollow(axis)
  axis = gridXY[axis]
  if axis.hasAdvanced then
    -- Skip follow if the axis has already advanced
    return
  end
  axis.pos = gem.inc(axis.pos, axis.increment)
  if axis.direction > 0 and axis.pos > axis.offset + axis.size or axis.pos > axis.max then
    axis.pos = gem.inc(axis.offset, axis.increment)
  elseif axis.pos <= axis.offset then
    axis.pos = axis.offset + axis.size
  end
end

-- playModes = {"->", "<-", "-><-", "<-->", "Follow ->", "Follow <-"}
local function advanceByPlayMode(v, axis)
  --print("advanceByPlayMode")
  gridXY[xAxis].hasAdvanced = false -- Reset
  gridXY[yAxis].hasAdvanced = false -- Reset
  local otherAxis = xAxis
  if axis == otherAxis then
    otherAxis = yAxis
  end
  local extra = math.abs(v.increment)
  if extra >= 1 then
    extra = 0
  end
  local axisIsFollow = string.sub(v.playMode, 1, 6) == "Follow"
  local otherAxisIsFollow = string.sub(gridXY[otherAxis].playMode, 1, 6) == "Follow"
  local bothAxisAreFollow = axisIsFollow and otherAxisIsFollow
  if gem.getRandomBoolean(v.randomProbability) then
    --print("PlayMode random")
    if v.size > 1 then
      v.pos = gem.getRandom(v.offset + 1, v.offset + v.size)
    else
      v.pos = v.offset + v.size
    end
    v.hasAdvanced = true
    if otherAxisIsFollow then
      handleFollow(otherAxis)
    end
  elseif v.playMode == "-><-" or v.playMode == "<-->" then
    v.pos = gem.inc(v.pos, v.increment)
    if v.pos <= v.offset then
      v.direction = 1
      v.pos = v.offset + 1
      if v.size > 1 and otherAxisIsFollow == false then
        v.pos = v.pos + 1 -- To avoid repeat
      end
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    elseif v.pos > v.offset + v.size or v.pos > v.max then
      v.direction = -1
      v.pos = v.offset + v.size
      if v.size > 1 and otherAxisIsFollow == false then
        v.pos = v.pos - 1 -- To avoid repeat
      end
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  elseif (v.direction > 0 and axisIsFollow == false) or bothAxisAreFollow then
    v.pos = gem.inc(v.pos, v.increment)
    if v.pos > v.offset + v.size + extra or v.pos > v.max + extra then
      v.pos = gem.inc(v.offset, v.increment)
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  elseif v.direction < 0 and axisIsFollow == false then
    v.pos = gem.inc(v.pos, v.increment)
    if v.pos - extra <= v.offset then
      v.pos = v.offset + v.size + extra
      print("v.pos, extra", v.pos, extra)
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  end
end

local function getCellForAxis(axis, pos)
  if axis == xAxis then
    local yPos = gridXY[yAxis].pos
    --print("getCell @ axis, pos, yPos", i, pos, yPos)
    return getCell(pos, yPos, "Note", grid)
  end

  local xPos = gridXY[xAxis].pos
  --print("getCell @ axis, xPos, pos", i, xPos, pos)
  return getCell(xPos, pos, "Note", grid)
end

local function getNotes()

  for axis,v in ipairs(gridXY) do
    if (v.mustAdvance or gem.getRandomBoolean(v.advanceProbability)) then
      advanceByPlayMode(v, axis)
      v.mustAdvance = false
    end
  end

  local cells = {} -- The selected cells to play
  if gridXY[xAxis].chord > 1 or gridXY[yAxis].chord > 1 then
    for axis,v in ipairs(gridXY) do
      if v.chord > 1 then
        local startPos = v.offset + 1
        local endPos = math.min(v.max, v.offset + v.size)
        --print("axis, startPos, endPos", i, startPos, endPos)
        local cellsForAxis = {}
        if v.randomChord then
          -- Get selected notes in random order
          local currentPos = startPos
          while currentPos <= endPos do
            --if isPosWithinSelectedAxis(pos, axis) then
            table.insert(cellsForAxis, getCellForAxis(axis, currentPos))
            currentPos = gem.inc(currentPos)
            --end
          end
          -- Remove random cells until we have the correct amount
          while #cellsForAxis > v.chord do
            table.remove(cellsForAxis, gem.getRandom(#cellsForAxis))
          end
        else
          -- Get selected notes in sequential order
          local currentPos = v.pos
          -- Add cells until we have the correct amount
          while #cellsForAxis < math.min(v.chord, v.size) do
            table.insert(cellsForAxis, getCellForAxis(axis, currentPos))
            currentPos = gem.inc(currentPos, 1, endPos, startPos)
          end
        end
        for _,cell in ipairs(cellsForAxis) do
          table.insert(cells, cell)
        end
      end
    end
  else
    -- No chord, just get the one note
    table.insert(cells, getCell(gridXY[xAxis].pos, gridXY[yAxis].pos, "Note", grid))
  end

  --print("Returning cells", #cells)
  return cells
end

local function resetGridPos()
  for axis=1,2 do
    if gridXY[axis].direction > 0 then
      gridXY[axis].pos = gridXY[axis].offset
      gridXY[axis].mustAdvance = true
    elseif string.sub(gridXY[axis].playMode, 1, 6) == "Follow" then
      gridXY[axis].pos = gridXY[axis].offset + gridXY[axis].size
    else
      gridXY[axis].pos = gridXY[axis].offset + gridXY[axis].size + 1
    end
    --print("resetGridPos: Set axis to pos", axis, gridXY[axis].pos)
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
  print("Seq runner starting")
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
          --print("Play note/duration", note, playDuration)
        end
        spawn(flashNote, noteInput, math.min(playDuration, duration))
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

local function setScale()
  if manualInput then
    -- Do not change anything when manual input is active
    --print("Skip set scale - manual input is active")
    return
  end
  local startNote = (rootNote - 1) + ((startOctave + 2) * 12)
  local maxNote = startNote + (octaves * 12)
  local scale = scales.createScale(scaleDefinitions[scaleDefinitionIndex], startNote, math.min(128, maxNote))
  local scalePos = 1
  local scaleIncrementDefinitionPos = 1
  local degreeDefinitionPos = 0
  local degreeOctave = 0
  local scaleResetPos = 1
  print("Root note is", startNote)
  print("Max note is", maxNote)
  print("#scale", #scale)
  for i,v in ipairs(grid) do
    -- Check if we have a degree definition
    -- Check if we are at the start of the x axis
    if #degreeDefinition > 0 and (i - 1) % gridXY[xAxis].max == 0 then
      -- Increment degree position
      degreeDefinitionPos = gem.inc(degreeDefinitionPos, 1, #degreeDefinition)
      -- Set the scale pos to the selected degree if within the scale
      if degreeDefinition[degreeDefinitionPos] <= #scale then
        scalePos = math.max(1, degreeDefinition[degreeDefinitionPos])
      end
      -- Set scale reset pos to match the scale pos set by the degree definition
      scaleResetPos = scalePos
      -- Increment degree octave on pos 1 of the degree def
      if i > 1 and degreeDefinitionPos == 1 then
        degreeOctave = gem.inc(degreeOctave, 1, (octaves - 1), 0)
        --print("Increment octave at degree pos", degreeOctave)
      end
      -- Reset the position for scale increments
      scaleIncrementDefinitionPos = 1
    end

    -- Set the note for this cell
    local noteNumber = math.min(127, scale[scalePos] + (degreeOctave * 12))
    -- Get random from scale
    if gem.getRandomBoolean(noteRandomizationProbability) then
      noteNumber = gem.getRandomFromTable(scale)
    end
    v:setValue(noteNumber)

    -- Get next scale position
    scalePos = math.max(1, gem.inc(scalePos, scaleIncrementDefinition[scaleIncrementDefinitionPos], #scale, scaleResetPos))

    if scalePos == scaleResetPos then
      -- Reset the position for scale increments when scale position is reset
      scaleIncrementDefinitionPos = 1
    else
      -- Get next scale increment position
      scaleIncrementDefinitionPos = gem.inc(scaleIncrementDefinitionPos, 1, #scaleIncrementDefinition)
    end
  end
end

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

local sequencerPanel = Panel("GridSequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 0
sequencerPanel.y = 0
sequencerPanel.width = 720
sequencerPanel.height = 30

local notePanel = Panel("Notes")
notePanel.backgroundColour = "black"
notePanel.x = sequencerPanel.x
notePanel.y = sequencerPanel.y + sequencerPanel.height
notePanel.width = sequencerPanel.width
notePanel.height = 240

local settingsPanel = Panel("Scale")
settingsPanel.backgroundColour = "404040"
settingsPanel.x = notePanel.x
settingsPanel.y = notePanel.y + notePanel.height + 0
settingsPanel.width = sequencerPanel.width
settingsPanel.height = 84

local axisMotionPanel = Panel("AxisMotionPanel")
axisMotionPanel.backgroundColour = "404040"
axisMotionPanel.x = settingsPanel.x
axisMotionPanel.y = settingsPanel.y + settingsPanel.height + 0
axisMotionPanel.width = sequencerPanel.width
axisMotionPanel.height = 132

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "404040"
rythmPanel.x = axisMotionPanel.x
rythmPanel.y = axisMotionPanel.y + axisMotionPanel.height + 0
rythmPanel.width = sequencerPanel.width
rythmPanel.height = 114

--------------------------------------------------------------------------------
-- Widgets
--------------------------------------------------------------------------------

local spacing = 20

local sequencerLabel = sequencerPanel:Label("Label")
sequencerLabel.text = "Grid Sequencer"
sequencerLabel.tooltip = "This sequencer plays notes along the x and y axis of a grid"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.position = {0,0}
sequencerLabel.size = {sequencerPanel.width,30}

local manualInputButton = sequencerPanel:OnOffButton("ManualInputButton", manualInput)
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
manualInputButton.x = sequencerPanel.width - (manualInputButton.width * 4) - 21
manualInputButton.y = 5
manualInputButton.changed = function(self)
  manualInput = self.value
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

local rowCounter = gridXY[yAxis].max - 1
local columnCounter = 0
local colSpacing = 3
local rowSpacing = 2
local noteListen = false
local noteIndex = 0

for y=1,gridXY[yAxis].max do
  for x=1,gridXY[xAxis].max do
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
    if columnCounter >= gridXY[xAxis].max then
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

local xSpacing = 10

local noteSelectionLabel = settingsPanel:Label("NoteSelectionLabel")
noteSelectionLabel.text = "Note Selection"
noteSelectionLabel.tooltip = "Settings for selecting the notes in the grid (disabled when manual input is active)"
noteSelectionLabel.alpha = 0.3
noteSelectionLabel.fontSize = 16
noteSelectionLabel.backgroundColour = labelBackgoundColour
noteSelectionLabel.textColour = labelTextColour
noteSelectionLabel.width = settingsPanel.width
noteSelectionLabel.height = 18
noteSelectionLabel.x = 0
noteSelectionLabel.y = 0

local keyMenu = settingsPanel:Menu("Key", notes.getNoteNames())
keyMenu.displayName = "Key"
keyMenu.tooltip = "The key to set for the notes in the grid"
keyMenu.showLabel = true
keyMenu.width = 90
keyMenu.x = 5
keyMenu.y = noteSelectionLabel.y + noteSelectionLabel.height + 10
keyMenu.backgroundColour = menuBackgroundColour
keyMenu.textColour = menuTextColour
keyMenu.arrowColour = menuArrowColour
keyMenu.outlineColour = menuOutlineColour

local scaleMenu = settingsPanel:Menu("Scale", scalesNames)
scaleMenu.selected = #scalesNames
scaleMenu.displayName = "Scale"
scaleMenu.tooltip = "The scale to set for the notes in the grid"
scaleMenu.showLabel = true
scaleMenu.width = 120
scaleMenu.x = keyMenu.x + keyMenu.width + xSpacing
scaleMenu.y = keyMenu.y
scaleMenu.backgroundColour = menuBackgroundColour
scaleMenu.textColour = menuTextColour
scaleMenu.arrowColour = menuArrowColour
scaleMenu.outlineColour = menuOutlineColour

local startOctaveInput = settingsPanel:NumBox("StartOctave", startOctave, -2, 7, true)
startOctaveInput.displayName = "Start octave"
startOctaveInput.tooltip = "The octave to start from when creating the scale"
startOctaveInput.backgroundColour = menuBackgroundColour
startOctaveInput.textColour = menuTextColour
startOctaveInput.height = 20
startOctaveInput.width = 126
startOctaveInput.x = scaleMenu.x + scaleMenu.width + xSpacing
startOctaveInput.y = scaleMenu.y

local octavesInput = settingsPanel:NumBox("Octaves", octaves, 1, 10, true)
octavesInput.displayName = "Octaves"
octavesInput.tooltip = "Set the octave range"
octavesInput.backgroundColour = menuBackgroundColour
octavesInput.textColour = menuTextColour
octavesInput.height = startOctaveInput.height
octavesInput.width = startOctaveInput.width
octavesInput.x = startOctaveInput.x
octavesInput.y = startOctaveInput.y + startOctaveInput.height + 5

local noteRandomizationProbabilityInput = settingsPanel:Knob("NoteRandomizationProbability", noteRandomizationProbability, 0, 100, true)
noteRandomizationProbabilityInput.unit = Unit.Percent
noteRandomizationProbabilityInput.displayName = "Random notes"
noteRandomizationProbabilityInput.tooltip = "Set the probability that notes within the current scale will be selected by chance."
noteRandomizationProbabilityInput.backgroundColour = widgetBackgroundColour
noteRandomizationProbabilityInput.fillColour = knobFillColour
noteRandomizationProbabilityInput.outlineColour = labelBackgoundColour
noteRandomizationProbabilityInput.showPopupDisplay = true
noteRandomizationProbabilityInput.height = 45
noteRandomizationProbabilityInput.width = 130
noteRandomizationProbabilityInput.y = startOctaveInput.y
noteRandomizationProbabilityInput.x = startOctaveInput.x + startOctaveInput.width + xSpacing
noteRandomizationProbabilityInput.changed = function(self)
  noteRandomizationProbability = self.value
  setScale()
end

local scaleIncrementInputLabel = settingsPanel:Label("ScaleIncrementInputLabel")
scaleIncrementInputLabel.text = "X"
scaleIncrementInputLabel.x = noteRandomizationProbabilityInput.x + noteRandomizationProbabilityInput.width + xSpacing
scaleIncrementInputLabel.y = noteRandomizationProbabilityInput.y
scaleIncrementInputLabel.height = startOctaveInput.height
scaleIncrementInputLabel.width = 20

local scaleIncrementInput = settingsPanel:Label("ScaleIncrementInput")
scaleIncrementInput.text = "1"
scaleIncrementInput.tooltip = "Set scale increments on the x axis - default is to increment by one step per cell. Increments are separated by comma, and will repeat until all cells are set."
scaleIncrementInput.editable = true
scaleIncrementInput.backgroundColour = colours.labelTextColour
scaleIncrementInput.backgroundColourWhenEditing = "white"
scaleIncrementInput.textColour = "white"
scaleIncrementInput.textColourWhenEditing = colours.labelTextColour
scaleIncrementInput.height = startOctaveInput.height
scaleIncrementInput.width = 165
scaleIncrementInput.x = scaleIncrementInputLabel.x + scaleIncrementInputLabel.width
scaleIncrementInput.y = scaleIncrementInputLabel.y
scaleIncrementInput.changed = function(self)
  scaleIncrementDefinition = createTableFromText(self.text)
  setScale()
end

local degreeInputLabel = settingsPanel:Label("DegreeInputLabel")
degreeInputLabel.text = "Y"
degreeInputLabel.x = scaleIncrementInputLabel.x
degreeInputLabel.y = scaleIncrementInputLabel.y + scaleIncrementInputLabel.height + 5
degreeInputLabel.height = scaleIncrementInputLabel.height
degreeInputLabel.width = scaleIncrementInputLabel.width

local degreeInput = settingsPanel:Label("DegreeInput")
degreeInput.text = ""
degreeInput.tooltip = "Degree definition: if set, the scale increment input will reset at the start of each row (y-axis), setting the degree as the root note. 1 = root. Degrees are separated by comma."
degreeInput.editable = true
degreeInput.backgroundColour = colours.labelTextColour
degreeInput.backgroundColourWhenEditing = "white"
degreeInput.textColour = "white"
degreeInput.textColourWhenEditing = colours.labelTextColour
degreeInput.height = scaleIncrementInput.height
degreeInput.width = scaleIncrementInput.width
degreeInput.x = degreeInputLabel.x + degreeInputLabel.width
degreeInput.y = degreeInputLabel.y
degreeInput.changed = function(self)  
  degreeDefinition = createTableFromText(self.text)
  setScale()
end

keyMenu.changed = function(self)
  rootNote = self.value
  setScale()
end

scaleMenu.changed = function(self)
  scaleDefinitionIndex = self.value
  setScale()
end

startOctaveInput.changed = function(self)
  startOctave = self.value
  setScale()
end

octavesInput.changed = function(self)
  octaves = self.value
  setScale()
end

--------------------------------------------------------------------------------
-- Axis Motion Settings
--------------------------------------------------------------------------------

xSpacing = 10 -- Horizontal widget spacing

local motionLabel = axisMotionPanel:Label("MotionLabel")
motionLabel.text = "Motion"
motionLabel.tooltip = "Settings for setting the grid selection, and controlling motion along the x and y axis"
motionLabel.alpha = noteSelectionLabel.alpha
motionLabel.fontSize = noteSelectionLabel.fontSize
motionLabel.backgroundColour = labelBackgoundColour
motionLabel.textColour = labelTextColour
motionLabel.width = axisMotionPanel.width
motionLabel.height = 18
motionLabel.x = 0
motionLabel.y = 0

-- X Axis

local axisLabelX = axisMotionPanel:Label("AxisLabelX")
axisLabelX.text = "X"
axisLabelX.tooltip = "Settings for the x-axis (horizontal)"
axisLabelX.textColour = labelBackgoundColour
axisLabelX.backgroundColour = labelTextColour
axisLabelX.fontSize = 22
axisLabelX.height = 40
axisLabelX.width = 24
axisLabelX.x = 5
axisLabelX.y = motionLabel.y + motionLabel.height + 10

local gridOffsetX = axisMotionPanel:Slider("GridOffsetX", gridXY[xAxis].offset, 0, gridXY[xAxis].max - 1)
gridOffsetX.displayName = "Offset"
gridOffsetX.tooltip = "Offset of x axis (can be adjusted by the top XY controller)"
gridOffsetX.backgroundColour = menuBackgroundColour
gridOffsetX.textColour = menuTextColour
gridOffsetX.height = 45
gridOffsetX.width = 60
gridOffsetX.x = axisLabelX.x + axisLabelX.width + xSpacing
gridOffsetX.y = axisLabelX.y - 5
gridOffsetX.changed = function(self)
  local offset = gem.round(self.value)
  if offset ~= gridXY[xAxis].offset then
    gridXY[xAxis].offset = offset
    gridXY[xAxis].mustAdvance = true
    setSelectedGrid()
  end
end

local gridLengthX = axisMotionPanel:Slider("GridSizeX", gridXY[xAxis].size, 1, gridXY[xAxis].max)
gridLengthX.displayName = "Length"
gridLengthX.tooltip = "Length of x axis (can be adjusted by the bottom XY controller)"
gridLengthX.backgroundColour = menuBackgroundColour
gridLengthX.textColour = menuTextColour
gridLengthX.height = gridOffsetX.height
gridLengthX.width = gridOffsetX.width
gridLengthX.x = gridOffsetX.x + gridOffsetX.width + xSpacing
gridLengthX.y = gridOffsetX.y
gridLengthX.changed = function(self)
  local size = gem.round(self.value)
  if size ~= gridXY[xAxis].size then
    gridXY[xAxis].size = size
    gridXY[xAxis].mustAdvance = true
    setSelectedGrid()
  end
end

local seqPlayModeX = axisMotionPanel:Menu("SequencerPlayModeX", playModes)
seqPlayModeX.displayName = "Mode"
seqPlayModeX.tooltip = "The sequencer play mode for the x axis (horizontal)"
seqPlayModeX.x = gridLengthX.x + gridLengthX.width + xSpacing
seqPlayModeX.y = gridLengthX.y
seqPlayModeX.height = gridLengthX.height
seqPlayModeX.width = 75
seqPlayModeX.backgroundColour = menuBackgroundColour
seqPlayModeX.textColour = menuTextColour
seqPlayModeX.arrowColour = menuArrowColour
seqPlayModeX.outlineColour = menuOutlineColour
seqPlayModeX.changed = function(self)
  setPlayMode(1, self.text)
end
seqPlayModeX:changed()

local randomChordButtonX = axisMotionPanel:OnOffButton("RandomChordButtonX", gridXY[xAxis].randomChord)
local chordButtonX = axisMotionPanel:NumBox("ChordX", 1, 1, gridXY[xAxis].max, true)
chordButtonX.displayName = "Notes"
chordButtonX.tooltip = "Number of notes to play simultaniously on the x axis"
chordButtonX.backgroundColour = menuBackgroundColour
chordButtonX.textColour = menuTextColour
chordButtonX.height = 20
chordButtonX.width = 66
chordButtonX.x = seqPlayModeX.x + seqPlayModeX.width + xSpacing
chordButtonX.y = seqPlayModeX.y + 25
chordButtonX.changed = function(self)
  gridXY[xAxis].chord = self.value
  randomChordButtonX.enabled = self.value > 1
end

randomChordButtonX.enabled = false
randomChordButtonX.backgroundColourOff = backgroundColourOff
randomChordButtonX.backgroundColourOn = backgroundColourOn
randomChordButtonX.textColourOff = textColourOff
randomChordButtonX.textColourOn = textColourOn
randomChordButtonX.displayName = "Random"
randomChordButtonX.tooltip = "Select chord notes by chance from within the active x axis (only when numer of notes as > 1)"
randomChordButtonX.size = {54,chordButtonX.height}
randomChordButtonX.x = chordButtonX.x + chordButtonX.width + 1
randomChordButtonX.y = chordButtonX.y
randomChordButtonX.changed = function(self)
  gridXY[xAxis].randomChord = self.value
end

local incrementX = axisMotionPanel:Knob("IncrementX", gridXY[xAxis].increment, .1, 3.)
incrementX.displayName = "Increment"
incrementX.tooltip = "Set the increment amount per step on the x axis (horizontal)."
incrementX.backgroundColour = widgetBackgroundColour
incrementX.fillColour = knobFillColour
incrementX.outlineColour = labelBackgoundColour
incrementX.showPopupDisplay = true
incrementX.height = 39
incrementX.width = 100
incrementX.y = seqPlayModeX.y + 8
incrementX.x = randomChordButtonX.x + randomChordButtonX.width + xSpacing
incrementX.changed = function(self)
  gridXY[xAxis].increment = self.value
end

local advanceProbabilityX = axisMotionPanel:Knob("AdvanceProbabilityX", gridXY[xAxis].advanceProbability, 0, 100, true)
advanceProbabilityX.unit = Unit.Percent
advanceProbabilityX.displayName = "Advance"
advanceProbabilityX.tooltip = "Set the probability that the position will advance on the x axis (horizontal)."
advanceProbabilityX.backgroundColour = widgetBackgroundColour
advanceProbabilityX.fillColour = knobFillColour
advanceProbabilityX.outlineColour = labelBackgoundColour
advanceProbabilityX.showPopupDisplay = true
advanceProbabilityX.height = incrementX.height
advanceProbabilityX.width = incrementX.width
advanceProbabilityX.y = incrementX.y
advanceProbabilityX.x = incrementX.x + incrementX.width + xSpacing
advanceProbabilityX.changed = function(self)
  gridXY[xAxis].advanceProbability = self.value
end

local randomProbabilityX = axisMotionPanel:Knob("RandomProbabilityX", gridXY[xAxis].randomProbability , 0, 100, true)
randomProbabilityX.unit = Unit.Percent
randomProbabilityX.displayName = "Random"
randomProbabilityX.tooltip = "Set the probability that the position on the x axis (horizontal) will be selected by chance."
randomProbabilityX.backgroundColour = widgetBackgroundColour
randomProbabilityX.fillColour = knobFillColour
randomProbabilityX.outlineColour = labelBackgoundColour
randomProbabilityX.showPopupDisplay = true
randomProbabilityX.height = advanceProbabilityX.height
randomProbabilityX.width = advanceProbabilityX.width
randomProbabilityX.y = advanceProbabilityX.y
randomProbabilityX.x = advanceProbabilityX.x + advanceProbabilityX.width
randomProbabilityX.changed = function(self)
  gridXY[xAxis].randomProbability = self.value
end

-- Y Axis

local axisLabelY = axisMotionPanel:Label("AxisLabelY")
axisLabelY.text = "Y"
axisLabelY.tooltip = "Settings for the y-axis (vertical)"
axisLabelY.fontSize = axisLabelX.fontSize
axisLabelY.textColour = labelBackgoundColour
axisLabelY.backgroundColour = labelTextColour
axisLabelY.height = axisLabelX.height
axisLabelY.width = axisLabelX.width
axisLabelY.x = axisLabelX.x
axisLabelY.y = axisLabelX.y + axisLabelX.height + 15

local gridOffsetY = axisMotionPanel:Slider("GridOffsetY", gridXY[yAxis].offset, 0, gridXY[yAxis].max - 1)
gridOffsetY.displayName = "Offset"
gridOffsetY.tooltip = "Offset of y axis (can be adjusted by the top XY controller)"
gridOffsetY.backgroundColour = menuBackgroundColour
gridOffsetY.textColour = menuTextColour
gridOffsetY.height = gridOffsetX.height
gridOffsetY.width = gridOffsetX.width
gridOffsetY.x = gridOffsetX.x
gridOffsetY.y = gridOffsetX.y + gridOffsetX.height + 10
gridOffsetY.changed = function(self)
  local offset = gem.round(self.value)
  if offset ~= gridXY[yAxis].offset then
    gridXY[yAxis].offset = offset
    gridXY[yAxis].mustAdvance = true
    setSelectedGrid()
  end
end

local gridLengthY = axisMotionPanel:Slider("GridSizeY", gridXY[yAxis].size, 1, gridXY[yAxis].max)
gridLengthY.displayName = "Length"
gridLengthY.tooltip = "Length of y axis (can be adjusted by the bottom XY controller)"
gridLengthY.backgroundColour = menuBackgroundColour
gridLengthY.textColour = menuTextColour
gridLengthY.height = gridLengthX.height
gridLengthY.width = gridLengthX.width
gridLengthY.x = gridLengthX.x
gridLengthY.y = gridOffsetY.y
gridLengthY.changed = function(self)
  local size = gem.round(self.value)
  if size ~= gridXY[yAxis].size then
    gridXY[yAxis].size = size
    gridXY[yAxis].mustAdvance = true
    setSelectedGrid()
  end
end

local seqPlayModeY = axisMotionPanel:Menu("SequencerPlayModeY", playModes)
seqPlayModeY.displayName = "Mode"
seqPlayModeY.tooltip = "The sequencer play mode for the y axis (vertical)"
seqPlayModeY.x = seqPlayModeX.x
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

local randomChordButtonY = axisMotionPanel:OnOffButton("RandomChordButtonY", gridXY[yAxis].randomChord)
local chordButtonY = axisMotionPanel:NumBox("ChordY", 1, 1, gridXY[yAxis].max, true)
chordButtonY.displayName = "Notes"
chordButtonY.tooltip = "Number of notes to play simultaniously on the y axis"
chordButtonY.backgroundColour = menuBackgroundColour
chordButtonY.textColour = menuTextColour
chordButtonY.height = chordButtonX.height
chordButtonY.width = chordButtonX.width
chordButtonY.x = chordButtonX.x
chordButtonY.y = seqPlayModeY.y + 25
chordButtonY.changed = function(self)
  gridXY[yAxis].chord = self.value
  randomChordButtonY.enabled = self.value > 1
end

randomChordButtonY.enabled = false
randomChordButtonY.backgroundColourOff = backgroundColourOff
randomChordButtonY.backgroundColourOn = backgroundColourOn
randomChordButtonY.textColourOff = textColourOff
randomChordButtonY.textColourOn = textColourOn
randomChordButtonY.displayName = "Random"
randomChordButtonY.tooltip = "Select chord notes by chance from within the active y axis (only when numer of notes as > 1)"
randomChordButtonY.size = randomChordButtonX.size
randomChordButtonY.x = randomChordButtonX.x
randomChordButtonY.y = seqPlayModeY.y + 24
randomChordButtonY.changed = function(self)
  gridXY[yAxis].randomChord = self.value
end

local incrementY = axisMotionPanel:Knob("IncrementY", gridXY[yAxis].increment, .1, 3.)
incrementY.displayName = "Increment"
incrementY.tooltip = "Set the increment amount per step on the y axis (vertical)."
incrementY.backgroundColour = widgetBackgroundColour
incrementY.fillColour = knobFillColour
incrementY.outlineColour = labelBackgoundColour
incrementY.showPopupDisplay = true
incrementY.height = incrementX.height
incrementY.width = incrementX.width
incrementY.y = incrementX.y + incrementX.height + 15
incrementY.x = incrementX.x
incrementY.changed = function(self)
  gridXY[yAxis].increment = self.value
end

local advanceProbabilityY = axisMotionPanel:Knob("AdvanceProbabilityY", gridXY[yAxis].advanceProbability, 0, 100, true)
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
advanceProbabilityY.y = incrementY.y
advanceProbabilityY.x = advanceProbabilityX.x
advanceProbabilityY.changed = function(self)
  gridXY[yAxis].advanceProbability = self.value
end

local randomProbabilityY = axisMotionPanel:Knob("RandomProbabilityY", gridXY[yAxis].randomProbability, 0, 100, true)
randomProbabilityY.unit = Unit.Percent
--randomProbabilityY.showLabel = false
--randomProbabilityY.showValue = false
randomProbabilityY.displayName = "Random"
randomProbabilityY.tooltip = "Set the probability that the position on the y axis (verical) will be selected by chance."
randomProbabilityY.backgroundColour = widgetBackgroundColour
randomProbabilityY.fillColour = knobFillColour
randomProbabilityY.outlineColour = labelBackgoundColour
randomProbabilityY.showPopupDisplay = true
randomProbabilityY.height = randomProbabilityX.height
randomProbabilityY.width = randomProbabilityX.width
randomProbabilityY.y = advanceProbabilityY.y
randomProbabilityY.x = randomProbabilityX.x
randomProbabilityY.changed = function(self)
  gridXY[yAxis].randomProbability = self.value
end

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythm"
rythmLabel.tooltip = "Settings for rythm and gate"
rythmLabel.alpha = noteSelectionLabel.alpha
rythmLabel.fontSize = noteSelectionLabel.fontSize
rythmLabel.backgroundColour = labelBackgoundColour
rythmLabel.textColour = labelTextColour
rythmLabel.width = rythmPanel.width
rythmLabel.height = 18
rythmLabel.x = 0
rythmLabel.y = 0

gateInput = rythmPanel:NumBox("GateInput", 90, 0, 110, true)
gateInput.unit = Unit.Percent
gateInput.displayName = "Gate"
gateInput.tooltip = "Set the gate length"
gateInput.backgroundColour = menuBackgroundColour
gateInput.textColour = menuTextColour
gateInput.size = {120,16}
gateInput.x = 468
gateInput.y = 1

gateRandomization = rythmPanel:NumBox("GateRandomization", 25, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = menuTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.size = gateInput.size
gateRandomization.x = gateInput.x + gateInput.width + 1
gateRandomization.y = gateInput.y

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, rythmLabel, colours, 2, 10, 10)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init grid")
  setSelectedGrid()
end

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
