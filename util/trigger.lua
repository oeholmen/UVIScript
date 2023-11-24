--------------------------------------------------------------------------------
-- Trigger
--------------------------------------------------------------------------------
-- Push a button to trigger a note or start a pulse with retrigger active
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

local backgroundColour = "202020" -- Light or Dark
local autostart = false
local shouldTrigger = false
local isTransportActive = false
local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local triggerResolutions = resolutions.getResolutionNames({"Hold"})
local quantizeResolutions = resolutions.getResolutionNames()
local quantize = 17
local triggerDuration = #triggerResolutions
local retrigger = false
local triggerActive = false
local note = 60
local gate = 100
local voiceId
local triggerButton

setBackgroundColour(backgroundColour)

local function stopNote()
  if type(voiceId) == "userdata" then
    releaseVoice(voiceId)
    voiceId = nil
    print("Note stopped")
    if retrigger == false and triggerDuration < #triggerResolutions then
      triggerButton:setValue(false)
    end
  end
end

local function triggerNote()
  stopNote()
  local duration = 0
  if triggerDuration < #triggerResolutions then
    local beatValue = resolutions.getResolution(triggerDuration)
    duration = beat2ms(resolutions.getPlayDuration(beatValue, gate))
  elseif retrigger then
    local beatValue = resolutions.getResolution(quantize)
    duration = beat2ms(resolutions.getPlayDuration(beatValue, gate))
  end
  voiceId = playNote(note, 64, duration)
  print("Triggered note, duration", note, duration)
  shouldTrigger = retrigger
end

local function sequenceRunner(uniqueId)
  print("Starting sequenceRunner")
  while isPlaying and seqIndex == uniqueId do
    local waitResolutionIndex = quantize
    --print("triggerActive and shouldTrigger", triggerActive, shouldTrigger)
    if triggerActive and shouldTrigger then
      spawn(triggerNote)
      if triggerDuration < #triggerResolutions then
        waitResolutionIndex = triggerDuration
      end
    end
    waitBeat(resolutions.getResolution(waitResolutionIndex))
    if retrigger == false and shouldTrigger == false and triggerDuration < #triggerResolutions then
      --print("Stopping")
      triggerButton:setValue(false)
    end
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
  print("Stop playing")
  isPlaying = false
  triggerButton:setValue(false)
  stopNote()
end

widgets.panel({
  backgroundColour = backgroundColour,
  x = 10,
  y = 10,
  width = 700,
  height = 66,
})

widgets.setSection({
  x = 10,
  y = 8,
  xSpacing = 15,
})

local label = widgets.label("Single Trigger", {
  tooltip = "Trigger a note at the next quantization tick",
  alpha = 0.5,
  fontSize = 22,
  height = 30,
  editable = true
})

widgets.setSection({
  width = 75,
  x = 170,
})

widgets.menu("Quantize", quantize, quantizeResolutions, {
  tooltip = "Quantize trigger start",
  changed = function(self)
    quantize = self.value
  end
})

widgets.menu("Duration", triggerDuration, triggerResolutions, {
  tooltip = "Trigger duration",
  changed = function(self)
    triggerDuration = self.value
    shouldTrigger = retrigger
  end
})

widgets.button("Retrigger", retrigger, {
  tooltip = "Retrigger note every round (duration)",
  width = 120,
  changed = function(self)
    retrigger = self.value
    if triggerDuration == #triggerResolutions then
      shouldTrigger = true
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

triggerButton = widgets.button("Trigger", triggerActive, {
  tooltip = "Trigger the note at the next tick (can only trigger when sequencer is running)",
  width = 96,
  height = 45,
  changed = function(self)
    triggerActive = self.value
    shouldTrigger = self.value
    if triggerActive then
      startPlaying()
      print("Trigger active: Waiting to trigger note")
    else
      print("Trigger inactive: Stopping note")
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
  tooltip = "Lowest note - notes below this are passed through",
  unit = Unit.MidiKey,
  width = 96,
  changed = function(self)
    note = self.value
    shouldTrigger = true
  end
})

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
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
