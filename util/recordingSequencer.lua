--------------------------------------------------------------------------------
-- Recording Sequencer - A sequencer with recording
--------------------------------------------------------------------------------

local gem = require "includes.common"
local resolutions = require "includes.resolutions"
local widgets = require "includes.widgets"

local resolutionNames = resolutions.getResolutionNames()
local resolution = #resolutionNames
local isPlaying = false
local recordActive = true
local positionTable
local countIn = 4
local baseSequenceResolution = 1 -- 1/4 TODO Metronome/tick?
local seqIndex = 0 -- Holds the unique id for the base sequencer
local tickResolution = resolutions.getPlayDuration()
local steps = 16
local ticks = steps / tickResolution
local tickCounter = 0 -- Holds the current sequence tick (position)
local sequence = {} -- Holds the recorded sequence
local backgroundColour = "202020" -- Light or Dark

widgets.setColours({
  backgroundColour = backgroundColour,
  widgetBackgroundColour = "black",
  widgetTextColour = "3EC1D3",
  labelTextColour = "black",
  labelBackgoundColour = "black",
  menuBackgroundColour = "01011F",
  menuArrowColour = "66" .. "black",
  menuOutlineColour = "5f" .. "3EC1D3",
  backgroundColourOff = "red",
})

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function setTableZero(theTable)
  for i=1,theTable.length do
    theTable:setValue(i, 0)
  end
end

local function playTick(quantizeTo, ticksInResolution)
  local ticksInQuantization = math.floor(ticksInResolution / 2)
  local startPos = math.max(-ticksInQuantization, (tickCounter - ticksInQuantization))
  local endPos = math.max(startPos, math.min(ticks, (tickCounter + ticksInQuantization - 1)))
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
  --print("tickCounter", tickCounter)
  while isPlaying and seqIndex == uniqueId do
    tickCounter = gem.inc(tickCounter, 1, ticks)
    internalTickCounter = gem.inc(internalTickCounter, 1, ticks)
    if (internalTickCounter - 1) % 32 == 0 then
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

      local quantizeTo = resolutions.getResolution(resolution)
      --[[ if recordActive then
        quantizeTo = tickResolution
      end ]]
      local ticksInResolution = quantizeTo / tickResolution
      local ticksDurationForResolution = tickResolution * ticksInResolution

      if (internalTickCounter - 1) % ticksInResolution == 0 and quantizeTo == ticksDurationForResolution then
        playTick(quantizeTo, ticksInResolution)
      end
    end

    waitBeat(tickResolution)
  end
end

local function initSequenceTable()
  print("Delete recording")
  sequence = {}
  ticks = steps / tickResolution
  for i=1,ticks do
    table.insert(sequence, {})
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
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
  backgroundColour = backgroundColour,
  x = 10,
  y = 10,
  width = 700,
  height = 40,
})

widgets.setSection({
  x = 10,
  y = 10,
  xSpacing = 15,
})

widgets.label("Recording Sequencer", {
  tooltip = "Record and play back a sequence",
  alpha = 0.5,
  fontSize = 22,
  width = 180,
})

widgets.panel({
  backgroundColour = backgroundColour,
  x = widgets.getPanel().x,
  y = widgets.posUnder(widgets.getPanel()),
  width = widgets.getPanel().width,
  height = 30,
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
  width = 680,
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
  xSpacing = 15,
})

widgets.menu("Quantize", resolution, resolutionNames, {
  tooltip = "Set the quantize resolution",
  showLabel = false,
  changed = function(self)
    resolution = self.value
  end
})

widgets.numBox("Steps", steps, {
  tooltip = "Lowest note - notes below this are passed through",
  min = 4,
  max = 64,
  integer = true,
  changed = function(self)
    steps = self.value
    positionTable.length = steps
    initSequenceTable()
  end
}):changed()

widgets.numBox("Count In", countIn, {
  tooltip = "Set a count in",
  min = 0,
  max = 4,
  integer = true,
  changed = function(self)
    countIn = self.value
  end
})

widgets.button("Record", recordActive, {
  tooltip = "Record enable",
  backgroundColourOn = "red",
  textColourOn = "white",
  backgroundColourOff = "gray",
  changed = function(self)
    recordActive = self.value
    if recordActive then
      positionTable.sliderColour = "red"
    else
      positionTable.sliderColour = "green"
      for i,s in ipairs(sequence) do
        for j,w in ipairs(s) do
          if type(w.endPos) == "nil" then
            sequence[i][j].endPos = tickCounter
            print("Set note, endPos", sequence[i][j].note, sequence[i][j].endPos)
          end
        end
      end
    end
  end
})

widgets.button("Clear", {
  changed = function(self)
    initSequenceTable()
  end
})

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
end

function onTransport(start)
  if start then
    startPlaying()
  else
    stopPlaying()
  end
end

function onNote(e)
  if isPlaying and recordActive then
    local tickPos = tickCounter
    if tickPos < 1 then
      tickPos = tickPos + ticks
    end
    table.insert(sequence[tickPos], {note = e.note, velocity = e.velocity, startPos = tickPos})
    print("Set note, startPos", e.note, tickPos)
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
-- Handle load/save
--------------------------------------------------------------------------------
