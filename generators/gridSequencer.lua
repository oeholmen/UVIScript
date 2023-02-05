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
local sliderColour = "5FB5FF"

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
local seqVelTable
local velocityRandomization
local seqGateTable
local gateRandomization
local rootNote = 1 -- Holds the current root note (key)
local scaleDefinitionIndex = #scalesNames -- Holds the scale definition index
local startOctave = -1 -- Holds the start octave when creating the scale
local octaves = 9 -- Holds the octave range
local noteRandomizationProbability = 0
local manualInput = false
local evolveFragmentProbability = 0
local randomizeCurrentResolutionProbability = 0
local adjustBias = 50

-- X Axis (index 1)
table.insert(gridXY, {
  pos = 0,
  direction = 1,
  increment = 1,
  playMode = playModes[1],
  chord = false,
  chordNotes = 2,
  chordNotesIncrement = 1,
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
  chord = false,
  chordNotes = 2,
  chordNotesIncrement = 1,
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
  --print("Get grid cell: x, y, floor(x), floor(y)", x, y, math.floor(x), math.floor(y))
  -- Not < 1
  x = math.max(1, math.floor(x))
  y = math.max(1, math.floor(y))
  -- Not > max
  if x > gridXY[xAxis].max then
    print("x > gridXY[xAxis].max")
    x = gridXY[xAxis].max
  end
  if y > gridXY[yAxis].max then
    print("y > gridXY[yAxis].max")
    y = gridXY[yAxis].max
  end
  -- Get cell name
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

local function getStartPos(axis)
  --print("getStartPos for axis", axis)
  if gridXY[axis].increment < 1 or string.sub(gridXY[axis].playMode, 1, 6) == "Follow" then
    return gridXY[axis].offset + 1
  end

  gridXY[axis].mustAdvance = true
  return gridXY[axis].offset
end

local function setPos()
  for axis=xAxis,yAxis do
    if gridXY[axis].direction == 1 then
      gridXY[axis].pos = getStartPos(axis)
      --print("setPos on direction == 1: axis/pos", axis, gridXY[axis].pos)
    elseif string.sub(gridXY[axis].playMode, 1, 6) == "Follow" then
      gridXY[axis].pos = gridXY[axis].offset + gridXY[axis].size
      --print("setPos on direction == -1 and playMode=follow: axis/pos", axis, gridXY[axis].pos)
    else
      gridXY[axis].pos = gridXY[axis].offset + gridXY[axis].size + 1
      --print("setPos on direction == -1: axis/pos", axis, gridXY[axis].pos)
    end
  end
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

local function setDirectionFromPlaymode(axis, playMode)
  gridXY[axis].playMode = playMode
  gridXY[axis].direction = 1
  gridXY[axis].increment = math.abs(gridXY[axis].increment)

  if playMode == "<-" or playMode == "<-->" or playMode == "Follow <-" then
    gridXY[axis].direction = -1
    gridXY[axis].increment = -gridXY[axis].increment
  end

  --print("setDirectionFromPlaymode: direction, increment, playMode", gridXY[axis].direction, gridXY[axis].increment, playMode)
end

local function handleFollow(axis)
  if gridXY[axis].hasAdvanced then
    -- Skip follow if the axis has already advanced
    return
  end
  gridXY[axis].pos = gem.inc(gridXY[axis].pos, gridXY[axis].increment)
  if gridXY[axis].direction == 1 and (gridXY[axis].pos > gridXY[axis].offset + gridXY[axis].size or gridXY[axis].pos > gridXY[axis].max) then
    gridXY[axis].pos = getStartPos(axis)
  elseif gridXY[axis].pos <= gridXY[axis].offset then
    gridXY[axis].pos = gridXY[axis].offset + gridXY[axis].size
  end
end

-- playModes = {"->", "<-", "-><-", "<-->", "Follow ->", "Follow <-"}
local function advanceByPlayMode(v, axis)
  local otherAxis = xAxis
  if axis == otherAxis then
    otherAxis = yAxis
  end
  local extra = math.abs(v.increment)
  if extra >= 1 then
    extra = 0
  end
  --print("advanceByPlayMode: extra", extra)
  local axisIsFollow = string.sub(v.playMode, 1, 6) == "Follow"
  local otherAxisIsFollow = string.sub(gridXY[otherAxis].playMode, 1, 6) == "Follow"
  local bothAxisAreFollow = axisIsFollow and otherAxisIsFollow
  if gem.getRandomBoolean(v.randomProbability) then
    --print("Advance random")
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
    if math.floor(v.pos) <= v.offset then
      v.direction = 1
      v.increment = math.abs(v.increment) -- Turn positive
      --print("Turned direction and increment positive", v.direction, v.increment)
      v.pos = getStartPos(axis) + v.increment
      if v.size > 1 and otherAxisIsFollow == false then
        v.pos = gem.inc(v.pos, v.increment) -- To avoid repeat
      end
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    elseif v.pos > v.offset + v.size or v.pos > v.max then
      v.direction = -1
      v.increment = -v.increment -- Turn negative
      --print("Turned direction and increment negative", v.direction, v.increment)
      v.pos = v.offset + v.size
      if v.size > 1 and otherAxisIsFollow == false then
        v.pos = gem.inc(v.pos, v.increment) -- To avoid repeat
      end
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  elseif (v.direction == 1 and axisIsFollow == false) or bothAxisAreFollow then
    --print("advanceByPlayMode: direction == 1")
    v.pos = gem.inc(v.pos, v.increment)
    --print("advanceByPlayMode: axis, pos", axis, v.pos)
    if v.pos > v.offset + v.size + extra or v.pos > v.max + extra then
      --v.pos = gem.inc(v.offset, v.increment)
      v.pos = getStartPos(axis) + v.increment
      --print("advanceByPlayMode: reset axis, pos", axis, v.pos)
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  elseif v.direction == -1 and axisIsFollow == false then
    v.pos = gem.inc(v.pos, v.increment)
    if v.pos - extra <= v.offset then
      v.pos = v.offset + v.size + extra
      --print("v.pos, extra", v.pos, extra)
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

local function getCellsForAxis(axis, v)
  local cellsForAxis = {}
  local startPos = v.offset + 1
  local endPos = math.min(v.max, v.offset + v.size)
  --print("axis, startPos, endPos", i, startPos, endPos)
  if v.chord and v.randomChord then
    -- Get selected notes in random order
    local currentPos = startPos
    while currentPos <= endPos do
      table.insert(cellsForAxis, getCellForAxis(axis, currentPos))
      currentPos = gem.inc(currentPos)
    end
    -- Remove random cells until we have the correct amount
    while #cellsForAxis > v.chordNotes do
      table.remove(cellsForAxis, gem.getRandom(#cellsForAxis))
    end
  else
    -- Get selected notes in sequential order
    local currentPos = v.pos
    -- Add cells until we have the correct amount
    while #cellsForAxis < v.chordNotes do
      table.insert(cellsForAxis, getCellForAxis(axis, currentPos))
      currentPos = gem.inc(currentPos, v.chordNotesIncrement, endPos, startPos)
    end
  end
  return cellsForAxis
end

local function getNotes()
  local cells = {} -- Holds the selected grid cells to play

  -- Reset advance status
  gridXY[xAxis].hasAdvanced = false
  gridXY[yAxis].hasAdvanced = false

  -- Advance each axis according to the set increment
  for axis,v in ipairs(gridXY) do
    if v.mustAdvance or gem.getRandomBoolean(v.advanceProbability) then
      advanceByPlayMode(v, axis)
      v.mustAdvance = false
    end
  end

  -- Get multiple cells if polymode is active on any of the axis
  for axis,v in ipairs(gridXY) do
    if v.chord then
      for _,cell in ipairs(getCellsForAxis(axis, v)) do
        table.insert(cells, cell)
      end
    end
  end

  -- If no cells were found using polymode, we return the cell at the current pos
  if #cells == 0 then
    table.insert(cells, getCellForAxis(gridXY[xAxis].pos, gridXY[yAxis].pos))
  end

  --print("Returning cells", #cells)
  return cells
end

local function getVelocity(pos)
  return seqVelTable:getValue(pos), gem.inc(pos, 1, seqVelTable.length)
end

local function randomizeVelocity(velocity)
  return gem.randomizeValue(velocity, seqVelTable.min, seqVelTable.max, velocityRandomization.value)
end

local function randomizeGate(gate)
  return gem.randomizeValue(gate, seqGateTable.min, seqGateTable.max, gateRandomization.value)
end

local function getGate(pos)
  return seqGateTable:getValue(pos), gem.inc(pos, 1, seqGateTable.length)
end

local function sequenceRunner()
  setPos()
  local previous = nil
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatCount = 0
  local fragmentRepeatProbability = 0
  local duration = nil
  local reverseFragment = false
  local rest = false
  local durationCounter = 0
  local velocity = seqVelTable:getValue(1)
  local velocityPos = 0
  local gate = seqGateTable:getValue(1)
  local gatePos = 0
  isPlaying = true
  --print("Seq runner starting")
  while isPlaying do
    local noteInputs = getNotes() -- The notes to play
    local notesPlaying = {} -- Holds the playing notes, to avoid duplicates
    velocity, velocityPos = getVelocity(velocityPos)
    gate, gatePos = getGate(gatePos)
    -- Get resolution from fragments
    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = rythmicFragments.getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
    if type(duration) == "nil" then
      -- Fallback to the default resolution if not found in fragment
      duration = sequencerResolution
    end
    if #noteInputs > 0 and rest == false and gate > 0 then
      for _,noteInput in ipairs(noteInputs) do
        local playDuration = rythmicFragments.resolutions.getPlayDuration(duration, randomizeGate(gate))
        local note = noteInput.value
        if gem.tableIncludes(notesPlaying, note) == false then
          playNote(note, randomizeVelocity(velocity), beat2ms(playDuration))
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
    local beatBase = 4 -- TODO Param?
    durationCounter = durationCounter + duration
    if durationCounter >= beatBase and gem.getRandomBoolean(evolveFragmentProbability) then
      durationCounter = 0
      previous = rythmicFragments.evolveFragments(previous, randomizeCurrentResolutionProbability, adjustBias)
    end
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
  print("Degree definition", #degreeDefinition)
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
notePanel.height = 300

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
rythmPanel.height = 220

--------------------------------------------------------------------------------
-- Grid Sequencer
--------------------------------------------------------------------------------

local xSpacing = 5

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
showListenersButton.x = manualInputButton.x + manualInputButton.width + xSpacing
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
autoplayButton.x = showListenersButton.x + showListenersButton.width + xSpacing
autoplayButton.y = showListenersButton.y

playButton.persistent = false
playButton.backgroundColourOff = backgroundColourOff
playButton.backgroundColourOn = backgroundColourOn
playButton.textColourOff = textColourOff
playButton.textColourOn = textColourOn
playButton.displayName = "Play"
playButton.size = autoplayButton.size
playButton.x = autoplayButton.x + autoplayButton.width + xSpacing
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

local xyOffset = notePanel:XY('GridOffset1', 'GridOffset2')
xyOffset.bounds = {546, 6, 168, 112}

local xySize = notePanel:XY('GridSize1', 'GridSize2')
xySize.bounds = {xyOffset.x, xyOffset.y+xyOffset.height+4, xyOffset.width, xyOffset.height}

seqVelTable = notePanel:Table("Velocity", 8, 90, 1, 127, true)
seqVelTable.tooltip = "Set the velocity pattern"
seqVelTable.showPopupDisplay = true
seqVelTable.fillStyle = "solid"
seqVelTable.sliderColour = sliderColour
seqVelTable.width = notePanel.width - xySize.width - 84
seqVelTable.height = 32
seqVelTable.x = 0
seqVelTable.y = xySize.y + xySize.height + 1

local velocityTableLength = notePanel:NumBox("VelocityTableLength", 8, 1, 64, true)
velocityTableLength.displayName = "Vel"
velocityTableLength.fontSize = 22
velocityTableLength.tooltip = "Length of velocity table"
velocityTableLength.width = 75
velocityTableLength.height = seqVelTable.height
velocityTableLength.x = seqVelTable.x + seqVelTable.width + 1
velocityTableLength.y = seqVelTable.y
velocityTableLength.backgroundColour = menuBackgroundColour
velocityTableLength.textColour = menuTextColour
velocityTableLength.changed = function(self)
  seqVelTable.length = self.value
end

seqGateTable = notePanel:Table("Velocity", 8, 90, 0, 110, true)
seqGateTable.unit = Unit.Percent
seqGateTable.tooltip = "Set gate pattern. If a gate step is set to zero, that step is muted."
seqGateTable.showPopupDisplay = true
seqGateTable.fillStyle = "solid"
seqGateTable.sliderColour = sliderColour
seqGateTable.width = seqVelTable.width
seqGateTable.height = seqVelTable.height
seqGateTable.x = seqVelTable.x
seqGateTable.y = seqVelTable.y + seqVelTable.height + 1

local gateTableLength = notePanel:NumBox("GateTableLength", 8, 1, 64, true)
gateTableLength.displayName = "Gate"
gateTableLength.fontSize = velocityTableLength.fontSize
gateTableLength.tooltip = "Length of gate table"
gateTableLength.width = velocityTableLength.width
gateTableLength.height = seqGateTable.height
gateTableLength.x = seqGateTable.x + seqGateTable.width + 1
gateTableLength.y = seqGateTable.y
gateTableLength.backgroundColour = menuBackgroundColour
gateTableLength.textColour = menuTextColour
gateTableLength.changed = function(self)
  seqGateTable.length = self.value
end

meter = notePanel:AudioMeter("OutputLevel", Part, false, 0, true)
meter.height = seqVelTable.height / 2
meter.width = xySize.width
meter.x = xySize.x
meter.y = seqVelTable.y + 1
meter["0dBColour"] = "red"
meter["3dBColour"] = "orange"
meter["6dBColour"] = "yellow"
meter["10dBColour"] = "green"

velocityRandomization = notePanel:NumBox("VelocityRandomization", 15, 0, 100, true)
velocityRandomization.unit = Unit.Percent
velocityRandomization.displayName = "Velocity Rand"
velocityRandomization.tooltip = "Amount of radomization applied to note velocity"
velocityRandomization.width = meter.width
velocityRandomization.x = meter.x
velocityRandomization.y = meter.y + meter.height + 4
velocityRandomization.backgroundColour = menuBackgroundColour
velocityRandomization.textColour = menuTextColour

gateRandomization = notePanel:NumBox("GateRandomization", 15, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Amount of radomization applied to note gate"
gateRandomization.backgroundColour = menuBackgroundColour
gateRandomization.textColour = menuTextColour
gateRandomization.size = velocityRandomization.size
gateRandomization.x = velocityRandomization.x
gateRandomization.y = velocityRandomization.y + velocityRandomization.height + 1

--------------------------------------------------------------------------------
-- Note Selection
--------------------------------------------------------------------------------

xSpacing = 10

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
degreeInput.text = "1"
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

-- XY Axis

for axis=xAxis,yAxis do
  local axisLabel = axisMotionPanel:Label("AxisLabel" .. axis)
  axisLabel.height = 40
  axisLabel.width = 24
  if axis == xAxis then
    axisLabel.text = "X"
    axisLabel.y = motionLabel.y + motionLabel.height + 10
  else
    axisLabel.text = "Y"
    axisLabel.y = motionLabel.y + motionLabel.height + 63
  end
  axisLabel.tooltip = "Settings for the current axis"
  axisLabel.textColour = labelBackgoundColour
  axisLabel.backgroundColour = labelTextColour
  axisLabel.fontSize = 22
  axisLabel.x = 5

  local gridOffset = axisMotionPanel:Slider("GridOffset" .. axis, gridXY[axis].offset, 0, gridXY[axis].max - 1)
  gridOffset.displayName = "Offset"
  gridOffset.tooltip = "Offset of the current axis (can be adjusted by the top XY controller)"
  gridOffset.backgroundColour = menuBackgroundColour
  gridOffset.textColour = menuTextColour
  gridOffset.height = 45
  gridOffset.width = 60
  gridOffset.x = axisLabel.x + axisLabel.width + xSpacing
  gridOffset.y = axisLabel.y - 5
  gridOffset.changed = function(self)
    local offset = gem.round(self.value)
    if offset ~= gridXY[axis].offset then
      gridXY[axis].offset = offset
      gridXY[axis].mustAdvance = true
      setSelectedGrid()
    end
  end

  local gridLength = axisMotionPanel:Slider("GridSize" .. axis, gridXY[axis].size, 1, gridXY[axis].max)
  gridLength.displayName = "Length"
  gridLength.tooltip = "Length of current axis (can be adjusted by the bottom XY controller)"
  gridLength.backgroundColour = menuBackgroundColour
  gridLength.textColour = menuTextColour
  gridLength.height = gridOffset.height
  gridLength.width = gridOffset.width
  gridLength.x = gridOffset.x + gridOffset.width + xSpacing
  gridLength.y = gridOffset.y
  gridLength.changed = function(self)
    local size = gem.round(self.value)
    if size ~= gridXY[axis].size then
      gridXY[axis].size = size
      gridXY[axis].mustAdvance = true
      setSelectedGrid()
    end
  end

  local seqPlayMode = axisMotionPanel:Menu("SequencerPlayMode" .. axis, playModes)
  seqPlayMode.displayName = "Mode"
  seqPlayMode.tooltip = "The sequencer play mode for the current axis"
  seqPlayMode.x = gridLength.x + gridLength.width + xSpacing
  seqPlayMode.y = gridLength.y
  seqPlayMode.height = gridLength.height
  seqPlayMode.width = 75
  seqPlayMode.backgroundColour = menuBackgroundColour
  seqPlayMode.textColour = menuTextColour
  seqPlayMode.arrowColour = menuArrowColour
  seqPlayMode.outlineColour = menuOutlineColour
  seqPlayMode.changed = function(self)
    setDirectionFromPlaymode(axis, self.text)
  end
  seqPlayMode:changed()

  local chordNotes = axisMotionPanel:NumBox("ChordNotes" .. axis, gridXY[axis].chordNotes, 2, gridXY[axis].max, true)
  local chordNoteIncrement = axisMotionPanel:NumBox("ChordNoteIncrement" .. axis, gridXY[axis].chordNotesIncrement, 1, math.floor(gridXY[axis].max / 2), true)
  local randomChordButton = axisMotionPanel:OnOffButton("RandomChordButton" .. axis, gridXY[axis].randomChord)

  local chordButton = axisMotionPanel:OnOffButton("ChordButton" .. axis, gridXY[axis].chord)
  chordButton.backgroundColourOff = backgroundColourOff
  chordButton.backgroundColourOn = backgroundColourOn
  chordButton.textColourOff = textColourOff
  chordButton.textColourOn = textColourOn
  chordButton.displayName = "Polymode"
  chordButton.tooltip = "In polymode, mutiple notes are played along the current axis"
  chordButton.size = {100,20}
  chordButton.x = seqPlayMode.x + seqPlayMode.width + xSpacing
  chordButton.y = seqPlayMode.y + 3
  chordButton.changed = function(self)
    gridXY[axis].chord = self.value
    if self.value then
      gridXY[axis].chordNotes = chordNotes.value
    else
      gridXY[axis].chordNotes = 1
    end
    chordNotes.enabled = self.value
    chordNoteIncrement.enabled = self.value and randomChordButton.value == false
    randomChordButton.enabled = self.value
  end
  chordButton:changed()

  chordNotes.enabled = false
  chordNotes.showLabel = false
  chordNotes.displayName = "Notes"
  chordNotes.tooltip = "Number of notes to play in polymode"
  chordNotes.backgroundColour = menuBackgroundColour
  chordNotes.textColour = menuTextColour
  chordNotes.size = {30,20}
  chordNotes.x = chordButton.x + chordButton.width + 1
  chordNotes.y = chordButton.y
  chordNotes.changed = function(self)
    gridXY[axis].chordNotes = self.value
  end

  chordNoteIncrement.enabled = false
  chordNoteIncrement.displayName = "Increment"
  chordNoteIncrement.tooltip = "The increment between notes in polymode"
  chordNoteIncrement.backgroundColour = menuBackgroundColour
  chordNoteIncrement.textColour = menuTextColour
  chordNoteIncrement.size = {81,20}
  chordNoteIncrement.x = chordButton.x
  chordNoteIncrement.y = chordButton.y + chordButton.height + 2
  chordNoteIncrement.changed = function(self)
    gridXY[axis].chordNotesIncrement = self.value
  end

  randomChordButton.enabled = false
  randomChordButton.backgroundColourOff = backgroundColourOff
  randomChordButton.backgroundColourOn = backgroundColourOn
  randomChordButton.textColourOff = textColourOff
  randomChordButton.textColourOn = textColourOn
  randomChordButton.displayName = "Random"
  randomChordButton.tooltip = "Select chord notes by chance from within the active axis"
  randomChordButton.size = {48,chordNotes.height}
  randomChordButton.x = chordNoteIncrement.x + chordNoteIncrement.width + 2
  randomChordButton.y = chordNoteIncrement.y
  randomChordButton.changed = function(self)
    gridXY[axis].randomChord = self.value
    chordNoteIncrement.enabled = self.value == false
  end

  local increment = axisMotionPanel:Knob("Increment" .. axis, gridXY[axis].increment, .1, 3.)
  increment.displayName = "Increment"
  increment.tooltip = "Set the increment amount per step on the current axis"
  increment.backgroundColour = widgetBackgroundColour
  increment.fillColour = knobFillColour
  increment.outlineColour = labelBackgoundColour
  increment.showPopupDisplay = true
  increment.height = 39
  increment.width = 100
  increment.y = seqPlayMode.y + 8
  increment.x = randomChordButton.x + randomChordButton.width + xSpacing
  increment.changed = function(self)
    gridXY[axis].increment = self.value
    setDirectionFromPlaymode(axis, seqPlayMode.text)
  end

  local advanceProbability = axisMotionPanel:Knob("AdvanceProbability" .. axis, gridXY[axis].advanceProbability, 0, 100, true)
  advanceProbability.unit = Unit.Percent
  advanceProbability.displayName = "Advance"
  advanceProbability.tooltip = "Set the probability that the position will advance on the current axis"
  advanceProbability.backgroundColour = widgetBackgroundColour
  advanceProbability.fillColour = knobFillColour
  advanceProbability.outlineColour = labelBackgoundColour
  advanceProbability.showPopupDisplay = true
  advanceProbability.height = increment.height
  advanceProbability.width = increment.width
  advanceProbability.y = increment.y
  advanceProbability.x = increment.x + increment.width + xSpacing
  advanceProbability.changed = function(self)
    gridXY[axis].advanceProbability = self.value
  end

  local randomProbability = axisMotionPanel:Knob("RandomProbability" .. axis, gridXY[axis].randomProbability , 0, 100, true)
  randomProbability.unit = Unit.Percent
  randomProbability.displayName = "Random"
  randomProbability.tooltip = "Set the probability that the position on the current axis will be selected by chance"
  randomProbability.backgroundColour = widgetBackgroundColour
  randomProbability.fillColour = knobFillColour
  randomProbability.outlineColour = labelBackgoundColour
  randomProbability.showPopupDisplay = true
  randomProbability.height = advanceProbability.height
  randomProbability.width = advanceProbability.width
  randomProbability.y = advanceProbability.y
  randomProbability.x = advanceProbability.x + advanceProbability.width
  randomProbability.changed = function(self)
    gridXY[axis].randomProbability = self.value
  end
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

local evolveFragmentProbabilityInput = rythmPanel:NumBox("EvolveFragmentProbability", evolveFragmentProbability, 0, 100, true)
evolveFragmentProbabilityInput.unit = Unit.Percent
evolveFragmentProbabilityInput.textColour = widgetTextColour
evolveFragmentProbabilityInput.backgroundColour = widgetBackgroundColour
evolveFragmentProbabilityInput.displayName = "Evolve"
evolveFragmentProbabilityInput.tooltip = "Set the probability that fragments will change over time, using the resolutions present in the fragments"
evolveFragmentProbabilityInput.width = 100
evolveFragmentProbabilityInput.height = 16
evolveFragmentProbabilityInput.x = rythmLabel.x + 239
evolveFragmentProbabilityInput.y = 1
evolveFragmentProbabilityInput.changed = function(self)
  evolveFragmentProbability = self.value
end

local randomizeCurrentResolutionProbabilityInput = rythmPanel:NumBox("RandomizeCurrentResolutionProbability", randomizeCurrentResolutionProbability, 0, 100, true)
randomizeCurrentResolutionProbabilityInput.unit = Unit.Percent
randomizeCurrentResolutionProbabilityInput.textColour = widgetTextColour
randomizeCurrentResolutionProbabilityInput.backgroundColour = widgetBackgroundColour
randomizeCurrentResolutionProbabilityInput.displayName = "Adjust"
randomizeCurrentResolutionProbabilityInput.tooltip = "Set the probability that evolve will adjust resolutions, based on the resolutions present in the fragments"
randomizeCurrentResolutionProbabilityInput.width = evolveFragmentProbabilityInput.width
randomizeCurrentResolutionProbabilityInput.height = evolveFragmentProbabilityInput.height
randomizeCurrentResolutionProbabilityInput.x = evolveFragmentProbabilityInput.x + evolveFragmentProbabilityInput.width + 5
randomizeCurrentResolutionProbabilityInput.y = evolveFragmentProbabilityInput.y
randomizeCurrentResolutionProbabilityInput.changed = function(self)
  randomizeCurrentResolutionProbability = self.value
end

local biasLabel = rythmPanel:Label("BiasLabel")
biasLabel.text = "Bias slow > fast"
biasLabel.tooltip = "Adjust bias: <50=more slow resolutions, >50=more fast resolutions"
biasLabel.alpha = 0.5
biasLabel.fontSize = 15
biasLabel.width = 90
biasLabel.height = randomizeCurrentResolutionProbabilityInput.height
biasLabel.x = randomizeCurrentResolutionProbabilityInput.x + randomizeCurrentResolutionProbabilityInput.width + 5
biasLabel.y = randomizeCurrentResolutionProbabilityInput.y

local adjustBiasInput = rythmPanel:Knob("Bias", adjustBias, 0, 100, true)
adjustBiasInput.showLabel = false
adjustBiasInput.showValue = false
adjustBiasInput.displayName = "Bias"
adjustBiasInput.tooltip = biasLabel.tooltip
adjustBiasInput.backgroundColour = widgetBackgroundColour
adjustBiasInput.fillColour = knobFillColour
adjustBiasInput.outlineColour = widgetTextColour
adjustBiasInput.width = 18
adjustBiasInput.height = biasLabel.height
adjustBiasInput.x = biasLabel.x + biasLabel.width
adjustBiasInput.y = biasLabel.y
adjustBiasInput.changed = function(self)
  adjustBias = self.value
end

local minResLabel = rythmPanel:Label("MinResolutionsLabel")
minResLabel.text = "Min resolution"
minResLabel.alpha = 0.5
minResLabel.fontSize = 15
minResLabel.width = 90
minResLabel.height = adjustBiasInput.height
minResLabel.x = adjustBiasInput.x + adjustBiasInput.width + 10
minResLabel.y = adjustBiasInput.y

local minResolution = rythmPanel:Menu("MinResolution", rythmicFragments.resolutions.getResolutionNames())
minResolution.displayName = minResLabel.text
minResolution.tooltip = "The highest allowed resolution for evolve adjustments"
minResolution.selected = 26
minResolution.showLabel = false
minResolution.width = 60
minResolution.height = adjustBiasInput.height
minResolution.backgroundColour = widgetBackgroundColour
minResolution.textColour = widgetTextColour
minResolution.arrowColour = menuArrowColour
minResolution.outlineColour = menuOutlineColour
minResolution.x = minResLabel.x + minResLabel.width
minResolution.y = minResLabel.y
minResolution.changed = function(self)
  rythmicFragments.setMaxResolutionIndex(self.value)
end
minResolution:changed()

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, rythmLabel, colours, 4, 15, 5)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init grid sequencer")
  setSelectedGrid()
  degreeInput:changed()
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
  degreeInput:changed()

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end
end
