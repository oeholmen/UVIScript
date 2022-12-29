--------------------------------------------------------------------------------
-- Drunken Sequencer
--------------------------------------------------------------------------------

require "includes.noteSelector"
require "includes.rythmicFragments"

local backgroundColour = "303030" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "white"
local menuBackgroundColour = "01011F"
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

local voices = 1
local notesPlaying = {}
local isPlaying = {}

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

setBackgroundColour(backgroundColour)

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 30

local settingsPanel = Panel("Settings")
settingsPanel.backgroundColour = "404040"
settingsPanel.x = sequencerPanel.x
settingsPanel.y = sequencerPanel.y + sequencerPanel.height + 5
settingsPanel.width = 700
settingsPanel.height = 85

local notePanel = Panel("Notes")
notePanel.backgroundColour = "404040"
notePanel.x = settingsPanel.x
notePanel.y = settingsPanel.y + settingsPanel.height + 5
notePanel.width = 700
notePanel.height = 150

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "404040"
rythmPanel.x = notePanel.x
rythmPanel.y = notePanel.y + notePanel.height + 5
rythmPanel.width = 700
rythmPanel.height = 215

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("Label")
sequencerLabel.text = "Drunken Sequencer"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.width = 170
sequencerLabel.x = 0

meter = sequencerPanel:AudioMeter("OutputLevel", Part, false, 0, true)
meter.height = sequencerLabel.height
meter.width = sequencerLabel.width
meter.x = sequencerLabel.x + sequencerLabel.width + 15
meter.y = sequencerLabel.y
meter["0dBColour"] = "red"
meter["3dBColour"] = "orange"
meter["6dBColour"] = "yellow"
meter["10dBColour"] = "green"

local channelOffset = sequencerPanel:NumBox("ChannelOffset", 1, 1, 16, true)
channelOffset.textColour = widgetTextColour
channelOffset.backgroundColour = widgetBackgroundColour
channelOffset.enabled = false
channelOffset.showLabel = false
channelOffset.displayName = "Offset"
channelOffset.tooltip = "When multichannel is enabled, each voice is assigned to separate channels starting from this channel"
channelOffset.size = {22,22}
channelOffset.x = sequencerPanel.width - 337
channelOffset.y = 5

local channelButton = sequencerPanel:OnOffButton("ChannelButton", false)
channelButton.backgroundColourOff = "#ff084486"
channelButton.backgroundColourOn = "#ff02ACFE"
channelButton.textColourOff = "#ff22FFFF"
channelButton.textColourOn = "#efFFFFFF"
channelButton.displayName = "Multichannel"
channelButton.tooltip = "When multichannel mode is enabled, each voice is sent to a separate channel"
channelButton.size = {100,22}
channelButton.x = channelOffset.x + channelOffset.width + 5
channelButton.y = channelOffset.y
channelButton.changed = function(self)
  channelOffset.enabled = self.value
end

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = "#ff084486"
autoplayButton.backgroundColourOn = "#ff02ACFE"
autoplayButton.textColourOff = "#ff22FFFF"
autoplayButton.textColourOn = "#efFFFFFF"
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = channelButton.size
autoplayButton.x = channelButton.x + channelButton.width + 5
autoplayButton.y = channelButton.y

local playButton = sequencerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = "#ff084486"
playButton.backgroundColourOn = "#ff02ACFE"
playButton.textColourOff = "#ff22FFFF"
playButton.textColourOn = "#efFFFFFF"
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

local settingsLabel = settingsPanel:Label("SettingsLabel")
settingsLabel.text = "Settings"
settingsLabel.alpha = 0.75
settingsLabel.fontSize = 15
settingsLabel.width = 350

--- First row ---

local noteRandomization = settingsPanel:NumBox("NoteRandomization", 25, 0, 100, true)
noteRandomization.unit = Unit.Percent
noteRandomization.textColour = widgetTextColour
noteRandomization.backgroundColour = widgetBackgroundColour
noteRandomization.displayName = "Note Movement"
noteRandomization.tooltip = "Random note movement amount - a small amount gives small steps between notes"
noteRandomization.size = {163,20}
noteRandomization.x = 5
noteRandomization.y = settingsLabel.y + settingsLabel.height + 5

local noteDirection = settingsPanel:NumBox("NoteDirection", 50, 0, 100, true)
noteDirection.unit = Unit.Percent
noteDirection.textColour = widgetTextColour
noteDirection.backgroundColour = widgetBackgroundColour
noteDirection.displayName = "Direction"
noteDirection.tooltip = "Affect the random note movement by specifying the probability of direction. <50% = more down, >50% = more up, 50% = equal chance"
noteDirection.size = noteRandomization.size
noteDirection.x = noteRandomization.x + noteRandomization.width + 10
noteDirection.y = noteRandomization.y

local randomReset = settingsPanel:OnOffButton("RandomReset", true)
randomReset.enabled = false
randomReset.backgroundColourOff = "#ff084486"
randomReset.backgroundColourOn = "#ff02ACFE"
randomReset.textColourOff = "#ff22FFFF"
randomReset.textColourOn = "#efFFFFFF"
randomReset.displayName = "Random Reset"
randomReset.tooltip = "When direction is biased (above or below 50%), use random reset to start from a random note when highest or lowest note is reached"
randomReset.size = noteDirection.size
randomReset.x = noteDirection.x + noteDirection.width + 10
randomReset.y = noteDirection.y

local voicesInput = settingsPanel:NumBox("Voices", voices, 1, 4, true)
voicesInput.textColour = widgetTextColour
voicesInput.backgroundColour = widgetBackgroundColour
voicesInput.displayName = "Voices"
voicesInput.tooltip = "Number of voices playing"
voicesInput.size = noteDirection.size
voicesInput.x = randomReset.x + randomReset.width + 10
voicesInput.y = randomReset.y
voicesInput.changed = function(self)
  voices = self.value
end

noteDirection.changed = function(self)
  randomReset.enabled = self.value ~= 50
end

--- Second row ---

local gateInput = settingsPanel:NumBox("Gate", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.textColour = widgetTextColour
gateInput.backgroundColour = widgetBackgroundColour
gateInput.displayName = "Gate"
gateInput.tooltip = "Default gate"
gateInput.size = noteDirection.size
gateInput.x = noteRandomization.x
gateInput.y = noteDirection.y + noteDirection.height + 5

local gateRandomization = settingsPanel:NumBox("GateRandomization", 25, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.size = gateInput.size
gateRandomization.x = gateInput.x + gateInput.width + 10
gateRandomization.y = gateInput.y

local velocityInput = settingsPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Default velocity"
velocityInput.size = gateRandomization.size
velocityInput.x = gateRandomization.x + gateRandomization.width + 10
velocityInput.y = gateInput.y

local velocityAccent = settingsPanel:NumBox("VelocityAccent", 64, 1, 127, true)
velocityAccent.textColour = widgetTextColour
velocityAccent.backgroundColour = widgetBackgroundColour
velocityAccent.displayName = "Accent"
velocityAccent.tooltip = "Velocity accent amount triggered at the start of a fragment"
velocityAccent.size = velocityInput.size
velocityAccent.x = velocityInput.x + velocityInput.width + 10
velocityAccent.y = velocityInput.y

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local noteLabel = notePanel:Label("NotesLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Set the probability that notes will be included when generating new notes"
noteLabel.alpha = 0.75
noteLabel.fontSize = 15
noteLabel.width = 50

local clearNotes = notePanel:Button("ClearNotes")
clearNotes.displayName = "Clear notes"
clearNotes.tooltip = "Deselect all notes"
clearNotes.persistent = false
clearNotes.height = noteLabel.height
clearNotes.width = 90
clearNotes.x = notePanel.width - (clearNotes.width * 3) - 30
clearNotes.y = 5
clearNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(false)
  end
end

local addNotes = notePanel:Button("AddNotes")
addNotes.displayName = "All notes"
addNotes.tooltip = "Select all notes"
addNotes.persistent = false
addNotes.height = noteLabel.height
addNotes.width = 90
addNotes.x = clearNotes.x + clearNotes.width + 10
addNotes.y = 5
addNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(true)
  end
end

local randomizeNotes = notePanel:Button("RandomizeNotes")
randomizeNotes.displayName = "Randomize notes"
randomizeNotes.tooltip = "Randomize all notes"
randomizeNotes.persistent = false
randomizeNotes.height = noteLabel.height
randomizeNotes.width = 90
randomizeNotes.x = addNotes.x + addNotes.width + 10
randomizeNotes.y = 5
randomizeNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(getRandomBoolean())
  end
end

createNoteAndOctaveSelector(notePanel, colours, noteLabel)

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythmic fragments"
rythmLabel.alpha = 0.75
rythmLabel.fontSize = 15
rythmLabel.width = 153

local paramsPerFragment = getParamsPerFragment(rythmPanel, rythmLabel, colours)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function generateNote(currentNote)
  local selectedNotes = getSelectedNotes() -- Holds note numbers that are available

  if #selectedNotes == 0 then
    return nil
  end

  if #selectedNotes == 1 then
    return selectedNotes[1]
  end

  local noteIndex = 1
  local currentIndex = getIndexFromValue(currentNote, selectedNotes)

  if type(currentNote) == "nil" or type(currentIndex) == "nil" then
    noteIndex = getRandom(#selectedNotes)
    --print("Get random note index", noteIndex)
  else
    local noteDirectionProbability = noteDirection.value
    local goUp = getRandomBoolean(noteDirectionProbability)
    local resetFull = randomReset.value == false
    if noteDirectionProbability == 50 then
      -- Equal up/down
      noteIndex = randomizeValue(currentIndex, 1, #selectedNotes, noteRandomization.value)
      --print("Equal up/down noteIndex/currentIndex", noteIndex, currentIndex)
    elseif goUp and (currentIndex < #selectedNotes or resetFull) then
      if currentIndex == #selectedNotes then
        noteIndex = 1 -- Reset to lowest index
      else
        noteIndex = randomizeValue(currentIndex, currentIndex, #selectedNotes, noteRandomization.value)
      end
      print("Up noteIndex/currentIndex", noteIndex, currentIndex)
    elseif currentIndex > 1 or resetFull then
      if currentIndex == 1 then
        noteIndex = #selectedNotes -- Reset to max index
      else
        noteIndex = randomizeValue(currentIndex, 1, currentIndex, noteRandomization.value)
      end
      print("Down noteIndex/currentIndex", noteIndex, currentIndex)
    else
      noteIndex = getRandom(#selectedNotes)
      print("Random note index", noteIndex)
    end
  end

  return selectedNotes[noteIndex]
end

function getGate()
  return randomizeValue(gateInput.value, gateInput.min, gateInput.max, gateRandomization.value)
end

function startPlaying()
  if #isPlaying > 1 then
    return
  end
  run(sequenceRunner)
end

function stopPlaying()
  if #isPlaying == 0 then
    return
  end
  isPlaying = {}
  notesPlaying = {}
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive.textColourOn = "black"
  end
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function sequenceRunner()
  --local previous = nil
  local currentVoices = 0
  repeat
    if currentVoices ~= voices then
      isPlaying = {}
      for i=1,voices do
        table.insert(isPlaying, i)
        if i > currentVoices then
          spawn(play, i)
        end
      end
      currentVoices = #isPlaying
    end
    local baseDuration = 4
    waitBeat(baseDuration)
    --[[ if getRandomBoolean(evolveFragmentProbability.value) then
      previous = evolveFragments(previous, randomizeCurrentResolutionProbability.value, adjustBias.value)
    end ]]
  until #isPlaying == 0
end

function play(voice)
  local note = nil
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatCount = 0
  local fragmentRepeatProbability = 0
  local duration = nil
  local rest = false
  local reverseFragment = false
  while isPlaying[voice] == voice do
    local channel = nil
    if channelButton.value then
      channel = voice + channelOffset.value - 1
    end
    note = generateNote(note)
    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
    local doPlayNote = rest == false and type(note) == "number" and type(duration) == "number"
    if doPlayNote then
      local gate = getGate()
      local velocity = velocityInput.value
      -- Use accent value in fragment start, if there is more than one resolution defined in the fragment
      if isFragmentStart and #activeFragment.f > 1 then
        velocity = velocityAccent.value
      end
      playNote(note, velocity, beat2ms(getPlayDuration(duration, gate)), nil, channel)
      table.insert(notesPlaying, note) -- Register
      for i,v in ipairs(paramsPerFragment) do
        if activeFragment.i == i then
          spawn(flashFragmentActive, v.fragmentActive, duration)
        end
      end
    end
    if type(duration) == "nil" then
      duration = 1 -- Failsafe
    end
    waitBeat(duration)
    if doPlayNote then
      table.remove(notesPlaying, getIndexFromValue(note, notesPlaying)) -- Remove
    end
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

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  return {fragmentInputData}
end

function onLoad(data)
  local fragmentInputData = data[1]

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end
end
