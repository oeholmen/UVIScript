-----------------------------------------------------------------------------------
-- Generative Chorder - Listens for incoming note events (rythm) on note number 0
-----------------------------------------------------------------------------------

local gem = require "includes.common"
local notes = require "includes.notes"
local scales = require "includes.scales"
local noteSelector = require "includes.noteSelector"

local backgroundColour = "6c6c6c" -- Light or Dark
local menuBackgroundColour = "01011F"
local widgetBackgroundColour = menuBackgroundColour -- Dark
local widgetTextColour = "9f02ACFE" -- Light
local labelTextColour = "AEFEFF" -- Light
local menuArrowColour = "66" .. labelTextColour
local labelBackgoundColour = "111D5E"
local menuOutlineColour = "5f" .. widgetTextColour
local sliderColour = "5FB5FF"
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"

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

local paramsPerPart = {}

-- *** NOTE *** The chord definitions use steps in the selected scale, not semitones.
-- 2 means two steps up the scale: C-E for a C major scale. A-C for an A minor scale.
local chordDefinitions = {
  {2,2,3}, -- Builds triads
  {2,2,2,1}, -- Builds 7th chords
  {3,1,3}, -- Builds supended chords
  {2,2,1,2}, -- Builds 6th chords
  {2,2,2,2,-1}, -- Builds 7th and 9th chords depending on polyphony
  {1,1,2,2,1}, -- Builds (close) 7th and 9th chords
  {4,3}, -- Builds open chords (no3)
  {1,2,1,2,1}, -- Builds supended chords including 7th and 9ths
}

local noteDisplay = {} -- Holds the widgets that displays the notes being played
local maxVoices = 16 -- Max number of oplyphonic voices
local noteNumberToNoteName = notes.getNoteMapping()

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Scale and note functions
--------------------------------------------------------------------------------

-- Use the selected chord definition to find the index for the next note in the chord
local function getNextScaleIndex(note, scale, chordDefinition, inversionIndex)
  local index = gem.getIndexFromValue(note, scale)
  print("getNextScaleIndex #chordDefinition/inversionIndex", #chordDefinition, inversionIndex)
  local increment = chordDefinition[inversionIndex]
  if type(index) == "nil" then
    index = 0
    print("!!!Note not found in scale!!!")
  end
  return index + increment
end

local function notesInclude(notesTable, note)
  for _,v in pairs(notesTable) do
    if v.note == note then
      --print("Note already included", note)
      return true
    end
  end
  return false
end

local function hasNoteWithinMonoLimit(notesTable, partPos)
  local monoLimit = paramsPerPart[partPos].monoLimit.value
  for _,v in pairs(notesTable) do
    if v.note <= monoLimit then
      return true
    end
  end
  return false
end

local function isRootNote(note, partPos)
  -- Find root note index
  local rootIndex = noteSelector.getKey()
  local noteIndex = note + 1 -- note index is 1 higher than note number
  return noteNumberToNoteName[rootIndex] == noteNumberToNoteName[noteIndex]
end

local function createChordDefinition(part)
  local maxSteps = 4 -- Max steps
  local maxLength = paramsPerPart[part].polyphony.value -- Max length depends on polyphony
  local definition = {} -- Table to hold definition
  local ln = gem.getRandom(maxLength) -- Set a random length for the definition
  for i=1, ln do
    local steps = gem.getRandom(maxSteps)
    table.insert(definition, steps)
    print("Add steps to definition", steps)
  end
  return definition
end

local function getChordInputText(definition)
  if #definition == 0 then
    return "Randomize"
  end
  return table.concat(definition, ",")
end

--------------------------------------------------------------------------------
-- Panels
--------------------------------------------------------------------------------

local tableWidth = 700

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = tableWidth
sequencerPanel.height = 200

local notePanel = Panel("Notes")
notePanel.backgroundColour = backgroundColour
notePanel.x = sequencerPanel.x
notePanel.y = sequencerPanel.y + sequencerPanel.height + 5
notePanel.width = tableWidth
notePanel.height = 150

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local label = sequencerPanel:Label("Label")
label.text = "Chorder Input"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {120,25}

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local channels = {"Omni"}
for j=1,16 do
  table.insert(channels, "" .. j)
end

local channelInput = sequencerPanel:Menu("ChannelInput", channels)
channelInput.tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through"
channelInput.arrowColour = menuArrowColour
channelInput.showLabel = false
channelInput.backgroundColour = menuBackgroundColour
channelInput.textColour = widgetTextColour
channelInput.size = {90,22}
channelInput.x = sequencerPanel.width - channelInput.width - 5
channelInput.y = 5

local chordProbabilityLabel = sequencerPanel:Label("ChordProbabilityProbabilityLabel")
chordProbabilityLabel.text = "Chords"
chordProbabilityLabel.tooltip = "Choose the probability that chords will be included when harmonizing"

local spreadProbabilityLabel = sequencerPanel:Label("SpreadProbabilityLabel")
spreadProbabilityLabel.text = "Note Spread"
spreadProbabilityLabel.tooltip = "Set note spread probability"

local inversionProbabilityLabel = sequencerPanel:Label("InversionProbabilityLabel")
inversionProbabilityLabel.text = "Chord Inversions"
inversionProbabilityLabel.tooltip = "Choose the probability that inversions will be used when harmonizing (root position is always included)"

-- Add params that are to be editable per part
--for i=1,1 do
local i = 1
local chords = {}
local spreads = {}
local inversions = {}

local generatePolyphonyPart = sequencerPanel:NumBox("GeneratePolyphony" .. i, 4, 1, maxVoices, true)
generatePolyphonyPart.displayName = "Polyphony"
generatePolyphonyPart.tooltip = "How many notes are played at once"
generatePolyphonyPart.backgroundColour = menuBackgroundColour
generatePolyphonyPart.textColour = widgetTextColour
generatePolyphonyPart.visible = false
generatePolyphonyPart.width = 108
--generatePolyphonyPart.x = 10
--generatePolyphonyPart.y = 10
generatePolyphonyPart.changed = function(self)
  for i,v in ipairs(noteDisplay) do
    v.enabled = maxVoices - self.value <= maxVoices - i
  end
end

local baseNoteRandomization = sequencerPanel:NumBox("BaseNoteProbability" .. i, 75, 0, 100, true)
baseNoteRandomization.displayName = "Base Chord"
baseNoteRandomization.tooltip = "Probability that first chord in the part will be the root chord"
baseNoteRandomization.unit = Unit.Percent
baseNoteRandomization.width = 108
--baseNoteRandomization.x = generateKeyPart.x
--baseNoteRandomization.y = generateKeyPart.y + generateKeyPart.height + 5
baseNoteRandomization.backgroundColour = menuBackgroundColour
baseNoteRandomization.textColour = widgetTextColour

local monoLimit = sequencerPanel:NumBox("MonoLimit" .. i, 48, 0, 64, true)
monoLimit.unit = Unit.MidiKey
monoLimit.showPopupDisplay = true
monoLimit.showLabel = true
monoLimit.backgroundColour = menuBackgroundColour
monoLimit.textColour = widgetTextColour
monoLimit.displayName = "Mono Limit"
monoLimit.tooltip = "Below this note there will only be played one note (polyphony=1)"
--monoLimit.x = generateKeyPart.x + generateKeyPart.width + 10
--monoLimit.y = generateKeyPart.y
monoLimit.width = 108

local harmonizationPropbability = sequencerPanel:NumBox("HarmonizationPropbability" .. i, 100, 0, 100, true)
harmonizationPropbability.displayName = "Harmonize"
harmonizationPropbability.tooltip = "When harmonizing, we get notes from the currently playing chord. Otherwise notes are selected from the current scale."
harmonizationPropbability.unit = Unit.Percent
harmonizationPropbability.height = 20
harmonizationPropbability.width = 108
--harmonizationPropbability.x = monoLimit.x + monoLimit.width + 10
--harmonizationPropbability.y = monoLimit.y
harmonizationPropbability.backgroundColour = menuBackgroundColour
harmonizationPropbability.textColour = widgetTextColour

local voiceLabelBgColour = "9F9F9F"
local voiceLabelTextColour = "202020"
local voiceRowCount = 2
local voiceLabelY = 150

if i == 1 then
  for j=1,maxVoices do
    local voiceLabel = sequencerPanel:Label("VoiceLabel" .. i .. j)
    voiceLabel.persistent = false
    voiceLabel.text = "Voice " .. j
    voiceLabel.tooltip = "Settings for voice " .. j
    voiceLabel.backgroundColour = voiceLabelBgColour
    voiceLabel.textColour = voiceLabelTextColour
    voiceLabel.width = tableWidth / maxVoices
    voiceLabel.height = 20
    voiceLabel.x = ((j - 1) * (voiceLabel.width + 1)) - 2
    voiceLabel.y = voiceLabelY
  end
end

if i == 1 then
  for j=1,maxVoices do
    local noteInput = sequencerPanel:Label("NoteInput" .. j)
    noteInput.enabled = false
    noteInput.persistent = false
    noteInput.tooltip = "Displays the note played by voice " .. j
    noteInput.text = "-"
    noteInput.backgroundColour = menuBackgroundColour
    noteInput.textColour = labelTextColour
    noteInput.width = tableWidth / maxVoices
    noteInput.height = 20
    noteInput.x = ((j - 1) * (noteInput.width + 1)) - 2
    noteInput.y = voiceLabelY + 22
    table.insert(noteDisplay, noteInput)
  end
end

chordProbabilityLabel.width = 108
--chordProbabilityLabel.x = 0
--chordProbabilityLabel.y = 5

local chordDefinitionInput = sequencerPanel:Label("ChordInput" .. i)
chordDefinitionInput.text = getChordInputText(chordDefinitions[1])
chordDefinitionInput.tooltip = "Chord definitions build chords. Numbers represent steps up or down the scale that is currently selected. Feel free to type your own chord definitions here, or select from the menu."
chordDefinitionInput.editable = true
chordDefinitionInput.backgroundColour = menuBackgroundColour
chordDefinitionInput.backgroundColourWhenEditing = "black"
chordDefinitionInput.textColour = labelTextColour
chordDefinitionInput.textColourWhenEditing = "white"
chordDefinitionInput.width = 240
chordDefinitionInput.height = 45
chordDefinitionInput.fontSize = 30
--chordDefinitionInput.x = generatePolyphonyPart.x
--chordDefinitionInput.y = chordProbabilityLabel.y + chordProbabilityLabel.height + 5

local autoChordButton = sequencerPanel:OnOffButton("AutoChordButton" .. i, false)
autoChordButton.displayName = "Auto"
autoChordButton.tooltip = "Default chord definitions are alternated by random while playing."
autoChordButton.backgroundColourOff = backgroundColourOff
autoChordButton.backgroundColourOn = backgroundColourOn
autoChordButton.textColourOff = textColourOff
autoChordButton.textColourOn = textColourOn
autoChordButton.width = 60
--autoChordButton.x = baseNoteRandomization.x
--autoChordButton.y = chordDefinitionInput.y

local randomChordButton = sequencerPanel:OnOffButton("RandomChordButton" .. i, false)
randomChordButton.displayName = "Random"
randomChordButton.tooltip = "Chord definitions are created by random while playing."
randomChordButton.backgroundColourOff = backgroundColourOff
randomChordButton.backgroundColourOn = backgroundColourOn
randomChordButton.textColourOff = textColourOff
randomChordButton.textColourOn = textColourOn
randomChordButton.width = autoChordButton.width
--randomChordButton.x = autoChordButton.x
--randomChordButton.y = autoChordButton.y + autoChordButton.height + 5

local slotChordButton = sequencerPanel:OnOffButton("SlotChordButton" .. i, false)
slotChordButton.displayName = "Slots"
slotChordButton.tooltip = "Chord definitions are selected by random from the slots."
slotChordButton.backgroundColourOff = backgroundColourOff
slotChordButton.backgroundColourOn = backgroundColourOn
slotChordButton.textColourOff = textColourOff
slotChordButton.textColourOn = textColourOn
slotChordButton.width = randomChordButton.width
--slotChordButton.x = randomChordButton.x
--slotChordButton.y = randomChordButton.y + randomChordButton.height + 5

local createChordDefinitionButton = sequencerPanel:Button("CreateDefButton" .. i)
createChordDefinitionButton.displayName = "Create"
createChordDefinitionButton.tooltip = "Create a random chord definition."
createChordDefinitionButton.persistent = false
createChordDefinitionButton.width = 60
--createChordDefinitionButton.x = chordProbabilityLabel.x
--createChordDefinitionButton.y = chordProbabilityLabel.y + chordProbabilityLabel.height + 5

local saveActions = {"Save to..."}
local chordDefinitionSlots = {}
for j=1,8 do
  local definitionSlot = sequencerPanel:OnOffButton("ChordSlot" .. i .. j)
  definitionSlot.backgroundColourOff = backgroundColourOff
  definitionSlot.backgroundColourOn = backgroundColourOn
  definitionSlot.textColourOff = textColourOff
  definitionSlot.textColourOn = textColourOn
  definitionSlot.displayName = "" .. j
  definitionSlot.enabled = false
  definitionSlot.tooltip = "Unused"
  definitionSlot.height = 20
  definitionSlot.width = 27
  definitionSlot.x = chordDefinitionInput.x + ((j-1) * (definitionSlot.width+2))
  definitionSlot.y = chordDefinitionInput.y + chordDefinitionInput.height + 5
  definitionSlot.changed = function(self)
    chordDefinitionInput.text = definitionSlot.tooltip
    self.value = false
  end
  table.insert(chordDefinitionSlots, definitionSlot)
  table.insert(saveActions, "Slot " .. j)
end

local loadActions = {"Load..."}
for _,v in ipairs(chordDefinitions) do
  table.insert(loadActions, getChordInputText(v))
end

local loadChordDefinition = sequencerPanel:Menu("LoadChordDefinition" .. i, loadActions)
loadChordDefinition.tooltip = "Load a chord definition"
loadChordDefinition.showLabel = false
loadChordDefinition.height = 20
loadChordDefinition.width = 108
--loadChordDefinition.x = createChordDefinitionButton.x
--loadChordDefinition.y = createChordDefinitionButton.y + createChordDefinitionButton.height + 5
loadChordDefinition.backgroundColour = menuBackgroundColour
loadChordDefinition.textColour = widgetTextColour
loadChordDefinition.arrowColour = menuArrowColour
loadChordDefinition.outlineColour = menuOutlineColour
loadChordDefinition.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local actionIndex = self.value - 1
  chordDefinitionInput.text = self.selectedText

  -- Must be last
  self.selected = 1
end

local saveChordDefinition = sequencerPanel:Menu("SaveChordDefinition" .. i, saveActions)
saveChordDefinition.tooltip = "Save the current chord definition to the selected slot"
saveChordDefinition.showLabel = false
saveChordDefinition.height = 20
saveChordDefinition.width = 108
--saveChordDefinition.x = loadChordDefinition.x
--saveChordDefinition.y = loadChordDefinition.y + loadChordDefinition.height + 5
saveChordDefinition.backgroundColour = menuBackgroundColour
saveChordDefinition.textColour = widgetTextColour
saveChordDefinition.arrowColour = menuArrowColour
saveChordDefinition.outlineColour = menuOutlineColour
saveChordDefinition.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local actionIndex = self.value - 1

  -- Save chord definition
  if string.len(chordDefinitionInput.text) > 0 then
    chordDefinitionSlots[actionIndex].tooltip = chordDefinitionInput.text
    chordDefinitionSlots[actionIndex].enabled = true
  else
    chordDefinitionSlots[actionIndex].tooltip = "Unused"
    chordDefinitionSlots[actionIndex].enabled = false
  end
  print("Chord definition saved to slot", chordDefinitionInput.text, actionIndex)

  -- Must be last
  self.selected = 1
end

autoChordButton.changed = function(self)
  slotChordButton:setValue(false, false)
  randomChordButton:setValue(false, false)
  chordDefinitionInput.enabled = self.value == false
  createChordDefinitionButton.enabled = self.value == false
end

randomChordButton.changed = function(self)
  autoChordButton:setValue(false, false)
  slotChordButton:setValue(false, false)
  chordDefinitionInput.enabled = self.value == false
  createChordDefinitionButton.enabled = self.value == false
end

slotChordButton.changed = function(self)
  autoChordButton:setValue(false, false)
  randomChordButton:setValue(false, false)
  chordDefinitionInput.enabled = true
  createChordDefinitionButton.enabled = true
end

createChordDefinitionButton.changed = function()
  chordDefinitionInput.text = getChordInputText(createChordDefinition(i))
end

--[[ spreadProbabilityLabel.x = monoLimit.x
spreadProbabilityLabel.y = chordProbabilityLabel.y
spreadProbabilityLabel.width = 108

inversionProbabilityLabel.x = 10
inversionProbabilityLabel.y = chordProbabilityLabel.y
inversionProbabilityLabel.width = 108 ]]

-- Note Spread
local perRow = 1
local columnCount = 0
local rowCount = 1
for spread=1,3 do
  local spreadProbability = sequencerPanel:NumBox("SpreadProbability" .. i .. spread, 100, 0, 100, true)
  if spread == 1 then
    spreadProbability.displayName = "Close"
    spreadProbability.tooltip = "Set the probability that close chords will be included"
  elseif spread == 2 then
    spreadProbability.displayName = "Medium"
    spreadProbability.tooltip = "Set the probability that medium wide chords will be included"
  else
    spreadProbability.displayName = "Wide"
    spreadProbability.tooltip = "Set the probability that wide chords will be included"
  end
  spreadProbability.unit = Unit.Percent
  spreadProbability.height = 20
  spreadProbability.width = 108
  spreadProbability.x = spreadProbabilityLabel.x + (columnCount * (spreadProbability.width + 10))
  spreadProbability.y = spreadProbabilityLabel.y + ((spreadProbability.height + 5) * rowCount)
  spreadProbability.backgroundColour = menuBackgroundColour
  spreadProbability.textColour = widgetTextColour
  table.insert(spreads, spreadProbability)
  columnCount = columnCount + 1
  if spread % perRow == 0 then
    rowCount = rowCount + 1
    columnCount = 0
  end
end

-- Inversions
local perRow = 1
local columnCount = 0
local rowCount = 1
for inversion=1,3 do
  local inversionProbability = sequencerPanel:NumBox("InversionsProbability" .. i .. inversion, 100, 0, 100, true)
  inversionProbability.displayName = "Inv " .. inversion
  inversionProbability.tooltip = "Probability that inversion " .. inversion .. " will be included"
  inversionProbability.unit = Unit.Percent
  inversionProbability.height = 20
  inversionProbability.width = 108
  inversionProbability.x = inversionProbabilityLabel.x + (columnCount * (inversionProbability.width + 10))
  inversionProbability.y = inversionProbabilityLabel.y + ((inversionProbability.height + 5) * rowCount)
  inversionProbability.backgroundColour = menuBackgroundColour
  inversionProbability.textColour = widgetTextColour
  table.insert(inversions, inversionProbability)
  columnCount = columnCount + 1
  if inversion % perRow == 0 then
    rowCount = rowCount + 1
    columnCount = 0
  end
end

table.insert(paramsPerPart, {chordDefinitionSlots=chordDefinitionSlots,createChordDefinitionButton=createChordDefinitionButton,loadChordDefinition=loadChordDefinition,saveChordDefinition=saveChordDefinition,chordDefinitionInput=chordDefinitionInput,autoChordButton=autoChordButton,randomChordButton=randomChordButton,slotChordButton=slotChordButton,inversions=inversions,spreads=spreads,chords=chords,baseNoteRandomization=baseNoteRandomization,polyphony=generatePolyphonyPart,harmonizationPropbability=harmonizationPropbability,monoLimit=monoLimit})

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local noteLabel = notePanel:Label("NoteLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Set the probability that notes will be included when generating new notes"
noteLabel.alpha = 0.75
noteLabel.fontSize = 15
noteLabel.width = 50
noteLabel.height = 20
noteLabel.y = 0

local clearNotes = notePanel:Button("ClearNotes")
clearNotes.displayName = "Clear notes"
clearNotes.tooltip = "Deselect all notes"
clearNotes.persistent = false
clearNotes.height = noteLabel.height
clearNotes.width = 90
clearNotes.x = notePanel.width - (clearNotes.width * 3) - 30
clearNotes.y = noteLabel.y
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
addNotes.y = noteLabel.y
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
randomizeNotes.y = noteLabel.y
randomizeNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(gem.getRandomBoolean())
  end
end

noteSelector.createNoteAndOctaveSelector(notePanel, colours, noteLabel)

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

local function getNotes()
  local currentPartPosition = 1 -- Holds the currently playing part
  local heldNoteIndex = 0
  local scale = {} -- The scale the generator can choose from.
  local inversionIndex = 0
  local notesToPlay = {} -- Ensure notes are reset when seqencer starts

  -- Number of simultainious notes are set by polyphony
  scale = noteSelector.getSelectedNotes()
  fullScale = noteSelector.getActiveNotes()
  local polyphony = paramsPerPart[currentPartPosition].polyphony.value
  local minNote = scale[1]
  local maxNote = scale[#scale]

  inversionIndex = 0 -- Reset counter for inversion progress
  local autoChord = paramsPerPart[currentPartPosition].autoChordButton.value
  local randomChord = paramsPerPart[currentPartPosition].randomChordButton.value
  local slotChord = paramsPerPart[currentPartPosition].slotChordButton.value
  if autoChord == true then
    local index = gem.getRandom(#chordDefinitions)
    paramsPerPart[currentPartPosition].chordDefinitionInput.text = getChordInputText(chordDefinitions[index])
  end
  if randomChord == true then
    paramsPerPart[currentPartPosition].chordDefinitionInput.text = getChordInputText(createChordDefinition(currentPartPosition))
  end
  if slotChord == true then
    local chordDefinitionSlots = {}
    for _,v in ipairs(paramsPerPart[currentPartPosition].chordDefinitionSlots) do
      if v.enabled == true then
        table.insert(chordDefinitionSlots, v)
      end
    end
    if #chordDefinitionSlots > 0 then
      chordDefinitionSlots[math.ceil(gem.getRandom(#chordDefinitionSlots))]:setValue(true)
    end
  end

  -- Find inversions to include
  local inversions = paramsPerPart[currentPartPosition].inversions
  local activeInversions = {0} -- Always add root
  for i,v in ipairs(inversions) do
    if gem.getRandomBoolean(v.value) == true then
      table.insert(activeInversions, i)
    end
  end

  if #activeInversions > 0 then
    -- Get a chord def index from the active definitions
    inversionIndex = gem.getRandomFromTable(activeInversions)
    print("Chord inversion selected by random/#activeInversions", inversionIndex, #activeInversions)
  end

  -- Find spreads to include
  local selectedSpread = 2 -- Reset to default
  local spreads = paramsPerPart[currentPartPosition].spreads
  local activeSpreads = {}
  for i,v in ipairs(spreads) do
    if gem.getRandomBoolean(v.value) == true then
      table.insert(activeSpreads, i)
    end
  end

  if #activeSpreads > 0 then
    -- Get a chord def index from the active definitions
    if #activeSpreads > 1 then
      selectedSpread = activeSpreads[gem.getRandom(#activeSpreads)]
    else
      selectedSpread = activeSpreads[1]
    end
    print("Chord spread selected by random: selectedSpread/#activeSpreads", selectedSpread, #activeSpreads)
  end

  --------------------------------------------------------------------------------
  -- Note functions
  --------------------------------------------------------------------------------

  -- Main function for getting note to play
  local function getNoteToPlay(voice, chordDefinition)
    -- Note generator function
    local function generateNote()
      local note = nil
      local baseNoteRandomization = paramsPerPart[currentPartPosition].baseNoteRandomization.value
      local monoLimit = paramsPerPart[currentPartPosition].monoLimit.value
      local baseMin = minNote
      local baseMax = maxNote

      if #scale == 0 then
        return note
      end

      if #scale == 1 then
        return scale[1]
      end

      if hasNoteWithinMonoLimit(notesToPlay, currentPartPosition) == true then
        -- Ensure we only have one note below the mono limit
        baseMin = monoLimit
        print("Adjust baseMin to mono limit", baseMin)
      elseif monoLimit > baseMin then
        -- Ensure we have a note within the mono limit
        baseMax = monoLimit
        print("Adjust baseMax to mono limit", baseMax)
      end

      local function getBaseNote()
        local baseNote = minNote -- Start from the lowest note
        if gem.getRandomBoolean(baseNoteRandomization) then
          while isRootNote(baseNote, currentPartPosition) == false and baseNote <= baseMax do
            baseNote = baseNote + 1 -- increment note until we hit the base note
          end
          print("Get root note: note/baseMin/baseMax", baseNote, baseMin, baseMax)
        else
          local noteRange = baseMax - baseMin
          if monoLimit <= baseMin then
            -- If there is no mono limit, we ajust the note range by polyphony to get a base note range
            noteRange = math.max(12, math.ceil(noteRange / polyphony))
            print("Calculate range for base note baseMin/baseMax/noteRange", baseMin, baseMax, noteRange)
          end
          baseNote = baseNote + gem.getRandom(noteRange) - 1
        end

        return notes.getNoteAccordingToScale(scale, baseNote)
      end

      -- The note on the first voice is the base note
      if voice == 1 then
        note = getBaseNote()
      end

      local harmonizationPropbability = paramsPerPart[currentPartPosition].harmonizationPropbability.value
      if type(note) == "nil" and gem.getRandomBoolean(harmonizationPropbability) == true then
        local startingNotes = {}
        for _,v in ipairs(notesToPlay) do
          table.insert(startingNotes, v.note)
          print("Insert into startingNotes", v.note)
        end
        if #startingNotes > 0 then
          -- If we have notes added, use them as the basis for the next note
          print("startingNotes", #startingNotes)
          local prevNote = startingNotes[#startingNotes]
          print("Found prevNote", prevNote)
          -- Increment inversion index
          inversionIndex = inversionIndex + 1
          if inversionIndex > #chordDefinition then
            inversionIndex = 1
          end
          local scaleIndex = getNextScaleIndex(prevNote, fullScale, chordDefinition, inversionIndex)
          note = fullScale[scaleIndex]
          if type(note) == "number" then
            note = notes.transpose(note, baseMin, baseMax)
            local noteRange = baseMax - prevNote
            local octaveFactor = 12-- / (selectedSpread / 2)
            local octaveRange = math.floor(noteRange / octaveFactor)
            local notesLeft = polyphony - #notesToPlay
            local octave = 0
            local octaveProbability = 50
            local negOctProbability = 50
            if selectedSpread == 1 then
              octaveProbability = 15
              negOctProbability = 75
            elseif selectedSpread == 3 then
              octaveProbability = 75
              negOctProbability = 15
            end
            if gem.getRandomBoolean(octaveProbability) then
              octave = math.floor(octaveRange / notesLeft)
            end
            print("Check octave/note/baseMax/negOctProbability", octave, note, baseMax, negOctProbability)
            if octave > 0 and octave < 3 and note > baseMax / 2 and gem.getRandomBoolean(negOctProbability) then
              octave = -octave
              print("Negative octave", octave)
            end
            local octaveOffset = octave * 12
            print("Calculate octave adjustment - noteRange/octaveRange/notesLeft/octave", noteRange, octaveRange, notesLeft, octave)
            if octaveOffset > 0 and note + octaveOffset <= baseMax then
              note = note + octaveOffset
              print("Octave adjusted octave/octaveOffset/note", octave, octaveOffset, note)
            end
            print("Found note from prev note - note, prevNote", note, prevNote)
          end
        end
      end

      -- Get random note from scale
      if type(note) == "nil" then
        note = notes.getNoteAccordingToScale(scale, gem.getRandom(baseMin, baseMax))
      end

      return note
    end

    -- Get notes for each node in the tree
    local note = generateNote()
    local noteToPlay = {
      note = note,
      voice = voice,
    }

    return noteToPlay
  end

  -- Get chord definition from input
  local chordDefinition = {}
  local input = paramsPerPart[currentPartPosition].chordDefinitionInput
  if string.len(input.text) > 0 then
    for w in string.gmatch(input.text, "-?%d+") do
      table.insert(chordDefinition, w)
      print("Add to chordDefinition", w)
    end
    print("Get chordDefinition from input", #chordDefinition)
  end

  -- Create a random chord definition if empty
  if #chordDefinition == 0 then
    chordDefinition = createChordDefinition(currentPartPosition)
  end
  
  -- Add notes to play
  local voice = 1
  local roundCounter = 0
  local maxRounds = polyphony * 2
  local monoLimit = paramsPerPart[currentPartPosition].monoLimit.value
  while voice <= polyphony and roundCounter < maxRounds do
    local noteToPlay = getNoteToPlay(voice, chordDefinition)
    if type(noteToPlay.note) == "number" and notesInclude(notesToPlay, noteToPlay.note) == false then
      table.insert(notesToPlay, noteToPlay)
      print("Insert note", noteToPlay.note)
      noteDisplay[voice].text = noteNumberToNoteName[noteToPlay.note + 1] .. " (" .. noteToPlay.note .. ")"
      voice = voice + 1
    end
    roundCounter = gem.inc(roundCounter)
    print("Searching for notes roundCounter", roundCounter)
  end
  print("Notes ready to play ", #notesToPlay)

  return notesToPlay
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

local activeVoices = {}

local function noteIsPlaying(note)
  for _,v in ipairs(activeVoices) do
    if v.event.note == note then
      return true
    end
  end
  return false
end

local function releaseVoices()
  for i,v in ipairs(activeVoices) do
    releaseVoice(v.id)
    print("Release active voice on channel", v.event.channel)
  end
  activeVoices = {}
end

local function isTrigger(e)
  local channel = channelInput.value - 1
  local isListeningForEvent = channel == 0 or channel == e.channel
  local isTrigger = e.note == 0 -- Note 0 is used as trigger
  return isTrigger and isListeningForEvent
end

local function handleTrigger(e)
  local notesForPlaying = getNotes()
  if #notesForPlaying > 0 then
    for _,v in ipairs(notesForPlaying) do
      if noteIsPlaying(v.note) == false then
        local id = playNote(v.note, e.velocity)
        e.note = v.note
        table.insert(activeVoices, {id=id,event=e,node=v})
      end
    end
  end
end

local function handleReleaseTrigger(e)
  for i,v in ipairs(activeVoices) do
    if v.event.channel == e.channel then
      releaseVoice(v.id)
      table.remove(activeVoices, i)
      print("Release active voice on channel", v.event.channel)
    end
  end
end

function onNote(e)
  if isTrigger(e) then
    handleTrigger(e)
  else
    postEvent(e)
  end
end

function onRelease(e)
  if isTrigger(e) then
    handleReleaseTrigger(e)
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start == false then
    releaseVoices()
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local chordDefinitionInputData = {}
  local chordDefinitionSlotsData = {}
  local i = 1

  table.insert(chordDefinitionInputData, paramsPerPart[i].chordDefinitionInput.text)
  for _,v in ipairs(paramsPerPart[i].chordDefinitionSlots) do
    table.insert(chordDefinitionSlotsData, v.tooltip)
  end

  return {chordDefinitionInputData, chordDefinitionSlotsData}
end

function onLoad(data)
  local chordDefinitionInputData = data[1]
  local chordDefinitionSlotsData = data[2]
  local dataCounter = 1

  for i,v in ipairs(chordDefinitionInputData) do
    paramsPerPart[i].chordDefinitionInput.text = chordDefinitionInputData[i]
    for _,v in ipairs(paramsPerPart[i].chordDefinitionSlots) do
      v.tooltip = chordDefinitionSlotsData[dataCounter]
      v.enabled = v.tooltip ~= "Unused"
      dataCounter = dataCounter + 1
    end
  end
end
