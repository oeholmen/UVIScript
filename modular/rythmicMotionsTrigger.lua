--------------------------------------------------------------------------------
-- Rythmic Motions - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
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
      local velocity = 64
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
    waitBeat(resolutions.getResolution(resolution))
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
notePanel.height = 250

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

widgets.setPanel(sequencerPanel)
widgets.widthDefault(100)
widgets.heightDefault(22)
widgets.xOffset((sequencerPanel.width / 2) + 45)
widgets.yOffset(5)

local channelInput = widgets.numBox('Channel', channel, 1, 1, {
  tooltip = "Send note events starting on this channel",
  min = 1,
  max = 16,
  integer = true,
})
channelInput.changed = function(self)
  channel = self.value
end

local autoplayButton = widgets.button('Auto Play', true, 2, 1, {
  tooltip = "Play automatically on transport",
})

local playButton = widgets.button('Play', false, 3, 1)
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

positionTable = notePanel:Table("Position", motionTableLength, 0, 0, 1, true)
positionTable.enabled = false
positionTable.persistent = false
positionTable.fillStyle = "solid"
positionTable.backgroundColour = widgetTextColour
positionTable.sliderColour = "green"
positionTable.width = notePanel.width
positionTable.height = 6
positionTable.x = 0
positionTable.y = 0

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
local firstRowY = motionTable.y + motionTable.height + noteWidgetRowSpacing
local secondRowY = firstRowY + noteWidgetHeight + noteWidgetRowSpacing
local thirdRowY = secondRowY + noteWidgetHeight + noteWidgetRowSpacing

widgets.setPanel(notePanel)
widgets.widthDefault(noteWidgetWidth)
widgets.xOffset(noteWidgetCellSpacing)
widgets.yOffset(firstRowY)
widgets.xSpacing(noteWidgetCellSpacing)
widgets.ySpacing(noteWidgetRowSpacing)

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

local tableRangeInput = widgets.numBox("Range", tableRange, 1, 3, {
  min = 8,
  max = 128,
  integer = true,
  tooltip = "Set the table range - high range = fewer events, low range = more events",
})
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

local bipolarButton = widgets.button("Bipolar", bipolar, 3, 3, {width = (noteWidgetWidth / 2) - (noteWidgetCellSpacing / 2)})
bipolarButton.changed = function(self)
  bipolar = self.value
  setRange()
end

local resetButton = widgets.button("Reset", false, nil, 3, {width = bipolarButton.width, x = widgets.posSide(bipolarButton)})
resetButton.changed = function(self)
  resetTableValues()
  startMoving()
  self.value = false
end

local motionTableLengthInput = widgets.numBox("Length", motionTableLength, 2, 3, {
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the table length",
})
motionTableLengthInput.changed = function(self)
  motionTableLength = self.value
  positionTable.length = motionTableLength
  motionTable.length = motionTableLength
  resetTableValues()
  startMoving()
end

local moveSpeedInput = widgets.numBox("Motion Speed", moveSpeed, 4, 1, {
  name = "MoveSpeed",
  min = moveSpeedMin,
  max = moveSpeedMax,
  tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller",
  unit = Unit.MilliSeconds,
})
moveSpeedInput.changed = function(self)
  moveSpeed = self.value
end

local factorInput = widgets.numBox("Speed Factor", factor, 4, 2, {
  name = "Factor",
  min = factorMin,
  max = factorMax,
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. Controlled by the Y-axis on the XY controller",
})
factorInput.changed = function(self)
  factor = self.value
end

local speedRandomizationAmountInput = widgets.numBox("Speed Rand", speedRandomizationAmount, 4, 3, {
  unit = Unit.Percent,
  tooltip = "Set the radomization amount applied to speed",
})
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
