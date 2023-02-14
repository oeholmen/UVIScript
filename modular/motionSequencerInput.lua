----------------------------------------------------------------------------------
-- Motion Sequencer - Listens for incoming note events (rythm) on note number 0
----------------------------------------------------------------------------------

local gem = require "includes.common"
local scales = require "includes.scales"
local resolutions = require "includes.resolutions"

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
local pitchOffsetTable
local pitchOffsetTableLength = 32
local scalesNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinitionIndex = #scalesNames
local activeScale = {} -- Holds the active scale
local factor = 2
local moveSpeed = 50
local motionTypes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Zero", "Random"}
local amountType = motionTypes[1]
local startModes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Zero", "Min", "Max", "Keep State", "Random"}
local startMode = startModes[6]
local activeVoices = {}

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetPitches()
  -- Reset position
  pitchOffsetPos = 1
  for i=1,pitchOffsetTableLength do
    positionTable:setValue(i, 0)
  end
  -- Reset pitches according to start mode
  if startMode == "Keep State" then
    return
  elseif startMode == "Ramp Up" then
    for i,v in ipairs(gem.rampUp(pitchOffsetTable.min, pitchOffsetTable.max, pitchOffsetTableLength)) do
      pitchOffsetTable:setValue(i, v)
    end
  elseif startMode == "Ramp Down" then
    for i,v in ipairs(gem.rampDown(pitchOffsetTable.min, pitchOffsetTable.max, pitchOffsetTableLength)) do
      pitchOffsetTable:setValue(i, v)
    end
  elseif startMode == "Triangle" then
    for i,v in ipairs(gem.triangle(pitchOffsetTable.min, pitchOffsetTable.max, pitchOffsetTableLength)) do
      pitchOffsetTable:setValue(i, v)
    end
  elseif startMode == "Random" then
    for i=1,pitchOffsetTableLength do
      pitchOffsetTable:setValue(i, gem.getRandom(pitchOffsetTable.min, pitchOffsetTable.max))
    end
  elseif startMode == "Min" then
    for i=1,pitchOffsetTableLength do
      pitchOffsetTable:setValue(i, pitchOffsetTable.min)
    end
  elseif startMode == "Max" then
    for i=1,pitchOffsetTableLength do
      pitchOffsetTable:setValue(i, pitchOffsetTable.max)
    end
  elseif startMode == "Even" then
    local minValue = pitchOffsetTable.min
    local maxValue = pitchOffsetTable.max
    for i=1,pitchOffsetTableLength do
      local val = minValue
      if i % 2 == 0 then
        val = maxValue
      end
      pitchOffsetTable:setValue(i, val)
    end
  elseif startMode == "Odd" then
    local minValue = pitchOffsetTable.min
    local maxValue = pitchOffsetTable.max
    for i=1,pitchOffsetTableLength do
      local val = maxValue
      if i % 2 == 0 then
        val = minValue
      end
      pitchOffsetTable:setValue(i, val)
    end
  else
    for i=1,pitchOffsetTableLength do
      positionTable:setValue(i, 0)
      pitchOffsetTable:setValue(i, 0)
    end
  end
end

local function setScale()
  local scaleDefinition = scaleDefinitions[scaleDefinitionIndex]
  local oneOctScale = scales.createScale(scaleDefinition, 0, 12)
  print("#oneOctScale", #oneOctScale)
  -- TODO Check octave range / bipolar before setting the table range
  local tableRange = #oneOctScale * octaveRange
  print("tableRange", tableRange)
  if bipolar then
    pitchOffsetTable:setRange(-tableRange, tableRange)
  else
    pitchOffsetTable:setRange(0, tableRange)
  end
  local startNote = baseNote
  if bipolar then
    startNote = startNote - (octaveRange * 12)
  end
  local maxNote = baseNote + (octaveRange * 12) + 1
  activeScale = scales.createScale(scaleDefinition, math.max(0, startNote), math.min(128, maxNote))
  print("#activeScale, startNote, maxNote", #activeScale, startNote, maxNote)
  resetPitches()
end

local function move(i)
  local middle = math.floor(pitchOffsetTableLength / 2)
  local direction = 1 -- TODO Param for setting start direction?
  local value = pitchOffsetTable:getValue(i)
  print("i, duration", i, duration)
  while isPlaying do
    local amount = i - 1
    if (i > middle and amountType == "Triangle") or amountType == "Ramp Down" then
      amount = (pitchOffsetTableLength - i)-- + 1
    elseif amountType == "Random" then
      amount = gem.getRandom(pitchOffsetTableLength) - 1
    elseif amountType == "Zero" or (amountType == "Even" and i % 2 == 0) or (amountType == "Odd" and i % 2 > 0) then
      amount = 0
    end
    local min = pitchOffsetTable.min
    local max = pitchOffsetTable.max
    local duration = moveSpeed + (amount * factor) -- TODO Param for operator?
    pitchOffsetTable:setValue(i, value)
    value = gem.inc(value, direction)
    if value < min then
      if true or gem.getRandomBoolean() then
        value = min
        direction = 1
        --print("Change direction", direction)
      else
        value = max
      end
      --print("Reset value", value)
    elseif value > max then
      if true or gem.getRandomBoolean() then
        value = max
        direction = -1
        --print("Change direction", direction)
      else
        value = min
      end
      --print("Reset value", value)
    end
    local valueBeforeWait = pitchOffsetTable:getValue(i)
    wait(duration)
    -- If value has been manually changed during the wait, we continue from that value
    if valueBeforeWait ~= pitchOffsetTable:getValue(i) then
      value = pitchOffsetTable:getValue(i)
    end
  end
end

local function getNote()
  -- TODO Find pitch offset
  --pitchOffsetPos = gem.getRandom(1, pitchOffsetTableLength)
  print("pitchOffsetTable:getValue(pitchOffsetPos), pitchOffsetPos", pitchOffsetTable:getValue(pitchOffsetPos), pitchOffsetPos)
  for i=1,pitchOffsetTableLength do
    local val = 0
    if i == pitchOffsetPos then
      val = 1
    end
    positionTable:setValue(i, val)
  end
  local scalePos = pitchOffsetTable:getValue(pitchOffsetPos) + 1
  if pitchOffsetTable.min < 0 then
    scalePos = scalePos + math.abs(pitchOffsetTable.min)
  end
  print("#activeScale, scalePos", #activeScale, scalePos)
  local note = activeScale[scalePos]
  pitchOffsetPos = gem.inc(pitchOffsetPos, 1, pitchOffsetTableLength)
  print("pitchOffsetPos", pitchOffsetPos)
  return note
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  for i=1,pitchOffsetTableLength do
    spawn(move, i)
  end
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetPitches()
end

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

local sequencerPanel = Panel("MotionSequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 0
sequencerPanel.y = 0
sequencerPanel.width = 720
sequencerPanel.height = 30

local notePanel = Panel("Notes")
notePanel.backgroundColour = "606060"
notePanel.x = sequencerPanel.x
notePanel.y = sequencerPanel.y + sequencerPanel.height
notePanel.width = sequencerPanel.width
notePanel.height = 270

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("Label")
sequencerLabel.text = "Motion Sequencer Input"
sequencerLabel.tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.position = {0,0}
sequencerLabel.size = {sequencerPanel.width,30}

local channels = {"Omni"}
for j=1,16 do
  table.insert(channels, "" .. j)
end

local channelInput = sequencerPanel:Menu("ChannelInput", channels)
channelInput.tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through"
channelInput.arrowColour = menuArrowColour
channelInput.showLabel = false
channelInput.backgroundColour = menuBackgroundColour
channelInput.textColour = widgetTextColour
channelInput.size = {90,22}
channelInput.x = sequencerPanel.width - channelInput.width - 5
channelInput.y = 5

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local noteLabel = notePanel:Label("NoteLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Note setup"
noteLabel.alpha = 0.5
noteLabel.fontSize = 16
noteLabel.backgroundColour = labelBackgoundColour
noteLabel.textColour = labelTextColour
noteLabel.width = sequencerPanel.width
noteLabel.height = 18
noteLabel.x = 0
noteLabel.y = 0

positionTable = notePanel:Table("Position", pitchOffsetTableLength, 0, 0, 1, true)
positionTable.enabled = false
positionTable.persistent = false
positionTable.fillStyle = "solid"
positionTable.backgroundColour = widgetTextColour
positionTable.sliderColour = "green"
positionTable.width = notePanel.width
positionTable.height = 6
positionTable.x = 0
positionTable.y = noteLabel.y + noteLabel.height

pitchOffsetTable = notePanel:Table("PitchOffset", pitchOffsetTableLength, 0, -24, 24, true)
pitchOffsetTable.persistent = false
--pitchOffsetTable.enabled = false
--pitchOffsetTable.drawInnerEdge = false
pitchOffsetTable.tooltip = "Set pitch offset"
pitchOffsetTable.showPopupDisplay = true
pitchOffsetTable.fillStyle = "solid"
pitchOffsetTable.sliderColour = sliderColour
pitchOffsetTable.width = notePanel.width
pitchOffsetTable.height = 160
pitchOffsetTable.x = 0
pitchOffsetTable.y = positionTable.y + positionTable.height

local noteWidgetHeight = 20
local noteWidgetWidth = 130
local noteWidgetRowSpacing = 5
local noteWidgetCellSpacing = 15
local firstRowY = pitchOffsetTable.y + pitchOffsetTable.height + 5
local secondRowY = firstRowY + noteWidgetHeight + noteWidgetRowSpacing
local thirdRowY = secondRowY + noteWidgetHeight + noteWidgetRowSpacing

local amountTypeMenu = notePanel:Menu("AmountType", motionTypes)
amountTypeMenu.displayName = "Amount Type"
amountTypeMenu.tooltip = "Amount type - Ramp Up means slower for every step (depending on factor)"
--amountTypeMenu.showLabel = false
amountTypeMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
amountTypeMenu.width = noteWidgetWidth
amountTypeMenu.x = noteWidgetCellSpacing
amountTypeMenu.y = firstRowY
amountTypeMenu.backgroundColour = menuBackgroundColour
amountTypeMenu.textColour = menuTextColour
amountTypeMenu.arrowColour = menuArrowColour
amountTypeMenu.outlineColour = menuOutlineColour
amountTypeMenu.changed = function(self)
  amountType = self.selectedText
  --print("amountType", amountType)
end

local startModeMenu = notePanel:Menu("StartMode", startModes)
startModeMenu.displayName = "Start Mode"
startModeMenu.selected = gem.getIndexFromValue(startMode, startModes)
startModeMenu.tooltip = "Start mode controls the table reset"
--startModeMenu.showLabel = false
startModeMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
startModeMenu.width = noteWidgetWidth
startModeMenu.x = amountTypeMenu.x + amountTypeMenu.width + 5
startModeMenu.y = firstRowY
startModeMenu.backgroundColour = menuBackgroundColour
startModeMenu.textColour = menuTextColour
startModeMenu.arrowColour = menuArrowColour
startModeMenu.outlineColour = menuOutlineColour
startModeMenu.changed = function(self)
  startMode = self.selectedText
  --print("startMode", startMode)
  resetPitches()
end

local scaleMenu = notePanel:Menu("Scale", scalesNames)
scaleMenu.selected = #scalesNames
scaleMenu.displayName = "Scale"
scaleMenu.tooltip = "The scale to use for automatic motion"
--scaleMenu.showLabel = false
scaleMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
scaleMenu.width = noteWidgetWidth
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
--noteInput.showLabel = false
noteInput.displayName = "Base Note"
noteInput.tooltip = "Set the root note"
noteInput.unit = Unit.MidiKey
noteInput.backgroundColour = menuBackgroundColour
noteInput.textColour = menuTextColour
noteInput.height = noteWidgetHeight
noteInput.width = noteWidgetWidth
noteInput.x = scaleMenu.x
noteInput.y = thirdRowY
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
octaveRangeInput.x = noteInput.x + noteInput.width + 5
octaveRangeInput.y = secondRowY
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
bipolarButton.x = scaleMenu.x + scaleMenu.width + 5
bipolarButton.y = firstRowY
bipolarButton.changed = function(self)
  bipolar = self.value
  setScale()
end

local pitchOffsetTableLengthInput = notePanel:NumBox("PitchOffsetTableLength", pitchOffsetTableLength, 2, 128, true)
pitchOffsetTableLengthInput.displayName = "Length"
pitchOffsetTableLengthInput.tooltip = "Set the table size"
pitchOffsetTableLengthInput.backgroundColour = menuBackgroundColour
pitchOffsetTableLengthInput.textColour = menuTextColour
pitchOffsetTableLengthInput.height = noteWidgetHeight
pitchOffsetTableLengthInput.width = noteWidgetWidth
pitchOffsetTableLengthInput.x = noteInput.x + noteInput.width + 5
pitchOffsetTableLengthInput.y = thirdRowY
pitchOffsetTableLengthInput.changed = function(self)
  pitchOffsetTableLength = self.value
  positionTable.length = pitchOffsetTableLength
  pitchOffsetTable.length = pitchOffsetTableLength
  pitchOffsetPos = 1 -- Reset pos on length change
  resetPitches()
end

local moveSpeedInput = notePanel:NumBox("MoveSpeed", moveSpeed, 1., 500., false)
moveSpeedInput.displayName = "Speed"
moveSpeedInput.tooltip = "Set the move speed"
moveSpeedInput.unit = Unit.MilliSeconds
moveSpeedInput.backgroundColour = menuBackgroundColour
moveSpeedInput.textColour = menuTextColour
moveSpeedInput.height = noteWidgetHeight
moveSpeedInput.width = noteWidgetWidth
moveSpeedInput.x = noteWidgetCellSpacing--scaleMenu.x + scaleMenu.width + noteWidgetCellSpacing
moveSpeedInput.y = thirdRowY
moveSpeedInput.changed = function(self)
  moveSpeed = self.value
end

local factorInput = notePanel:NumBox("Factor", factor, 0., 30., false)
factorInput.displayName = "Speed Factor"
factorInput.tooltip = "Set the factor of slowdown or spedup per step"
factorInput.backgroundColour = menuBackgroundColour
factorInput.textColour = menuTextColour
factorInput.height = noteWidgetHeight
factorInput.width = noteWidgetWidth
factorInput.x = moveSpeedInput.x + moveSpeedInput.width + 5
factorInput.y = thirdRowY
factorInput.changed = function(self)
  factor = self.value
end

local xySpeedFactor = notePanel:XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = bipolarButton.x + bipolarButton.width + noteWidgetCellSpacing
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
    print("Add active voice on note/channel", e.note, e.channel)
  end
end

local function handleReleaseTrigger(e)
  for i,v in ipairs(activeVoices) do
    if v.event.channel == e.channel then
      releaseVoice(v.id)
      table.remove(activeVoices, i)
      print("Release active voice on channel", v.event.channel)
    end
  end
end

function onInit()
  print("Init sequencer")
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
