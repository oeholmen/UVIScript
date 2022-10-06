-------------------------------------------------------------------------------
-- Random note generator
-------------------------------------------------------------------------------

require "generative"

local voices = 1
local isPlaying = {}
local notesPlaying = {} -- Keep track of notes to avoid dupicates

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "F637EC"
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

local colours = {
  backgroundColour = backgroundColour,
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = labelTextColour,
  menuBackgroundColour = menuBackgroundColour,
  menuArrowColour = menuArrowColour,
  menuOutlineColour = menuOutlineColour
}

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

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
end

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
notePanel.backgroundColour = backgroundColour
notePanel.x = settingsPanel.x
notePanel.y = settingsPanel.y + settingsPanel.height + 5
notePanel.width = 700
notePanel.height = 150

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local label = sequencerPanel:Label("SequencerLabel")
label.text = "Random Note Generator"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 210

local channelButton = sequencerPanel:OnOffButton("ChannelButton", false)
channelButton.backgroundColourOff = "#ff084486"
channelButton.backgroundColourOn = "#ff02ACFE"
channelButton.textColourOff = "#ff22FFFF"
channelButton.textColourOn = "#efFFFFFF"
channelButton.displayName = "Multichannel"
channelButton.tooltip = "When multichannel mode is enabled, each voice is sent to a separate channel"
channelButton.size = {100,22}
channelButton.x = sequencerPanel.width - (channelButton.width * 3) - 10
channelButton.y = 5

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

local widgetWidth = 127

local voicesInput = settingsPanel:NumBox("Voices", voices, 1, 16, true)
voicesInput.textColour = widgetTextColour
voicesInput.backgroundColour = widgetBackgroundColour
voicesInput.displayName = "Voices"
voicesInput.tooltip = "Number of voices playing"
voicesInput.width = widgetWidth
voicesInput.x = 10
voicesInput.y = 0
voicesInput.changed = function(self)
  voices = self.value
end

local reverseFragmentProbability = settingsPanel:NumBox("ReverseProbability", 0, 0, 100, true)
reverseFragmentProbability.unit = Unit.Percent
reverseFragmentProbability.displayName = "Reverse"
reverseFragmentProbability.tooltip = "Probability that rythmic fragments will be played backwards"
reverseFragmentProbability.textColour = widgetTextColour
reverseFragmentProbability.backgroundColour = widgetBackgroundColour
reverseFragmentProbability.width = widgetWidth
reverseFragmentProbability.x = voicesInput.x + voicesInput.width + 10
reverseFragmentProbability.y = voicesInput.y

local noteRandomization = settingsPanel:NumBox("NoteRandomization", 25, 0, 100, true)
noteRandomization.unit = Unit.Percent
noteRandomization.textColour = widgetTextColour
noteRandomization.backgroundColour = widgetBackgroundColour
noteRandomization.displayName = "Note Move"
noteRandomization.tooltip = "Note movement amount"
noteRandomization.width = widgetWidth
noteRandomization.x = reverseFragmentProbability.x + reverseFragmentProbability.width + 10
noteRandomization.y = reverseFragmentProbability.y

local gateInput = settingsPanel:NumBox("Gate", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.textColour = widgetTextColour
gateInput.backgroundColour = widgetBackgroundColour
gateInput.displayName = "Gate"
gateInput.tooltip = "Note gate"
gateInput.width = widgetWidth
gateInput.x = noteRandomization.x + noteRandomization.width + 10
gateInput.y = noteRandomization.y

local gateRandomization = settingsPanel:NumBox("GateRand", 0, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.width = widgetWidth
gateRandomization.x = gateInput.x + gateInput.width + 10
gateRandomization.y = gateInput.y

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
clearNotes.x = notePanel.width - (clearNotes.width * 3) - 33
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

setNotesAndOctaves(notePanel, colours, noteLabel)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function addDurations(resolutions, durations, fragmentDuration)
  -- Include all durations faster than the total fragmentDuration
  for _,i in ipairs(resolutions) do
    local duration = getResolution(i)
    if duration <= fragmentDuration then
      table.insert(durations, duration)
      print("Inserted duration", duration)
    end
  end
  return durations
end

-- Auto generate fragment
function createFragment()
  local minResolution = 23 -- TODO Param
  local resolutionsByType = getResolutionsByType(minResolution)
  local currentDuration = 0
  local fragmentDuration = getRandomFromTable({0.25,0.5,1,2,4,8,12,16}) -- TODO Param
  print("Selected fragmentDuration", fragmentDuration)
  local definition = {}
  local durations = {}
  -- Add resolutions that can fit inside the fragmentDuration
  durations = addDurations(resolutionsByType[1], durations, fragmentDuration)
  if getRandomBoolean(75) then -- TODO Param
    durations = addDurations(resolutionsByType[2], durations, fragmentDuration)
  end
  if getRandomBoolean(25) then -- TODO Param
    durations = addDurations(resolutionsByType[3], durations, fragmentDuration)
  end
  print("Found durations", #durations)
  -- Select durations for the definition
  while currentDuration < fragmentDuration do
    local duration = getRandomFromTable(durations)
    if currentDuration + duration > fragmentDuration then
      duration = fragmentDuration - currentDuration
      print("currentDuration + duration > fragmentDuration, duration", currentDuration, duration, fragmentDuration)
    end
    currentDuration = currentDuration + duration
    table.insert(definition, duration)
    print("Add duration", duration)
  end
  local selectProbability = 100
  local repeatProbability = getRandom(100)-- TODO Param
  local repeatProbabilityDecay = getRandom(50)-- TODO Param
  local minRepeats = getRandom(4)-- TODO Param
  return {f=definition, p=selectProbability, r=repeatProbability, d=repeatProbabilityDecay, m=minRepeats}
end

function getSelectedFragments()
  -- f = the resolutions of the fragment definition (resolution name (1/8) or beat value (0.5))
  -- p = probability of include
  -- r = repeat probability
  -- d = repeat probability decay
  -- m = min repeats
  local resolutionFragments = {
    {f={'2x'},                   p=15,  r=3,    d=100},
    {f={'1/1'},                  p=24,  r=9,    d=100},
    {f={'1/2'},                  p=30,  r=15,   d=100},
    {f={'1/4'},                  p=39,  r=30,   d=50},
    {f={'1/8'},                  p=50,  r=75,   d=25},
    {f={'1/16'},                 p=100, r=100,  d=1, m=4},
    {f={'1/16','1/16','1/8'},    p=100, r=100,  d=3},
    {f={'1/16','1/8','1/8'},     p=100, r=100,  d=3},
    {f={'1/4 dot','1/8'},        p=100, r=100,  d=3},
    {f={'1/4 dot','1/16','1/16'},p=100, r=100,  d=3},
    {f={'1/4','1/8','1/8'},      p=100, r=100,  d=3},
    {f={'1/8 tri'},              p=30,  r=100,  d=15, m=3},
  }
  local selectedFragments = {}
  for _,v in ipairs(resolutionFragments) do
    if getRandomBoolean(v.p) then
      table.insert(selectedFragments, v)
    end
  end
  print("selectedFragments", #selectedFragments)
  if #selectedFragments == 0 then
    return resolutionFragments
  end
  return selectedFragments
end

function getFragment()
  -- TODO Generate 10(?) fragments that are selected from
  return createFragment()
  --return getRandomFromTable(getSelectedFragments())
end

function getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
  if type(activeFragment) == "nil" then
    activeFragment = getFragment()
    fragmentRepeatProbability = activeFragment.r
  end

  if (reverseFragment == false and fragmentPos == #activeFragment.f) or (reverseFragment and fragmentPos == 1) then
    -- END OF FRAGMENT
    fragmentRepeatCount = fragmentRepeatCount + 1
    -- TODO Check modulo for grouping/required number of repeats
    local mustRepeat = false
    if type(activeFragment.m) == "number" then
      print("***MustRepeat?*** fragmentRepeatCount % activeFragment.m", fragmentRepeatCount, activeFragment.m, (fragmentRepeatCount % activeFragment.m))
      --mustRepeat = activeFragment.m % fragmentRepeatCount > 0
      mustRepeat = fragmentRepeatCount % activeFragment.m > 0
    end
    print("FRAGMENT fragmentRepeatCount, mustRepeat", fragmentRepeatCount, mustRepeat)
    if mustRepeat or getRandomBoolean(fragmentRepeatProbability) then
      -- REPEAT FRAGMENT
      fragmentRepeatProbability = fragmentRepeatProbability - (fragmentRepeatProbability * (activeFragment.d / 100))
      print("REPEAT FRAGMENT, fragmentRepeatProbability", fragmentRepeatProbability)
    else
      -- CHANGE FRAGMENT
      fragmentRepeatCount = 0 -- Init repeat counter
      activeFragment = getFragment()
      fragmentRepeatProbability = activeFragment.r
      print("CHANGE FRAGMENT, #fragment, fragmentRepeatProbability", #activeFragment.f, fragmentRepeatProbability)
    end
    -- REVERSE
    -- TODO Randomize fragment order?
    reverseFragment = getRandomBoolean(reverseFragmentProbability.value)
    if reverseFragment then
      print("REVERSE fragment", reverseFragment)
      fragmentPos = #activeFragment.f
    else
      fragmentPos = 1
    end
    print("SET fragmentPos", fragmentPos)
  else
    -- INCREMENT FRAGMENT POS
    local increment = 1
    if reverseFragment then
      increment = -increment
    end
    fragmentPos = fragmentPos + increment
    print("INCREMENT FRAGMENT POS", fragmentPos)
  end

  -- Get fragment at current position
  local duration = activeFragment.f[fragmentPos]
  if type(duration) == "string" then
    -- If duration is string, we must resolve it from resolution names
    local resolutionIndex = getIndexFromValue(duration, getResolutionNames())
    if type(resolutionIndex) == "nil" then
      resolutionIndex = 20 -- 1/8 as a failsafe in case the resolution could not be resolved
    else
      duration = getResolution(resolutionIndex)
    end
  end

  print("RETURN duration", duration)

  return duration, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount
end

--function generateNote(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment)
function generateNote(note)
  local selectedNotes = getSelectedNotes() -- Holds note numbers that are available

  if #selectedNotes == 0 then
    return nil
  end

  if #selectedNotes == 1 then
    return selectedNotes[1]
  end

  local noteIndex = 1
  local currentIndex = getIndexFromValue(note, selectedNotes)

  if type(note) == "nil" or type(currentIndex) == "nil" then
    noteIndex = getRandom(#selectedNotes)
  else
    local maxRounds = 100
    repeat
      noteIndex = randomizeValue(currentIndex, 1, #selectedNotes, noteRandomization.value)
      maxRounds = maxRounds - 1
    until tableIncludes(notesPlaying, selectedNotes[noteIndex]) == false or maxRounds < 1
  end
  return selectedNotes[noteIndex]
end
--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function sequenceRunner()
  local currentVoices = 0
  repeat
    --print("sequenceRunner new round")
    if currentVoices ~= voices then
      --print("currentVoices ~= voices", currentVoices, voices)
      isPlaying = {}
      for i=1,voices do
        table.insert(isPlaying, i)
        if i > currentVoices then
          spawn(play, i)
        end
      end
      currentVoices = #isPlaying
    end
    local baseDuration = 4 -- TODO Param?
    waitBeat(baseDuration)
  until #isPlaying == 0
end

function play(voice)
  local note = nil
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatCount = 0
  local fragmentRepeatProbability = 0
  local duration = nil
  local reverseFragment = false
  while isPlaying[voice] == voice do
    local channel = nil
    if channelButton.value then
      channel = voice
    end
    note = generateNote(note)
    duration, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
    local gate = randomizeValue(gateInput.value, gateInput.min, gateInput.max, gateRandomization.value)
    playNote(note, 64, beat2ms(getPlayDuration(duration, gate)), nil, channel)
    table.insert(notesPlaying, note) -- Register
    waitBeat(duration)
    table.remove(notesPlaying, getIndexFromValue(note, notesPlaying)) -- Remove
  end
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  if autoplayButton.value == true then
    table.insert(playingNotes, e.note)
    postEvent(e)
  else
    playButton:setValue(true)
  end
end

function onRelease(e)
  if autoplayButton.value == true then
    local index = getIndexFromValue(e.note, playingNotes)
    if type(index) == "number" then
      table.remove(playingNotes, index)
    end
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
