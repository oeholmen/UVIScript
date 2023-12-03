--------------------------------------------------------------------------------
-- Quantized Trigger
--------------------------------------------------------------------------------
-- Push a button to trigger a note or start a pulse (when retrigger is active)
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

local autostart = false
local triggerOnNote = false
local triggerActive = false
local shouldTrigger = false
local isTransportActive = false
local isPlaying = false
local restartQuantizeSequencer = false
local baseSequenceResolution = 1 -- 1/4
local baseSeqIndex = 0 -- Holds the unique id for the base sequencer
local quantizeSeqIndex = 0 -- Holds the unique id for the quantize sequence runnder
local triggerSeqIndex = 0 -- Holds the unique id for the trigger sequencer
local triggerResolutions = resolutions.getResolutionNames({"Hold"})
local quantizeResolutions = resolutions.getResolutionNames()
local quantize = 17
local triggerDuration = #triggerResolutions
local retrigger = false
local note = 60
local gate = 100
local voiceId
local triggerButton
local positionTableQuantize
local positionTableDuration

local backgroundColour = "202020" -- Light or Dark
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function setTableZero(theTable)
  for i=1,theTable.length do
    theTable:setValue(i, 0)
  end
end

local function stopNote()
  if type(voiceId) == "userdata" then
    releaseVoice(voiceId)
    voiceId = nil
    if retrigger == false and triggerDuration < #triggerResolutions then
      triggerButton:setValue(false)
    end
  end
end

local function triggerNote()
  stopNote()
  local duration = 0
  local beatValue = 0
  if triggerDuration < #triggerResolutions then
    beatValue = resolutions.getResolution(triggerDuration)
  elseif retrigger then
    beatValue = resolutions.getResolution(quantize)
  end
  if beatValue > 0 then
    duration = beat2ms(resolutions.getPlayDuration(beatValue, gate))
  end
  voiceId = playNote(note, 64, duration)
  --print("Triggered note, duration", note, duration)
  shouldTrigger = retrigger and triggerActive
end

local function stopNoteAfter()
  waitBeat(resolutions.getResolution(triggerDuration))
  stopNote()
end

local function triggerSequenceRunner(uniqueId)
  print("Starting triggerSequenceRunner", uniqueId)
  local index = 1
  while isPlaying and triggerSeqIndex == uniqueId do
    if shouldTrigger then
      spawn(triggerNote)
    end

    setTableZero(positionTableDuration)
    positionTableDuration:setValue(index, 1)
    index = gem.inc(index, 1, positionTableDuration.length)

    waitBeat(resolutions.getResolution(triggerDuration))
    if retrigger == false and shouldTrigger == false then
      print("Stopping triggerSequenceRunner")
      triggerButton:setValue(false)
    else
      --print("triggerSequenceRunner round")
    end
  end
end

local function sequenceRunner(uniqueId)
  print("Starting sequenceRunner", uniqueId)
  local currentTriggerSeqIndex = -1
  local index = 1
  while isPlaying and quantizeSeqIndex == uniqueId do
    setTableZero(positionTableQuantize)
    positionTableQuantize:setValue(index, 1)
    index = gem.inc(index, 1, positionTableQuantize.length)
  
    if triggerDuration < #triggerResolutions then
      if shouldTrigger and currentTriggerSeqIndex < triggerSeqIndex then
        currentTriggerSeqIndex = triggerSeqIndex
        spawn(triggerSequenceRunner, triggerSeqIndex)
      end
    elseif shouldTrigger then
      spawn(triggerNote)
    end
    waitBeat(resolutions.getResolution(quantize))
  end
end

local function baseRunner(uniqueId)
  local currentSeqIndex = -1
  while isPlaying and baseSeqIndex == uniqueId do
    if currentSeqIndex < quantizeSeqIndex then
      currentSeqIndex = quantizeSeqIndex
      spawn(sequenceRunner, quantizeSeqIndex)
    end
    waitBeat(baseSequenceResolution)
    if restartQuantizeSequencer then
      print("Quantize seq restart")
      quantizeSeqIndex = gem.inc(quantizeSeqIndex)
      restartQuantizeSequencer = false
    end
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  baseSeqIndex = gem.inc(baseSeqIndex)
  run(baseRunner, baseSeqIndex)
end

local function stopPlaying()
  print("Stop playing")
  isPlaying = false
  triggerButton:setValue(false)
  stopNote()
  setTableZero(positionTableQuantize)
  setTableZero(positionTableDuration)
end

--------------------------------------------------------------------------------
-- Widgets
--------------------------------------------------------------------------------

widgets.panel({
  backgroundColour = backgroundColour,
  x = 10,
  y = 10,
  width = 700,
  height = 66,
})

widgets.setSection({
  x = 0,
  y = 12,
  xSpacing = 15,
})

local label = widgets.label("Quantized Trigger", {
  tooltip = "Trigger a note at the next quantization tick",
  alpha = 0.75,
  width = 160,
  fontSize = 22,
  backgroundColour = backgroundColour,
  textColourWhenEditing = "silver",
  textColour = "orange",
  height = 30,
  editable = true
})

widgets.setSection({
  width = 75,
  y = 6,
  x = 170,
})

widgets.menu("Quantize", quantize, quantizeResolutions, {
  tooltip = "Quantize trigger start",
  changed = function(self)
    quantize = self.value
    restartQuantizeSequencer = true
  end
})

widgets.menu("Duration", triggerDuration, triggerResolutions, {
  tooltip = "Trigger duration",
  changed = function(self)
    triggerDuration = self.value
    shouldTrigger = retrigger and triggerActive
    if triggerDuration < #triggerResolutions and isPlaying then
      spawn(stopNoteAfter)
    end
    triggerSeqIndex = gem.inc(triggerSeqIndex)
    print("Trigger seq restart")
  end
})

widgets.button("Retrigger", retrigger, {
  tooltip = "Retrigger note every round",
  width = 120,
  changed = function(self)
    retrigger = self.value
    if triggerDuration == #triggerResolutions then
      shouldTrigger = triggerActive
    elseif retrigger == false then
      triggerButton:setValue(false)
    end
  end
})

widgets.button("Auto Play", autostart, {
  tooltip = "Start automatically on transport",
  width = 96,
  changed = function(self)
    autostart = self.value
  end
})

triggerButton = widgets.button("Play", triggerActive, {
  tooltip = "Trigger the selected note at the next quantization tick",
  width = 96,
  changed = function(self)
    triggerActive = self.value
    shouldTrigger = self.value
    if shouldTrigger then
      startPlaying()
      print("Trigger active: Waiting to trigger note")
    else
      print("Trigger stopped")
      if triggerDuration < #triggerResolutions then
        triggerSeqIndex = gem.inc(triggerSeqIndex)
        print("Trigger seq stopped")
      end
      if isTransportActive then
        stopNote()
      else
        stopPlaying()
      end
    end
  end
})

widgets.setSection({
  width = 75,
  y = 13,
  x = 170,
})

widgets.row()
widgets.col(2)

widgets.numBox("Gate", gate, {
  tooltip = "Trigger duration gate",
  unit = Unit.Percent,
  width = 120,
  changed = function(self)
    gate = self.value
  end
})

widgets.numBox("Note", note, {
  tooltip = "The note to trigger",
  unit = Unit.MidiKey,
  width = 96,
  changed = function(self)
    note = self.value
    triggerButton:setValue(triggerOnNote)
    shouldTrigger = triggerActive
  end
})

widgets.button("Trigger on note", triggerOnNote, {
  tooltip = "Trigger automatically on note change",
  width = 96,
  changed = function(self)
    triggerOnNote = self.value
  end
})

widgets.row()

positionTableQuantize = widgets.table("PositionQuantize", 0, 2, {
  width = 75,
  max = 2,
  integer = true,
  enabled = false,
  persistent = false,
  sliderColour = "yellow",
  backgroundColour = "cfffe",
  height = 3,
})

positionTableDuration = widgets.table("PositionDuration", 0, 2, {
  width = 75,
  max = 2,
  integer = true,
  enabled = false,
  persistent = false,
  sliderColour = "yellow",
  backgroundColour = "cfffe",
  height = 3,
})

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function onInit()
  baseSeqIndex = 0
  quantizeSeqIndex = 0
  triggerSeqIndex = 0
end

function onTransport(start)
  isTransportActive = start
  if start then
    triggerButton:setValue(autostart)
    startPlaying()
  else
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  return {label.text}
end

function onLoad(data)
  label.text = data[1]
end
