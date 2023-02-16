----------------------------------------------------------------------------------
-- Motion Sequencer - Listens for incoming note events (rythm) on note number 0
----------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local scales = require "includes.scales"
local resolutions = require "includes.resolutions"
local tableMotion = require "includes.tableMotion"

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
local sliderColour = "5FB5FF"

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local sequencerResolution = 0.25 -- Fallback value
local baseNote = 60 -- Option
local octaveRange = 2 -- Option
local bipolar = true -- Option
local pitchOffsetPos = 1
local positionTable
local motionTable
local scalesNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinitionIndex = #scalesNames
local activeScale = {} -- Holds the active scale
local activeVoices = {}
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local movingCells = {}

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetPitches()
  tableMotion.setTableZero(positionTable)
  tableMotion.setStartMode(motionTable, startMode)
end

local function setScale()
  local scaleDefinition = scaleDefinitions[scaleDefinitionIndex]
  local oneOctScale = scales.createScale(scaleDefinition, 0, 12)
  --print("#oneOctScale", #oneOctScale)
  -- Check octave range / bipolar before setting the table range
  local tableRange = #oneOctScale * octaveRange
  --print("tableRange", tableRange)
  tableMotion.setRange(motionTable, tableRange, bipolar)
  local startNote = baseNote
  if bipolar then
    startNote = startNote - (octaveRange * 12)
  end
  local maxNote = baseNote + (octaveRange * 12) + 1
  activeScale = scales.createScale(scaleDefinition, math.max(0, startNote), math.min(128, maxNote))
  --print("#activeScale, startNote, maxNote", #activeScale, startNote, maxNote)
  resetPitches()
end

local function move(i, uniqueId)
  local direction = 1
  local value = motionTable:getValue(i)
  while isPlaying and movingCells[i] == uniqueId do
    value, direction = tableMotion.moveTable(motionTable, i, value, direction)
  end
end

local function startMoving()
  movingCells = {} -- Reset index to stop
  for i=1,motionTable.length do
    table.insert(movingCells, uniqueIndex)
    spawn(move, i, uniqueIndex)
    uniqueIndex = gem.inc(uniqueIndex)
  end
end

local function getNote()
  for i=1,motionTable.length do
    local val = 0
    if i == pitchOffsetPos then
      val = 1
    end
    positionTable:setValue(i, val)
  end
  local scalePos = motionTable:getValue(pitchOffsetPos) + 1
  if motionTable.min < 0 then
    scalePos = scalePos + math.abs(motionTable.min)
  end
  --print("#activeScale, scalePos", #activeScale, scalePos)
  local note = activeScale[scalePos]
  pitchOffsetPos = gem.inc(pitchOffsetPos, 1, motionTable.length)
  --print("pitchOffsetPos", pitchOffsetPos)
  return note
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  startMoving()
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetPitches()
end

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

local sequencerPanel = widgets.getPanel(1, 1, {
  width = 720,
  height = 30,
})

widgets.label("Motion Sequencer Input", 1, 1, {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

local channels = {"Omni"}
for j=1,16 do
  table.insert(channels, "" .. j)
end

local channelInput = widgets.menu("Channel", 1, channels, 1, 1, {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  width = 90,
  x = sequencerPanel.width - 95,
  y = 5
})

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

widgets.setColour('backgroundColour', "606060")

local notePanel = widgets.panel(1, 1, {
  x = sequencerPanel.x,
  y = widgets.posUnder(sequencerPanel),
  width = sequencerPanel.width,
  height = 255,
})

positionTable = notePanel:Table("Position", tableMotion.options.tableLength, 0, 0, 1, true)
positionTable.enabled = false
positionTable.persistent = false
positionTable.fillStyle = "solid"
positionTable.backgroundColour = widgetTextColour
positionTable.sliderColour = "green"
positionTable.width = notePanel.width
positionTable.height = 6
positionTable.x = 0
positionTable.y = 0

motionTable = notePanel:Table("PitchOffset", tableMotion.options.tableLength, 0, -24, 24, true)
motionTable.tooltip = "Set pitch offset"
motionTable.showPopupDisplay = true
motionTable.fillStyle = "solid"
motionTable.sliderColour = sliderColour
motionTable.width = notePanel.width
motionTable.height = 160
motionTable.x = 0
motionTable.y = positionTable.y + positionTable.height

local noteWidgetHeight = 20
local noteWidgetWidth = 130
local noteWidgetRowSpacing = 5
local noteWidgetCellSpacing = 15
local firstRowY = motionTable.y + motionTable.height + 10
local secondRowY = firstRowY + noteWidgetHeight + noteWidgetRowSpacing
local thirdRowY = secondRowY + noteWidgetHeight + noteWidgetRowSpacing

local speedTypeMenu = notePanel:Menu("SpeedType", tableMotion.speedTypes)
speedTypeMenu.displayName = "Speed Type"
speedTypeMenu.tooltip = "Set the speed type (depending on factor > 0) - Ramp Up = slower for every cell, Ramp Down = faster etc"
speedTypeMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
speedTypeMenu.width = noteWidgetWidth
speedTypeMenu.x = 10
speedTypeMenu.y = firstRowY
speedTypeMenu.backgroundColour = menuBackgroundColour
speedTypeMenu.textColour = menuTextColour
speedTypeMenu.arrowColour = menuArrowColour
speedTypeMenu.outlineColour = menuOutlineColour
speedTypeMenu.changed = function(self)
  tableMotion.options.speedType = self.selectedText
end

local startModeMenu = notePanel:Menu("StartMode", tableMotion.startModes)
startModeMenu.displayName = "Start Mode"
startModeMenu.tooltip = "Start mode controls the table reset"
startModeMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
startModeMenu.width = noteWidgetWidth
startModeMenu.x = speedTypeMenu.x + speedTypeMenu.width + 5
startModeMenu.y = firstRowY
startModeMenu.backgroundColour = menuBackgroundColour
startModeMenu.textColour = menuTextColour
startModeMenu.arrowColour = menuArrowColour
startModeMenu.outlineColour = menuOutlineColour
startModeMenu.changed = function(self)
  tableMotion.options.startMode = self.selectedText
  resetPitches()
end

local scaleMenu = notePanel:Menu("Scale", scalesNames)
scaleMenu.selected = #scalesNames
scaleMenu.displayName = "Scale"
scaleMenu.tooltip = "The scale to use for automatic motion"
scaleMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
scaleMenu.width = noteWidgetWidth - 36
scaleMenu.x = startModeMenu.x + startModeMenu.width + noteWidgetCellSpacing
scaleMenu.y = firstRowY
scaleMenu.backgroundColour = menuBackgroundColour
scaleMenu.textColour = menuTextColour
scaleMenu.arrowColour = menuArrowColour
scaleMenu.outlineColour = menuOutlineColour
scaleMenu.changed = function(self)
  scaleDefinitionIndex = self.value
  setScale()
end

local noteInput = notePanel:NumBox("BaseNote", baseNote, 0, 127, true)
--noteInput.enabled = false
noteInput.showLabel = false
noteInput.displayName = "Base Note"
noteInput.tooltip = "Set the root note"
noteInput.unit = Unit.MidiKey
noteInput.backgroundColour = menuBackgroundColour
noteInput.textColour = menuTextColour
noteInput.height = noteWidgetHeight
noteInput.width = 36
noteInput.x = scaleMenu.x + scaleMenu.width
noteInput.y = secondRowY
noteInput.changed = function(self)
  baseNote = self.value
  setScale()
end

local octaveRangeInput = notePanel:NumBox("OctaveRange", octaveRange, 1, 4, true)
octaveRangeInput.displayName = "Octave Range"
octaveRangeInput.tooltip = "Set the octave range"
octaveRangeInput.backgroundColour = menuBackgroundColour
octaveRangeInput.textColour = menuTextColour
octaveRangeInput.height = noteWidgetHeight
octaveRangeInput.width = noteWidgetWidth
octaveRangeInput.x = scaleMenu.x-- + noteInput.width + 5
octaveRangeInput.y = thirdRowY
octaveRangeInput.changed = function(self)
  octaveRange = self.value
  setScale()
end

local bipolarButton = notePanel:OnOffButton("Bipolar", bipolar)
bipolarButton.backgroundColourOff = backgroundColourOff
bipolarButton.backgroundColourOn = backgroundColourOn
bipolarButton.textColourOff = textColourOff
bipolarButton.textColourOn = textColourOn
bipolarButton.displayName = "Bipolar"
bipolarButton.width = noteWidgetWidth
bipolarButton.height = noteWidgetHeight
bipolarButton.x = speedTypeMenu.x-- + scaleMenu.width + 5
bipolarButton.y = thirdRowY
bipolarButton.changed = function(self)
  bipolar = self.value
  setScale()
end

local motionTableLengthInput = notePanel:NumBox("PitchOffsetTableLength", tableMotion.options.tableLength, 2, 128, true)
motionTableLengthInput.displayName = "Length"
motionTableLengthInput.tooltip = "Set the table size"
motionTableLengthInput.backgroundColour = menuBackgroundColour
motionTableLengthInput.textColour = menuTextColour
motionTableLengthInput.height = noteWidgetHeight
motionTableLengthInput.width = noteWidgetWidth
motionTableLengthInput.x = startModeMenu.x-- + noteInput.width + 5
motionTableLengthInput.y = thirdRowY
motionTableLengthInput.changed = function(self)
  tableMotion.options.tableLength = self.value
  positionTable.length = tableMotion.options.tableLength
  motionTable.length = tableMotion.options.tableLength
  pitchOffsetPos = 1 -- Reset pos on length change
  resetPitches()
  startMoving()
end

local moveSpeedInput = notePanel:NumBox("MoveSpeed", tableMotion.options.moveSpeed, tableMotion.options.moveSpeedMin, tableMotion.options.moveSpeedMax, false)
moveSpeedInput.displayName = "Motion Speed"
moveSpeedInput.tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller"
moveSpeedInput.unit = Unit.MilliSeconds
moveSpeedInput.backgroundColour = menuBackgroundColour
moveSpeedInput.textColour = menuTextColour
moveSpeedInput.height = noteWidgetHeight
moveSpeedInput.width = noteWidgetWidth
moveSpeedInput.x = noteInput.x + noteInput.width + noteWidgetCellSpacing
moveSpeedInput.y = firstRowY
moveSpeedInput.changed = function(self)
  tableMotion.options.moveSpeed = self.value
end

local factorInput = notePanel:NumBox("Factor", tableMotion.options.factor, tableMotion.options.factorMin, tableMotion.options.factorMax, false)
factorInput.displayName = "Speed Factor"
factorInput.tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. Controlled by the Y-axis on the XY controller"
factorInput.backgroundColour = menuBackgroundColour
factorInput.textColour = menuTextColour
factorInput.height = noteWidgetHeight
factorInput.width = noteWidgetWidth
factorInput.x = moveSpeedInput.x
factorInput.y = secondRowY
factorInput.changed = function(self)
  tableMotion.options.factor = self.value
end

local speedRandomizationAmountInput = notePanel:NumBox("SpeedRandomizationAmount", tableMotion.options.speedRandomizationAmount, 0, 100, true)
speedRandomizationAmountInput.unit = Unit.Percent
speedRandomizationAmountInput.displayName = "Speed Rand"
speedRandomizationAmountInput.tooltip = "Set the radomization amount applied to speed"
speedRandomizationAmountInput.backgroundColour = menuBackgroundColour
speedRandomizationAmountInput.textColour = menuTextColour
speedRandomizationAmountInput.height = noteWidgetHeight
speedRandomizationAmountInput.width = noteWidgetWidth
speedRandomizationAmountInput.x = factorInput.x
speedRandomizationAmountInput.y = thirdRowY
speedRandomizationAmountInput.changed = function(self)
  tableMotion.options.speedRandomizationAmount = self.value
end

local xySpeedFactor = notePanel:XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = speedRandomizationAmountInput.x + speedRandomizationAmountInput.width + noteWidgetCellSpacing
xySpeedFactor.width = noteWidgetWidth
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

local function noteIsPlaying(note)
  for _,v in ipairs(activeVoices) do
    if v.event.note == note then
      return true
    end
  end
  return false
end

local function isTrigger(e)
  local channel = channelInput.value - 1
  local isListeningForEvent = channel == 0 or channel == e.channel
  local isTrigger = e.note == 0 -- Note 0 is used as trigger
  return isTrigger and isListeningForEvent
end

local function handleTrigger(e)
  e.note = getNote()
  if noteIsPlaying(e.note) == false then
    startPlaying()
    local id = postEvent(e)
    table.insert(activeVoices, {id=id,event=e})
    --print("Add active voice on note/channel", e.note, e.channel)
  end
end

local function handleReleaseTrigger(e)
  for i,v in ipairs(activeVoices) do
    if v.event.channel == e.channel then
      releaseVoice(v.id)
      table.remove(activeVoices, i)
      --print("Release active voice on channel", v.event.channel)
    end
  end
end

function onInit()
  print("Init sequencer")
  uniqueIndex = 1
  tableMotion.options.startMode = tableMotion.startModes[6]
  startModeMenu.selected = gem.getIndexFromValue(tableMotion.options.startMode, tableMotion.startModes)
  setScale()
end

function onNote(e)
  if isTrigger(e) then
    handleTrigger(e)
  else
    postEvent(e)
  end
end

function onRelease(e)
  if isTrigger(e) then
    handleReleaseTrigger(e)
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
