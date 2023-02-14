--------------------------------------------------------------------------------
-- Rythmic Motions - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
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
local sliderColour = "pink"--"5FB5FF"

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local tableRange = 16
local bipolar = true
local positionTable
local motionTable
local motionTableLength = 32
local channel = 1
local factor = 2
local factorMin = 0
local factorMax = 4
local moveSpeed = 25
local moveSpeedMin = 5
local moveSpeedMax = 250
local speedRandomizationAmount = 0
local speedTypes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Random"}
local speedType = speedTypes[1]
local startModes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Zero", "Min", "Max", "Keep State", "Random"}
local startMode = startModes[1]
local noteEventId = 0 -- Holds the index if the cell in the table that last triggered an event
local resolutionNames = resolutions.getResolutionNames()
local resolution = #resolutionNames
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local movingCells = {}
local voiceId = nil -- Holds the id of the created note event

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetTableValues()
  -- Reset event id
  noteEventId = 0
  -- Reset position
  for i=1,motionTableLength do
    positionTable:setValue(i, 0)
  end
  -- Reset pitches according to start mode
  if startMode == "Keep State" then
    return
  elseif startMode == "Ramp Up" then
    for i,v in ipairs(gem.rampUp(motionTable.min, motionTable.max, motionTableLength)) do
      motionTable:setValue(i, v)
    end
  elseif startMode == "Ramp Down" then
    for i,v in ipairs(gem.rampDown(motionTable.min, motionTable.max, motionTableLength)) do
      motionTable:setValue(i, v)
    end
  elseif startMode == "Triangle" then
    for i,v in ipairs(gem.triangle(motionTable.min, motionTable.max, motionTableLength)) do
      motionTable:setValue(i, v)
    end
  elseif startMode == "Random" then
    for i=1,motionTableLength do
      motionTable:setValue(i, gem.getRandom(motionTable.min, motionTable.max))
    end
  elseif startMode == "Min" then
    for i=1,motionTableLength do
      motionTable:setValue(i, motionTable.min)
    end
  elseif startMode == "Max" then
    for i=1,motionTableLength do
      motionTable:setValue(i, motionTable.max)
    end
  elseif startMode == "Even" then
    local minValue = motionTable.min
    local maxValue = motionTable.max
    for i=1,motionTableLength do
      local val = minValue
      if i % 2 == 0 then
        val = maxValue
      end
      motionTable:setValue(i, val)
    end
  elseif startMode == "Odd" then
    local minValue = motionTable.min
    local maxValue = motionTable.max
    for i=1,motionTableLength do
      local val = maxValue
      if i % 2 == 0 then
        val = minValue
      end
      motionTable:setValue(i, val)
    end
  else
    for i=1,motionTableLength do
      positionTable:setValue(i, 0)
      motionTable:setValue(i, 0)
    end
  end
end

local function setRange()
  if bipolar then
    motionTable:setRange(-tableRange, tableRange)
  else
    motionTable:setRange(0, tableRange)
  end
  resetTableValues()
end

local function move(i, uniqueId)
  local middle = math.floor(motionTableLength / 2)
  local direction = 1 -- TODO Param for setting start direction?
  local value = motionTable:getValue(i)
  while isPlaying and movingCells[i] == uniqueId do
    -- Send note event if value is min or max
    -- TODO Add params for triggers?
    if value == motionTable.min or value == motionTable.max then
      noteEventId = i
    end
    -- Increment value
    local amount = i - 1
    if (i > middle and speedType == "Triangle") or speedType == "Ramp Down" then
      amount = (motionTableLength - i)
    elseif speedType == "Random" then
      amount = gem.getRandom(motionTableLength) - 1
    elseif (speedType == "Even" and i % 2 == 0) or (speedType == "Odd" and i % 2 > 0) then
      amount = 0
    elseif speedType == "Even" and i == 1 then
      amount = i
    end
    local min = motionTable.min
    local max = motionTable.max
    local duration = gem.randomizeValue(moveSpeed, moveSpeedMin, moveSpeedMax, speedRandomizationAmount) + (amount * factor) -- TODO Param for operator?
    motionTable:setValue(i, value)
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
    local valueBeforeWait = motionTable:getValue(i)
    wait(duration)
    -- If value has been manually changed during the wait, we continue from that value
    if valueBeforeWait ~= motionTable:getValue(i) then
      value = motionTable:getValue(i)
    end
  end
end

local function startMoving()
  movingCells = {} -- Reset index to stop
  for i=1,motionTableLength do
    table.insert(movingCells, uniqueIndex)
    spawn(move, i, uniqueIndex)
    uniqueIndex = gem.inc(uniqueIndex)
  end
end

local function sequenceRunner()
  startMoving()
  while isPlaying do
    if noteEventId > 0 then
      -- Release the voice if active
      if type(voiceId) == "userdata" then
        releaseVoice(voiceId)
        voiceId = nil
        --print("Releasing trigger")
      end
      local velocity = 64 -- TODO Get from param? Randomize? Create velocitySequencer eventProcessor?
      voiceId = playNote(0, velocity, -1, nil, channel)
      --print("Creating trigger")
      -- Mark the position that initiated the event
      for i=1,motionTableLength do
        local value = 0
        if i == noteEventId then
          value = 1
        end
        positionTable:setValue(i, value)
      end
      noteEventId = 0 -- Reset event id
    end
    wait(beat2ms(resolutions.getResolution(resolution)))
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  run(sequenceRunner)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetTableValues()
  if type(voiceId) == "userdata" then
    releaseVoice(voiceId)
    voiceId = nil
    --print("Releasing trigger")
  end
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
sequencerLabel.text = "Rythmic Motions Trigger"
sequencerLabel.tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.position = {0,0}
sequencerLabel.size = {sequencerPanel.width,30}

local channelInput = sequencerPanel:NumBox("Channel", channel, 1, 16, true)
channelInput.displayName = "Channel"
channelInput.tooltip = "Send note events starting on this channel"
channelInput.size = {90,22}
channelInput.x = (sequencerPanel.width / 2) + 50
channelInput.y = 5
channelInput.backgroundColour = menuBackgroundColour
channelInput.textColour = menuTextColour
channelInput.changed = function(self)
  channel = self.value
end

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = backgroundColourOff
autoplayButton.backgroundColourOn = backgroundColourOn
autoplayButton.textColourOff = textColourOff
autoplayButton.textColourOn = textColourOn
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = {100,22}
autoplayButton.x = channelInput.x + channelInput.width + 5
autoplayButton.y = channelInput.y

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

positionTable = notePanel:Table("Position", motionTableLength, 0, 0, 1, true)
positionTable.enabled = false
positionTable.persistent = false
positionTable.fillStyle = "solid"
positionTable.backgroundColour = widgetTextColour
positionTable.sliderColour = "green"
positionTable.width = notePanel.width
positionTable.height = 6
positionTable.x = 0
positionTable.y = noteLabel.y + noteLabel.height

motionTable = notePanel:Table("MotionTable", motionTableLength, 0, -tableRange, tableRange, true)
motionTable.tooltip = "Events are triggered when the value hits max or min"
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
local noteWidgetCellSpacing = 12
local firstRowY = motionTable.y + motionTable.height + 5
local secondRowY = firstRowY + noteWidgetHeight + noteWidgetRowSpacing
local thirdRowY = secondRowY + noteWidgetHeight + noteWidgetRowSpacing

local speedTypeMenu = notePanel:Menu("SpeedType", speedTypes)
speedTypeMenu.displayName = "Speed Type"
speedTypeMenu.tooltip = "Set the speed type (depending on factor > 0) - Ramp Up = slower for every cell, Ramp Down = faster etc"
speedTypeMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
speedTypeMenu.width = noteWidgetWidth
speedTypeMenu.x = noteWidgetCellSpacing
speedTypeMenu.y = firstRowY
speedTypeMenu.backgroundColour = menuBackgroundColour
speedTypeMenu.textColour = menuTextColour
speedTypeMenu.arrowColour = menuArrowColour
speedTypeMenu.outlineColour = menuOutlineColour
speedTypeMenu.changed = function(self)
  speedType = self.selectedText
end

local startModeMenu = notePanel:Menu("StartMode", startModes)
startModeMenu.displayName = "Start Mode"
startModeMenu.selected = gem.getIndexFromValue(startMode, startModes)
startModeMenu.tooltip = "Start mode controls the table reset"
startModeMenu.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
startModeMenu.width = noteWidgetWidth
startModeMenu.x = speedTypeMenu.x + speedTypeMenu.width + noteWidgetCellSpacing
startModeMenu.y = firstRowY
startModeMenu.backgroundColour = menuBackgroundColour
startModeMenu.textColour = menuTextColour
startModeMenu.arrowColour = menuArrowColour
startModeMenu.outlineColour = menuOutlineColour
startModeMenu.changed = function(self)
  startMode = self.selectedText
  resetTableValues()
end

local tableRangeInput = notePanel:NumBox("OctaveRange", tableRange, 8, 128, true)
tableRangeInput.displayName = "Range"
tableRangeInput.tooltip = "Set the table range - high range = fewer events, low range = more events"
tableRangeInput.backgroundColour = menuBackgroundColour
tableRangeInput.textColour = menuTextColour
tableRangeInput.height = noteWidgetHeight
tableRangeInput.width = noteWidgetWidth
tableRangeInput.x = speedTypeMenu.x
tableRangeInput.y = thirdRowY
tableRangeInput.changed = function(self)
  tableRange = self.value
  setRange()
end

local resolutionInput = notePanel:Menu("Quantize", resolutionNames)
resolutionInput.displayName = "Quantize"
resolutionInput.tooltip = "Event triggers are quantized to this resolution"
resolutionInput.selected = resolution
resolutionInput.height = (noteWidgetHeight * 2) + noteWidgetRowSpacing
resolutionInput.width = noteWidgetWidth
resolutionInput.backgroundColour = widgetBackgroundColour
resolutionInput.textColour = widgetTextColour
resolutionInput.arrowColour = menuArrowColour
resolutionInput.outlineColour = menuOutlineColour
resolutionInput.x = startModeMenu.x + startModeMenu.width + noteWidgetCellSpacing
resolutionInput.y = firstRowY
resolutionInput.changed = function(self)
  resolution = self.value
end

local bipolarButton = notePanel:OnOffButton("Bipolar", bipolar)
bipolarButton.backgroundColourOff = backgroundColourOff
bipolarButton.backgroundColourOn = backgroundColourOn
bipolarButton.textColourOff = textColourOff
bipolarButton.textColourOn = textColourOn
bipolarButton.displayName = "Bipolar"
bipolarButton.width = noteWidgetWidth
bipolarButton.height = noteWidgetHeight
bipolarButton.x = resolutionInput.x
bipolarButton.y = thirdRowY
bipolarButton.changed = function(self)
  bipolar = self.value
  setRange()
end

local motionTableLengthInput = notePanel:NumBox("MotionTableLength", motionTableLength, 2, 128, true)
motionTableLengthInput.displayName = "Length"
motionTableLengthInput.tooltip = "Set the table length"
motionTableLengthInput.backgroundColour = menuBackgroundColour
motionTableLengthInput.textColour = menuTextColour
motionTableLengthInput.height = noteWidgetHeight
motionTableLengthInput.width = noteWidgetWidth
motionTableLengthInput.x = startModeMenu.x
motionTableLengthInput.y = thirdRowY
motionTableLengthInput.changed = function(self)
  motionTableLength = self.value
  positionTable.length = motionTableLength
  motionTable.length = motionTableLength
  resetTableValues()
  startMoving()
end

local moveSpeedInput = notePanel:NumBox("MoveSpeed", moveSpeed, moveSpeedMin, moveSpeedMax, false)
moveSpeedInput.displayName = "Motion Speed"
moveSpeedInput.tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller"
moveSpeedInput.unit = Unit.MilliSeconds
moveSpeedInput.backgroundColour = menuBackgroundColour
moveSpeedInput.textColour = menuTextColour
moveSpeedInput.height = noteWidgetHeight
moveSpeedInput.width = noteWidgetWidth
moveSpeedInput.x = resolutionInput.x + resolutionInput.width + noteWidgetCellSpacing
moveSpeedInput.y = firstRowY
moveSpeedInput.changed = function(self)
  moveSpeed = self.value
end

local factorInput = notePanel:NumBox("Factor", factor, factorMin, factorMax, false)
factorInput.displayName = "Speed Factor"
factorInput.tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. Controlled by the Y-axis on the XY controller"
factorInput.backgroundColour = menuBackgroundColour
factorInput.textColour = menuTextColour
factorInput.height = noteWidgetHeight
factorInput.width = noteWidgetWidth
factorInput.x = moveSpeedInput.x
factorInput.y = secondRowY
factorInput.changed = function(self)
  factor = self.value
end

local speedRandomizationAmountInput = notePanel:NumBox("SpeedRandomizationAmount", speedRandomizationAmount, 0, 100, true)
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
  speedRandomizationAmount = self.value
end

local xySpeedFactor = notePanel:XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = moveSpeedInput.x + moveSpeedInput.width + noteWidgetCellSpacing
xySpeedFactor.width = noteWidgetWidth
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  uniqueIndex = 1
  setRange()
end

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
