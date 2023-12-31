--------------------------------------------------------------------------------
-- Recording Sequencer - A sequencer with recording
--------------------------------------------------------------------------------

-- TODO Record only selected midi channel?
-- TODO Use takes when recording?
-- TODO Handle undo
-- TODO Show recorded notes - editable!
-- TODO Option to persist quantization for a voice/take?

local gem = require "includes.common"
local resolutions = require "includes.resolutions"
local widgets = require "includes.widgets"

local resolutionNames = resolutions.getResolutionNames()
local quantizeResolutions = {
  "1/1", -- 11
  "1/1 tri", -- 13
  "1/2", -- 14
  "1/2 tri", -- 16
  "1/4", -- 17
  "1/4 tri", -- 19
  "1/8", -- 20
  "1/8 tri", -- 22
  "1/16", -- 23
  "1/16 tri", -- 25
  "1/32", -- 26
  "1/32 tri", -- 28
  "1/64", -- 29
  "1/64 tri", -- 31
  "Off"
}
local resolution = #resolutionNames
local isPlaying = false
local recordActive = true
local positionTable
local countIn = 4
local baseSequenceResolution = 1 -- 1/4 TODO Metronome/tick?
local seqIndex = 0 -- Holds the unique id for the base sequencer
local tickResolution = resolutions.getTriplet(resolutions.getPlayDuration())
local steps = 16
local ticks = steps / tickResolution
local tickCounter = 0 -- Holds the current sequence tick (position)
local sequence = {} -- Holds the recorded sequence
local takesCounter = 0 -- Holds the counter for takes
local createTakeForEachRound = false -- Whether to create a take for each round
local backgroundColour = "117744" -- Light or Dark

--[[ widgets.setColours({
  backgroundColour = backgroundColour,
  widgetBackgroundColour = "black",
  widgetTextColour = "3EC1D3",
  labelTextColour = "black",
  labelBackgoundColour = "black",
  menuBackgroundColour = "01011F",
  menuArrowColour = "66" .. "black",
  menuOutlineColour = "5f" .. "3EC1D3",
  backgroundColourOff = "red",
}) ]]

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function setTableZero(theTable)
  for i=1,theTable.length do
    theTable:setValue(i, 0)
  end
end

local function isQuantizeOff()
  return resolution == #resolutionNames
end

local function isQuantizeOn()
  return isQuantizeOff() == false
end

local function playTick()
  local startPos = tickCounter
  local endPos = tickCounter

  if isQuantizeOn() then
    local quantizeTo = resolutions.getResolution(resolution)
    local ticksInResolution = quantizeTo / tickResolution
    local ticksInQuantization = math.floor(ticksInResolution / 2)
    startPos = math.max(-ticksInQuantization, (tickCounter - ticksInQuantization))
    endPos = math.min(ticks, (tickCounter + ticksInQuantization - 1))
  end
  --print("startPos, endPos", startPos, endPos)
  for i=startPos,endPos do
    local tickPos = i
    if tickPos < 1 then
      tickPos = tickPos + ticks
    end
    for _,e in ipairs(sequence[tickPos]) do
      if isKeyDown(e.note) == false then
        if type(e.endPos) == "nil" then
          e.endPos = ticks
          print("Missing end pos")
        end
        local diff = e.endPos - e.startPos
        if diff < 0 then
          diff = diff + ticks
        end
        local duration = diff * tickResolution
        playNote(e.note, e.velocity, beat2ms(duration))
        --print("note, startPos, endPos, diff, duration", e.note, e.startPos, e.endPos, diff, duration)
      end
    end
  end
end

local function shouldPlayTick(internalTickCounter)
  if isQuantizeOff() then
    return true
  end

  local quantizeTo = resolutions.getResolution(resolution)
  local ticksInResolution = quantizeTo / tickResolution
  local ticksDurationForResolution = tickResolution * ticksInResolution

  return (internalTickCounter - 1) % ticksInResolution == 0 and quantizeTo == ticksDurationForResolution
end

local function lastTakeIsEmpty()
  for i,tickEvents in ipairs(sequence) do
    for i,v in ipairs(tickEvents) do
      if v.take == takesCounter then
        print("Found an event for take", takesCounter)
        return false
      end
    end
  end

  print("No events for take", takesCounter)
  return true
end

local function incrementTakesCounter()
  if takesCounter > 0 and lastTakeIsEmpty() then
    return
  end

  takesCounter = gem.inc(takesCounter, 1)
  print("Set takesCounter", takesCounter)
end

local function sequenceRunner(uniqueId)
  local tablePos = 1
  local countInPos = 0
  local countInActive = recordActive and countInPos < countIn
  local countInTicks = countIn / tickResolution
  local internalTickCounter = 0
  tickCounter = 0
  if countInActive then
    tickCounter = -countInTicks
  end
  local countInQuantizeTo = 1 -- 1/4
  local countInTicksInResolution = countInQuantizeTo / tickResolution
  local countInTicksDurationForResolution = tickResolution * countInTicksInResolution
  --print("tickCounter", tickCounter)
  while isPlaying and seqIndex == uniqueId do
    tickCounter = gem.inc(tickCounter, 1, ticks)
    internalTickCounter = gem.inc(internalTickCounter, 1, ticks)
    if internalTickCounter == 1 and createTakeForEachRound then
      incrementTakesCounter()
    end
    if (internalTickCounter - 1) % countInTicksInResolution == 0 and countInQuantizeTo == countInTicksDurationForResolution then
      --print("1/4", internalTickCounter)
      if countInActive then
        if countInPos == countIn then
          countInActive = false
          internalTickCounter = 1
          tablePos = 1
        elseif countInPos < countIn then
          positionTable.sliderColour = "orange"
        end
        countInPos = gem.inc(countInPos, 1)
      end

      if countInActive == false then
        if recordActive then
          positionTable.sliderColour = "red"
        else
          positionTable.sliderColour = "green"
        end
      end

      setTableZero(positionTable)
      positionTable:setValue(tablePos, 1)
      tablePos = gem.inc(tablePos, 1, positionTable.length)
    end

    if countInActive == false then
      if tickCounter ~= internalTickCounter then
        print("tickCounter ~= internalTickCounter", tickCounter, internalTickCounter)
      end

      if shouldPlayTick(internalTickCounter) then
        playTick()
      end
    end

    waitBeat(tickResolution)
  end
end

local function removeTake()
  if lastTakeIsEmpty() then
    takesCounter = gem.inc(takesCounter, -1)
  end

  if takesCounter < 1 then
    return
  end

  local newSequence = {}
  for i=1,ticks do
    local tickEvents = {}
    for i,v in ipairs(sequence[i]) do
      if v.take == takesCounter then
        print("Skipping event for take", takesCounter)
      else
        print("Keeping event for take", v.take)
        table.insert(tickEvents, v)
      end
    end
    table.insert(newSequence, tickEvents)
  end

  sequence = newSequence -- Set sequence
end

local function adjustSequenceTable()
  print("Adjust sequence length, ticks", ticks)
  local newSequence = {}
  for i=1,ticks do
    local tickEvents = {}
    if type(sequence[i]) == "table" then
      tickEvents = sequence[i]
    end
    table.insert(newSequence, tickEvents)
  end
  sequence = newSequence -- Set sequence
end

local function initSequenceTable()
  print("Delete recording")
  takesCounter = 0
  sequence = {}
  for i=1,ticks do
    table.insert(sequence, {})
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  if recordActive and createTakeForEachRound == false then
    incrementTakesCounter()
  end
  seqIndex = gem.inc(seqIndex)
  run(sequenceRunner, seqIndex)
end

local function stopPlaying()
  isPlaying = false
  setTableZero(positionTable)
end

--------------------------------------------------------------------------------
-- Widgets
--------------------------------------------------------------------------------

widgets.panel({
  backgroundColour = "113344",
  x = 3,
  y = 3,
  width = 714,
  height = 48,
})

widgets.setSection({
  x = 15,
  y = 15,
  xSpacing = 15,
})

local labelWidget = widgets.label("Recording Sequencer", {
  tooltip = "Record and play back a sequence",
  alpha = 0.5,
  fontSize = 22,
  width = 210,
  editable = true,
})

widgets.col()

local recordButton = widgets.button("Record", recordActive, {
  tooltip = "When record is enabled, the count in will play before the sequencer starts. Use transport or the Play button to start recording.",
  width = 96,
  changed = function(self)
    recordActive = self.value
    if recordActive then
      positionTable.sliderColour = "red"
    else
      positionTable.sliderColour = "green"
    end
  end
})

local autoplayButton = widgets.button("Auto Play", true, {
  tooltip = "Start automatically on transport",
  width = 96,
})

local playButton = widgets.button("Play", false, {
  width = 96,
  changed = function(self)
    if self.value then
      startPlaying()
    else
      stopPlaying()
    end
  end
})

widgets.panel({
  backgroundColour = backgroundColour,
  x = widgets.getPanel().x,
  y = widgets.posUnder(widgets.getPanel()),
  width = widgets.getPanel().width,
  height = 20,
})

widgets.setSection({
  x = 10,
  y = 10,
  xSpacing = 15,
})

positionTable = widgets.table("SequencePosition", 0, steps, {
  max = 1,
  integer = true,
  enabled = false,
  persistent = false,
  sliderColour = "green",
  backgroundColour = "cfffe",
  width = 690,
  height = 6,
})

widgets.panel({
  backgroundColour = backgroundColour,
  x = widgets.getPanel().x,
  y = widgets.posUnder(widgets.getPanel()),
  width = widgets.getPanel().width,
  height = 60,
})

widgets.setSection({
  x = 10,
  y = 10,
  ySpacing = 5,
  xSpacing = 15,
})

widgets.numBox("Steps", steps, {
  tooltip = "Lowest note - notes below this are passed through",
  min = 4,
  max = 64,
  integer = true,
  changed = function(self)
    steps = self.value
    positionTable.length = steps
    ticks = steps / tickResolution
    adjustSequenceTable()
  end
}):changed()

widgets.menu("Quantize", #quantizeResolutions, quantizeResolutions, {
  tooltip = "Set the quantize resolution",
  --showLabel = false,
  changed = function(self)
    local resolutionIndex = gem.getIndexFromValue(self.text, resolutionNames)
    if type(resolutionIndex) == "nil" then
      resolution = #resolutionNames
    else
      resolution = resolutionIndex
    end
    print("Quantize resolution", resolution)
  end
})

local options = {
  "Select...",
  "Undo last take",
  --"Set quantization on sequence",
  "--- Danger Zone ---",
  "Clear sequence",
}

widgets.menu("Actions", 1, options, {
  changed = function(self)
    if self.text == "Clear sequence" then
      initSequenceTable()
    elseif self.text == "Undo last take" then
      removeTake()
    end
    self:setValue(1, false)
  end
})

widgets.row()

widgets.numBox("Count In", countIn, {
  tooltip = "Set a count in",
  min = 0,
  max = 4,
  integer = true,
  changed = function(self)
    countIn = self.value
  end
})

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
end

function onTransport(start)
  if autoplayButton.value == true then
    playButton:setValue(start)
  end
end

function onNote(e)
  if isPlaying and recordActive then
    local tickPos = tickCounter
    if tickPos < 1 then
      tickPos = tickPos + ticks
    end
    if takesCounter < 1 then
      incrementTakesCounter()
    end
    table.insert(sequence[tickPos], {note = e.note, velocity = e.velocity, startPos = tickPos, take = takesCounter})
    print("Set note, startPos, take, #events@pos", e.note, tickPos, takesCounter, #sequence[tickPos])
  end
  postEvent(e)
end

function onRelease(e)
  if isPlaying and recordActive then
    for i,s in ipairs(sequence) do
      for j,w in ipairs(s) do
        if e.note == w.note and type(w.endPos) == "nil" then
          sequence[i][j].endPos = tickCounter
          print("Set note, endPos", e.note, sequence[i][j].endPos)
        end
      end
    end
  end
  postEvent(e)
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  return {labelWidget.text, sequence}
end

function onLoad(data)
  labelWidget.text = data[1]
  sequence = data[2]
end
