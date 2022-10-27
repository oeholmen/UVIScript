-------------------------------------------------------------------------------
-- Random note selector using rythmic fragments (Fragmented Notes)
-------------------------------------------------------------------------------

require "../includes/rythmicFragments"

local voices = 1
local isPlaying = {}
local notesPlaying = {} -- Keep track of playing notes to avoid dupicates

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "F637EC"
local menuTextColour = "#9f02ACFE"
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"
local knobFillColour = "E6D5B8" -- Light

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
notePanel.backgroundColour = "404040"
notePanel.x = settingsPanel.x
notePanel.y = settingsPanel.y + settingsPanel.height + 5
notePanel.width = 700
notePanel.height = 110

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "505050"
rythmPanel.x = notePanel.x
rythmPanel.y = notePanel.y + notePanel.height + 5
rythmPanel.width = 700
rythmPanel.height = 215

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("SequencerLabel")
sequencerLabel.text = "Fragmented Notes"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.width = 160

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

local widgetWidth = 131

local voicesInput = settingsPanel:NumBox("Voices", voices, 1, 4, true)
voicesInput.textColour = widgetTextColour
voicesInput.backgroundColour = widgetBackgroundColour
voicesInput.displayName = "Voices"
voicesInput.tooltip = "Number of voices playing"
voicesInput.width = widgetWidth
voicesInput.x = 5
voicesInput.y = 0
voicesInput.changed = function(self)
  voices = self.value
end

local gateInput = settingsPanel:NumBox("Gate", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.textColour = widgetTextColour
gateInput.backgroundColour = widgetBackgroundColour
gateInput.displayName = "Gate"
gateInput.tooltip = "Note gate"
gateInput.width = widgetWidth
gateInput.x = voicesInput.x + voicesInput.width + 10
gateInput.y = voicesInput.y

local gateRandomization = settingsPanel:NumBox("GateRand", 0, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.width = widgetWidth
gateRandomization.x = gateInput.x + gateInput.width + 10
gateRandomization.y = gateInput.y

local velocityInput = settingsPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Note velocity"
velocityInput.width = widgetWidth
velocityInput.x = gateRandomization.x + gateRandomization.width + 10
velocityInput.y = gateRandomization.y

local velocityAccent = settingsPanel:NumBox("VelocityAccent", 64, 1, 127, true)
velocityAccent.textColour = widgetTextColour
velocityAccent.backgroundColour = widgetBackgroundColour
velocityAccent.displayName = "Accent"
velocityAccent.tooltip = "Velocity accent amount triggered at the start of a fragment"
velocityAccent.width = widgetWidth
velocityAccent.x = velocityInput.x + velocityInput.width + 10
velocityAccent.y = velocityInput.y

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local noteNames = getNoteNames()
local scaleNames = getScaleNames()
local noteListen = nil
local paramsPerNote = {}
local rowSpacing = 3
local numNotes = 8

local noteLabel = notePanel:Label("NotesLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Set the probability that notes will be included when generating new notes"
noteLabel.alpha = 0.75
noteLabel.fontSize = 15
noteLabel.width = 300

local generateKey = notePanel:Menu("GenerateKey", noteNames)
generateKey.persistent = false
generateKey.tooltip = "Set selected notes from key"
generateKey.showLabel = false
generateKey.backgroundColour = colours.menuBackgroundColour
generateKey.textColour = colours.widgetTextColour
generateKey.arrowColour = colours.menuArrowColour
generateKey.outlineColour = colours.menuOutlineColour
generateKey.width = 60
generateKey.height = 18
generateKey.x = noteLabel.x + noteLabel.width + 10
generateKey.y = noteLabel.y

local generateScale = notePanel:Menu("GenerateScale", scaleNames)
generateScale.persistent = false
generateScale.tooltip = "Set selected notes from scale"
generateScale.showLabel = false
generateScale.backgroundColour = colours.menuBackgroundColour
generateScale.textColour = colours.widgetTextColour
generateScale.arrowColour = colours.menuArrowColour
generateScale.outlineColour = colours.menuOutlineColour
generateScale.width = 120
generateScale.height = generateKey.height
generateScale.x = generateKey.x + generateKey.width + 10
generateScale.y = generateKey.y

local octaveOffset = notePanel:NumBox("OctaveOffset", 2, -2, 6, true)
octaveOffset.persistent = false
octaveOffset.displayName = "Octave"
octaveOffset.tooltip = "Set the octave to start from"
octaveOffset.backgroundColour = menuBackgroundColour
octaveOffset.textColour = menuTextColour
octaveOffset.width = 90
octaveOffset.height = generateScale.height
octaveOffset.x = generateScale.x + generateScale.width + 10
octaveOffset.y = generateScale.y

local templates = {
  "Tools...",
  "Mute all",
  "Unmute all",
  "Toggle mute",
  "Set all note probabilities to 100%",
  "Set all note probabilities to 0%",
  "Randomize note probabilities",
  "Randomize notes",
}
local templateMenu = notePanel:Menu("Templates", templates)
templateMenu.tooltip = "Select a tool - NOTE: Will change current settings!"
templateMenu.showLabel = false
templateMenu.width = 75
templateMenu.height = octaveOffset.height
templateMenu.x = octaveOffset.x + octaveOffset.width + 10
templateMenu.y = octaveOffset.y
templateMenu.backgroundColour = colours.menuBackgroundColour
templateMenu.textColour = colours.widgetTextColour
templateMenu.arrowColour = colours.menuArrowColour
templateMenu.outlineColour = colours.menuOutlineColour
templateMenu.changed = function(self)
  if self.value == 1 then
    return
  end
  for part,v in ipairs(paramsPerNote) do
    if self.selectedText == "Mute all" then
      v.mute:setValue(true)
    elseif self.selectedText == "Unmute all" then
      v.mute:setValue(false)
    elseif self.selectedText == "Toggle mute" then
      v.mute:setValue(v.mute.value == false)
    elseif self.selectedText == "Set all note probabilities to 100%" then
      v.noteProbability:setValue(100)
    elseif self.selectedText == "Set all note probabilities to 0%" then
      v.noteProbability:setValue(0)
    elseif self.selectedText == "Randomize note probabilities" then
      v.noteProbability:setValue(getRandom(100))
    elseif self.selectedText == "Randomize notes" then
      v.noteInput:setValue(getRandom(21, 108))
    end
  end
  -- Must be last
  self:setValue(1, false)
end

generateKey.changed = function(self)
  setScale(generateScale.value, self.value)
end

generateScale.changed = function(self)
  setScale(self.value, generateKey.value)
end

octaveOffset.changed = function(self)
  setScale(generateScale.value, generateKey.value)
  --transposeOctave(self.value)
end

local inputWidth = 654 / numNotes
for i=1,numNotes do
  local noteInput = notePanel:NumBox("TriggerNote" .. i, (47+i), 0, 127, true)
  noteInput.displayName = "Note"
  noteInput.tooltip = "The note to trigger"
  noteInput.unit = Unit.MidiKey
  noteInput.showLabel = false
  noteInput.backgroundColour = menuBackgroundColour
  noteInput.textColour = menuTextColour
  noteInput.height = 22
  noteInput.width = inputWidth
  noteInput.x = ((noteInput.width + 5) * (i - 1)) + 10
  noteInput.y = noteLabel.height + 10

  local noteProbability = notePanel:NumBox("NoteProbability" .. i, 100, 0, 100, true)
  noteProbability.tooltip = "Probability that note will be played"
  noteProbability.unit = Unit.Percent
  noteProbability.showLabel = false
  noteProbability.backgroundColour = menuBackgroundColour
  noteProbability.textColour = menuTextColour
  noteProbability.height = noteInput.height
  noteProbability.width = noteInput.width
  noteProbability.x = noteInput.x-- + noteInput.width + rowSpacing
  noteProbability.y = noteInput.y + noteInput.height + rowSpacing

  local listen = notePanel:OnOffButton("Listen" .. i)
  listen.displayName = "Learn"
  listen.tooltip = "Note learn"
  listen.persistent = false
  listen.textColourOff = "white"
  listen.backgroundColourOn = "green"
  --listen.normalImage = "../resources/icons/headphone_inactive_grey.png"
  --listen.pressedImage = "../resources/icons/headphone_active_white_no_check.png"
  listen.height = noteInput.height
  listen.width = noteInput.width / 2
  listen.x = noteProbability.x
  listen.y = noteProbability.y + noteProbability.height + rowSpacing
  listen.changed = function(self)
    if self.value then
      noteListen = i
    else
      noteListen = nil
    end
  end

  local mute = notePanel:OnOffButton("Mute" .. i)
  mute.displayName = "Mute"
  mute.tooltip = "Mute note"
  mute.textColourOff = "white"
  mute.backgroundColourOn = "red"
  --mute.normalImage = "../resources/icons/mute_active_white_no_check.png"
  --mute.pressedImage = "../resources/icons/mute_inactive_grey.png"
  mute.height = listen.height
  mute.width = listen.width
  mute.x = listen.x + listen.width-- + rowSpacing
  mute.y = listen.y

  table.insert(paramsPerNote, {noteInput=noteInput, noteProbability=noteProbability, listen=listen, mute=mute})
end

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythmic fragments"
rythmLabel.alpha = 0.75
rythmLabel.fontSize = 15
rythmLabel.width = 153

local evolveFragmentProbability = rythmPanel:NumBox("EvolveFragmentProbability", 0, 0, 100, true)
evolveFragmentProbability.unit = Unit.Percent
evolveFragmentProbability.textColour = widgetTextColour
evolveFragmentProbability.backgroundColour = widgetBackgroundColour
evolveFragmentProbability.displayName = "Evolve"
evolveFragmentProbability.tooltip = "Set the probability that fragments will change over time, using the resolutions present in the fragments"
evolveFragmentProbability.width = 120
evolveFragmentProbability.height = 18
evolveFragmentProbability.x = rythmLabel.x + rythmLabel.width
evolveFragmentProbability.y = rythmLabel.y

local randomizeCurrentResolutionProbability = rythmPanel:NumBox("RandomizeCurrentResolutionProbability", 0, 0, 100, true)
randomizeCurrentResolutionProbability.unit = Unit.Percent
randomizeCurrentResolutionProbability.textColour = widgetTextColour
randomizeCurrentResolutionProbability.backgroundColour = widgetBackgroundColour
randomizeCurrentResolutionProbability.displayName = "Adjust"
randomizeCurrentResolutionProbability.tooltip = "Set the probability that evolve will adjust resolutions, based on the resolutions present in the fragments"
randomizeCurrentResolutionProbability.width = evolveFragmentProbability.width
randomizeCurrentResolutionProbability.height = evolveFragmentProbability.height
randomizeCurrentResolutionProbability.x = evolveFragmentProbability.x + evolveFragmentProbability.width + 10
randomizeCurrentResolutionProbability.y = evolveFragmentProbability.y

local biasLabel = rythmPanel:Label("BiasLabel")
biasLabel.text = "Bias slow > fast"
biasLabel.tooltip = "Adjust bias: <50=more slow resolutions, >50=more fast resolutions"
biasLabel.alpha = 0.5
biasLabel.fontSize = 15
biasLabel.width = 90
biasLabel.height = randomizeCurrentResolutionProbability.height
biasLabel.x = randomizeCurrentResolutionProbability.x + randomizeCurrentResolutionProbability.width + 10
biasLabel.y = randomizeCurrentResolutionProbability.y

local adjustBias = rythmPanel:Knob("Bias", 50, 0, 100, true)
adjustBias.showLabel = false
adjustBias.showValue = false
adjustBias.displayName = "Bias"
adjustBias.tooltip = biasLabel.tooltip
adjustBias.backgroundColour = widgetBackgroundColour
adjustBias.fillColour = knobFillColour
adjustBias.outlineColour = widgetTextColour
adjustBias.width = 18
adjustBias.height = biasLabel.height
adjustBias.x = biasLabel.x + biasLabel.width
adjustBias.y = biasLabel.y

local minResLabel = rythmPanel:Label("MinResolutionsLabel")
minResLabel.text = "Min resolution"
minResLabel.alpha = 0.5
minResLabel.fontSize = 15
minResLabel.width = 90
minResLabel.height = adjustBias.height
minResLabel.x = adjustBias.x + adjustBias.width + 10
minResLabel.y = adjustBias.y

local minResolution = rythmPanel:Menu("MinResolution", getResolutionNames())
minResolution.displayName = minResLabel.text
minResolution.tooltip = "The highest allowed resolution for evolve adjustments"
minResolution.selected = 26
minResolution.showLabel = false
minResolution.width = 60
minResolution.height = adjustBias.height
minResolution.backgroundColour = widgetBackgroundColour
minResolution.textColour = widgetTextColour
minResolution.arrowColour = menuArrowColour
minResolution.outlineColour = menuOutlineColour
minResolution.x = minResLabel.x + minResLabel.width
minResolution.y = minResLabel.y
minResolution.changed = function(self)
  setMaxResolutionIndex(self.value)
end
minResolution:changed()

local paramsPerFragment = getParamsPerFragment(rythmPanel, rythmLabel, colours)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

--[[ function transposeOctave(octave)
  octave = octave + 2 -- Set the start octave for the scale
  for i,v in ipairs(paramsPerNote) do
    local note = v.noteInput.value + (octave * 12)
    v.noteInput:setValue(note)
    print("transposeOctave: inputNumber, note", i, note)
  end
end ]]

function getScale(scaleIndex, keyIndex)
  local octave = octaveOffset.value + 2 -- Set the start octave for the scale
  print("getScale: octave", octave)
  local scaleDefinitions = getScaleDefinitions()
  local scaleDefinition = scaleDefinitions[scaleIndex]
  local rootNote = (keyIndex - 1) + (octave * 12) -- Root note
  print("getScale: rootNote", rootNote)
  return createScale(scaleDefinition, rootNote)
end

function setScale(scaleIndex, keyIndex)
  local scale = getScale(scaleIndex, keyIndex)
  for i,v in ipairs(paramsPerNote) do
    if type(scale[i]) ~= "number" then
      break
    end
    v.noteInput:setValue(scale[i])
  end
end

function flashNoteLabel(voice, duration)
  local flashDuration = 150
  if type(duration) == "number" then
    flashDuration = beat2ms(duration)
  end
  paramsPerNote[voice].noteInput.textColour = "efefef"
  wait(flashDuration)
  paramsPerNote[voice].noteInput.textColour = menuTextColour
end

function doSelectNote(voice)
  return paramsPerNote[voice].mute.value == false and getRandomBoolean(paramsPerNote[voice].noteProbability.value)
end

function generateNote()
  local selectedNotes = {}
  for i=1,numNotes do
    if doSelectNote(i) then
      table.insert(selectedNotes, i)
    end
  end

  if #selectedNotes == 0 then
    return nil
  end

  local note = nil
  local noteIndex = nil
  local maxRounds = 100
  repeat
    noteIndex = getRandomFromTable(selectedNotes)
    note = paramsPerNote[noteIndex].noteInput.value
    maxRounds = maxRounds - 1
  until tableIncludes(notesPlaying, selectedNotes[noteIndex]) == false or maxRounds < 1
  return noteIndex, note
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
  local previous = nil
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
    if getRandomBoolean(evolveFragmentProbability.value) then
      previous = evolveFragments(previous, randomizeCurrentResolutionProbability.value, adjustBias.value)
    end
  until #isPlaying == 0
end

function play(voice)
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
      channel = voice
    end
    local noteIndex, note = generateNote()
    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
    local doPlayNote = rest == false and type(note) == "number" and type(duration) == "number"
    if doPlayNote then
      local gate = randomizeValue(gateInput.value, gateInput.min, gateInput.max, gateRandomization.value)
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
      spawn(flashNoteLabel, noteIndex, duration)
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
  if type(noteListen) == "number" then
    paramsPerNote[noteListen].noteInput:setValue(e.note)
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
