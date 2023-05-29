-----------------------------------------------------------------------------------------------------------------
-- Note Select Input - Replaces note 0 in incoming note events with a random note from the selected notes
-----------------------------------------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local modular = require "includes.modular"
local notes = require "includes.notes"
local scales = require "includes.scales"

local sequencerPanel = widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Note Select Input", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 90,
  x = 530,
  y = 5,
  xSpacing = 5,
  ySpacing = 5,
})

modular.getForwardWidget()
modular.getChannelWidget()

--------------------------------------------------------------------------------
-- Notes
--------------------------------------------------------------------------------

local octaveOffset
local notesPlaying = {} -- Keep track of playing notes to avoid duplicates
local noteNames = notes.getNoteNames()
local scaleNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local noteListen = nil
local paramsPerNote = {}
local numNotes = 8

local function getScale(scaleIndex, keyIndex)
  local octave = octaveOffset.value + 2 -- Set the start octave for the scale
  --print("getScale: octave", octave)
  local scaleDefinition = scaleDefinitions[scaleIndex]
  local rootNote = (keyIndex - 1) + (octave * 12) -- Root note
  --print("getScale: rootNote", rootNote)
  return scales.createScale(scaleDefinition, rootNote)
end

local function setScale(scaleIndex, keyIndex)
  local scale = getScale(scaleIndex, keyIndex)
  for i,v in ipairs(paramsPerNote) do
    if type(scale[i]) ~= "number" then
      break
    end
    v.noteInput:setValue(scale[i])
  end
end

local function flashNoteLabel(voice)
  local flashDuration = .125
  local textColour = widgets.getColours().widgetTextColour
  paramsPerNote[voice].noteInput.textColour = "efefef"
  waitBeat(flashDuration)
  paramsPerNote[voice].noteInput.textColour = textColour
end

local function doSelectNote(voice)
  return paramsPerNote[voice].mute.value == false and gem.getRandomBoolean(paramsPerNote[voice].noteProbability.value)
end

local function getNote()
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
    noteIndex = gem.getRandomFromTable(selectedNotes)
    note = paramsPerNote[noteIndex].noteInput.value
    maxRounds = maxRounds - 1
  until gem.tableIncludes(notesPlaying, selectedNotes[noteIndex]) == false or maxRounds < 1
  return noteIndex, note
end

widgets.setSection({
  x = 0,
  y = 0,
  xSpacing = 0,
  ySpacing = 0,
})

local notePanel = widgets.panel({
  x = sequencerPanel.x,
  y = widgets.posUnder(sequencerPanel),
  width = sequencerPanel.width,
  height = 110,
})

local noteLabel = widgets.label("Notes", {
  tooltip = "Set the probability that notes will be included when generating new notes",
  alpha = 0.75,
  width = sequencerPanel.width,
  height = 22,
})

widgets.setSection({
  x = 339,
  y = 1,
  xSpacing = 5,
  ySpacing = 0,
})

local generateKey = widgets.menu("GenerateKey", noteNames, {
  tooltip = "Set selected notes from key",
  showLabel = false,
})

local generateScale = widgets.menu("GenerateScale", #scaleNames, scaleNames, {
  tooltip = "Set selected notes from scale",
  hierarchical = true,
  showLabel = false,
})

octaveOffset = widgets.numBox("Octave", 2, {
  tooltip = "Set the octave to start from",
  min = -2,
  max = 6,
  integer = true,
})

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

local templateMenu = widgets.menu("Templates", templates, {
  tooltip = "Select a tool - NOTE: Will change current settings!",
  showLabel = false,
  changed = function(self)
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
        v.noteProbability:setValue(gem.getRandom(100))
      elseif self.selectedText == "Randomize notes" then
        v.noteInput:setValue(gem.getRandom(21, 108))
      end
    end
    -- Must be last
    self:setValue(1, false)
  end
})

generateKey.changed = function(self)
  setScale(generateScale.value, self.value)
end

generateScale.changed = function(self)
  setScale(self.value, generateKey.value)
end

octaveOffset.changed = function(self)
  setScale(generateScale.value, generateKey.value)
end

local offsetX = 5
for i=1,numNotes do
  widgets.setSection({
    width = 80,
    x = offsetX + (90 * (i-1)),
    y = 30,
    xSpacing = 5,
    ySpacing = 0,
  })  
  
  local noteInput = widgets.numBox("Note", (47+i), {
    name = "TriggerNote" .. i,
    tooltip = "The note to trigger",
    showLabel = false,
    unit = Unit.MidiKey,
  })

  local noteProbability = widgets.numBox("Probability", 100, {
    name = "NoteProbability" .. i,
    tooltip = "Probability that note will be played",
    unit = Unit.Percent,
    showLabel = false,
    y = widgets.posUnder(noteInput) + 5,
    x = noteInput.x,
  })

  local listen = widgets.button("Learn", false, {
    name = "Learn" .. i,
    tooltip = "Note learn",
    persistent = false,
    y = widgets.posUnder(noteProbability) + 5,
    x = noteProbability.x,
    width = (noteProbability.width / 2) - 2,
    changed = function(self)
      if self.value then
        noteListen = i
      else
        noteListen = nil
      end
    end  
  })

  local mute = widgets.button("Mute", false, {
    name = "Mute" .. i,
    tooltip = "Mute note",
    persistent = false,
    y = listen.y,
    x = widgets.posSide(listen),
    width = listen.width,
  })

  table.insert(paramsPerNote, {noteInput=noteInput, noteProbability=noteProbability, listen=listen, mute=mute})
end

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

function onNote(e)
  if type(noteListen) == "number" then
    paramsPerNote[noteListen].noteInput:setValue(e.note)
    paramsPerNote[noteListen].listen:setValue(false)
  end
  if modular.isTrigger(e) then
    local noteIndex, note = getNote()
    if modular.handleTrigger(e, note) then
      spawn(flashNoteLabel, noteIndex)
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
  if start == false then
    modular.releaseVoices()
  end
end
