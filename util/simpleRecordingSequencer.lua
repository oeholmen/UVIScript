--------------------------------------------------------------------------------
-- Simple Recording Sequencer - A sequencer with recording
--------------------------------------------------------------------------------

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
local recordActivatedDuringRun = false
local recordButton
local recordOptions
local positionTable
local countIn = 4
local baseSequenceResolution = 1 -- 1/4 TODO Metronome/tick?
local seqIndex = 0 -- Holds the unique id for the base sequencer
local tickResolution = resolutions.getTriplet(resolutions.getPlayDuration())
local steps = 16
local maxSteps = 128
local ticks = steps / tickResolution -- Holds total number if ticks in sequence
local tickCounter = 0 -- Holds the current sequence tick (position)
local sequence = {} -- Holds the recorded sequence
local noteSequence = {} -- Holds the sequence per note
local takesCounter = 0 -- Holds the counter for takes
local backgroundColour = "117744" -- Light or Dark

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function isQuantizeOff()
  return resolution == #resolutionNames
end

local function isQuantizeOn()
  return isQuantizeOff() == false
end

local function shouldPlayTick(tick)
  if isQuantizeOff() then
    return true
  end

  local quantizeTo = resolutions.getResolution(resolution)
  local ticksInResolution = quantizeTo / tickResolution
  local ticksDurationForResolution = tickResolution * ticksInResolution

  return (tick - 1) % ticksInResolution == 0 and quantizeTo == ticksDurationForResolution
end

local function getQantizedPos(tick)
  local quantizedPos = tick
  local forward = tick
  local backward = tick

  while shouldPlayTick(forward) == false do
    forward = gem.inc(forward)
  end

  while shouldPlayTick(backward) == false do
    backward = gem.inc(backward, -1)
  end

  local diffForward = forward - tick
  local diffBackward = backward - tick

  if math.abs(diffBackward) > diffForward then
    -- Go forward
    quantizedPos = forward
    if quantizedPos > ticks then
      quantizedPos = ticks - quantizedPos
    end
  else
    -- Go backward
    quantizedPos = backward
    if quantizedPos < 1 then
      quantizedPos = quantizedPos + ticks
    end
  end

  --print("tick, forward, backward, diffForward, diffBackward, quantizedPos", tick, forward, backward, diffForward, diffBackward, quantizedPos)

  return quantizedPos
end

local function getSequenceForNote(note)
  for _,v in ipairs(noteSequence) do
    if note == v.note then
      return v
    end
  end
end

local function drawNoteInTable(note, tickPos, value)
  if type(value) == "nil" then
    value = 1
  end
  local seq = getSequenceForNote(note)
  if type(seq) == "table" then
    seq.table:setValue(tickPos, value)
  end
end

local function drawNoteTicks(tickPos, eventPos, value)
  local note = sequence[tickPos][eventPos].note
  local startPos = sequence[tickPos][eventPos].startPos
  local endPos = sequence[tickPos][eventPos].endPos

  if type(endPos) == "nil" then
    endPos = startPos
  end

  if startPos > endPos then
    startPos = startPos - ticks
  end

  local eventLength = endPos - startPos

  startPos = getQantizedPos(startPos)
  endPos = startPos + eventLength
  endPos = math.min(endPos, ticks)

  --print("drawNoteTicks, note, tickPos, startPos, endPos, value", note, tickPos, startPos, endPos, value)

  for i=startPos, endPos do
    local tick = i
    if tick < 1 then
      tick = tick + ticks
    end
    drawNoteInTable(note, tick, value)
  end
end

local function setTableZero(theTable)
  for i=1,theTable.length do
    theTable:setValue(i, 0)
  end
end

local function getEventsForTick(tick)
  local startPos = tick
  local endPos = tick

  if isQuantizeOn() then
    local quantizeTo = resolutions.getResolution(resolution)
    local ticksInResolution = quantizeTo / tickResolution
    local ticksInQuantization = math.floor(ticksInResolution / 2)
    startPos = math.max(-ticksInQuantization, (tick - ticksInQuantization))
    endPos = math.min(ticks, (tick + ticksInQuantization - 1))
  end

  local tickEvents = {}

  for i=startPos,endPos do
    local tickPos = i
    if tickPos < 1 then
      tickPos = tickPos + ticks
    end
    for _,e in ipairs(sequence[tickPos]) do
      table.insert(tickEvents, e)
    end
  end

  --print("Found tickEvents for tick", #tickEvents, tick)

  return tickEvents
end

local function playTick()
  local tickEvents = getEventsForTick(tickCounter)
  for _,e in ipairs(tickEvents) do
    if isKeyDown(e.note) == false then
      if type(e.endPos) == "nil" then
        e.endPos = ticks
        --print("Missing end pos")
      end
      local diff = e.endPos - e.startPos
      if diff < 0 then
        diff = diff + ticks
      end
      local duration = diff * tickResolution
      playNote(e.note, e.velocity, beat2ms(duration), nil, e.channel)
      --print("note, startPos, endPos, diff, duration", e.note, e.startPos, e.endPos, diff, duration)
    end
  end
end

local function lastTakeIsEmpty()
  for i,tickEvents in ipairs(sequence) do
    for i,v in ipairs(tickEvents) do
      if v.take == takesCounter then
        --print("Found an event for take", takesCounter)
        return false
      end
    end
  end

  --print("No events for take", takesCounter)
  return true
end

local function incrementTakesCounter()
  if takesCounter > 0 and lastTakeIsEmpty() then
    return
  end

  takesCounter = gem.inc(takesCounter, 1)
  --print("Set takesCounter", takesCounter)
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
  local roundCounter = 0
  --print("tickCounter", tickCounter)
  while isPlaying and seqIndex == uniqueId do
    tickCounter = gem.inc(tickCounter, 1, ticks)
    internalTickCounter = gem.inc(internalTickCounter, 1, ticks)
    if internalTickCounter == 1 then
      roundCounter = gem.inc(roundCounter)
      if recordActive and recordOptions.text == "Punch Out" and roundCounter > 1 and #sequence > 0 then
        if recordActivatedDuringRun or countInActive then
          recordActivatedDuringRun = false
        else
          recordButton:setValue(false)
        end
      end
    end
    if (internalTickCounter - 1) % countInTicksInResolution == 0 and countInQuantizeTo == countInTicksDurationForResolution then
      if countInActive then
        if countInPos == countIn then
          countInActive = false
          internalTickCounter = 1
          tablePos = 1
        elseif countInPos < countIn then
          positionTable.sliderColour = "orange"
        end
        countInPos = gem.inc(countInPos)
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
        --print("tickCounter ~= internalTickCounter", tickCounter, internalTickCounter)
      end

      if shouldPlayTick(internalTickCounter) then
        playTick()
      end
    end

    waitBeat(tickResolution)
  end
end

local function clearNoteTables()
  for _,v in ipairs(noteSequence) do
    setTableZero(v.table)
    v.table.length = ticks
  end
end

local function writeSequenceToNoteTables()
  clearNoteTables()
  for tick,events in ipairs(sequence) do
    for i,tickEvent in ipairs(events) do
      drawNoteTicks(tick, i)
    end
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
    for j,v in ipairs(sequence[i]) do
      if v.take == takesCounter then
        --print("Skipping event for take", takesCounter)
      else
        --print("Keeping event for take", v.take)
        table.insert(tickEvents, v)
      end
    end
    table.insert(newSequence, tickEvents)
  end

  sequence = newSequence -- Set sequence
  writeSequenceToNoteTables()
end

local function adjustSequenceTable()
  --print("Adjust sequence length, ticks", ticks)
  local newSequence = {}
  for i=1,ticks do
    local tickEvents = {}
    if type(sequence[i]) == "table" then
      tickEvents = sequence[i]
    end
    table.insert(newSequence, tickEvents)
  end
  sequence = newSequence -- Set sequence
  writeSequenceToNoteTables()
end

local function initSequenceTable()
  --print("Delete recording")
  takesCounter = 0
  sequence = {}
  for i=1,ticks do
    table.insert(sequence, {})
  end
  clearNoteTables()
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  if recordActive then
    incrementTakesCounter()
  end
  seqIndex = gem.inc(seqIndex)
  run(sequenceRunner, seqIndex)
end

local function stopPlaying()
  isPlaying = false
  setTableZero(positionTable)
  if recordOptions.text == "Punch Out" and lastTakeIsEmpty() == false then
    recordButton:setValue(false)
  end
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

local labelWidget = widgets.label("Simple Recording Sequencer", {
  tooltip = "Record and play back a sequence",
  alpha = 0.5,
  fontSize = 22,
  width = 240,
  editable = true,
})

widgets.col(1, 100)

recordButton = widgets.button("Record", recordActive, {
  tooltip = "When record is enabled, the count in will play before the sequencer starts. Use transport or the Play button to start recording.",
  width = 96,
  changed = function(self)
    recordActive = self.value
    if recordActive then
      recordActivatedDuringRun = isPlaying
      positionTable.sliderColour = "red"
    else
      recordActivatedDuringRun = false
      positionTable.sliderColour = "green"
      incrementTakesCounter()
      writeSequenceToNoteTables()
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
  height = 320,
})

widgets.setSection({
  x = 0,
  y = 5,
  width = 714,
  height = 10,
  cols = 1,
})

local noteMin = 36
local noteMax = noteMin + (12 * 4)
for i=noteMax,noteMin,-1 do
  local noteTable = widgets.table("Note", 0, ticks, {
    name = "Note_" .. i,
    max = 1,
    integer = true,
    persistent = false,
    enabled = false,
    sliderColour = "black",
    backgroundColour = "006633",
    height = 6,
  })
  table.insert(noteSequence, {
    note = i,
    events = {},
    table = noteTable
  })
end

positionTable = widgets.table("SequencePosition", 0, steps, {
  max = 1,
  integer = true,
  enabled = false,
  persistent = false,
  sliderColour = "green",
  backgroundColour = "cfffe",
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
  height = 20,
  width = 160,
  cols = 6,
})

widgets.numBox("Steps", steps, {
  tooltip = "Lowest note - notes below this are passed through",
  min = 4,
  max = maxSteps,
  integer = true,
  changed = function(self)
    steps = self.value
    ticks = steps / tickResolution
    positionTable.length = steps
    adjustSequenceTable()
  end
}):changed()

widgets.menu("Quantize", #quantizeResolutions, quantizeResolutions, {
  tooltip = "Set the quantize resolution",
  changed = function(self)
    local resolutionIndex = gem.getIndexFromValue(self.text, resolutionNames)
    if type(resolutionIndex) == "nil" then
      resolution = #resolutionNames
    else
      resolution = resolutionIndex
    end
    writeSequenceToNoteTables()
    --print("Quantize resolution", resolution)
  end
})

recordOptions = widgets.menu("Record Mode", 1, {
  "Punch Out",
  "Loop",
})

widgets.menu("Actions", 1, {
  "Select...",
  "Undo last take",
  "--- Danger Zone ---",
  "Clear sequence",
}, {
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
    table.insert(sequence[tickPos], {note = e.note, velocity = e.velocity, channel = e.channel, startPos = tickPos, take = takesCounter})
    drawNoteInTable(e.note, tickPos)
    --print("Set note, startPos, take, #events@pos", e.note, tickPos, takesCounter, #sequence[tickPos])
  end

  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(true)
  end
end

function onRelease(e)
  if isPlaying and recordActive then
    for tick,events in ipairs(sequence) do
      for i,tickEvent in ipairs(events) do
        if e.note == tickEvent.note and type(tickEvent.endPos) == "nil" then
          sequence[tick][i].endPos = tickCounter
          drawNoteTicks(tick, i)
          --print("Set note, endPos", e.note, sequence[tick][i].endPos)
        end
      end
    end
  end

  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(false)
  end
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
  writeSequenceToNoteTables()
end
