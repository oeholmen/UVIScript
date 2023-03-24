-----------------------------------------------------------------------------------------------------------------
-- Strategy Input - A standard sequencer that listens to incoming events on note 0
-----------------------------------------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local modular = require "includes.modular"
local notes = require "includes.notes"
local scales = require "includes.scales"
local resolutions = require "includes.resolutions"

local voices = 1 -- Holds the maximum amount of seen voices
local strategyPropbability = 100
local strategyInput = ""
local strategyRestart = 1
local voiceSlotStrategy = false
local randomSlotStrategy = false
local strategyPos = {} -- Holds the position in the selected strategy
local notePosition = {} -- Holds the current note position
local unusedStrategySlotDefaultText = "Unused"
local strategySlots = {}
local selectedNotes = {}
local key = 1
local noteMin = 48
local noteMax = noteMin + 24
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinition = scaleDefinitions[#scaleDefinitions]
local rangeOverlapAmount = 50
local numSlots = 8
local isPlaying = false
local resolutionNames = resolutions.getResolutionNames()
local resolution = 11

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

--------------------------------------------------------------------------------
-- Strategy Functions
--------------------------------------------------------------------------------

-- Returns the notes filtered by scale and range
local function setNotes()
  local scale = scales.createScale(scaleDefinition, (key - 1), noteMax)
  selectedNotes = {} -- Reset selectedNotes
  for _,note in ipairs(scale) do
    if note >= noteMin and note <= noteMax then
      table.insert(selectedNotes, note)
    end
  end
  --print("Found selectedNotes within selected scale/range", #selectedNotes)
end

local function createStrategy()
  local maxLength = 16 -- The maximum number of steps in the created strategy
  local strategy = {} -- Table to hold strategy
  local ln = gem.getRandom(maxLength) -- Number of steps to add
  for i=1, ln do
    local value = gem.getRandom(-7,7)
    table.insert(strategy, value)
    --print("Add value to strategy", value)
  end
  return strategy
end

local function getStrategyInputText(strategy)
  if type(strategy) == nil or #strategy == 0 then
    return "Randomize"
  end
  return table.concat(strategy, ",")
end

local function setRandomSlot()
  local slots = {}
  for _,v in ipairs(strategySlots) do
    if v.enabled == true then
      table.insert(slots, v)
    end
  end
  if #slots > 0 then
    gem.getRandomFromTable(slots):setValue(true)
  end
end

local function getStrategyFromSlot(voice)
  if voice > numSlots then
    voice = voice - numSlots
  end
  local slot = strategySlots[voice]
  if slot.enabled then
    return slot.tooltip
  end
end

local function getNotePosition(noteCount, voice)
  local maxIndex = noteCount
  local preferLowerHalf = type(notePosition[voice]) == "nil" or notePosition[voice] > maxIndex
  -- Prefer lower/upper half when resetting, depending on above or below range
  if noteCount > 7 then
    noteCount = math.ceil(noteCount / 2)
  end
  --print("maxIndex, noteCount, preferLowerHalf", maxIndex, noteCount, preferLowerHalf)
  if maxIndex > noteCount then
    if preferLowerHalf then
      -- Lower half
      --print("Resetting in lower half", 1, noteCount)
      return gem.getRandom(1, noteCount)
    else
      -- Upper half
      --print("Resetting in upper half", noteCount, maxIndex)
      return gem.getRandom(noteCount, maxIndex)
    end
  elseif maxIndex > 1 then
    --print("Resetting within full range", maxIndex)
    return gem.getRandom(maxIndex)
  end
  return 1
end

local function getNoteFromStrategy(filteredNotes, voice)
  local strategy = {}
  local strategyText
  -- Try to get strategy from the slot corresponding to the current voice
  if voiceSlotStrategy then
    strategyText = getStrategyFromSlot(voice)
  end
  -- Get strategy from input field if not found in a slot
  if type(strategyText) ~= "string" or string.len(strategyText) == 0 then
    strategyText = strategyInput
  end
  if string.len(strategyText) > 0 then
    for w in string.gmatch(strategyText, "-?%d+") do
      table.insert(strategy, tonumber(w))
    end
    --print("Get strategy from input or slot, voice", #strategy, voice)
  end
  -- Get random strategy from default strategies
  if #strategy == 0 then
    strategy = gem.getRandomFromTable(strategies)
    --print("No strategy found - use random strategy from default strategies")
  end
  -- Reset strategy position if required
  if type(strategyPos[voice]) == "nil" or strategyPos[voice] > #strategy then
    strategyPos[voice] = 1
    --print("Reset strategy position for voice", voice)
    if strategyRestart == 3 or strategyRestart == 4 then
      notePosition[voice] = nil -- Reset counter for note position
      --print("Reset note position for voice due to strategyRestart == 2", voice)
    end
  end
  if type(notePosition[voice]) == "nil" or #strategy == 0 then
    -- Start at a random notePosition
    notePosition[voice] = getNotePosition(#filteredNotes, voice)
    --print("Set random notePosition, voice", notePosition[voice], voice)
    if strategyRestart == 2 then
      strategyPos[voice] = 1
    end
  else
    -- Get next notePosition from strategy
    --print("Increment notePosition, voice", notePosition[voice], voice)
    notePosition[voice] = gem.inc(notePosition[voice], strategy[strategyPos[voice]])
    --print("After increment notePosition, voice", notePosition[voice], voice)
    if notePosition[voice] > #filteredNotes or notePosition[voice] < 1 then
      notePosition[voice] = getNotePosition(#filteredNotes, voice)
      --print("Out of range - set random note position for voice", notePosition[voice], voice)
      if strategyRestart == 2 then
        strategyPos[voice] = 1
        --print("Reset strategy position for voice due to strategyRestart == 2", voice)
      end
    else
      -- Increment strategy pos
      if #strategy > 1 then
        strategyPos[voice] = gem.inc(strategyPos[voice])
        --print("Increment strategy position for voice", strategyPos[voice], voice)
      end
    end
  end
  return filteredNotes[notePosition[voice]]
end

-- Returns the selected notes filtered by overlap range and playing notes
local function getFilteredNotes(voice)
  local noteRangeMin = 1
  local noteRangeMax = #selectedNotes
  local notesPerVoice = 5
  local notesRequiredForRange = voices * notesPerVoice

  --print("BEFORE selectedNotes, voices, voice", #selectedNotes, voices, voice)

  -- Adjust note range min/max for voice overlap, if we have enough available notes
  if #selectedNotes >= notesRequiredForRange then
    local range = #selectedNotes / voices
    --print("range, voices, voice", range, voices, voice)
    local overlapValue = math.ceil(range * (rangeOverlapAmount / 100))
    --print("overlapValue, voice", overlapValue, voice)
    noteRangeMax = math.min(noteRangeMax, ((range * voice) + overlapValue))
    noteRangeMin = math.max(1, (noteRangeMax - range - overlapValue))
    --print("noteRangeMin, noteRangeMax, voice", noteRangeMin, noteRangeMax, voice)
  end

  -- Find the notes, filter for min/max
  local filteredNotes = {}
  for i,v in ipairs(selectedNotes) do
    if i >= math.floor(noteRangeMin) and i <= math.ceil(noteRangeMax) then
      table.insert(filteredNotes, v)
    end
  end

  --print("AFTER notes, voice", #filteredNotes, voice)
  return filteredNotes
end

local function getNote(voice)
  if type(voice) == "nil" then
    voice = 1
  end

  -- Set the voices count
  --if voice > 1 then
    voices = math.max(voice, voices)
  --end

  local filteredNotes = getFilteredNotes(voice)

  if #filteredNotes == 0 then
    return nil
  end

  if #filteredNotes == 1 then
    return filteredNotes[1]
  end

  if gem.getRandomBoolean(strategyPropbability) then
    return getNoteFromStrategy(filteredNotes, voice)
  end

  return gem.getRandomFromTable(filteredNotes)
end

-----------------------------------------------------------------------------------------------------------------
-- Sequencer Panel
-----------------------------------------------------------------------------------------------------------------

widgets.setSection({
  width = 720,
})

local sequencerPanel = widgets.panel({
  height = 30,
})

local sequencerLabel = widgets.label("Strategy Input", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  height = 30,
  editable = true,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 100,
  xOffset = 300,
  yOffset = 5,
  xSpacing = 5,
  ySpacing = 5,
  labelBackgroundColour = "transparent",
})

local voicesLabel = widgets.label("Playing", {
  visible = false,
  textColour = "505050"
})

widgets.setSection({
  x = 510,
})

modular.getForwardWidget()
modular.getChannelWidget()

--------------------------------------------------------------------------------
-- Strategy Panel
--------------------------------------------------------------------------------

widgets.setSection({
  width = 720,
  x = 0,
  y = widgets.posUnder(sequencerPanel),
})

widgets.panel({
  height = 84,
  backgroundColour = "404040"
})

-- Strategy input field
local strategyInputField = widgets.label(getStrategyInputText(gem.getRandomFromTable(strategies)), {
  tooltip = "Strategies are ways to play notes in a scale. Numbers represent steps up or down the scale that is currently selected. Feel free to type your own strategies here.",
  editable = true,
  backgroundColour = "black",
  backgroundColourWhenEditing = "white",
  textColourWhenEditing = "black",
  textColour = "white",
  width = 276,
  height = 20,
  x = 5,
  y = 5,
  changed = function(self) strategyInput = self.text end
})
strategyInputField:changed()

-- Slots
widgets.setSection({
  width = 30,
  height = 20,
  x = strategyInputField.x,
  y = widgets.posUnder(strategyInputField),
  cols = 8,
})

local actions = {"Actions..."}
for j=1,numSlots do
  local strategySlot = widgets.button("" .. j, false, {
    tooltip = unusedStrategySlotDefaultText,
    enabled = false,
  })
  strategySlot.changed = function(self)
    strategyInputField.text = strategySlot.tooltip
    self.value = false
  end
  table.insert(strategySlots, strategySlot)
  table.insert(actions, "Save to " .. j)
end

table.insert(actions, "--- Load ---")
for _,v in ipairs(strategies) do
  table.insert(actions, getStrategyInputText(v))
end

widgets.setSection({
  width = 116,
  height = 20,
  x = strategyInputField.x,
  y = widgets.posUnder(strategyInputField) + 24,
  cols = 6,
})

local voiceSlotStrategyInput = widgets.menu("Play Mode", {"Active Input", "Random Slot", "Voice->Slot"}, {
  tooltip = "Select the strategy to use for note selection. The default is using the strategy displayed in the input.",
  showLabel = false,
  changed = function(self)
    randomSlotStrategy = self.value == 2
    voiceSlotStrategy = self.value == 3
    notePosition = {}
  end
})

local strategyActions = widgets.menu("Actions", actions, {
  tooltip = "Available actions for strategies",
  width = 90,
  showLabel = false,
})

widgets.button("Create", {
  tooltip = "Replace the current strategy with a randomly created strategy.",
  width = 60,
  changed = function()
    local strategy = createStrategy()
    strategyInputField.text = table.concat(strategy, ",")
  end
})

-- Options
widgets.setSection({
  width = 120,
  height = 20,
  x = widgets.posSide(strategyInputField) + 2,
  y = strategyInputField.y,
})

widgets.menu("Strategy", strategyRestart, {"Restart each round", "Out of range", "When finished", "Finished+round"}, {
  tooltip = "Controls when the strategy is restarted",
  changed = function(self) strategyRestart = self.value end
})

widgets.menu("Key", key, notes.getNoteNames(), {
  width = 50,
  changed = function(self)
    key = self.value
    setNotes()
  end
})

local scaleMenu = scales.widget()
scaleMenu.persistent = false -- Avoid running changed function on load, overwriting scaleInput

widgets.label("Scale Definition", {
  textColour = "#d0d0d0"
})

widgets.row()

local scaleInput = scales.inputWidget(scaleDefinition, 120)
scaleInput.x = widgets.posSide(scaleMenu)

widgets.row()

widgets.numBox("Probability", strategyPropbability, {
  tooltip = "Probability that the active playing strategy will be used to select the next note. Otherwise notes are selected by random.",
  unit = Unit.Percent,
  changed = function(self) strategyPropbability = self.value end
})

local noteMinInput = widgets.numBox("Note Range", noteMin, {
  width = 105,
  max = noteMax,
  tooltip = "Lowest note",
  unit = Unit.MidiKey,
})

local noteMaxInput = widgets.numBox("Max", noteMax, {
  min = noteMin,
  width = 30,
  showLabel = false,
  tooltip = "Highest note",
  unit = Unit.MidiKey,
})

widgets.numBox("Overlap", rangeOverlapAmount, {
  tooltip = "Set the overlap range for the voices. 100 = all voices use the full range, 0 = separate ranges. Requires at least 5 notes per voice.",
  width = 90,
  --showLabel = false,
  unit = Unit.Percent,
  changed = function(self) rangeOverlapAmount = self.value end
})

--widgets.row()

widgets.menu("Resolution", resolution, resolutionNames, {
  tooltip = "Set the round duration that is used for strategy restart.",
  width = 60,
  showLabel = false,
  changed = function(self)
    resolution = self.value
  end
})

--------------------------------------------------------------------------------
-- Changed functions for widgets
--------------------------------------------------------------------------------

scaleMenu.changed = function(self)
  scaleInput.text = scales.getTextFromScaleDefinition(scaleDefinitions[self.value])
end

scaleInput.changed = function(self)
  scaleDefinition = scales.getScaleDefinitionFromText(self.text)
  print("#scaleDefinition", #scaleDefinition)
  self.tooltip = scales.getScaleInputTooltip(scaleDefinition)
  setNotes()
end

noteMinInput.changed = function(self)
  noteMaxInput:setRange(self.value, 127)
  noteMin = self.value
  setNotes()
end

noteMaxInput.changed = function(self)
  noteMinInput:setRange(0, self.value)
  noteMax = self.value
  setNotes()
end

strategyActions.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local actionIndex = self.value - 1

  -- Save strategy
  if actionIndex <= #strategySlots then
    if string.len(strategyInputField.text) > 0 then
      strategySlots[actionIndex].tooltip = strategyInputField.text
      strategySlots[actionIndex].enabled = true
    else
      strategySlots[actionIndex].tooltip = unusedStrategySlotDefaultText
      strategySlots[actionIndex].enabled = false
    end
    --print("Strategy saved to slot", strategyInputField.text, actionIndex)
  elseif actionIndex > #strategySlots + 1 then
    strategyInputField.text = self.selectedText
  end

  -- Must be last
  self:setValue(1, false)
end

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function sequenceRunner()
  print("Starting sequenceRunner")
  local round = 1
  while isPlaying do
    if strategyRestart == 1 or strategyRestart == 4 then
      notePosition = {} -- Reset counter for note position
      if strategyRestart == 4 then
        strategyPos = {} -- Reset strategy position
      end
    end
    if randomSlotStrategy then
      setRandomSlot()
    end
    print("Round", round)
    waitBeat(resolutions.getResolution(resolution))
    round = gem.inc(round)
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  run(sequenceRunner)
end

local function stopPlaying()
  print("Stop playing")
  if type(voiceId) == "userdata" then
    releaseVoice(voiceId)
  end
  isPlaying = false
  voiceId = nil
  currentEvent = nil
end

local function flashVoicesLabel()
  voicesLabel.textColour = "303030"
  waitBeat(.125)
  voicesLabel.textColour = "505050"
end

function onInit()
  setNotes()
end

function onNote(e)
  if modular.isTrigger(e) then
    if modular.handleTrigger(e, getNote(e.channel)) then
      voicesLabel.text = "Playing " .. voiceSlotStrategyInput.text
      spawn(flashVoicesLabel)
      voicesLabel.visible = true
      startPlaying()
    end
  else
    postEvent(e)
  end
end

function onRelease(e)
  if modular.isTrigger(e) then
    modular.handleReleaseTrigger(e)
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start then
    startPlaying()
  else
    voices = 1 -- Reset voices when stopping
    voicesLabel.visible = false
    modular.releaseVoices()
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local strategySlotsData = {}
  for _,v in ipairs(strategySlots) do
    table.insert(strategySlotsData, v.tooltip)
  end

  return {sequencerLabel.text, strategyInputField.text, scaleInput.text, strategySlotsData}
end

function onLoad(data)
  sequencerLabel.text = data[1]
  strategyInputField.text = data[2]
  local strategySlotsData = data[4]

  -- Check if we find a scale definition that matches the stored definition
  local scaleIndex = scales.getScaleDefinitionIndex(data[3])
  if type(scaleIndex) == "number" then
    print("onLoad, found scale", scaleIndex)
    scaleMenu.value = scaleIndex
  else
    scaleInput.text = data[3]
    scaleInput:changed()
  end

  for i,v in ipairs(strategySlots) do
    v.tooltip = strategySlotsData[i]
    v.enabled = v.tooltip ~= unusedStrategySlotDefaultText
  end
end
