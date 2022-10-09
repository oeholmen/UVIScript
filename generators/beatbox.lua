-------------------------------------------------------------------------------
-- Random note generator
-------------------------------------------------------------------------------

require "../includes/generative"
require "../includes/rythmicFragments"

local voices = 8
local beatCounter = 1
local isPlaying = false
local playingVoices = {}

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "F637EC"
local menuBackgroundColour = "01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"

local colours = {
  backgroundColour = backgroundColour,
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = labelTextColour,
  menuBackgroundColour = menuBackgroundColour,
  menuArrowColour = menuArrowColour,
  menuOutlineColour = menuOutlineColour,
  backgroundColourOff = backgroundColourOff,
  backgroundColourOn = backgroundColourOn,
  textColourOff = textColourOff,
  textColourOn = textColourOn,
}

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

local sequencerPanel = Panel("RandomNoteGenerator")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 36

local settingsPanel = Panel("Settings")
settingsPanel.backgroundColour = backgroundColour
settingsPanel.x = sequencerPanel.x
settingsPanel.y = sequencerPanel.y + sequencerPanel.height + 5
settingsPanel.width = 700
settingsPanel.height = 30

local notePanel = Panel("Notes")
notePanel.backgroundColour = "202020"
notePanel.x = settingsPanel.x
notePanel.y = settingsPanel.y + settingsPanel.height + 5
notePanel.width = 700
notePanel.height = 110

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "505050"
rythmPanel.x = notePanel.x
rythmPanel.y = notePanel.y + notePanel.height + 5
rythmPanel.width = 700
rythmPanel.height = voices * 51

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("SequencerLabel")
sequencerLabel.text = "Beatbox"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.width = 220

local channelButton = sequencerPanel:OnOffButton("ChannelButton", false)
channelButton.backgroundColourOff = backgroundColourOff
channelButton.backgroundColourOn = backgroundColourOn
channelButton.textColourOff = textColourOff
channelButton.textColourOn = textColourOn
channelButton.displayName = "Multichannel"
channelButton.tooltip = "When multichannel mode is enabled, each voice is sent to a separate channel"
channelButton.size = {100,22}
channelButton.x = sequencerPanel.width - (channelButton.width * 3) - 10
channelButton.y = 5

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = backgroundColourOff
autoplayButton.backgroundColourOn = backgroundColourOn
autoplayButton.textColourOff = textColourOff
autoplayButton.textColourOn = textColourOn
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = channelButton.size
autoplayButton.x = channelButton.x + channelButton.width + 5
autoplayButton.y = channelButton.y

local playButton = sequencerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = backgroundColourOff
playButton.backgroundColourOn = backgroundColourOn
playButton.textColourOff = textColourOff
playButton.textColourOn = textColourOn
playButton.displayName = "Play"
playButton.size = autoplayButton.size
playButton.x = autoplayButton.x + autoplayButton.width + 5
playButton.y = channelButton.y
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

local widgetWidth = 659 / 4

local velocityInput = settingsPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Note velocity"
velocityInput.width = widgetWidth
velocityInput.x = 5
velocityInput.y = 0

local velocityAccent = settingsPanel:NumBox("VelocityAccent", 64, 1, 127, true)
velocityAccent.textColour = widgetTextColour
velocityAccent.backgroundColour = widgetBackgroundColour
velocityAccent.displayName = "Accent"
velocityAccent.tooltip = "Velocity accent amount triggered on the start of a fragment"
velocityAccent.width = widgetWidth
velocityAccent.x = velocityInput.x + velocityInput.width + 10
velocityAccent.y = velocityInput.y

local useNoteProbabilityAlways = settingsPanel:OnOffButton("UseNoteProbabilityAlways", true)
useNoteProbabilityAlways.displayName = "Use Always"
useNoteProbabilityAlways.tooltip = "When this is activated, note probability is used for both sequence runner and individual notes"
useNoteProbabilityAlways.backgroundColourOff = backgroundColourOff
useNoteProbabilityAlways.backgroundColourOn = backgroundColourOn
useNoteProbabilityAlways.textColourOff = textColourOff
useNoteProbabilityAlways.textColourOn = textColourOn
useNoteProbabilityAlways.width = velocityAccent.width
useNoteProbabilityAlways.x = velocityAccent.x + velocityAccent.width + 10
useNoteProbabilityAlways.y = velocityAccent.y

local accentFragmentStart = settingsPanel:OnOffButton("AccentFragmentStart", true)
accentFragmentStart.displayName = "Accent Start"
accentFragmentStart.tooltip = "When this is activated fragment start is accented"
accentFragmentStart.backgroundColourOff = backgroundColourOff
accentFragmentStart.backgroundColourOn = backgroundColourOn
accentFragmentStart.textColourOff = textColourOff
accentFragmentStart.textColourOn = textColourOn
accentFragmentStart.width = useNoteProbabilityAlways.width
accentFragmentStart.x = useNoteProbabilityAlways.x + useNoteProbabilityAlways.width + 10
accentFragmentStart.y = useNoteProbabilityAlways.y

-- TODO Param for accent per ...?

--------------------------------------------------------------------------------
-- Drum Panel
--------------------------------------------------------------------------------

local noteLabel = notePanel:Label("NotesLabel")
noteLabel.text = "Drums"
noteLabel.tooltip = "Select drums"
noteLabel.alpha = 0.75
noteLabel.fontSize = 15
noteLabel.width = 50
noteLabel.x = 0
noteLabel.y = 0

local paramsPerNote = {}
for i=1,voices do
  local types = {"Kick", "Snare", "Hihat", "Clap", "Toms", "Cymbal", "Tambourine", "Perc"}
  local typeLabel = notePanel:Label("Label" .. i)
  typeLabel.tooltip = "Part Label"
  typeLabel.editable = true
  typeLabel.text = types[i]
  typeLabel.backgroundColour = menuBackgroundColour
  typeLabel.backgroundColourWhenEditing = "#cccccc"
  typeLabel.width = 639 / 8
  typeLabel.height = 22
  typeLabel.x = ((typeLabel.width + 6) * (i - 1)) + 10
  typeLabel.y = noteLabel.height + 5

  local triggerNote = notePanel:NumBox("TriggerNote" .. i, 36, 0, 127, true)
  if i == 2 then
    triggerNote.value = 38
  elseif i == 3 then
    triggerNote.value = 42
  elseif i == 4 then
    triggerNote.value = 39
  elseif i == 5 then
    triggerNote.value = 41
  elseif i == 6 then
    triggerNote.value = 49
  elseif i == 7 then
    triggerNote.value = 54
  elseif i == 8 then
    triggerNote.value = 66
  end
  triggerNote.displayName = "Note"
  triggerNote.tooltip = "The note to trigger"
  triggerNote.unit = Unit.MidiKey
  triggerNote.showLabel = false
  triggerNote.backgroundColour = menuBackgroundColour
  triggerNote.textColour = menuTextColour
  triggerNote.height = 22
  triggerNote.width = 30
  triggerNote.x = typeLabel.x
  triggerNote.y = typeLabel.y + typeLabel.height

  local noteProbability = notePanel:NumBox("NoteProbability" .. i, 100, 0, 100, true)
  noteProbability.tooltip = "Probability of include"
  noteProbability.unit = Unit.Percent
  noteProbability.showLabel = false
  noteProbability.backgroundColour = menuBackgroundColour
  noteProbability.textColour = menuTextColour
  noteProbability.height = 22
  noteProbability.width = typeLabel.width - triggerNote.width
  noteProbability.x = triggerNote.x + triggerNote.width
  noteProbability.y = triggerNote.y

  local accent = notePanel:NumBox("NoteAccent" .. i, 0, 0, 16, true)
  accent.displayName = "Accent"
  accent.tooltip = "Accent every n-th trigger"
  accent.showLabel = true
  accent.backgroundColour = menuBackgroundColour
  accent.textColour = menuTextColour
  accent.height = 22
  accent.width = triggerNote.width + noteProbability.width
  accent.x = typeLabel.x
  accent.y = triggerNote.y + triggerNote.height

  table.insert(paramsPerNote, {typeLabel=typeLabel, triggerNote=triggerNote, noteProbability=noteProbability, accent=accent})
end

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythm"
rythmLabel.alpha = 0.75
rythmLabel.fontSize = 15
rythmLabel.width = 50

local paramsPerFragment = getParamsPerFragment(rythmPanel, rythmLabel, colours, voices)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function getNote(voice)
  local noteProbability = paramsPerNote[voice].noteProbability.value
  if useNoteProbabilityAlways.value == false or getRandomBoolean(noteProbability) then
    return paramsPerNote[voice].triggerNote.value
  end
end

function startPlaying()
  if isPlaying then
    return
  end
  run(sequenceRunner)
end

function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  playingVoices = {}
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive.textColourOn = "black"
  end
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function sequenceRunner()
  isPlaying = true
  playingVoices = {}
  for voice=1,voices do
    table.insert(playingVoices, false) -- Init voices
  end
  beatCounter = 1 -- Reset when starting sequencer
  while isPlaying do
    print("*** BEAT sequenceRunner ***", beatCounter)
    -- Check playing voices
    for voice=1,voices do
      if playingVoices[voice] == false then
        --print("Voice is NOT playing", voice)
        playingVoices[voice] = getRandomBoolean(paramsPerNote[voice].noteProbability.value)
        if playingVoices[voice] then
          print("Play voice", voice)
          spawn(play, voice)
        end
      end
    end

    waitBeat(1) -- Base resolution
    beatCounter = beatCounter + 1
  end
end

function play(voice)
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatCount = 0
  local fragmentRepeatProbability = 0
  local duration = nil
  local rest = false
  local reverseFragment = false
  local round = 0
  while playingVoices[voice] do
    round = round + 1
    local accentEvery = paramsPerNote[voice].accent.value
    print("*** BEAT VOICE ROUND, ACCENT ***", beatCounter, voice, round, accentEvery)
    local channel = nil
    if channelButton.value then
      channel = voice
    end
    local isFirstRound = type(activeFragment) == "nil"
    local note = getNote(voice)
    duration, isFragmentStart, isRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
    if isFirstRound == false and isFragmentStart == true and isRepeat == false then
      -- Start of a new fragment - break the loop and remove from playing voices
      print("Breaking loop for voice", voice)
      playingVoices[voice] = false
      break
    end
    local doPlayNote = rest == false and type(note) == "number"
    if doPlayNote then
      local velocity = velocityInput.value
      if (accentEvery > 0 and round % accentEvery == 0) or (accentFragmentStart.value and isFragmentStart and #activeFragment.f > 1) then
        print("accentEvery, round", accentEvery, round)
        velocity = velocityAccent.value
      end
      playNote(note, velocity, beat2ms(getPlayDuration(duration)), nil, channel)
    end
    waitBeat(duration)
  end
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local fragmentInputData = {}
  local noteLabelData = {}

  for _,v in ipairs(paramsPerNote) do
    table.insert(noteLabelData, v.typeLabel.text)
  end

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  return {fragmentInputData, noteLabelData}
end

function onLoad(data)
  local fragmentInputData = data[1]
  local noteLabelData = data[2]

  for i,v in ipairs(noteLabelData) do
    paramsPerNote[i].typeLabel.text = v
  end

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end
end
