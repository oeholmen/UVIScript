-----------------------------------------------------------------------------------------------------------------
-- Strategy Input - A standard sequencer that listens to incoming events on note 0
-----------------------------------------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local modular = require "includes.modular"
local noteSelector = require "includes.noteSelector"

local channel = 0 -- 0 = Omni
local forward = false
local voices = 1
local strategyPropbability = 100
local rangeOverlap = 25
local selectedNotes = {}
local strategyInput
local strategyRestart = 1
local voiceToStrategySlot = false
local strategyPos = {} -- Holds the position in the selected strategy
local notePosition = {} -- Holds the current note position
local unusedStrategySlotDefaultText = "Unused"
local strategySlots = {}

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

local function createStrategy()
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

local function getStrategyInputText(strategy)
  if type(strategy) == nil or #strategy == 0 then
    return "Randomize"
  end
  return table.concat(strategy, ",")
end

local function getSlotForVoice(voice)
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

local function getNoteFromStrategy(notes, voice)
  local strategy = {}
  -- Get strategy from slot, if button active
  if voiceToStrategySlot then
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
    if string.len(strategyInput) > 0 then
      for w in string.gmatch(strategyInput, "-?%d+") do
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
    if strategyRestart == 3 or strategyRestart == 4 then
      notePosition[voice] = nil -- Reset counter for note position
      --print("Reset note position for voice", voice)
    end
  end
  if type(notePosition[voice]) == "nil" or #strategy == 0 then
    -- Start at a random notePosition
    notePosition[voice] = gem.getRandom(#notes)
    --print("Set random notePosition, voice", notePosition[voice], voice)
    if strategyRestart == 1 then
      strategyPos[voice] = 1
    end
  else
    -- Get next notePosition from strategy
    --print("Set notePosition, strategyPos, voice", notePosition[voice], strategy[strategyPos[voice]], voice)
    notePosition[voice] = notePosition[voice] + strategy[strategyPos[voice]]
    local randomReset = true -- TODO Param?
    if randomReset and (notePosition[voice] > #notes or notePosition[voice] < 1) then
      notePosition[voice] = gem.getRandom(#notes)
      if strategyRestart == 2 then
        strategyPos[voice] = 1
      end
    elseif notePosition[voice] > #notes then
      --print("Reset notePosition >= #notes", notePosition, #notes)
      notePosition[voice] = 1
      if strategyRestart == 2 then
        strategyPos[voice] = 1
      end
    elseif notePosition[voice] < 1 then
      --print("Reset notePosition[voice] <= 1", notePosition[voice])
      notePosition[voice] = #notes
      if strategyRestart == 2 then
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

-- Returns the selected notes filtered by overlap range and playing notes
local function getFilteredNotes(voice)
  --print("BEFORE selectedNotes, voices, voice", #selectedNotes, voices, voice)
  local noteRangeMin = 1
  local noteRangeMax = #selectedNotes
  local notesPerVoice = 5
  local notesRequiredForRange = voices * notesPerVoice

  -- Adjust note range min/max for voice overlap, if we have enough available notes
  if #selectedNotes >= notesRequiredForRange then
    local rangeOverlapAmount = rangeOverlap
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
    if i >= noteRangeMin and i <= noteRangeMax and gem.tableIncludes(noteSelector.getNotesPlaying(), v) == false then
      table.insert(notes, v)
    end
  end

  print("AFTER notes, voice", #notes, voice)
  return notes
end

local function generateNote(voice)
  if type(voice) == "nil" then
    voice = 1
  end

  local notes = getFilteredNotes(voice)

  if #notes == 0 then
    return nil
  end

  if #notes == 1 then
    return notes[1]
  end

  if gem.getRandomBoolean(strategyPropbability) then
    return getNoteFromStrategy(notes, voice)
  end

  return gem.getRandomFromTable(notes)
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
  xOffset = 510,
  yOffset = 5,
  xSpacing = 5,
  ySpacing = 5,
  labelBackgroundColour = "transparent",
})

widgets.button("Forward", forward, {
  tooltip = "Forward triggers (note=0 events) to the next processor",
  changed = function(self) forward = self.value end,
})

widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to triggers (note=0 events) on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

--------------------------------------------------------------------------------
-- Strategy Panel
--------------------------------------------------------------------------------

widgets.setSection({
  width = 720,
  x = 0,
  y = widgets.posUnder(sequencerPanel),
})

local strategyPanel = widgets.panel({
  height = 54,
  backgroundColour = "404040"
})

widgets.setSection({
  width = 260,
  height = 45,
  x = 5,
  y = 5,
})

local strategyInputField = widgets.label(getStrategyInputText(gem.getRandomFromTable(strategies)), {
  tooltip = "Strategies are ways to play scales. Numbers represent steps up or down the scale that is currently playing. Feel free to type your own strategies here.",
  editable = true,
  fontSize = 30,
  backgroundColour = "black",
  backgroundColourWhenEditing = "white",
  textColourWhenEditing = "black",
  textColour = "white",
  changed = function(self) strategyInput = self.text end
})
strategyInputField:changed()

widgets.setSection({
  width = 120,
  height = 20,
  x = widgets.posSide(strategyInputField) + 5,
})

local createButton = widgets.button("Create", {
  changed = function()
    local strategy = createStrategy()
    strategyInputField.text = table.concat(strategy, ",")
  end
})

widgets.setSection({
  --width = 120,
  x = createButton.x,
  y = widgets.posUnder(createButton),
})

widgets.menu("Strategy Restart", strategyRestart, {"Restart each round", "Out of range", "When finished", "Finished+round"}, {
  showLabel = false,
  width = 120,
  changed = function(self) strategyRestart = self.value end
})

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

widgets.setSection({
  width = 720,
  height = 160,
  x = 0,
  y = widgets.posUnder(strategyPanel),
})

local notePanel = widgets.panel({
  backgroundColour = "707070"
})

widgets.setSection({
  width = 60,
  height = 20,
  x = 5,
  y = 5,
})

local noteLabel = widgets.label("Notes", {
  fontSize = 15,
})

widgets.setSection({
  width = 90,
  x = notePanel.width - 290,
})

widgets.button("Clear notes", {
  changed = function()
    for _,v in ipairs(noteSelector.getNoteInputs()) do
      v:setValue(false)
    end
  end
})

widgets.button("All notes", {
  changed = function()
    for _,v in ipairs(noteSelector.getNoteInputs()) do
      v:setValue(true)
    end
  end
})

widgets.button("Randomize notes", {
  changed = function()
    for _,v in ipairs(noteSelector.getNoteInputs()) do
      v:setValue(gem.getRandomBoolean())
    end
  end
})

noteSelector.createNoteAndOctaveSelector(notePanel, widgets.getColours(), noteLabel, 20, 10)

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function getNote()
  -- Refresh selected notes
  selectedNotes = noteSelector.getSelectedNotes(true)
  return generateNote()
end

function onNote(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    modular.handleTrigger(e, getNote())
  else
    postEvent(e)
  end
end

function onRelease(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    modular.handleReleaseTrigger(e)
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start == false then
    modular.releaseVoices()
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

  return {sequencerLabel.text, strategyInputField.text, strategySlotsData}
end

function onLoad(data)
  sequencerLabel.text = data[1]
  strategyInputField.text = data[2]
  local strategySlotsData = data[3]

  for i,v in ipairs(strategySlots) do
    v.tooltip = strategySlotsData[i]
    v.enabled = v.tooltip ~= unusedStrategySlotDefaultText
  end
end
