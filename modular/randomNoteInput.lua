-----------------------------------------------------------------------------------------------------------------
-- Random Notes - Replaces note 0 in incoming note events with a random note from the selected key and scale
-----------------------------------------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local noteSelector = require "includes.noteSelector"

local activeVoices = {}

local sequencerPanel = widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Random Note Input", {
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

widgets.setSection({
  width = 90,
  xOffset = sequencerPanel.width - 95,
  yOffset = 5
})

local channelInput = widgets.menu("Channel", 1, channels, {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
})

--------------------------------------------------------------------------------
-- Notes
--------------------------------------------------------------------------------

local notePanel = widgets.panel({
  x = sequencerPanel.x,
  y = widgets.posUnder(sequencerPanel),
  width = sequencerPanel.width,
  height = 200,
})

widgets.setSection({
  xOffset = 0,
  yOffset = 0,
})

local noteLabel = widgets.label("Notes", {
  tooltip = "Set the probability that notes will be included when generating new notes",
  alpha = 0.75,
  width = sequencerPanel.width,
  height = 22,
})

local inputButton = widgets.button(" ", false, {
  tooltip = "Shows when notes are triggered",
  persistent = false,
  enabled = false,
  width = channelInput.width,
  height = 18,
  y = 2,
  x = channelInput.x,
})
inputButton.backgroundColourOff = "202020"
 
noteSelector.createNoteAndOctaveSelector(notePanel, widgets.colours(), noteLabel, 15, 42, {x = 15, y = widgets.posUnder(noteLabel) + 10})

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function flashInput()
  inputButton.backgroundColourOff = "606060"
  waitBeat(.125)
  inputButton.backgroundColourOff = "202020"
end

local function getNote()
  return gem.getRandomFromTable(noteSelector.getSelectedNotes())
end

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
    local id = postEvent(e)
    table.insert(activeVoices, {id=id,event=e})
    spawn(flashInput)
  end
end

local function handleReleaseTrigger(e)
  for i,v in ipairs(activeVoices) do
    if v.event.channel == e.channel then
      releaseVoice(v.id)
      table.remove(activeVoices, i)
    end
  end
end

local function releaseVoices()
  for i,v in ipairs(activeVoices) do
    releaseVoice(v.id)
    print("Release active voice on channel", v.event.channel)
  end
  activeVoices = {}
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
  if start == false then
    releaseVoices()
  end
end
