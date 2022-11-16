--------------------------------------------------------------------------------
-- Generative Strategy Sequencer
--------------------------------------------------------------------------------

require "../includes/noteSelector"
require "../includes/rythmicFragments"

local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "9f02ACFE" -- Light
local labelTextColour = "AEFEFF" -- Light
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"
local backgroundColour = "202020"
local knobFillColour = "E6D5B8" -- Light

local colours = {
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = "black", -- Used for rythmic fragments
  menuBackgroundColour = menuBackgroundColour,
  menuArrowColour = menuArrowColour,
  menuOutlineColour = menuOutlineColour,
  backgroundColourOff = backgroundColourOff,
  backgroundColourOn = backgroundColourOn,
  textColourOff = textColourOff,
  textColourOn = textColourOn,
  backgroundColour = backgroundColour
}

local voices = 1
local isPlaying = {}
local baseDuration = nil

--------------------------------------------------------------------------------
-- Strategies
--------------------------------------------------------------------------------

-- Strategies are ways to play chords and scales
local strategies = {
  {}, -- Randomize next note position +/- 1 oct
  {1}, -- Up
  {-1}, -- Down
  {2,-1}, -- Alternate up
  {-2,1}, -- Alternate down
  {-1,1,-2,-1,3}, -- Generated 1
  {3,1,-1,2}, -- Generated 2
  {-3,2}, -- Generated 3
  {2,2,3}, -- Up v 2
  {-3,-2,-2}, -- Down v 2
  {3,-2,7},
  {-5,4,4},
  {7,7,-5},
  {7,5,6},
  {-7,2,7},
  {7,0,-7},
  {4,0,-4},
  {0},
  {4,-2},
  {3,-2},
}

local strategyPos = {} -- Holds the position in the selected strategy
local notePosition = {} -- Holds the current note position
local unusedStrategySlotDefaultText = "Unused"
local selectedNotes = {}

function getStrategyInputText(strategy)
  if type(strategy) == nil or #strategy == 0 then
    return "Randomize"
  end
  return table.concat(strategy, ",")
end

function createStrategy()
  local maxLength = 8
  local strategy = {} -- Table to hold strategy
  local ln = getRandom(maxLength) -- Length
  for i=1, ln do
    local value = getRandom(-7,7)
    table.insert(strategy, value)
    --print("Add value to strategy", value)
  end
  return strategy
end

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

setBackgroundColour(backgroundColour)

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 30

local strategyPanel = Panel("Strategy")
strategyPanel.backgroundColour = "003865"
strategyPanel.x = sequencerPanel.x
strategyPanel.y = sequencerPanel.y + sequencerPanel.height + 5
strategyPanel.width = 405
strategyPanel.height = 110

local gateVelPanel = Panel("GateVelocityPanel")
gateVelPanel.backgroundColour = "303030"
gateVelPanel.x = strategyPanel.x + strategyPanel.width + 5
gateVelPanel.y = strategyPanel.y
gateVelPanel.width = 140
gateVelPanel.height = strategyPanel.height

local voicePanel = Panel("VoicePanel")
voicePanel.backgroundColour = "003865"
voicePanel.x = gateVelPanel.x + gateVelPanel.width + 5
voicePanel.y = strategyPanel.y
voicePanel.width = gateVelPanel.width
voicePanel.height = strategyPanel.height

local notePanel = Panel("Notes")
notePanel.backgroundColour = "505050"
notePanel.x = strategyPanel.x
notePanel.y = strategyPanel.y + strategyPanel.height + 5
notePanel.width = 700
notePanel.height = 150

local rythmPanel = Panel("Resolutions")
rythmPanel.backgroundColour = "003865"
rythmPanel.x = notePanel.x
rythmPanel.y = notePanel.y + notePanel.height + 5
rythmPanel.width = 700
rythmPanel.height = 420

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local label = sequencerPanel:Label("Label")
label.text = "Generative Strategy Sequencer"
label.alpha = 0.5
label.textColour = labelTextColour
label.fontSize = 22
label.width = 260
label.x = 0

local channelButton = sequencerPanel:OnOffButton("ChannelButton", false)
channelButton.backgroundColourOff = "#ff084486"
channelButton.backgroundColourOn = "#ff02ACFE"
channelButton.textColourOff = "#ff22FFFF"
channelButton.textColourOn = "#efFFFFFF"
channelButton.displayName = "Multichannel"
channelButton.tooltip = "When multichannel mode is enabled, each voice is sent to a separate channel"
channelButton.size = {100,22}
channelButton.x = sequencerPanel.width - (channelButton.width * 3) - 15
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

local gateInput = gateVelPanel:NumBox("Gate", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.textColour = widgetTextColour
gateInput.backgroundColour = widgetBackgroundColour
gateInput.displayName = "Gate"
gateInput.tooltip = "Note gate level"
gateInput.size = {130,20}
gateInput.x = 5
gateInput.y = 7

local gateRandomization = gateVelPanel:NumBox("GateRandomization", 15, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Randomization"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.size = gateInput.size
gateRandomization.x = gateInput.x
gateRandomization.y = gateInput.y + gateInput.height + 5

local velocityInput = gateVelPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Default velocity"
velocityInput.size = gateRandomization.size
velocityInput.x = gateRandomization.x
velocityInput.y = gateRandomization.y + gateRandomization.height + 5

local velocityRandomization = gateVelPanel:NumBox("VelocityRandomization", 15, 0, 100, true)
velocityRandomization.unit = Unit.Percent
velocityRandomization.textColour = widgetTextColour
velocityRandomization.backgroundColour = widgetBackgroundColour
velocityRandomization.displayName = "Randomization"
velocityRandomization.tooltip = "Velocity randomization amount"
velocityRandomization.size = velocityInput.size
velocityRandomization.x = velocityInput.x
velocityRandomization.y = velocityInput.y + velocityInput.height + 5

local voicesInput = voicePanel:NumBox("Voices", voices, 1, 4, true)
voicesInput.textColour = widgetTextColour
voicesInput.backgroundColour = widgetBackgroundColour
voicesInput.displayName = "Voices"
voicesInput.tooltip = "Voices"
voicesInput.size = gateRandomization.size
voicesInput.x = 5
voicesInput.y = 5
voicesInput.changed = function(self)
  voices = self.value
end

local rangeOverlap = voicePanel:NumBox("RangeOverlap", 50, 0, 100, true)
rangeOverlap.unit = Unit.Percent
rangeOverlap.textColour = widgetTextColour
rangeOverlap.backgroundColour = widgetBackgroundColour
rangeOverlap.displayName = "Range Overlap"
rangeOverlap.tooltip = "Set the overlap range for the voices. 100 = all voices use the full range, 0 = separate ranges. Requires at least 7 notes per voice."
rangeOverlap.size = voicesInput.size
rangeOverlap.x = voicesInput.x
rangeOverlap.y = voicesInput.y + voicesInput.height + 5

local voiceToFragmentButton = voicePanel:OnOffButton("VoiceToFragmentButton", false)
voiceToFragmentButton.displayName = "Voice to fragment"
voiceToFragmentButton.tooltip = "Activate to let each voice use the corresponding fragment. Voice 1 gets fragment 1+5, voice 2 gets 2+6 etc..."
voiceToFragmentButton.backgroundColourOff = backgroundColourOff
voiceToFragmentButton.backgroundColourOn = backgroundColourOn
voiceToFragmentButton.textColourOff = textColourOff
voiceToFragmentButton.textColourOn = textColourOn
voiceToFragmentButton.size = rangeOverlap.size
voiceToFragmentButton.x = rangeOverlap.x
voiceToFragmentButton.y = rangeOverlap.y + rangeOverlap.height + 5

local voiceToStrategySlotButton = voicePanel:OnOffButton("VoiceToStrategySlotButton", false)
voiceToStrategySlotButton.displayName = "Voice to strategy slot"
voiceToStrategySlotButton.tooltip = "Activate to let each voice use the corresponding slot. Voice 1 gets slot 1+5, voice 2 gets 2+6 etc..."
voiceToStrategySlotButton.backgroundColourOff = backgroundColourOff
voiceToStrategySlotButton.backgroundColourOn = backgroundColourOn
voiceToStrategySlotButton.textColourOff = textColourOff
voiceToStrategySlotButton.textColourOn = textColourOn
voiceToStrategySlotButton.size = voiceToFragmentButton.size
voiceToStrategySlotButton.x = voiceToFragmentButton.x
voiceToStrategySlotButton.y = voiceToFragmentButton.y + voiceToFragmentButton.height + 5

--------------------------------------------------------------------------------
-- Strategy Panel
--------------------------------------------------------------------------------

local strategyLabel = strategyPanel:Label("StrategyLabel")
strategyLabel.text = "Strategy"
strategyLabel.alpha = 0.75
strategyLabel.fontSize = 15
strategyLabel.width = 350

local boxSize = {120,20}

-- TODO Add param for strategy probability decay?
local strategyPropbability = strategyPanel:NumBox("StrategyPropbability", 100, 0, 100, true)
strategyPropbability.displayName = "Probability"
strategyPropbability.tooltip = "Probability that a playing strategy will be used to select the next note. Otherwise notes are selected by random."
strategyPropbability.unit = Unit.Percent
strategyPropbability.size = boxSize
strategyPropbability.x = strategyLabel.x
strategyPropbability.y = strategyLabel.y + strategyLabel.height + 5
strategyPropbability.backgroundColour = menuBackgroundColour
strategyPropbability.textColour = widgetTextColour

local strategyRestart = strategyPanel:Menu("StrategyRestart", {"Restart each round", "Out of range", "When finished", "Finished+round"})
strategyRestart.tooltip = "Choose when a strategy restarts"
strategyRestart.showLabel = false
strategyRestart.size = boxSize
strategyRestart.x = strategyPropbability.x
strategyRestart.y = strategyPropbability.y + strategyPropbability.height + 5
strategyRestart.backgroundColour = menuBackgroundColour
strategyRestart.textColour = widgetTextColour
strategyRestart.arrowColour = menuArrowColour
strategyRestart.outlineColour = menuOutlineColour

local resLabel = strategyPanel:Label("ResolutionsLabel")
resLabel.text = "Round"
resLabel.tooltip = "Round duration affects strategy, selected notes and fragment evolve."
resLabel.alpha = 0.5
resLabel.fontSize = 15
resLabel.width = boxSize[1] / 2
resLabel.height = boxSize[2]
resLabel.x = strategyRestart.x
resLabel.y = strategyRestart.y + strategyRestart.height + 5

local baseResolution = strategyPanel:Menu("BaseResolution", getResolutionNames())
baseResolution.displayName = resLabel.text
baseResolution.tooltip = resLabel.tooltip
baseResolution.selected = 11
baseResolution.showLabel = false
baseResolution.width = boxSize[1] / 2
baseResolution.height = boxSize[2]
baseResolution.backgroundColour = widgetBackgroundColour
baseResolution.textColour = widgetTextColour
baseResolution.arrowColour = menuArrowColour
baseResolution.outlineColour = menuOutlineColour
baseResolution.x = resLabel.x + resLabel.width
baseResolution.y = resLabel.y
baseResolution.changed = function(self)
  baseDuration = getResolution(self.value)
end
baseResolution:changed()

local strategyInput = strategyPanel:Label("StrategyInput")
strategyInput.text = getStrategyInputText(getRandomFromTable(strategies))
strategyInput.tooltip = "Strategies are ways to play scales. Numbers represent steps up or down the scale that is currently playing. Feel free to type your own strategies here."
strategyInput.editable = true
strategyInput.backgroundColour = "black"
strategyInput.backgroundColourWhenEditing = "white"
strategyInput.textColour = "white"
strategyInput.textColourWhenEditing = "black"
strategyInput.x = strategyRestart.x + strategyRestart.width + 10
strategyInput.y = strategyPropbability.y
strategyInput.width = 260
strategyInput.height = 45
strategyInput.fontSize = 30

local actions = {"Actions..."}
local strategySlots = {}
for j=1,(voicesInput.max*2) do
  local strategySlot = strategyPanel:OnOffButton("StrategySlot" .. j)
  strategySlot.backgroundColourOff = backgroundColourOff
  strategySlot.backgroundColourOn = backgroundColourOn
  strategySlot.textColourOff = textColourOff
  strategySlot.textColourOn = textColourOn
  strategySlot.displayName = "" .. j
  strategySlot.enabled = false
  strategySlot.tooltip = unusedStrategySlotDefaultText
  strategySlot.height = 20
  strategySlot.width = 30
  strategySlot.x = strategyInput.x + ((j-1) * (strategySlot.width+3)) - 1
  strategySlot.y = strategyInput.y + strategyInput.height + 5
  strategySlot.changed = function(self)
    strategyInput.text = strategySlot.tooltip
    self.value = false
  end
  table.insert(strategySlots, strategySlot)
  table.insert(actions, "Save to " .. j)
end

table.insert(actions, "--- Load ---")
for _,v in ipairs(strategies) do
  table.insert(actions, getStrategyInputText(v))
end

local autoStrategyButton = strategyPanel:OnOffButton("AutoStrategyButton", false)
autoStrategyButton.displayName = "Auto"
autoStrategyButton.tooltip = "Random strategies are automatically created and for every round."
autoStrategyButton.backgroundColourOff = backgroundColourOff
autoStrategyButton.backgroundColourOn = backgroundColourOn
autoStrategyButton.textColourOff = textColourOff
autoStrategyButton.textColourOn = textColourOn
autoStrategyButton.width = (boxSize[1] / 2) - 15
autoStrategyButton.x = strategyRestart.x + strategyRestart.width + 10
autoStrategyButton.y = strategyLabel.y

local slotStrategyButton = strategyPanel:OnOffButton("SlotStrategyButton", false)
slotStrategyButton.displayName = "Slots"
slotStrategyButton.tooltip = "Strategies are selected from the slots."
slotStrategyButton.backgroundColourOff = backgroundColourOff
slotStrategyButton.backgroundColourOn = backgroundColourOn
slotStrategyButton.textColourOff = textColourOff
slotStrategyButton.textColourOn = textColourOn
slotStrategyButton.width = autoStrategyButton.width
slotStrategyButton.x = autoStrategyButton.x + autoStrategyButton.width + 5
slotStrategyButton.y = autoStrategyButton.y

local createStrategyButton = strategyPanel:Button("CreateStrategyButton")
createStrategyButton.displayName = "Create"
createStrategyButton.tooltip = "Replace the current strategy with a new one."
createStrategyButton.persistent = false
createStrategyButton.width = slotStrategyButton.width
createStrategyButton.x = slotStrategyButton.x + slotStrategyButton.width + 5
createStrategyButton.y = slotStrategyButton.y

autoStrategyButton.changed = function(self)
  slotStrategyButton:setValue(false, false)
  notePosition = {} -- Reset note position
  strategyInput.enabled = self.value == false
  createStrategyButton.enabled = self.value == false
end

slotStrategyButton.changed = function(self)
  autoStrategyButton:setValue(false, false)
  notePosition = {} -- Reset note position
  strategyInput.enabled = true
  createStrategyButton.enabled = true
end

createStrategyButton.changed = function()
  local strategy = createStrategy()
  strategyInput.text = table.concat(strategy, ",")
end

local strategyActions = strategyPanel:Menu("StrategyActions", actions)
strategyActions.tooltip = "Available actions for strategies"
strategyActions.showLabel = false
strategyActions.height = 20
strategyActions.width = 110
strategyActions.x = createStrategyButton.x + createStrategyButton.width + 5
strategyActions.y = createStrategyButton.y
strategyActions.backgroundColour = menuBackgroundColour
strategyActions.textColour = widgetTextColour
strategyActions.arrowColour = menuArrowColour
strategyActions.outlineColour = menuOutlineColour
strategyActions.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local actionIndex = self.value - 1

  -- Save strategy
  if actionIndex <= #strategySlots then
    if string.len(strategyInput.text) > 0 then
      strategySlots[actionIndex].tooltip = strategyInput.text
      strategySlots[actionIndex].enabled = true
    else
      strategySlots[actionIndex].tooltip = unusedStrategySlotDefaultText
      strategySlots[actionIndex].enabled = false
    end
    --print("Strategy saved to slot", strategyInput.text, actionIndex)
  elseif actionIndex > #strategySlots + 1 then
    strategyInput.text = self.selectedText
  end

  -- Must be last
  self:setValue(1, false)
end

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
rythmLabel.width = 120

local evolveButton = rythmPanel:OnOffButton("EvolveActive", false)
evolveButton.backgroundColourOff = backgroundColourOff
evolveButton.backgroundColourOn = backgroundColourOn
evolveButton.textColourOff = textColourOff
evolveButton.textColourOn = textColourOn
evolveButton.displayName = "Evolve"
evolveButton.tooltip = "Activate evolve"
evolveButton.width = 54
evolveButton.height = 18
evolveButton.x = rythmLabel.x + rythmLabel.width + 10
evolveButton.y = rythmLabel.y

local evolveFragmentProbability = rythmPanel:NumBox("EvolveFragmentProbability", 0, 0, 100, true)
evolveFragmentProbability.unit = Unit.Percent
evolveFragmentProbability.textColour = widgetTextColour
evolveFragmentProbability.backgroundColour = widgetBackgroundColour
evolveFragmentProbability.displayName = "Evolve"
evolveFragmentProbability.tooltip = "Set the probability that fragments will change over time, using the resolutions present in the fragments"
evolveFragmentProbability.width = 100
evolveFragmentProbability.height = evolveButton.height
evolveFragmentProbability.x = evolveButton.x + evolveButton.width + 10
evolveFragmentProbability.y = evolveButton.y

local randomizeCurrentResolutionProbability = rythmPanel:NumBox("RandomizeCurrentResolutionProbability", 0, 0, 100, true)
randomizeCurrentResolutionProbability.unit = Unit.Percent
randomizeCurrentResolutionProbability.textColour = widgetTextColour
randomizeCurrentResolutionProbability.backgroundColour = widgetBackgroundColour
randomizeCurrentResolutionProbability.displayName = "Adjust"
randomizeCurrentResolutionProbability.tooltip = "Set the probability that evolve will adjust resolutions (double, half, dot/tri), based on the resolutions present in the fragments"
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

local paramsPerFragment = getParamsPerFragment(rythmPanel, rythmLabel, colours, (voicesInput.max * 2))

--------------------------------------------------------------------------------
-- Note Functions
--------------------------------------------------------------------------------

-- Returns the selected notes filtered by overlap range and playing notes
local function getFilteredNotes(voice)
  print("BEFORE selectedNotes, voices, voice", #selectedNotes, voices, voice)
  local noteRangeMin = 1
  local noteRangeMax = #selectedNotes
  local notesPerVoice = 5
  local notesRequiredForRange = voices * notesPerVoice

  -- Adjust note range min/max for voice overlap, if we have enough available notes
  if #selectedNotes >= notesRequiredForRange then
    local rangeOverlapAmount = rangeOverlap.value
    local range = #selectedNotes / voices
    --print("range, voices, voice", range, voices, voice)
    local overlapValue = math.ceil(range * (rangeOverlapAmount / 100))
    --print("overlapValue, voice", overlapValue, voice)
    noteRangeMax = math.min(noteRangeMax, ((range * voice) + overlapValue))
    noteRangeMin = math.max(1, (noteRangeMax - range - overlapValue))
    print("noteRangeMin, noteRangeMax, voice", noteRangeMin, noteRangeMax, voice)
  end

  -- Find the notes, filter for min/max and notes that are already playing
  local notes = {}
  for i,v in ipairs(selectedNotes) do
    if i >= noteRangeMin and i <= noteRangeMax and tableIncludes(notesPlaying, v) == false then
      table.insert(notes, v)
    end
  end

  print("AFTER notes, voice", #notes, voice)
  return notes
end

local function generateNote(voice)
  local notes = getFilteredNotes(voice)

  if #notes == 0 then
    return nil
  end

  if #notes == 1 then
    return notes[1]
  end

  if getRandomBoolean(strategyPropbability.value) then
    return getNoteFromStrategy(notes, voice)
  end

  return getRandomFromTable(notes)
end

function getGate()
  return randomizeValue(gateInput.value, 0, 101, gateRandomization.value) / 100
end

function getVelocity()
  return randomizeValue(velocityInput.value, 1, 127, velocityRandomization.value)
end

--------------------------------------------------------------------------------
-- Strategy Functions
--------------------------------------------------------------------------------

function getSlotForVoice(voice)
  -- Select strategies from slot 1 and 5 for voice 1, 2 and 6 for voice 2 etc.
  local slot1 = strategySlots[voice]
  local slot2 = strategySlots[voice+voicesInput.max]
  if slot1.enabled and slot2.enabled then
    if getRandomBoolean() then
      return slot1.tooltip
    else
      return slot2.tooltip
    end
  end
  if slot1.enabled then
    return slot1.tooltip
  end
  if slot2.enabled then
    return slot2.tooltip
  end
end

function getNoteFromStrategy(notes, voice)
  local strategy = {}
  -- Get strategy from slot, if button active
  if voiceToStrategySlotButton.value then
    local slot = getSlotForVoice(voice)
    if type(slot) == "string" then
      for w in string.gmatch(slot, "-?%d+") do
        table.insert(strategy, w)
        --print("Add to strategy from slot for voice", w, voice)
      end
      --print("Get strategy from slot", #strategy)
    end
  end
  -- Get strategy from input
  if #strategy == 0 then
    local input = strategyInput
    --if input.enabled == true and string.len(input.text) > 0 then
    if string.len(input.text) > 0 then
      for w in string.gmatch(input.text, "-?%d+") do
        table.insert(strategy, w)
        --print("Add to strategy", w)
      end
      --print("Get strategy from input", #strategy)
    end
  end
  -- Get strategy from index
  if #strategy == 0 then
    strategy = getRandomFromTable(strategies)
  end
  -- Reset strategy position
  if type(strategyPos[voice]) == "nil" or strategyPos[voice] > #strategy then
    strategyPos[voice] = 1
    if strategyRestart.value == 3 or strategyRestart.value == 4 then
      notePosition[voice] = nil -- Reset counter for note position
      --print("Reset note position for voice", voice)
    end
  end
  if type(notePosition[voice]) == "nil" or #strategy == 0 then
    -- Start at a random notePosition
    notePosition[voice] = getRandom(#notes)
    --print("Set random notePosition, voice", notePosition[voice], voice)
    if strategyRestart.value == 1 then
      strategyPos[voice] = 1
    end
  else
    -- Get next notePosition from strategy
    --print("Set notePosition, strategyPos, voice", notePosition[voice], strategy[strategyPos[voice]], voice)
    notePosition[voice] = notePosition[voice] + strategy[strategyPos[voice]]
    local randomReset = true -- TODO Param?
    if randomReset and (notePosition[voice] > #notes or notePosition[voice] < 1) then
      notePosition[voice] = getRandom(#notes)
      if strategyRestart.value == 2 then
        strategyPos[voice] = 1
      end
    elseif notePosition[voice] > #notes then
      --print("Reset notePosition >= #notes", notePosition, #notes)
      notePosition[voice] = 1
      if strategyRestart.value == 2 then
        strategyPos[voice] = 1
      end
    elseif notePosition[voice] < 1 then
      --print("Reset notePosition[voice] <= 1", notePosition[voice])
      notePosition[voice] = #notes
      if strategyRestart.value == 2 then
        strategyPos[voice] = 1
      end
    else
      -- Increment strategy pos
      if #strategy > 1 then
        strategyPos[voice] = strategyPos[voice] + 1
        --print("Increment strategy pos", strategyPos)
      end
    end
  end
  return notes[notePosition[voice]]
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function sequenceRunner()
  strategyPos = {} -- Reset strategy pos
  local maxStrategies = 32
  local currentVoices = 0
  local previous = nil
  repeat
    --print("sequenceRunner new round")
    selectedNotes = getSelectedNotes(true) -- Refresh selected notes
    if autoStrategyButton.value == true then
      local strategy = createStrategy()
      strategyInput.text = getStrategyInputText(strategy)
    end

    if slotStrategyButton.value == true then
      local slots = {}
      for _,v in ipairs(strategySlots) do
        if v.enabled == true then
          table.insert(slots, v)
        end
      end
      if #slots > 0 then
        slots[getRandom(#slots)]:setValue(true)
      end
    end

    if strategyRestart.value == 1 or strategyRestart.value == 4 then
      notePosition = {} -- Reset counter for note position
      if strategyRestart.value == 4 then
        strategyPos = {} -- Reset strategy position
      end
    end

    -- Check if the number if voices is changed
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

    -- Restart voices if stopped
    for i=1,voices do
      if type(isPlaying[i]) == "nil" then
        isPlaying[i] = i
        spawn(play, i)
      end
    end

    waitBeat(baseDuration)
    if evolveButton.value and getRandomBoolean(evolveFragmentProbability.value) then
      previous = evolveFragments(previous, randomizeCurrentResolutionProbability.value, adjustBias.value)
    end
  until #isPlaying == 0
end

function play(voice)
  local noteToPlay = nil
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
    local sources = nil
    if voiceToFragmentButton.value then
      sources = {voice,voice+voicesInput.max}
    end
    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount, sources)
    if type(duration) == "nil" then
      isPlaying[voice] = nil
      --print("No duration was found for voice", voice)
      break
    end
    local gate = getGate()
    if gate > 0 and rest == false then
      noteToPlay = generateNote(voice)
    else
      noteToPlay = nil
    end
    if type(noteToPlay) == "number" then
      local velocity = getVelocity()
      local playDuration = beat2ms(duration) * gate
      playNote(noteToPlay, velocity, playDuration, nil, channel)
      --print("playNote noteToPlay, velocity, playDuration, voice", noteToPlay, velocity, playDuration, voice)
      -- Register playing note
      table.insert(notesPlaying, noteToPlay)
      for i,v in ipairs(paramsPerFragment) do
        if activeFragment.i == i then
          spawn(flashFragmentActive, v.fragmentActive, duration)
        end
      end
    end
    waitBeat(duration)
    if type(noteToPlay) == "number" then
      -- Unregister note
      table.remove(notesPlaying, getIndexFromValue(noteToPlay, notesPlaying))
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
  local strategyInputData = {}
  local strategySlotsData = {}
  local fragmentInputData = {}

  strategyInputData = strategyInput.text
  for _,v in ipairs(strategySlots) do
    table.insert(strategySlotsData, v.tooltip)
  end

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  return {strategyInputData, strategySlotsData, fragmentInputData}
end

function onLoad(data)
  local strategyInputData = data[1]
  local strategySlotsData = data[2]
  local fragmentInputData = data[3]

  strategyInput.text = strategyInputData
  for i,v in ipairs(strategySlots) do
    v.tooltip = strategySlotsData[i]
    v.enabled = v.tooltip ~= unusedStrategySlotDefaultText
  end

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end
end
