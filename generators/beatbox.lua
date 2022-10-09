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
notePanel.height = 150

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "505050"
rythmPanel.x = notePanel.x
rythmPanel.y = notePanel.y + notePanel.height + 5
rythmPanel.width = 700
rythmPanel.height = 410

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("SequencerLabel")
sequencerLabel.text = "Beatbox"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.width = 80

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

local widgetWidth = 659 / 3

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

local accentFragmentStart = settingsPanel:OnOffButton("AccentFragmentStart", true)
accentFragmentStart.displayName = "Accent Start"
accentFragmentStart.tooltip = "When this is activated fragment start is accented"
accentFragmentStart.backgroundColourOff = backgroundColourOff
accentFragmentStart.backgroundColourOn = backgroundColourOn
accentFragmentStart.textColourOff = textColourOff
accentFragmentStart.textColourOn = textColourOn
accentFragmentStart.width = velocityAccent.width
accentFragmentStart.x = velocityAccent.x + velocityAccent.width + 10
accentFragmentStart.y = velocityAccent.y

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
  triggerNote.width = 39
  triggerNote.x = typeLabel.x
  triggerNote.y = typeLabel.y + typeLabel.height

  local noteProbability = notePanel:NumBox("NoteProbability" .. i, 100, 0, 100, true)
  noteProbability.tooltip = "Probability that note will be played"
  noteProbability.unit = Unit.Percent
  noteProbability.showLabel = false
  noteProbability.backgroundColour = menuBackgroundColour
  noteProbability.textColour = menuTextColour
  noteProbability.height = triggerNote.height
  noteProbability.width = 40
  noteProbability.x = triggerNote.x + triggerNote.width
  noteProbability.y = triggerNote.y

  local accentLabel = notePanel:Label("AccentLabel" .. i)
  accentLabel.text = "Accent"
  accentLabel.tooltip = "Accent every n-th trigger"
  accentLabel.textColour = "white"
  accentLabel.alpha = 0.5
  accentLabel.fontSize = 12
  accentLabel.height = noteProbability.height
  accentLabel.width = triggerNote.width
  accentLabel.x = triggerNote.x
  accentLabel.y = triggerNote.y + triggerNote.height

  local accent = notePanel:NumBox("NoteAccent" .. i, 0, 0, 16, true)
  accent.showLabel = false
  accent.tooltip = accentLabel.tooltip
  accent.backgroundColour = menuBackgroundColour
  accent.textColour = menuTextColour
  accent.height = triggerNote.height
  accent.width = noteProbability.width
  accent.x = noteProbability.x
  accent.y = accentLabel.y

  local downBeatProbabilityLabel = notePanel:Label("DownBeatProbabilityLabel" .. i)
  downBeatProbabilityLabel.text = "DwnBt"
  downBeatProbabilityLabel.tooltip = "Probability of being played in the downbeat"
  downBeatProbabilityLabel.textColour = "white"
  downBeatProbabilityLabel.alpha = 0.5
  downBeatProbabilityLabel.fontSize = 12
  downBeatProbabilityLabel.height = accent.height
  downBeatProbabilityLabel.width = triggerNote.width
  downBeatProbabilityLabel.x = accentLabel.x
  downBeatProbabilityLabel.y = accentLabel.y + accentLabel.height

  local downBeatProbability = notePanel:NumBox("DownBeatProbability" .. i, 100, 0, 100, true)
  downBeatProbability.unit = Unit.Percent
  downBeatProbability.showLabel = false
  downBeatProbability.tooltip = downBeatProbabilityLabel.tooltip
  downBeatProbability.backgroundColour = menuBackgroundColour
  downBeatProbability.textColour = menuTextColour
  downBeatProbability.height = downBeatProbabilityLabel.height
  downBeatProbability.width = noteProbability.width
  downBeatProbability.x = noteProbability.x
  downBeatProbability.y = downBeatProbabilityLabel.y

  local upBeatProbabilityLabel = notePanel:Label("UpBeatProbabilityLabel" .. i)
  upBeatProbabilityLabel.text = "UpBeat"
  upBeatProbabilityLabel.tooltip = "Probability of being played in the upbeat"
  upBeatProbabilityLabel.textColour = "white"
  upBeatProbabilityLabel.alpha = 0.5
  upBeatProbabilityLabel.fontSize = 12
  upBeatProbabilityLabel.height = downBeatProbability.height
  upBeatProbabilityLabel.width = triggerNote.width
  upBeatProbabilityLabel.x = downBeatProbabilityLabel.x
  upBeatProbabilityLabel.y = downBeatProbabilityLabel.y + downBeatProbabilityLabel.height

  local upBeatProbability = notePanel:NumBox("UpBeatProbability" .. i, 100, 0, 100, true)
  upBeatProbability.unit = Unit.Percent
  upBeatProbability.showLabel = false
  upBeatProbability.tooltip = "Probability of being played in the downbeat"
  upBeatProbability.backgroundColour = menuBackgroundColour
  upBeatProbability.textColour = menuTextColour
  upBeatProbability.height = upBeatProbabilityLabel.height
  upBeatProbability.width = downBeatProbability.width
  upBeatProbability.x = downBeatProbability.x
  upBeatProbability.y = downBeatProbability.y + downBeatProbability.height

  table.insert(paramsPerNote, {typeLabel=typeLabel, triggerNote=triggerNote, noteProbability=noteProbability, accent=accent, downBeatProbability=downBeatProbability, upBeatProbability=upBeatProbability})
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

local selectNone = rythmPanel:Button("SelectNone")
selectNone.displayName = "Select none"
selectNone.tooltip = "Deselect all fragments"
selectNone.persistent = false
selectNone.height = noteLabel.height
selectNone.width = 120
selectNone.x = rythmPanel.width - (selectNone.width * 3) - 30
selectNone.y = 5
selectNone.changed = function()
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive:setValue(false)
  end
end

local selectAll = rythmPanel:Button("SelectAll")
selectAll.displayName = "Select all"
selectAll.tooltip = "Select all fragments"
selectAll.persistent = false
selectAll.height = noteLabel.height
selectAll.width = selectNone.width
selectAll.x = selectNone.x + selectNone.width + 10
selectAll.y = 5
selectAll.changed = function()
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive:setValue(string.len(v.fragmentInput.text) > 0)
  end
end

local randomizeSelection = rythmPanel:Button("RandomizeSelection")
randomizeSelection.displayName = "Randomize selection"
randomizeSelection.tooltip = "Randomize fragment selection"
randomizeSelection.persistent = false
randomizeSelection.height = noteLabel.height
randomizeSelection.width = selectNone.width
randomizeSelection.x = selectAll.x + selectAll.width + 10
randomizeSelection.y = 5
randomizeSelection.changed = function()
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive:setValue(string.len(v.fragmentInput.text) > 0 and getRandomBoolean())
  end
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function getNote(voice)
  local noteProbability = paramsPerNote[voice].noteProbability.value
  if getRandomBoolean(noteProbability) then
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

function isDownBeat()
  local beatBase = 2
  return beatCounter % beatBase > 0
end

function isUpBeat()
  return isDownBeat() == false
end

function sequenceRunner()
  local beat = 1 -- Base beat resolution
  isPlaying = true
  playingVoices = {}
  for voice=1,voices do
    table.insert(playingVoices, false) -- Init voices
  end
  beatCounter = 1 -- Reset when starting sequencer
  while isPlaying do
    print("*** BEAT isDownBeat ***", beatCounter, isDownBeat)
    -- Check playing voices
    for voice=1,voices do
      if playingVoices[voice] == false then
        local playOnDownBeat = getRandomBoolean(paramsPerNote[voice].downBeatProbability.value)
        local playOnUpBeat = getRandomBoolean(paramsPerNote[voice].upBeatProbability.value)
        playingVoices[voice] = (isDownBeat() and playOnDownBeat) or (isUpBeat() and playOnUpBeat)
        if playingVoices[voice] then
          print("Play voice", voice)
          spawn(play, voice, playOnDownBeat, playOnUpBeat)
        end
      end
    end
    waitBeat(beat)
    beatCounter = beatCounter + beat
  end
end

function play(voice, playOnDownBeat, playOnUpBeat)
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatCount = 0
  local fragmentRepeatProbability = 0
  local duration = nil
  local rest = false
  local reverseFragment = false
  local round = 0
  while playingVoices[voice] do
    -- TODO Add param to set probability of starting with a rest
    round = round + 1
    local accentEvery = paramsPerNote[voice].accent.value
    print("*** BEAT VOICE ROUND, isDownBeat ***", beatCounter, voice, round, isDownBeat())
    local channel = nil
    if channelButton.value then
      channel = voice
    end
    local note = getNote(voice)
    duration, isFragmentStart, isRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
    if type(duration) == "nil" or (round > 1 and isFragmentStart == true and isRepeat == false) or (isDownBeat() and playOnDownBeat == false) or (isUpBeat() and playOnUpBeat == false) then
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
