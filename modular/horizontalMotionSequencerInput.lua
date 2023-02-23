----------------------------------------------------------------------------------
-- Motion Sequencer - Listens for incoming note events (rythm) on note number 0
----------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local scales = require "includes.scales"
local notes = require "includes.notes"
local modular = require "includes.modular"
local tableMotion = require "includes.tableMotion"

local backgroundColour = "606060"
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local sequencerResolution = 0.25 -- Fallback value
local baseNote = 60 -- Option
local tableRange = 16
local octaveRange = 2 -- Option
local bipolar = true -- Option
--local noteMode = 1
--local noteModes = {"Active", "Last Min/Max", "Last Max", "Last Min", "Chance"}
local activationMode = 1
local activationModes = {"Max:On,Min:Off", "Max:Toggle", "Min:Toggle", "Zero:Toggle", "Min:On,Max:Off"}
local positionTable
local motionTable
local scaleNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinitionIndex = #scaleNames
local activeScale = {} -- Holds the active scale
local activeNotes = {} -- Holds the active notes in the scale
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local movingCells = {}
local forward = false
local channel = 0
--local notePositionIndex = 0 -- Holds the index if the cell in the table that last set a note active

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetTableValues()
  -- Reset note position index
  --notePositionIndex = 0

  -- Reset position
  tableMotion.setTableZero(positionTable)

  -- Set start mode
  tableMotion.setStartMode(motionTable)
end

local function move(i, uniqueId)
  local direction = 1
  local value = motionTable:getValue(i)
  --print("Start moving i, uniqueId", i, uniqueId)
  while isPlaying and movingCells[i] == uniqueId do
    -- Set note position active when value is min or max
    -- {"Max:On,Min:Off", "Max:Toggle", "Min:Toggle", "Zero:Toggle", "Min:On,Max:Off"}
    --[[ if value == 0 or value == motionTable.min or value == motionTable.max then
      if noteMode == 2 or noteMode == 5 or (noteMode == 3 and value == motionTable.max) or (noteMode == 4 and value == motionTable.min) then
        notePositionIndex = i
      end
    end ]]
    if activationMode == 1 and (value == motionTable.min or value == motionTable.max) then
      activeNotes[i] = value == motionTable.max
    elseif activationMode == 2 and value == motionTable.max and direction == 1 then
      activeNotes[i] = activeNotes[i] == false
    elseif activationMode == 3 and value == motionTable.min and direction == 1 then
      activeNotes[i] = activeNotes[i] == false
    elseif activationMode == 4 and value == 0 then
      activeNotes[i] = activeNotes[i] == false
    elseif activationMode == 5 and (value == motionTable.min or value == motionTable.max) then
      activeNotes[i] = value == motionTable.min
    end
    --print("Set activeNotes[i], i, uniqueId", activeNotes[i], i, uniqueId)
    value, direction = tableMotion.moveTable(motionTable, i, value, direction)
  end
end

local function startMoving()
  movingCells = {} -- Reset index to stop motion
  for i=1,motionTable.length do
    table.insert(movingCells, uniqueIndex)
    spawn(move, i, uniqueIndex)
    uniqueIndex = gem.inc(uniqueIndex)
  end
end

local function setRange()
  tableMotion.setRange(motionTable, tableRange, bipolar)
  resetTableValues()
end

local function setScaleTable()
  local scaleDefinition = scaleDefinitions[scaleDefinitionIndex]
  local startNote = baseNote
  if bipolar then
    startNote = startNote - (octaveRange * 12)
  end
  local maxNote = baseNote + (octaveRange * 12)
  activeScale = scales.createScale(scaleDefinition, startNote, maxNote)
  activeNotes = {} -- Reset
  for _,v in ipairs(activeScale) do
    table.insert(activeNotes, false) -- Notes start deactivated
  end

  -- Set table length according to the number of notes in the selected scale
  tableMotion.options.tableLength = #activeScale
  positionTable.length = tableMotion.options.tableLength
  motionTable.length = tableMotion.options.tableLength

  --print("#activeScale, startNote, maxNote", #activeScale, startNote, maxNote)
  resetTableValues()
  startMoving()
end

local function getResetPosition()
  local reset = gem.getRandom(4)

  -- Lowest
  if reset == 1 then
    return 1
  end

  -- Middle
  if reset == 2 then
    return math.ceil(#activeScale / 2)
  end

  -- Random
  if reset == 3 then
    return gem.getRandom(#activeScale)
  end

  -- Highest
  return #activeScale
end

local function getNote()
  --local scalePos = notePositionIndex

  -- {"Active", "Last", "Last Max", "Last Min", "Chance"}

  -- Get note position form active notes
  --local selectFromActiveNotes = noteMode == 1 or (noteMode == 5 and gem.getRandomBoolean())
  --if selectFromActiveNotes then
    local activePositions = {}
    for i,v in ipairs(activeNotes) do
      if v then
        table.insert(activePositions, i)
      end
    end
    print("activeNotes", #activeNotes)
    print("activePositions", #activePositions)
    local scalePos = gem.getRandomFromTable(activePositions)
  --end

  -- No active notes
  if type(scalePos) == "nil" then-- or scalePos < 1 or scalePos > #activeScale then
    return
  end

  -- Set in position table
  for i=1,positionTable.length do
    local val = 0
    if activeNotes[i] then
      val = 1
    end
    if i == scalePos then
      val = 2
    end
    positionTable:setValue(i, val)
  end

  --[[ if scalePos < 1 or scalePos > #activeScale then
    scalePos = getResetPosition()
  end ]]

  -- Get note from scale
  return activeScale[scalePos]
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  setScaleTable()
  startMoving()
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetTableValues()
end

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

local sequencerPanel = widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Horizontal Motion Sequencer", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 90,
  x = 531,
  y = 5,
  xSpacing = 5,
  ySpacing = 5,
})

widgets.button("Forward", forward, {
  tooltip = "Forward triggers (note=0 events) to the next processor",
  changed = function(self) forward = self.value end,
})

local channelInput = widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

widgets.setSection({
  width = sequencerPanel.width,
  x = 0,
  y = 0,
  xSpacing = 0,
  ySpacing = 0,
})

local settingsPanel = widgets.panel({
  backgroundColour = backgroundColour,
  y = widgets.posUnder(sequencerPanel),
  height = 254,
})

positionTable = widgets.table("Position", 0, tableMotion.options.tableLength, {
  max = 2,
  integer = true,
  enabled = false,
  persistent = false,
  sliderColour = "green",
  backgroundColour = "CFFFFE",
  height = 10,
})

widgets.setSection({
  height = 160,
  y = widgets.posUnder(positionTable),
})

motionTable = widgets.table("Motion", 0, tableMotion.options.tableLength, {
  tooltip = "Events are triggered when the value hits max or min",
  showPopupDisplay = true,
  backgroundColour = "191E25",
  min = -tableRange,
  max = tableRange,
  integer = true,
})

local noteWidgetHeight = 20
local noteWidgetWidth = 130
local noteWidgetRowSpacing = 5
local noteWidgetCellSpacing = 14
local firstRowY = motionTable.y + motionTable.height + 10

widgets.setSection({
  width = noteWidgetWidth,
  height = noteWidgetHeight,
  menuHeight = 45,
  x = 10,
  y = firstRowY,
  xSpacing = noteWidgetCellSpacing,
  ySpacing = noteWidgetRowSpacing,
  cols = 7
})

widgets.menu("Speed Type", tableMotion.speedTypes, {
  width = 75,--82,
  changed = function(self) tableMotion.options.speedType = self.selectedText end
})

widgets.menu("Start Mode", 3, tableMotion.startModes, {
  width = 75,--82,
  changed = function(self)
    tableMotion.options.startMode = self.selectedText
    resetTableValues()
  end
}):changed()

widgets.menu("Activation Mode", activationMode, activationModes, {
  width = 82+14,
  changed = function(self) activationMode = self.value end
})

--[[ widgets.menu("Note Mode", noteMode, noteModes, {
  width = 82,
  changed = function(self) noteMode = self.value end
}) ]]

local scaleMenu = widgets.menu("Scale", #scaleNames, scaleNames, {
  width = 90,
  changed = function(self)
    scaleDefinitionIndex = self.value
    setScaleTable()
  end
})

local noteInput = widgets.numBox("Base Note", baseNote, {
  width = 33,
  x = widgets.posSide(scaleMenu) - 7,
  y = firstRowY + 25,
  unit = Unit.MidiKey,
  showLabel = false,
  tooltip = "Set the root note",
  changed = function(self)
    baseNote = self.value
    setScaleTable()
  end
})

local moveSpeedInput = widgets.numBox("Motion Speed", tableMotion.options.moveSpeed, {
  x = widgets.posSide(noteInput),
  name = "MoveSpeed",
  min = tableMotion.options.moveSpeedMin,
  max = tableMotion.options.moveSpeedMax,
  tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller",
  unit = Unit.MilliSeconds,
  changed = function(self) tableMotion.options.moveSpeed = self.value end
})

widgets.row()
widgets.col(3)

widgets.numBox("Speed Factor", tableMotion.options.factor, {
  name = "Factor",
  min = tableMotion.options.factorMin,
  max = tableMotion.options.factorMax,
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. Controlled by the Y-axis on the XY controller",
  changed = function(self) tableMotion.options.factor = self.value end
})

widgets.row()

widgets.numBox("Range", tableRange, {
  min = 8,
  max = 128,
  integer = true,
  tooltip = "Set the table range - high range = fewer events, low range = more events",
  changed = function(self)
    tableRange = self.value
    setRange()
  end
})

local bipolarButton = widgets.button("Bipolar", bipolar, {
  width = (noteWidgetWidth / 2) - (noteWidgetCellSpacing / 2),
  changed = function(self)
    bipolar = self.value
    setRange()
    setScaleTable()
    startMoving()
  end
})

widgets.button("Reset", false, {
  width = bipolarButton.width,
  changed = function(self)
    resetTableValues()
    startMoving()
    self.value = false
  end
})

widgets.numBox("Octave Range", octaveRange, {
  tooltip = "Set the octave range",
  min = 1,
  max = 4,
  integer = true,
  changed = function(self)
    octaveRange = self.value
    setScaleTable()
  end
})

widgets.numBox("Speed Rand", tableMotion.options.speedRandomizationAmount, {
  unit = Unit.Percent,
  tooltip = "Set the radomization amount applied to speed",
  changed = function(self) tableMotion.options.speedRandomizationAmount = self.value end
})

local xySpeedFactor = widgets.getPanel():XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = widgets.posSide(moveSpeedInput) - 5
xySpeedFactor.width = noteWidgetWidth
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  uniqueIndex = 1
  setScaleTable()
end

function onNote(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    startPlaying()
    modular.handleTrigger(e, getNote())
  else
    postEvent(e)
  end
end

function onRelease(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    modular.handleReleaseTrigger(e)
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start == true then
    startPlaying()
  else
    stopPlaying()
  end
end
