--------------------------------------------------------------------------------
-- Generative Strategy Sequencer
--------------------------------------------------------------------------------

require "../includes/generative"

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

local colours = {
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
  backgroundColour = backgroundColour
}

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

local voices = 1
local isPlaying = {}
local globalResolution = nil -- Holds the global resolution for all voices
local minResolution = resolutions[#resolutions] -- The lowest allowed resolution

local strategyPos = 1 -- Holds the position in the selected strategy
local notePosition = 0 -- Holds the current note position
local strategyIndex = getRandom(#strategies) -- Holds the selected strategy - start with a random strategy
local notes = {} -- Holds the playing notes - notes are removed when they are finished playing

function getStrategyInputText(strategy)
  if #strategy == 0 then
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
    print("Add value to strategy", value)
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

local gatePanel = Panel("GatePanel")
gatePanel.backgroundColour = "303030"
gatePanel.x = strategyPanel.x + strategyPanel.width + 5
gatePanel.y = strategyPanel.y
gatePanel.width = 140
gatePanel.height = strategyPanel.height

local velocityPanel = Panel("VelovityPanel")
velocityPanel.backgroundColour = "003865"
velocityPanel.x = gatePanel.x + gatePanel.width + 5
velocityPanel.y = strategyPanel.y
velocityPanel.width = gatePanel.width
velocityPanel.height = strategyPanel.height

local notePanel = Panel("Notes")
notePanel.backgroundColour = "505050"
notePanel.x = strategyPanel.x
notePanel.y = strategyPanel.y + strategyPanel.height + 5
notePanel.width = 700
notePanel.height = 150

local resolutionPanel = Panel("Resolutions")
resolutionPanel.backgroundColour = "003865"
resolutionPanel.x = notePanel.x
resolutionPanel.y = notePanel.y + notePanel.height + 5
resolutionPanel.width = 700
resolutionPanel.height = 162

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local label = sequencerPanel:Label("Label")
label.text = "Generative Sequencer"
label.alpha = 0.5
label.textColour = labelTextColour
label.fontSize = 22
label.width = 170
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

local gateLabel = gatePanel:Label("SettingsLabel")
gateLabel.text = "Gate"
gateLabel.alpha = 0.75
gateLabel.fontSize = 15
gateLabel.width = 120

local gateInput = gatePanel:NumBox("Gate", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.textColour = widgetTextColour
gateInput.backgroundColour = widgetBackgroundColour
gateInput.displayName = "Level"
gateInput.tooltip = "Default gate"
gateInput.size = {130,20}
gateInput.x = 5
gateInput.y = gateLabel.y + gateLabel.height + 15

local gateRandomization = gatePanel:NumBox("GateRandomization", 25, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Randomization"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.size = gateInput.size
gateRandomization.x = gateInput.x
gateRandomization.y = gateInput.y + gateInput.height + 15

local velocityLabel = velocityPanel:Label("SettingsLabel")
velocityLabel.text = "Velocity"
velocityLabel.alpha = 0.75
velocityLabel.fontSize = 15
velocityLabel.width = 120

local velocityInput = velocityPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Level"
velocityInput.tooltip = "Default velocity"
velocityInput.size = gateRandomization.size
velocityInput.x = 5
velocityInput.y = velocityLabel.y + velocityLabel.height + 15

local velocityRandomization = velocityPanel:NumBox("VelocityRandomization", 25, 0, 100, true)
velocityRandomization.unit = Unit.Percent
velocityRandomization.textColour = widgetTextColour
velocityRandomization.backgroundColour = widgetBackgroundColour
velocityRandomization.displayName = "Randomization"
velocityRandomization.tooltip = "Velocity randomization amount"
velocityRandomization.size = velocityInput.size
velocityRandomization.x = velocityInput.x
velocityRandomization.y = velocityInput.y + velocityInput.height + 15

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
strategyPropbability.tooltip = "Set the probability that a playing strategy will be used to select the next note. Otherwise notes will be selected by random from the current scale."
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

local strategyInput = strategyPanel:Label("StrategyInput")
strategyInput.text = getStrategyInputText(strategies[strategyIndex])
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
for j=1,9 do
  local strategySlot = strategyPanel:OnOffButton("StrategySlot" .. j)
  strategySlot.backgroundColourOff = backgroundColourOff
  strategySlot.backgroundColourOn = backgroundColourOn
  strategySlot.textColourOff = textColourOff
  strategySlot.textColourOn = textColourOn
  strategySlot.displayName = "" .. j
  strategySlot.enabled = false
  strategySlot.tooltip = "Unused"
  strategySlot.height = 20
  strategySlot.width = 27
  strategySlot.x = strategyInput.x + ((j-1) * (strategySlot.width+2))
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

local strategyActions = strategyPanel:Menu("StrategyActions", actions)
strategyActions.tooltip = "Choose when a strategy restarts"
strategyActions.showLabel = false
strategyActions.height = 20
strategyActions.width = strategyRestart.width
strategyActions.x = strategyRestart.x
strategyActions.y = strategyRestart.y + strategyRestart.height + 5
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
      strategySlots[actionIndex].tooltip = "Unused"
      strategySlots[actionIndex].enabled = false
    end
    print("Strategy saved to slot", strategyInput.text, actionIndex)
  elseif actionIndex > #strategySlots + 1 then
    strategyInput.text = self.selectedText
    strategyIndex = actionIndex - #strategySlots - 1
    print("Strategy index selected", strategyIndex)
  end

  -- Must be last
  self.selected = 1
end

local autoStrategyButton = strategyPanel:OnOffButton("AutoStrategyButton", false)
autoStrategyButton.displayName = "Auto"
autoStrategyButton.tooltip = "Strategies are automatically created and randomly changed while playing."
autoStrategyButton.backgroundColourOff = backgroundColourOff
autoStrategyButton.backgroundColourOn = backgroundColourOn
autoStrategyButton.textColourOff = textColourOff
autoStrategyButton.textColourOn = textColourOn
autoStrategyButton.width = boxSize[1] / 2 - 2
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
  notePosition = 0 -- Reset note position
  strategyInput.enabled = self.value == false
  createStrategyButton.enabled = self.value == false
end

slotStrategyButton.changed = function(self)
  autoStrategyButton:setValue(false, false)
  notePosition = 0 -- Reset note position
  strategyInput.enabled = true
  createStrategyButton.enabled = true
end

createStrategyButton.changed = function()
  local strategy = createStrategy()
  strategyInput.text = table.concat(strategy, ",")
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

setNotesAndOctaves(notePanel, colours, noteLabel)

--------------------------------------------------------------------------------
-- Resolution Panel
--------------------------------------------------------------------------------

local resLabel = resolutionPanel:Label("ResolutionsLabel")
resLabel.text = "Resolutions"
resLabel.tooltip = "Set probability for each resolution to be selected"
resLabel.alpha = 0.75
resLabel.fontSize = 15
resLabel.width = 350

local clearResolutions = resolutionPanel:Button("ClearResolutions")
clearResolutions.displayName = "All off"
clearResolutions.tooltip = "Deactivate all resolutions"
clearResolutions.persistent = false
clearResolutions.height = resLabel.height
clearResolutions.width = 90
clearResolutions.x = resolutionPanel.width - (clearResolutions.width * 3) - 30
clearResolutions.y = 5
clearResolutions.changed = function()
  for i,v in ipairs(resolutionInputs) do
    toggleResolutionInputs[i]:setValue(false)
  end
end

local addResolutions = resolutionPanel:Button("AddResolutions")
addResolutions.displayName = "All on"
addResolutions.tooltip = "Activate all resolutions"
addResolutions.persistent = false
addResolutions.height = clearResolutions.height
addResolutions.width = 90
addResolutions.x = clearResolutions.x + clearResolutions.width + 10
addResolutions.y = 5
addResolutions.changed = function()
  for i,v in ipairs(resolutionInputs) do
    toggleResolutionInputs[i]:setValue(true)
  end
end

local randomizeResolutions = resolutionPanel:Button("RandomizeResolutions")
randomizeResolutions.displayName = "Randomize"
randomizeResolutions.tooltip = "Randomize selected resolutions"
randomizeResolutions.persistent = false
randomizeResolutions.height = clearResolutions.height
randomizeResolutions.width = 90
randomizeResolutions.x = addResolutions.x + addResolutions.width + 10
randomizeResolutions.y = 5
randomizeResolutions.changed = function()
  for i,v in ipairs(resolutionInputs) do
    toggleResolutionInputs[i]:setValue(getRandomBoolean())
  end
end

rowCount = setResolutions(resolutionPanel, colours)

local resLabel = resolutionPanel:Label("ResolutionsLabel")
resLabel.text = "Base Resolution"
resLabel.alpha = 0.5
resLabel.fontSize = 15
resLabel.width = 106
resLabel.x = 5
resLabel.y = (25 * rowCount) + 10

local baseResolution = resolutionPanel:Menu("BaseResolution", resolutionNames)
baseResolution.displayName = resLabel.text
baseResolution.tooltip = "The duration between resets"
baseResolution.selected = 7
baseResolution.showLabel = false
baseResolution.height = 20
baseResolution.width = 106
baseResolution.backgroundColour = widgetBackgroundColour
baseResolution.textColour = widgetTextColour
baseResolution.arrowColour = menuArrowColour
baseResolution.outlineColour = menuOutlineColour
baseResolution.x = resLabel.x + resLabel.width + 10
baseResolution.y = resLabel.y

local durationRepeatProbabilityInput = resolutionPanel:NumBox("DurationRepeatProbability", 100, 0, 100, true)
durationRepeatProbabilityInput.unit = Unit.Percent
durationRepeatProbabilityInput.textColour = widgetTextColour
durationRepeatProbabilityInput.backgroundColour = widgetBackgroundColour
durationRepeatProbabilityInput.displayName = "Repeat Probability"
durationRepeatProbabilityInput.tooltip = "The probability that a resolution will be repeated"
durationRepeatProbabilityInput.size = {222,20}
durationRepeatProbabilityInput.x = baseResolution.x + baseResolution.width + 10
durationRepeatProbabilityInput.y = baseResolution.y

local durationRepeatDecay = resolutionPanel:NumBox("DurationRepeatDecay", 1, 10., 100)
durationRepeatDecay.unit = Unit.Percent
durationRepeatDecay.textColour = widgetTextColour
durationRepeatDecay.backgroundColour = widgetBackgroundColour
durationRepeatDecay.displayName = "Probability Decay"
durationRepeatDecay.tooltip = "The reduction in repeat probability for each iteration of the playing voice"
durationRepeatDecay.size = durationRepeatProbabilityInput.size
durationRepeatDecay.x = durationRepeatProbabilityInput.x + durationRepeatProbabilityInput.width + 10
durationRepeatDecay.y = durationRepeatProbabilityInput.y

--------------------------------------------------------------------------------
-- Note Functions
--------------------------------------------------------------------------------

local function generateNote()
  local note = nil

  local selectedNotes = getSelectedNotes()

  if #selectedNotes == 0 then
    return nil
  end

  if #selectedNotes == 1 then
    return selectedNotes[1]
  end

  if getRandomBoolean(strategyPropbability.value) then
    note = getNoteFromStrategy(selectedNotes)
    print("Get note from scale using strategy: note/strategyPos/strategyIndex", note, strategyPos, strategyIndex)
  else
    note = selectedNotes[getRandom(#selectedNotes)]
    print("Get random note from selectedNotes: note", note)
  end
  return note
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

function getNoteFromStrategy(selectedNotes)
  local strategy = {}
  local input = strategyInput
  if input.enabled == true and string.len(input.text) > 0 then
    for w in string.gmatch(input.text, "-?%d+") do
      table.insert(strategy, w)
      print("Add to strategy", w)
    end
    print("Get strategy from input", #strategy)
  end
  if #strategy == 0 then
    strategy = strategies[strategyIndex]
  end
  -- Reset strategy position
  if strategyPos > #strategy then
    strategyPos = 1
    if strategyRestart.value == 3 or strategyRestart.value == 4 then
      notePosition = 0 -- Reset counter for note position
      print("Reset counter for note position")
    end
  end
  print("Get strategy strategyIndex/strategyPos", strategyIndex, strategyPos)
  if notePosition == 0 or #strategy == 0 then
    -- Start at a random notePosition
    notePosition = getRandom(#selectedNotes)
    print("Set random notePosition", notePosition)
    if strategyRestart.value == 1 then
      strategyPos = 1
    end
  else
    -- Get next notePosition from strategy
    notePosition = notePosition + strategy[strategyPos]
    print("Set notePosition/strategyPos", notePosition, strategy[strategyPos])
    local randomReset = true -- TODO Param?
    if randomReset and (notePosition > #selectedNotes or notePosition < 1) then
      notePosition = getRandom(#selectedNotes)
      if strategyRestart.value == 2 then
        strategyPos = 1
      end
    elseif notePosition > #selectedNotes then
      print("Reset notePosition >= #selectedNotes", notePosition, #selectedNotes)
      notePosition = 1
      if strategyRestart.value == 2 then
        strategyPos = 1
      end
    elseif notePosition < 1 then
      print("Reset notePosition <= 1", notePosition)
      notePosition = #selectedNotes
      if strategyRestart.value == 2 then
        strategyPos = 1
      end
    else
      -- Increment strategy pos
      if #strategy > 1 then
        strategyPos = strategyPos + 1
        print("Increment strategy pos", strategyPos)
      end
    end
  end
  local note = selectedNotes[notePosition]
  return note
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function sequenceRunner()
  strategyPos = 1 -- Reset strategy pos
  local maxStrategies = 32
  local currentVoices = 0
  repeat
    --print("sequenceRunner new round")
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
      notePosition = 0 -- Reset counter for note position
      if strategyRestart.value == 4 then
        strategyPos = 1 -- Reset strategy position
      end
    end

    if currentVoices ~= voices then
      --print("currentVoices ~= voices", currentVoices, voices)
      isPlaying = {}
      for i=1,voices do
        table.insert(isPlaying, i)
        if i > currentVoices then
          spawn(arpeg, i)
        end
      end
      currentVoices = #isPlaying
    end

    local baseDuration = getResolution(baseResolution.value)
    waitBeat(baseDuration)
  until #isPlaying == 0
end

function arpeg(voice)
  local waitDuration = nil
  local noteToPlay = nil
  local remainingDuration = 0
  local durationRepeatProbability = durationRepeatProbabilityInput.value
  local repeatCounter = 1
  --print("Start playing voice", voice)
  while isPlaying[voice] == voice do
    local channel = nil
    if channelButton.value then
      channel = voice
    end
    --print("arpeg gate", gate)
    if remainingDuration == 0 then
      remainingDuration = getResolution(baseResolution.value) -- Reset remaining duration to base duration
      repeatCounter = 1 -- Reset repeat counter - should counter be reset here?
      --print("New round for voice, remainingDuration", voice, remainingDuration)
    end
    waitDuration, repeatCounter, durationRepeatProbability = getNoteDuration(waitDuration, repeatCounter, durationRepeatProbability, durationRepeatDecay.value)
    if durationRepeatProbability == nil then
      durationRepeatProbability = durationRepeatProbabilityInput.value
    end
    --print("remainingDuration, waitDuration, repeatCounter, durationRepeatProbability", remainingDuration, waitDuration, repeatCounter, durationRepeatProbability)
    if remainingDuration < waitDuration then
      waitDuration = remainingDuration
      --print("waitDuration changed to remaining", waitDuration)
    end
    local gate = getGate()
    if gate > 0 and waitDuration >= minResolution then
      noteToPlay = generateNote()
    else
      noteToPlay = nil
    end
    if type(noteToPlay) == "number" then
      local velocity = getVelocity()
      local playDuration = beat2ms(waitDuration) * gate
      playNote(noteToPlay, velocity, playDuration, nil, channel)
      --print("playNote noteToPlay, velocity, playDuration, voice", noteToPlay, velocity, playDuration, voice)
      -- Register playing note
      table.insert(notesPlaying, noteToPlay)
    end
    --print("waitBeat(waitDuration)", waitDuration)
    waitBeat(waitDuration)
    if type(noteToPlay) == "number" then
      -- Unregister note
      table.remove(notesPlaying, getIndexFromValue(noteToPlay, notesPlaying))
    end
    remainingDuration = remainingDuration - waitDuration
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

  strategyInputData = strategyInput.text
  for _,v in ipairs(strategySlots) do
    table.insert(strategySlotsData, v.tooltip)
  end

  return {strategyInputData, strategySlotsData}
end

function onLoad(data)
  local strategyInputData = data[1]
  local strategySlotsData = data[2]

  strategyInput.text = strategyInputData
  for i,v in ipairs(strategySlots) do
    v.tooltip = strategySlotsData[i]
    v.enabled = v.tooltip ~= "Unused"
  end
end
