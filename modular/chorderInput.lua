-----------------------------------------------------------------------------------
-- Generative Chorder - Listens for incoming note events (rythm) on note number 0
-----------------------------------------------------------------------------------

local gem = require "includes.common"
local notes = require "includes.notes"
local scales = require "includes.scales"
local modular = require "includes.modular"
local widgets = require "includes.widgets"

local backgroundColour = "404040" -- Light or Dark
local panelBackgroundColour = "505050" -- Light or Dark
local menuBackgroundColour = "01011F"
local widgetBackgroundColour = menuBackgroundColour -- Dark
local widgetTextColour = "9f02ACFE" -- Light
local labelTextColour = "black"
local menuArrowColour = "66" .. labelTextColour

widgets.setColours({
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = labelTextColour,
  menuBackgroundColour = menuBackgroundColour,
  menuArrowColour = menuArrowColour,
  backgroundColour = backgroundColour,
  panelBackgroundColour = panelBackgroundColour,
})

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
local channel = 0 -- 0 = Omni
local forward = false
local scale = {}
local key = 1
local noteMin = 24
local noteMax = noteMin + (5 * 12)
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinition = scaleDefinitions[#scaleDefinitions]

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Scale and note functions
--------------------------------------------------------------------------------

-- Returns the notes filtered by scale and range
local function setScale()
  scale = {} -- Reset scale
  for _,note in ipairs(scales.createScale(scaleDefinition, (key - 1), noteMax)) do
    if note >= noteMin and note <= noteMax then
      table.insert(scale, note)
    end
  end
end

-- Use the selected chord definition to find the index for the next note in the chord
local function getNextScaleIndex(note, scale, chordDefinition, inversionIndex)
  local index = gem.getIndexFromValue(note, scale)
  --print("getNextScaleIndex #chordDefinition/inversionIndex", #chordDefinition, inversionIndex)
  local increment = chordDefinition[inversionIndex]
  if type(index) == "nil" then
    index = 0
    --print("!!!Note not found in scale!!!")
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
  -- Note index is 1 higher than note number
  local noteIndex = note + 1
  return noteNumberToNoteName[key] == noteNumberToNoteName[noteIndex]
end

local function createChordDefinition(part)
  local maxSteps = 4 -- Max steps
  local maxLength = paramsPerPart[part].polyphony.value -- Max length depends on polyphony
  local definition = {} -- Table to hold definition
  local ln = gem.getRandom(maxLength) -- Set a random length for the definition
  for i=1, ln do
    local steps = gem.getRandom(maxSteps)
    table.insert(definition, steps)
    --print("Add steps to definition", steps)
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
-- Sequencer Panel
--------------------------------------------------------------------------------

local tableWidth = 720

local sequencerPanel = widgets.panel({
  width = tableWidth,
  height = 30,
  x = 0,
  y = 0,
})

local chorderLabel = widgets.label("Chorder Input", {
  width = tableWidth,
  height = 30,
  alpha = 0.5,
  fontSize = 22
})

widgets.setSection({
  x = 470,
  y = 5,
  xSpacing = 5,
  ySpacing = 5,
})

widgets.button("Forward", forward, {
  tooltip = "Forward triggers (note=0 events) to the next processor",
  changed = function(self) forward = self.value end,
})

widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

-- Add params that are to be editable per part
for i=1,1 do
  local numSlots = 8
  local chords = {}
  local spreads = {}
  local inversions = {}
  local chordDefinitionSlots = {}

  --------------------------------------------------------------------------------
  -- Chord Definition Panel
  --------------------------------------------------------------------------------
  
  local chordDefinitionPanel = widgets.panel({
    width = 356,
    height = 108,
    y = widgets.posUnder(sequencerPanel),
    x = 5,
  })

  widgets.section({
    width = 90,
    x = 5,
    y = 5,
    xSpacing = 5,
    ySpacing = 5,
    cols = 6,
  })

  local chordDefinitionLabel = widgets.label("Chord Definition", {
    backgroundColour = "transparent",
    textColour = "white",
    width = 155
  })

  local createChordDefinitionButton = widgets.button("Create", {
    tooltip = "Create a random chord definition.",
  })

  local chordSelectionMenu = widgets.menu("Chord Selection", {"Active Input", "Auto", "Random", "Slots"}, {
    tooltip = "Auto: Default chord definitions are alternated, Random: Chord definitions are created by random, Slots: Chord definitions are selected from the slots",
  })

  widgets.section({
    width = 90,
    x = 5,
    y = widgets.posUnder(chordDefinitionLabel),
    xSpacing = 5,
    ySpacing = 5,
    cols = 9,
  })

  local chordDefinitionInput = widgets.label(getChordInputText(chordDefinitions[1]), {
    tooltip = "The current chord definition. Numbers represent steps up or down the scale that is currently selected. Feel free to type your own chord definitions here, or select from the menu.",
    editable = true,
    width = 251,
    height = 45,
    fontSize = 22,
    backgroundColour = "black",
    textColour = "white",
    backgroundColourWhenEditing = "white",
    textColourWhenEditing = "black",
  })

  createChordDefinitionButton.changed = function()
    chordDefinitionInput.text = getChordInputText(createChordDefinition(i))
  end

  widgets.row()
  widgets.col(1, chordDefinitionInput.width)

  local loadActions = {"Load..."}
  for _,v in ipairs(chordDefinitions) do
    table.insert(loadActions, getChordInputText(v))
  end

  local loadChordDefinition = widgets.menu("Load Menu", loadActions, {
    tooltip = "Load a chord definition",
    showLabel = false,
    changed = function(self)
      -- 1 is the menu label...
      if self.value == 1 then
        return
      end
    
      local actionIndex = self.value - 1
      chordDefinitionInput.text = self.selectedText
    
      -- Must be last
      self.selected = 1
    end    
  })

  widgets.row()

  for j=1,numSlots do
    local definitionSlot = widgets.button("" .. j, false, {
      enabled = false,
      tooltip = "Unused",
      height = 20,
      width = 27,
      changed = function(self)
        chordDefinitionInput.text = self.tooltip
        self.value = false
      end
    })
    table.insert(chordDefinitionSlots, definitionSlot)
  end

  local saveActions = {"Save to..."}
  for j=1,numSlots do
    table.insert(saveActions, "Slot " .. j)
  end
  local saveChordDefinition = widgets.menu("Save", saveActions, {
    tooltip = "Save the current chord definition to the selected slot",
    showLabel = false,
    changed = function(self)
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
      --print("Chord definition saved to slot", chordDefinitionInput.text, actionIndex)
    
      -- Must be last
      self.selected = 1
    end  
  })

  --------------------------------------------------------------------------------
  -- Polyphony and note limits
  --------------------------------------------------------------------------------
  
  local polyhonyPanel = widgets.panel({
    x = widgets.posSide(chordDefinitionPanel),
    y = chordDefinitionPanel.y,
    width = 348,
    height = 60,
  })
  
  widgets.section({
    width = 109,
    x = 5,
    y = 8,
    cols = 3,
  })

  local generatePolyphonyPart = widgets.numBox("Polyphony", 4, {
    tooltip = "How many notes are played at once",
    min = 1,
    max = maxVoices,
    integer = true,
  })
  generatePolyphonyPart.changed = function(self)
    for i,v in ipairs(noteDisplay) do
      v.enabled = maxVoices - self.value <= maxVoices - i
    end
  end

  local baseNoteRandomization = widgets.numBox("Base Chord", 25, {
    tooltip = "Probability that the root chord will be selected",
    unit = Unit.Percent,
  })

  local harmonizationPropbability = widgets.numBox("Harmonize", 100, {
    tooltip = "When harmonizing, we get notes from the currently playing chord. Otherwise notes are selected from the current scale.",
    unit = Unit.Percent,
  })

  local noteMinInput = widgets.numBox("Note Min", noteMin, {
    max = noteMax,
    tooltip = "Lowest note",
    unit = Unit.MidiKey,
  })

  local monoLimit = widgets.numBox("Mono Limit", noteMin + 24, {
    tooltip = "Below this note there will only be played one note (polyphony=1)",
    unit = Unit.MidiKey,
  })

  local noteMaxInput = widgets.numBox("Note Max", noteMax, {
    min = noteMin,
    tooltip = "Highest note",
    unit = Unit.MidiKey,
  })

  noteMinInput.changed = function(self)
    noteMaxInput:setRange(self.value, 127)
    noteMin = self.value
    setScale()
  end

  noteMaxInput.changed = function(self)
    noteMinInput:setRange(0, self.value)
    noteMax = self.value
    setScale()
  end  

  -- Key and scale
  local scalePanel = widgets.panel({
    x = chordDefinitionPanel.x,
    y = widgets.posUnder(chordDefinitionPanel),
    width = chordDefinitionPanel.width,
    height = 60,
  })

  widgets.section({
    width = 120,
    x = 5,
    y = 5,
    cols = 4,
  })

  local keyMenu = widgets.menu("Key", key, notes.getNoteNames(), {
    width = 60,
    changed = function(self)
      key = self.value
      setScale()
    end
  })

  local scaleMenu = scales.widget(widgets.getSectionValue('width'), true)

  widgets.label("Scale Definition", {
    textColour = "#d0d0d0",
    backgroundColour = "transparent",
  })

  widgets.row()
  widgets.col()
  widgets.col(1, keyMenu.width)

  local scaleInput = scales.inputWidget(scaleDefinition, 153)

  scaleMenu.changed = function(self)
    scaleInput.text = scales.getTextFromScaleDefinition(scaleDefinitions[self.value])
  end

  scaleInput.changed = function(self)
    scaleDefinition = scales.getScaleDefinitionFromText(self.text)
    setScale()
  end

  -- Note Spread
  local noteSpreadPanel = widgets.panel({
    x = widgets.posSide(scalePanel),
    y = widgets.posUnder(polyhonyPanel),
    width = 171,
    height = 108,
  })

  widgets.section({
    width = 159,
    x = 5,
    y = 5,
    cols = 1,
  })

  widgets.label("Note Spread (Voicing)", {
    textColour = "white",
    backgroundColour = "transparent",
  })

  table.insert(spreads, widgets.numBox("Close", 100, {
    tooltip = "Set the probability that close chords will be included",
    unit = Unit.Percent,
  }))

  table.insert(spreads, widgets.numBox("Medium", 100, {
    tooltip = "Set the probability that medium chords will be included",
    unit = Unit.Percent,
  }))

  table.insert(spreads, widgets.numBox("Wide", 100, {
    tooltip = "Set the probability that wide chords will be included",
    unit = Unit.Percent,
  }))

  -- Inversions
  local inversionPanel = widgets.panel({
    x = widgets.posSide(noteSpreadPanel),
    y = noteSpreadPanel.y,
    width = noteSpreadPanel.width,
    height = noteSpreadPanel.height,
  })

  widgets.section({
    width = 159,
    cols = 1,
  })

  widgets.label("Chord Inversions", {
    textColour = "white",
    backgroundColour = "transparent",
  })

  for inversion=1,3 do
    local p = 100
    if inversion == 3 then
      p = 0
    end
    table.insert(inversions, widgets.numBox("Inv " .. inversion, p, {
      name = "Inversion" .. inversion,
      tooltip = "Probability that inversion " .. inversion .. " will be included",
      unit = Unit.Percent,
    }))
  end

  table.insert(paramsPerPart, {scaleInput=scaleInput,scaleMenu=scaleMenu,keyMenu=keyMenu,chordDefinitionSlots=chordDefinitionSlots,chordDefinitionInput=chordDefinitionInput,chordSelectionMenu=chordSelectionMenu,inversions=inversions,spreads=spreads,chords=chords,baseNoteRandomization=baseNoteRandomization,polyphony=generatePolyphonyPart,harmonizationPropbability=harmonizationPropbability,monoLimit=monoLimit})
end

local voiceLabelWidth = 693 / maxVoices

local voicesPanel = widgets.panel({
  width = 710,
  height = 45,
  x = 5,
  y = 212,
  backgroundColour = "transparent"
})

widgets.section({
  width = voiceLabelWidth,
  cols = 16,
  x = 1,
  y = 2,
  xSpacing = 1,
  ySpacing = 1,
})

for j=1,maxVoices do
  local voiceLabel = widgets.label("Voice " .. j, {
    persistent = false,
  })
end

for j=1,maxVoices do
  table.insert(noteDisplay, widgets.label("-", {
    tooltip = "Displays the note played by voice " .. j,
    enabled = false,
    persistent = false,
    backgroundColour = "black",
    textColour = "white",
  }))
end

paramsPerPart[1].polyphony:changed()

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

local function getNotes()
  local currentPartPosition = 1 -- Holds the currently playing part
  local heldNoteIndex = 0
  local inversionIndex = 0
  local notesToPlay = {} -- Ensure notes are reset when seqencer starts

  -- Number of simultainious notes are set by polyphony
  local polyphony = paramsPerPart[currentPartPosition].polyphony.value
  local minNote = scale[1]
  local maxNote = scale[#scale]

  inversionIndex = 0 -- Reset counter for inversion progress
  -- Chord Selection: {"Active Input", "Auto", "Random", "Slots"}
  local chordSelection = paramsPerPart[currentPartPosition].chordSelectionMenu.selectedText
  if chordSelection == "Auto" then
    local index = gem.getRandom(#chordDefinitions)
    paramsPerPart[currentPartPosition].chordDefinitionInput.text = getChordInputText(chordDefinitions[index])
  elseif chordSelection == "Random" then
    paramsPerPart[currentPartPosition].chordDefinitionInput.text = getChordInputText(createChordDefinition(currentPartPosition))
  elseif chordSelection == "Slots" then
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
    --print("Chord inversion selected by random/#activeInversions", inversionIndex, #activeInversions)
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
    --print("Chord spread selected by random: selectedSpread/#activeSpreads", selectedSpread, #activeSpreads)
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
        --print("Adjust baseMin to mono limit", baseMin)
      elseif monoLimit > baseMin then
        -- Ensure we have a note within the mono limit
        baseMax = monoLimit
        --print("Adjust baseMax to mono limit", baseMax)
      end

      local function getBaseNote()
        local baseNote = minNote -- Start from the lowest note
        if gem.getRandomBoolean(baseNoteRandomization) then
          while isRootNote(baseNote, currentPartPosition) == false and baseNote <= baseMax do
            baseNote = baseNote + 1 -- increment note until we hit the base note
          end
          --print("Get root note: note/baseMin/baseMax", baseNote, baseMin, baseMax)
        else
          local noteRange = baseMax - baseMin
          if monoLimit <= baseMin then
            -- If there is no mono limit, we ajust the note range by polyphony to get a base note range
            noteRange = math.max(12, math.ceil(noteRange / polyphony))
            --print("Calculate range for base note baseMin/baseMax/noteRange", baseMin, baseMax, noteRange)
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
          --print("Insert into startingNotes", v.note)
        end
        if #startingNotes > 0 then
          -- If we have notes added, use them as the basis for the next note
          --print("startingNotes", #startingNotes)
          local prevNote = startingNotes[#startingNotes]
          --print("Found prevNote", prevNote)
          -- Increment inversion index
          inversionIndex = inversionIndex + 1
          if inversionIndex > #chordDefinition then
            inversionIndex = 1
          end
          local scaleIndex = getNextScaleIndex(prevNote, scale, chordDefinition, inversionIndex)
          note = scale[scaleIndex]
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
            --print("Check octave/note/baseMax/negOctProbability", octave, note, baseMax, negOctProbability)
            if octave > 0 and octave < 3 and note > baseMax / 2 and gem.getRandomBoolean(negOctProbability) then
              octave = -octave
              --print("Negative octave", octave)
            end
            local octaveOffset = octave * 12
            --print("Calculate octave adjustment - noteRange/octaveRange/notesLeft/octave", noteRange, octaveRange, notesLeft, octave)
            if octaveOffset > 0 and note + octaveOffset <= baseMax then
              note = note + octaveOffset
              --print("Octave adjusted octave/octaveOffset/note", octave, octaveOffset, note)
            end
            --print("Found note from prev note - note, prevNote", note, prevNote)
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
      --print("Add to chordDefinition", w)
    end
    --print("Get chordDefinition from input", #chordDefinition)
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
      --print("Insert note", noteToPlay.note)
      noteDisplay[voice].text = noteNumberToNoteName[noteToPlay.note + 1] .. " (" .. noteToPlay.note .. ")"
      voice = voice + 1
    end
    roundCounter = gem.inc(roundCounter)
    --print("Searching for notes roundCounter", roundCounter)
  end
  print("Notes ready to play ", #notesToPlay)

  return notesToPlay
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

local function handleTrigger(e)
  local notesForPlaying = getNotes()
  if #notesForPlaying > 0 then
    for _,v in ipairs(notesForPlaying) do
      modular.handleTrigger(e, v.note)
    end
  end
end

function onInit()
  setScale()
end

function onNote(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    handleTrigger(e)
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
  local chordDefinitionInputData = {}
  local chordDefinitionSlotsData = {}
  local scaleInputData = {}
  local i = 1

  for _,v in ipairs(paramsPerPart) do
    table.insert(chordDefinitionInputData, v.chordDefinitionInput.text)
    table.insert(scaleInputData, v.scaleInput.text)
    for _,s in ipairs(v.chordDefinitionSlots) do
      table.insert(chordDefinitionSlotsData, s.tooltip)
    end
  end

  return {chordDefinitionInputData, chordDefinitionSlotsData, scaleInputData}
end

function onLoad(data)
  local chordDefinitionInputData = data[1]
  local chordDefinitionSlotsData = data[2]
  local scaleInputData = data[3]

  local dataCounter = 1
  for i,v in ipairs(chordDefinitionInputData) do
    paramsPerPart[i].chordDefinitionInput.text = chordDefinitionInputData[i]
    paramsPerPart[i].scaleInput.text = scaleInputData[i]
    for _,v in ipairs(paramsPerPart[i].chordDefinitionSlots) do
      v.tooltip = chordDefinitionSlotsData[dataCounter]
      v.enabled = v.tooltip ~= "Unused"
      dataCounter = dataCounter + 1
    end
  end
end
