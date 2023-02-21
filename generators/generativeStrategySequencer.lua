--------------------------------------------------------------------------------
-- Generative Strategy Sequencer
--------------------------------------------------------------------------------

local gem = require "includes.common"
local notes = require "includes.notes"
local scales = require "includes.scales"
local resolutions = require "includes.resolutions"
local noteSelector = require "includes.noteSelector"
local rythmicFragments = require "includes.rythmicFragments"

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
local isPlaying = false
local baseDuration = nil
local recallStoredState = nil -- Holds the index of the stored fragment state to recall
local storedFragments = {} -- Holds stored fragment states
local partOrder = {} -- Holds the playing order of the parts
local playingIndex = {}
local playIndex = 1

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
  local ln = gem.getRandom(maxLength) -- Length
  for i=1, ln do
    local value = gem.getRandom(-7,7)
    table.insert(strategy, value)
    --print("Add value to strategy", value)
  end
  return strategy
end

-- Returns a fragment that can be set directly on fragmentInput.text
-- Used by the tools menu
-- 1 = Default (even+dot)
-- 2 = Single
-- 3 = Extended (fast+slow)
-- 4 = Slow
function getRandomFragment(definitionNumber)
  local fragmentDefinition = {}
  if definitionNumber == 2 then
    fragmentDefinition = {resolutions.getResolution(gem.getRandomFromTable(rythmicFragments.getSelectedResolutions()))} -- Single
  else
    fragmentDefinition = rythmicFragments.createFragmentDefinition(definitionNumber)
  end
  return rythmicFragments.getFragmentInputText(rythmicFragments.fragmentDefinitionToResolutionNames(fragmentDefinition))
end

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

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
  initNotes()
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
rythmPanel.height = 282

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

local channelOffset = sequencerPanel:NumBox("ChannelOffset", 1, 1, 16, true)
channelOffset.textColour = widgetTextColour
channelOffset.backgroundColour = widgetBackgroundColour
channelOffset.enabled = false
channelOffset.showLabel = false
channelOffset.displayName = "Offset"
channelOffset.tooltip = "When multichannel is enabled, each voice is assigned to separate channels starting from this channel"
channelOffset.size = {22,22}
channelOffset.x = sequencerPanel.width - 342
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
  for voice=1,math.max(voices, self.value) do
    if voice > self.value and type(playingIndex[voice]) == "number" then
      print("Stopping voice", voice)
      playingIndex[voice] = nil
    elseif type(playingIndex[voice]) == "nil" then
      table.insert(playingIndex, nil)
    end
  end
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
voiceToFragmentButton.tooltip = "Activate to let each voice use the corresponding fragment."
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

local baseResolution = strategyPanel:Menu("BaseResolution", resolutions.getResolutionNames())
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
  baseDuration = resolutions.getResolution(self.value)
end
baseResolution:changed()

local strategyInput = strategyPanel:Label("StrategyInput")
strategyInput.text = getStrategyInputText(gem.getRandomFromTable(strategies))
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
autoStrategyButton.tooltip = "Random strategies are automatically created for every round."
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
    v:setValue(gem.getRandomBoolean())
  end
end

noteSelector.createNoteAndOctaveSelector(notePanel, colours, noteLabel)

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythmic fragments"
rythmLabel.alpha = 0.75
rythmLabel.fontSize = 15
rythmLabel.width = 120

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, rythmLabel, colours, voicesInput.max)

local templates = {
  "Action...",
  "Clear all fragment settings",
  "Clear fragment inputs",
  "Randomize all fragment settings",
  "Randomize fragment inputs",
  "Randomize fragments (single)",
  "Randomize fragments (slow)",
  "Randomize fragments (extended)",
}
local templateMenu = rythmPanel:Menu("Templates", templates)
templateMenu.tooltip = "Randomize fragments - NOTE: Will change current settings!"
templateMenu.showLabel = false
templateMenu.height = 18
templateMenu.width = 100
templateMenu.x = 685 - templateMenu.width
templateMenu.y = rythmLabel.y
templateMenu.backgroundColour = menuBackgroundColour
templateMenu.textColour = widgetTextColour
templateMenu.arrowColour = menuArrowColour
templateMenu.outlineColour = menuOutlineColour
templateMenu.changed = function(self)
  if self.value == 1 then
    return
  end
  for _,v in ipairs(paramsPerFragment) do
    if self.selectedText == "Clear fragment inputs" then
      v.fragmentInput.text = ""
    elseif self.selectedText == "Clear all fragment settings" then
      v.fragmentInput.text = ""
      v.fragmentPlayProbability.value = v.fragmentPlayProbability.default
      v.fragmentActive.value = v.fragmentActive.default
      v.fragmentRepeatProbability.value = v.fragmentRepeatProbability.default
      v.fragmentRepeatProbabilityDecay.value = v.fragmentRepeatProbabilityDecay.default
      v.fragmentMinRepeats.value = v.fragmentMinRepeats.default
      v.reverseFragmentProbability.value = v.reverseFragmentProbability.default
      v.randomizeFragmentProbability.value = v.randomizeFragmentProbability.default
      v.restProbability.value = v.restProbability.default
    elseif self.selectedText == "Randomize all fragment settings" then
      v.fragmentInput.text = getRandomFragment(1)
      v.fragmentPlayProbability.value = gem.getRandom(100)
      v.fragmentActive.value = true
      v.fragmentRepeatProbability.value = gem.getRandom(100)
      v.fragmentRepeatProbabilityDecay.value = gem.getRandom(100)
      v.fragmentMinRepeats.value = gem.getRandom(100)
      v.reverseFragmentProbability.value = gem.getRandom(100)
      v.randomizeFragmentProbability.value = gem.getRandom(100)
      v.restProbability.value = gem.getRandom(100)
    elseif self.selectedText == "Randomize fragment inputs" then
      v.fragmentInput.text = getRandomFragment(1)
    elseif self.selectedText == "Randomize fragments (single)" then
      v.fragmentInput.text = getRandomFragment(2)
    elseif self.selectedText == "Randomize fragments (extended)" then
      v.fragmentInput.text = getRandomFragment(3)
    elseif self.selectedText == "Randomize fragments (slow)" then
      v.fragmentInput.text = getRandomFragment(4)
    end
  end
  -- Must be last
  self:setValue(1, false)
end

--- Structure - Store/recall parts, set playing order etc. ---

local loadFragmentMenu = rythmPanel:Menu("LoadFragmentMenu", {"Load..."})
loadFragmentMenu.enabled = false

local storeButton = rythmPanel:Button("StoreButton")
storeButton.displayName = "Store"
storeButton.tooltip = "Store the current state of the fragments"
storeButton.width = 75
storeButton.height = 20
storeButton.x = rythmLabel.x
storeButton.y = 220

local slotSpacing = 3
local unusedSlotDefaultText = "Unused"
local actions = {"Save..."}
local slotToStoredIndex = {} -- Holds the index of the stored fragment for each slot
local fragmentSlots = {}
for i=1,8 do
  local fragmentSlot = rythmPanel:OnOffButton("StoreFragmentSlot" .. i)
  fragmentSlot.backgroundColourOff = backgroundColourOff
  fragmentSlot.backgroundColourOn = backgroundColourOn
  fragmentSlot.textColourOff = textColourOff
  fragmentSlot.textColourOn = textColourOn
  fragmentSlot.displayName = "" .. i
  fragmentSlot.enabled = false
  fragmentSlot.tooltip = unusedSlotDefaultText
  fragmentSlot.width = 20
  fragmentSlot.height = storeButton.height
  fragmentSlot.x = storeButton.x + storeButton.width + ((i-1) * (fragmentSlot.width + slotSpacing)) + 10
  fragmentSlot.y = storeButton.y
  fragmentSlot.changed = function(self)
    if self.value then
      local storedIndex = slotToStoredIndex[i]
      if type(storedFragments[storedIndex]) == "table" then
        recallStoredState = storedIndex
        --print("Set part/recallStoredState", i, recallStoredState)
        -- If sequencer is not playing, we can recall right now
        if isPlaying == false then
          recall()
        end
      end
    end
    for j,v in ipairs(fragmentSlots) do
      if j ~= i then
        v:setValue(false, false)
      end
    end
  end
  table.insert(fragmentSlots, fragmentSlot)
  table.insert(slotToStoredIndex, nil)
  table.insert(actions, "Save to " .. i)
end

local slotActions = rythmPanel:Menu("SlotActions", actions)
slotActions.tooltip = "Save current fragment state to the selected slot"
slotActions.showLabel = false
slotActions.height = storeButton.height
slotActions.width = 90
slotActions.x = storeButton.x + storeButton.width + ((fragmentSlots[1].width + slotSpacing) * #fragmentSlots) + 15
slotActions.y = storeButton.y
slotActions.backgroundColour = menuBackgroundColour
slotActions.textColour = widgetTextColour
slotActions.arrowColour = menuArrowColour
slotActions.outlineColour = menuOutlineColour
slotActions.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local index = self.value - 1

  -- Save current fragment state
  -- TODO Add options to remove?
  if index <= #fragmentSlots then
    storeButton:changed() -- Store the current state
    slotToStoredIndex[index] = #storedFragments -- Set the most recent stored fragment to this slot
    fragmentSlots[index].tooltip = "Part " .. index .. " - Stored state " .. slotToStoredIndex[index]
    fragmentSlots[index].enabled = true
  end

  -- Must be last
  self:setValue(1, false)
end

loadFragmentMenu.tooltip = "Load a stored fragment state"
loadFragmentMenu.showLabel = false
loadFragmentMenu.height = storeButton.height
loadFragmentMenu.width = slotActions.width
loadFragmentMenu.x = slotActions.x + slotActions.width + 10
loadFragmentMenu.y = slotActions.y
loadFragmentMenu.backgroundColour = menuBackgroundColour
loadFragmentMenu.textColour = widgetTextColour
loadFragmentMenu.arrowColour = menuArrowColour
loadFragmentMenu.outlineColour = menuOutlineColour
loadFragmentMenu.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local index = self.value - 1

  if type(storedFragments[index]) == "table" then
    recallStoredState = index
    -- If sequencer is not playing, we can recall right now
    if isPlaying == false then
      recall()
    end  
  end

  -- Must be last
  self:setValue(1, false)
end

local partOrderButton = rythmPanel:OnOffButton("PartOrderLabel")
partOrderButton.displayName = "Part Order"
partOrderButton.tooltip = "Activate part order"
partOrderButton.width = 60
partOrderButton.height = 20
partOrderButton.backgroundColourOff = backgroundColourOff
partOrderButton.backgroundColourOn = backgroundColourOn
partOrderButton.textColourOff = textColourOff
partOrderButton.textColourOn = textColourOn
partOrderButton.x = loadFragmentMenu.x + loadFragmentMenu.width + 10
partOrderButton.y = loadFragmentMenu.y

local partOrderInput = rythmPanel:Label("PartOrderInput")
partOrderInput.text = ""
partOrderInput.tooltip = "Set the playing order of the parts (1-8 as stored in the slots). Format <PART><x|e><REPEATS> separated by comma (use e instead of x to activate evolve). Example: 1x16,2e8,3"
partOrderInput.editable = true
partOrderInput.backgroundColour = "black"
partOrderInput.backgroundColourWhenEditing = "white"
partOrderInput.textColour = "white"
partOrderInput.textColourWhenEditing = "black"
partOrderInput.x = partOrderButton.x + partOrderButton.width
partOrderInput.y = partOrderButton.y
partOrderInput.width = 156
partOrderInput.height = 20
partOrderInput.fontSize = 15
partOrderInput.changed = function(self)
  setPartOrder(self.text)
end

--- Evolve ---

local recallButton = rythmPanel:Button("RecallButton")
recallButton.displayName = "Recall"
recallButton.enabled = false
recallButton.tooltip = "Recall the last stored fragment state"
recallButton.width = storeButton.width
recallButton.height = storeButton.height
recallButton.x = storeButton.x
recallButton.y = storeButton.y + storeButton.height + 10

local evolveButton = rythmPanel:OnOffButton("EvolveActive", false)
evolveButton.backgroundColourOff = backgroundColourOff
evolveButton.backgroundColourOn = backgroundColourOn
evolveButton.textColourOff = textColourOff
evolveButton.textColourOn = textColourOn
evolveButton.displayName = "Evolve"
evolveButton.tooltip = "Activate evolve"
evolveButton.width = recallButton.width
evolveButton.height = recallButton.height
evolveButton.x = recallButton.x + recallButton.width + 10
evolveButton.y = recallButton.y

local evolveFragmentProbability = rythmPanel:NumBox("EvolveFragmentProbability", 50, 0, 100, true)
evolveFragmentProbability.unit = Unit.Percent
evolveFragmentProbability.textColour = widgetTextColour
evolveFragmentProbability.backgroundColour = widgetBackgroundColour
evolveFragmentProbability.displayName = "Amount"
evolveFragmentProbability.tooltip = "Set the probability that fragments will change over time, using the resolutions present in the fragments"
evolveFragmentProbability.width = 105
evolveFragmentProbability.height = recallButton.height
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
biasLabel.width = 95
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
adjustBias.width = 20
adjustBias.height = biasLabel.height
adjustBias.x = biasLabel.x + biasLabel.width
adjustBias.y = biasLabel.y

local minResLabel = rythmPanel:Label("MinResolutionsLabel")
minResLabel.text = "Min resolution"
minResLabel.alpha = 0.5
minResLabel.fontSize = 15
minResLabel.width = biasLabel.width
minResLabel.height = adjustBias.height
minResLabel.x = adjustBias.x + adjustBias.width + 10
minResLabel.y = adjustBias.y

local minResolution = rythmPanel:Menu("MinResolution", resolutions.getResolutionNames())
minResolution.displayName = minResLabel.text
minResolution.tooltip = "The highest allowed resolution for evolve adjustments"
minResolution.selected = 26
minResolution.showLabel = false
minResolution.width = 69
minResolution.height = adjustBias.height
minResolution.backgroundColour = widgetBackgroundColour
minResolution.textColour = widgetTextColour
minResolution.arrowColour = menuArrowColour
minResolution.outlineColour = menuOutlineColour
minResolution.x = minResLabel.x + minResLabel.width
minResolution.y = minResLabel.y
minResolution.changed = function(self)
  rythmicFragments.setMaxResolutionIndex(self.value)
end
minResolution:changed()

storeButton.changed = function(self)
  table.insert(storedFragments, rythmicFragments.getFragmentState())
  recallButton.enabled = true
  loadFragmentMenu.enabled = true
  loadFragmentMenu:addItem("State " .. #storedFragments)
end

recallButton.changed = function(self)
  recallStoredState = #storedFragments
  -- If sequencer is not playing, we can recall right now
  if isPlaying == false then
    recall()
  end
end

--------------------------------------------------------------------------------
-- Note Functions
--------------------------------------------------------------------------------

-- Returns the selected notes filtered by overlap range and playing notes
local function getFilteredNotes(voice)
  --print("BEFORE selectedNotes, voices, voice", #selectedNotes, voices, voice)
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
    --print("noteRangeMin, noteRangeMax, voice", noteRangeMin, noteRangeMax, voice)
  end

  -- Find the notes, filter for min/max and notes that are already playing
  local notes = {}
  for i,v in ipairs(selectedNotes) do
    if i >= noteRangeMin and i <= noteRangeMax and gem.tableIncludes(noteSelector.getNotesPlaying(), v) == false then
      table.insert(notes, v)
    end
  end

  --print("AFTER notes, voice", #notes, voice)
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

  if gem.getRandomBoolean(strategyPropbability.value) then
    return getNoteFromStrategy(notes, voice)
  end

  return gem.getRandomFromTable(notes)
end

function getGate()
  return gem.randomizeValue(gateInput.value, 0, 101, gateRandomization.value) / 100
end

function getVelocity()
  return gem.randomizeValue(velocityInput.value, 1, 127, velocityRandomization.value)
end

--------------------------------------------------------------------------------
-- Strategy Functions
--------------------------------------------------------------------------------

function getSlotForVoice(voice)
  -- Select strategies from slot 1 and 5 for voice 1, 2 and 6 for voice 2 etc.
  local slot1 = strategySlots[voice]
  local slot2 = strategySlots[voice+voicesInput.max]
  if slot1.enabled and slot2.enabled then
    if gem.getRandomBoolean() then
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
    strategy = gem.getRandomFromTable(strategies)
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
    notePosition[voice] = gem.getRandom(#notes)
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
      notePosition[voice] = gem.getRandom(#notes)
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

function initNotes()
  noteSelector.clearNotesPlaying()
  playingIndex = {}
  rythmicFragments.clearResolutionsForEvolve()
  for voice=1,voices do
    table.insert(playingIndex, nil) -- Init index
  end
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive.textColourOn = "black"
  end
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentInputDirty = false
  end
end

function playVoices(partDuration)
  for voice=1,voices do
    if playingIndex[voice] == nil then
      playingIndex[voice] = playIndex
      print("Play voice", voice)
      spawn(play, voice, playIndex, partDuration)
      playIndex = playIndex + 1
    end
  end
end

function recall()
  -- Find the state we are to recall
  rythmicFragments.setFragmentState(storedFragments[recallStoredState])
  --print("Recalled fragments from stored state", recallStoredState)
  recallStoredState = nil
end

-- Parse the part order input
-- Format: <PART><x|e><REPEATS> separated by comma (use e instead of x to activate evolve). Example: 1x16,2e8,3
-- Set the part to zero "0" to use the current state instead of loading a part
function setPartOrder(partOrderText)
  partOrder = {} -- Reset
  for s in string.gmatch(partOrderText, "[^,]+") do
    local evolve = type(string.find(s, "e", 1, true)) == "number" -- Check if "e" is given for evolve
    local part = tonumber(string.sub(s, 1, 1)) -- Parts are 1-8, so we get the first pos in the string
    local repeats = tonumber(string.sub(s, 3)) -- Get repeats from the third pos to the end - if any is set
    if type(repeats) ~= "number" then
      repeats = 1
    end
    if type(part) == "number" then
      --print("setPartOrder part, repeats, evolve", part, repeats, evolve)
      table.insert(partOrder, {part=part,repeats=repeats,evolve=evolve})
    end
  end
  --print("#partOrder", #partOrder)
  return partOrder
end

function sequenceRunner()
  strategyPos = {} -- Reset strategy pos
  local partOrderPos = 1 -- Position in the part order
  local partOrderRepeatCounter = 0 -- Counter for part repeats
  local slotIndex = nil -- The currently selected slot
  local remainingDuration = 0
  local partDuration = nil -- When using part order, this is the duration of the parts with repeats
  local partInfo = nil
  local startEvolve = false -- Can be set by part order
  local maxStrategies = 32
  local currentVoices = 0
  local previous = nil
  playIndex = 1 -- Reset play index
  isPlaying = true
  initNotes()
  while isPlaying do
    --print("sequenceRunner new round: #partOrder", #partOrder)

    if partOrderButton.value and #partOrder > 0 then
      if partOrderRepeatCounter == 0 then
        -- Start new part
        partInfo = partOrder[partOrderPos]
        slotIndex = partInfo.part
        partOrderRepeatCounter = partInfo.repeats
        startEvolve = partInfo.evolve
        --print("startEvolve, slotIndex, partOrderPos", startEvolve, slotIndex, partOrderPos)
        partDuration = partOrderRepeatCounter * baseDuration
        remainingDuration = partDuration
        -- If slot is already selected, deactivate so we can select it again
        if slotIndex > 0 then
          if fragmentSlots[slotIndex].value == true then
            fragmentSlots[slotIndex]:setValue(false)
          end
          fragmentSlots[slotIndex]:setValue(true)
        end
        -- Increment part order position
        partOrderPos = partOrderPos + 1
        if partOrderPos > #partOrder then
          partOrderPos = 1
        end
      end

      partOrderRepeatCounter = partOrderRepeatCounter - 1 -- Decrement repeat counter
      --print("Decrementing partOrderRepeatCounter", partOrderRepeatCounter)
    end

    if type(recallStoredState) == "number" then
      initNotes()
      recall()
      evolveButton:setValue(startEvolve)
    end

    selectedNotes = noteSelector.getSelectedNotes(true) -- Refresh selected notes
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
        slots[gem.getRandom(#slots)]:setValue(true)
      end
    end

    if strategyRestart.value == 1 or strategyRestart.value == 4 then
      notePosition = {} -- Reset counter for note position
      if strategyRestart.value == 4 then
        strategyPos = {} -- Reset strategy position
      end
    end

    if type(partDuration) == "nil" or remainingDuration == partDuration or remainingDuration == 0 then
      playVoices(partDuration)
    end

    waitBeat(baseDuration)
    if evolveButton.value and gem.getRandomBoolean(evolveFragmentProbability.value) then
      previous = rythmicFragments.evolveFragments(previous, randomizeCurrentResolutionProbability.value, adjustBias.value)
    end
  end
end

function play(voice, uniqueId, partDuration)
  local playDuration = 0 -- Keep track of the played duration
  local noteToPlay = nil
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatCount = 0
  local fragmentRepeatProbability = 0
  local duration = nil
  local rest = false
  local reverseFragment = false
  while playingIndex[voice] == uniqueId do
    local channel = nil
    if channelButton.value then
      channel = voice + channelOffset.value - 1
    end
    local sources = nil
    if voiceToFragmentButton.value then
      sources = {voice}
    end
    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = rythmicFragments.getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount, sources)
    if type(duration) == "nil" then
      playingIndex[voice] = nil
      --print("No duration was found for voice", voice)
      break
    end

    if type(partDuration) == "number" and (playDuration + duration) > partDuration then
      duration = partDuration - playDuration -- Remaining
      --print("duration changed to remaining", duration, "voice " .. voice)
    end

    -- Update total play duration
    playDuration = playDuration + duration

    local gate = getGate()
    if gate > 0 and rest == false then
      noteToPlay = generateNote(voice)
    else
      noteToPlay = nil
    end
    if type(noteToPlay) == "number" then
      local velocity = getVelocity()
      local noteDuration = beat2ms(duration) * gate
      playNote(noteToPlay, velocity, noteDuration, nil, channel)
      --print("playNote noteToPlay, velocity, noteDuration, voice", noteToPlay, velocity, noteDuration, voice)
      -- Register playing note
      noteSelector.addNotePlaying(noteToPlay)
      for i,v in ipairs(paramsPerFragment) do
        if activeFragment.i == i then
          spawn(rythmicFragments.flashFragmentActive, v.fragmentActive, duration)
        end
      end
    end


    if type(partDuration) == "number" and playDuration == partDuration then
      playingIndex[voice] = nil
    else
      waitBeat(duration)
    end

    if type(noteToPlay) == "number" then
      -- Unregister note
      noteSelector.removeNotePlaying(noteToPlay)
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
  local fragmentSlotsData = {}

  strategyInputData = strategyInput.text
  for _,v in ipairs(strategySlots) do
    table.insert(strategySlotsData, v.tooltip)
  end

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  for _,v in ipairs(fragmentSlots) do
    table.insert(fragmentSlotsData, v.tooltip)
  end

  return {strategyInputData, strategySlotsData, fragmentInputData, fragmentSlotsData, storedFragments, partOrderInput.text, slotToStoredIndex}
end

function onLoad(data)
  local strategyInputData = data[1]
  local strategySlotsData = data[2]
  local fragmentInputData = data[3]
  local fragmentSlotsData = data[4]
  storedFragments = data[5]
  partOrderInput.text = tostring(data[6])
  slotToStoredIndex = data[7]

  setPartOrder(partOrderInput.text)

  strategyInput.text = strategyInputData
  for i,v in ipairs(strategySlots) do
    v.tooltip = strategySlotsData[i]
    v.enabled = v.tooltip ~= unusedStrategySlotDefaultText
  end

  if type(storedFragments) == "nil" then
    storedFragments = {}
  end

  if type(fragmentSlotsData) == "nil" then
    fragmentSlotsData = {}
  end

  if type(slotToStoredIndex) == "nil" then
    slotToStoredIndex = {}
    for i=1,#fragmentSlots do
      table.insert(slotToStoredIndex, nil)
    end
  end

  recallButton.enabled = #storedFragments > 0

  for i=1,#storedFragments do
    loadFragmentMenu:addItem("State " .. i)
  end
  loadFragmentMenu.enabled = #storedFragments > 0

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end

  for i,v in ipairs(fragmentSlotsData) do
    fragmentSlots[i].tooltip = v
    fragmentSlots[i].enabled = type(slotToStoredIndex[i]) == "number"
  end
end
