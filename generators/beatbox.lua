-------------------------------------------------------------------------------
-- Random note generator
-------------------------------------------------------------------------------

require "../includes/generative"
require "../includes/rythmicFragments"

local noteListen = nil
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
notePanel.height = 100

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

local isInEditMode = false
local bounds = {}
local paramsPerNote = {}
for i=1,voices do
  local types = {"Kick", "Snare", "Hihat", "Clap", "Toms", "Cymbal", "Tambourine", "Perc"}
  local typeLabel = notePanel:Label("Label" .. i)
  typeLabel.tooltip = "Part Label"
  typeLabel.editable = true
  typeLabel.text = types[i]
  typeLabel.backgroundColour = menuBackgroundColour
  typeLabel.backgroundColourWhenEditing = "#cccccc"
  typeLabel.width = 80
  typeLabel.height = 22
  typeLabel.x = ((typeLabel.width + 6) * (i - 1)) + 8
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
  triggerNote.width = 40
  triggerNote.x = typeLabel.x
  triggerNote.y = typeLabel.y + typeLabel.height

  local noteProbabilityDefault = 100
  if i > 3 then
    noteProbabilityDefault = 50
  end
  local noteProbability = notePanel:NumBox("NoteProbability" .. i, noteProbabilityDefault, 0, 100, true)
  noteProbability.tooltip = "Probability that note will be played"
  noteProbability.unit = Unit.Percent
  noteProbability.showLabel = false
  noteProbability.backgroundColour = menuBackgroundColour
  noteProbability.textColour = menuTextColour
  noteProbability.height = triggerNote.height
  noteProbability.width = 40
  noteProbability.x = triggerNote.x + triggerNote.width
  noteProbability.y = triggerNote.y

  local listen = notePanel:OnOffButton("Listen" .. i)
  listen.displayName = "L"
  listen.tooltip = "Note learn"
  listen.textColourOff = "white"
  listen.backgroundColourOn = "green"
  listen.height = noteProbability.height
  listen.width = 25
  listen.x = triggerNote.x
  listen.y = triggerNote.y + triggerNote.height
  listen.changed = function(self)
    if self.value then
      noteListen = i
    else
      noteListen = nil
    end
  end

  local edit = notePanel:Button("Edit" .. i)
  edit.displayName = "E"
  edit.tooltip = "Edit note details"
  edit.height = noteProbability.height
  edit.width = listen.width
  edit.x = listen.x + listen.width + 4
  edit.y = listen.y
  edit.changed = function(self)
    if isInEditMode == false then
      for j,v in ipairs(paramsPerNote) do
        local isVisible = i == j
        if isVisible then
          --noteLabel.text = v.typeLabel.text
          -- Remember bounds
          bounds = {
            typeLabel=v.typeLabel.bounds,
            triggerNote=v.triggerNote.bounds,
            noteProbability=v.noteProbability.bounds,
            listen=v.listen.bounds,
            edit=v.edit.bounds,
            mute=v.mute.bounds
          }
          -- Set bounds for edit
          v.typeLabel.bounds = paramsPerNote[1].typeLabel.bounds
          v.triggerNote.bounds = paramsPerNote[1].triggerNote.bounds
          v.noteProbability.bounds = paramsPerNote[1].noteProbability.bounds
          v.listen.bounds = paramsPerNote[1].listen.bounds
          v.edit.bounds = paramsPerNote[1].edit.bounds
          v.mute.bounds = paramsPerNote[1].mute.bounds
        end
        for _,w in ipairs(v.sourceSelectors) do
          w.visible = isVisible
        end
        v.typeLabel.visible = isVisible
        v.triggerNote.visible = isVisible
        v.noteProbability.visible = isVisible
        v.accent.visible = isVisible
        v.downBeatProbability.visible = isVisible
        v.upBeatProbability.visible = isVisible
        v.sourceLabel.visible = isVisible
        v.listen.visible = isVisible
        v.edit.visible = isVisible
        v.edit.displayName = "X"
        v.mute.visible = isVisible
      end
    else
      for j,v in ipairs(paramsPerNote) do
        if i == j then
          v.typeLabel.bounds = bounds.typeLabel
          v.triggerNote.bounds = bounds.triggerNote
          v.noteProbability.bounds = bounds.noteProbability
          v.listen.bounds = bounds.listen
          v.edit.bounds = bounds.edit
          v.mute.bounds = bounds.mute
        end
        v.typeLabel.visible = true
        v.triggerNote.visible = true
        v.noteProbability.visible = true
        v.listen.visible = true
        v.mute.visible = true
        v.edit.visible = true
        v.edit.displayName = "E"
        v.accent.visible = false
        v.downBeatProbability.visible = false
        v.upBeatProbability.visible = false
        v.sourceLabel.visible = false
        for _,w in ipairs(v.sourceSelectors) do
          w.visible = false
        end
      end
    end
    --noteLabel.text = "Drums"
    isInEditMode = isInEditMode == false
  end

  local mute = notePanel:OnOffButton("Mute" .. i)
  mute.displayName = "M"
  mute.tooltip = "Mute note"
  mute.textColourOff = "white"
  mute.backgroundColourOn = "red"
  mute.height = noteProbability.height
  mute.width = edit.width
  mute.x = edit.x + edit.width + 4
  mute.y = edit.y

  local accent = notePanel:NumBox("NoteAccent" .. i, 0, 0, 16, true)
  accent.visible = false
  accent.displayName = "Accent"
  accent.tooltip = "Accent every n-th trigger"
  accent.backgroundColour = menuBackgroundColour
  accent.textColour = menuTextColour
  accent.height = triggerNote.height
  accent.width = 120
  accent.x = typeLabel.width + 20
  accent.y = noteLabel.height + 5

  local downBeatProbabilityDefault = 100
  if i == 2 then
    downBeatProbabilityDefault = 0
  end
  local downBeatProbability = notePanel:NumBox("DownBeatProbability" .. i, downBeatProbabilityDefault, 0, 100, true)
  downBeatProbability.unit = Unit.Percent
  downBeatProbability.visible = false
  downBeatProbability.displayName = "Downbeat"
  downBeatProbability.tooltip = "Probability of being played in the downbeat"
  downBeatProbability.backgroundColour = menuBackgroundColour
  downBeatProbability.textColour = menuTextColour
  downBeatProbability.height = accent.height
  downBeatProbability.width = accent.width
  downBeatProbability.x = accent.x
  downBeatProbability.y = accent.y + accent.height

  local upBeatProbabilityDefault = 100
  if i == 1 then
    upBeatProbabilityDefault = 0
  end
  local upBeatProbability = notePanel:NumBox("UpBeatProbability" .. i, upBeatProbabilityDefault, 0, 100, true)
  upBeatProbability.unit = Unit.Percent
  upBeatProbability.visible = false
  upBeatProbability.displayName = "Upbeat"
  upBeatProbability.tooltip = "Probability of being played in the upbeat"
  upBeatProbability.backgroundColour = menuBackgroundColour
  upBeatProbability.textColour = menuTextColour
  upBeatProbability.height = accent.height
  upBeatProbability.width = accent.width
  upBeatProbability.x = downBeatProbability.x
  upBeatProbability.y = downBeatProbability.y + downBeatProbability.height

  local sourceLabel = notePanel:Label("SourceInput" .. i)
  sourceLabel.visible = false
  sourceLabel.text = "Sources"
  sourceLabel.tooltip = "Select the fragments that are available for this part - NOTE: If all are 0, then all fragments can be selected."
  sourceLabel.height = accent.height
  sourceLabel.width = accent.width
  sourceLabel.x = upBeatProbability.x + upBeatProbability.width + 10
  sourceLabel.y = accent.y

  local sourceSelectors = {}
  local rowCounter = 1
  local columnCounter = 0
  for j=1, voices do
    local sourceSelector = notePanel:NumBox("SourceSelector" .. i .. "_" .. j, 0, 0, 100, true)
    sourceSelector.unit = Unit.Percent
    sourceSelector.visible = false
    sourceSelector.displayName = "Rythm " .. j
    sourceSelector.tooltip = "Probability of rythmic fragment " .. j .. " being used for this part"
    sourceSelector.backgroundColour = menuBackgroundColour
    sourceSelector.textColour = menuTextColour
    sourceSelector.size = {112,22}
    sourceSelector.x = sourceLabel.x + (columnCounter * (sourceSelector.width + 5))
    sourceSelector.y = sourceLabel.y + (sourceLabel.height * rowCounter)
    table.insert(sourceSelectors, sourceSelector)
    columnCounter = columnCounter + 1
    if j == voices / 2 then
      rowCounter = 2
      columnCounter = 0
    end
  end

  table.insert(paramsPerNote, {typeLabel=typeLabel, triggerNote=triggerNote, noteProbability=noteProbability, accent=accent, downBeatProbability=downBeatProbability, upBeatProbability=upBeatProbability, sourceLabel=sourceLabel, sourceSelectors=sourceSelectors, listen=listen, edit=edit, mute=mute})
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
selectNone.x = rythmPanel.width - (selectNone.width * 4) - 36
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
    v.fragmentActive:setValue(true)
  end
end

local invertSelection = rythmPanel:Button("InvertSelection")
invertSelection.displayName = "Invert selection"
invertSelection.tooltip = "Invert current selection"
invertSelection.persistent = false
invertSelection.height = noteLabel.height
invertSelection.width = selectAll.width
invertSelection.x = selectAll.x + selectAll.width + 10
invertSelection.y = 5
invertSelection.changed = function()
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive:setValue(v.fragmentActive.value == false and string.len(v.fragmentInput.text) > 0)
  end
end

local randomizeSelection = rythmPanel:Button("RandomizeSelection")
randomizeSelection.displayName = "Randomize selection"
randomizeSelection.tooltip = "Randomize fragment selection"
randomizeSelection.persistent = false
randomizeSelection.height = noteLabel.height
randomizeSelection.width = selectNone.width
randomizeSelection.x = invertSelection.x + invertSelection.width + 10
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

function getSources(voice)
  local sources = {}
  for i,v in ipairs(paramsPerNote[voice].sourceSelectors) do
    if getRandomBoolean(v.value) then
      table.insert(sources, i)
    end
  end
  return sources
end

function getChannel(voice)
  local channel = nil
  if channelButton.value then
    channel = voice
  end
  return channel
end

function isDownBeat()
  local beatBase = 2
  return beatCounter % beatBase > 0
end

function isUpBeat()
  return isDownBeat() == false
end

function getPlayOnUpBeat(voice)
  return getRandomBoolean(paramsPerNote[voice].upBeatProbability.value)
end

function getPlayOnDownBeat(voice)
  return getRandomBoolean(paramsPerNote[voice].downBeatProbability.value)
end

function isNoteActive(voice)
  return paramsPerNote[voice].noteProbability.value > 0 and paramsPerNote[voice].mute.value == false
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
    print("*** BEAT isDownBeat ***", beatCounter, isDownBeat())
    -- Check playing voices
    for voice=1,voices do
      if playingVoices[voice] == false then
        playingVoices[voice] = isNoteActive(voice) and ((isDownBeat() and getPlayOnDownBeat(voice)) or (isUpBeat() and getPlayOnUpBeat(voice)))
        if playingVoices[voice] then
          print("Play voice", voice)
          spawn(play, voice)
        end
      end
    end
    waitBeat(beat)
    beatCounter = beatCounter + beat
  end
end

function play(voice)
  local round = 0
  local playDuration = 0 -- Keep track of the played duration
  -- First
  local duration, isFragmentStart, isRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = getDuration(nil, 0, 0, false, 0, getSources(voice))
  -- Start loop
  while playingVoices[voice] do
    round = round + 1

    if type(duration) == "nil" or isNoteActive(voice) == false or (isDownBeat() and getPlayOnDownBeat(voice) == false) or (isUpBeat() and getPlayOnUpBeat(voice) == false) then
      -- Return voice to sequence runner
      print("BEFORE: Breaking loop for voice", voice)
      playingVoices[voice] = false
      break
    end

    local accentEvery = paramsPerNote[voice].accent.value
    local note = getNote(voice)
    local doPlayNote = rest == false and type(note) == "number"
    if doPlayNote then
      local velocity = velocityInput.value
      if (accentEvery > 0 and round % accentEvery == 0) or (accentFragmentStart.value and isFragmentStart and #activeFragment.f > 1) then
        print("accentEvery, round", accentEvery, round)
        velocity = velocityAccent.value
      end
      playNote(note, velocity, beat2ms(getPlayDuration(duration)), nil, getChannel())
    end

    -- Update total play duration
    playDuration = playDuration + duration
    
    -- Get next
    duration, isFragmentStart, isRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount, getSources(voice))

    -- Check if loop should be broken at the start of next round
    local remainingInBeat = math.ceil(playDuration) - playDuration
    --print("AFTER playDuration, remainingInBeat, isFragmentStart, isRepeat, voice", playDuration, remainingInBeat, isFragmentStart, isRepeat, "voice " .. voice)
    if remainingInBeat == 0 and round > 1 and isFragmentStart == true and isRepeat == false then
      print("AFTER: Breaking loop for voice", voice)
      playingVoices[voice] = false
    else
      waitBeat(duration)
    end
  end
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  if type(noteListen) == "number" then
    paramsPerNote[noteListen].triggerNote:setValue(e.note)
    paramsPerNote[noteListen].listen:setValue(false)
  end
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
