--------------------------------------------------------------------------------
-- Common Generative Functions
--------------------------------------------------------------------------------

require "common"

--------------------------------------------------------------------------------
-- Resolution Parameters
--------------------------------------------------------------------------------

local divOpt = {}
for i=1,128 do
  table.insert(divOpt, "/ " .. i)
end

globalResolution = nil -- Holds the global resolution for all voices
resolutions = getResolutions()
resolutionNames = getResolutionNames()
resolutionInputs = {}
toggleResolutionInputs = {}
resolutionProbabilityInputs = {}
minRepeats = {}
divisions = {}

--------------------------------------------------------------------------------
-- Note and Scale Parameters
--------------------------------------------------------------------------------

local octaves = 9
local scaleDefinitions = getScaleDefinitions()
local scaleNames = getScaleNames()
local noteNames = getNoteNames()

notesPlaying = {}
noteInputs = {}
noteProbabilityInputs = {}
octaveInputs = {}
octaveProbabilityInputs = {}

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function getScale(scaleIndex, keyIndex)
  local scaleDefinition = scaleDefinitions[scaleIndex]
  local rootNote = keyIndex - 1 -- Root note
  return createScale(scaleDefinition, rootNote)
end

function setScale(scaleIndex, keyIndex)
  local scale = getScale(scaleIndex, keyIndex)
  for i,v in ipairs(noteInputs) do
    local noteNumber = i + 11 -- Check note in octave above
    v:setValue(tableIncludes(scale, noteNumber))
  end
end

function getSelectedNotes()
  local selectedNotes = {} -- Holds note numbers that are available
  for octaveIndex,octave in ipairs(octaveInputs) do
    local octaveProbability = octaveProbabilityInputs[octaveIndex].value
    if octave.value and octaveProbability > 0 then
      for i,v in ipairs(noteInputs) do
        -- Check if note should be added for this octave
        local noteProbability = noteProbabilityInputs[i].value
        if v.value and getRandomBoolean(noteProbability) and getRandomBoolean(octaveProbability) then
          local noteNumber = i - 1 -- Base note
          noteNumber = noteNumber + (12 * octaveIndex) -- Set octave
          if tableIncludes(notesPlaying, noteNumber) == false then
            table.insert(selectedNotes, noteNumber)
            --print("Note added: noteNumber/name", noteNumber, noteNumberToNoteName[noteNumber+1])
          end
        end
      end
    end
  end
  --print("#selectedNotes", #selectedNotes)
  return selectedNotes
end

-- Get all notes that are activated in all octaves (full scale)
function getActiveNotes()
  local notes = {}
  for octaveIndex=1, #octaveInputs do
    for i,v in ipairs(noteInputs) do
      if v.value then
        local noteNumber = i - 1 -- Base note
        noteNumber = noteNumber + (12 * octaveIndex) -- Set octave
        table.insert(notes, noteNumber)
      end
    end
  end
  return notes
end

function adjustForDuration(decay, currentDuration)
  -- TODO Param for adjusting decay
  -- TODO Increase decay for longer durations - less repetition of longer notes
  local middleIndex = 17 -- 1/4 (1 beat) -- TODO Param?
  local middleResolution = resolutions[middleIndex]
  local increase = 0
  if currentDuration > middleResolution and tableIncludes(resolutions, currentDuration) then
    -- Note is longer than 1/4 - increase decay
    local resolutionIndex = getIndexFromValue(currentDuration, resolutions)
    local percentIncrease = (middleIndex * resolutionIndex) / 100
    local factor = decay / percentIncrease
    increase = decay * (factor / 100)
    print("Decay adjusted decay, increase", decay, increase)
  end
  return math.min(100, (decay + increase)) / 100
end

function getNoteDuration(currentDuration, repeatCounter, durationRepeatProbability, durationRepeatDecay, useGlobalProbability)
  --print("repeatCounter", repeatCounter)
  repeatCounter = repeatCounter - 1
  -- Repeat the current duration until repeat counter reaches zero
  if repeatCounter > 0 then
    --print("Repeating duration", repeatCounter, currentDuration)
    return currentDuration, repeatCounter, durationRepeatProbability
  end

  -- Find available resolutions
  local availableResolutions = {}
  local selectedDivisionsAndRepeats = {}
  for i,v in ipairs(resolutionInputs) do
    local resolutionActive = toggleResolutionInputs[i].value
    if resolutionActive and getRandomBoolean(resolutionProbabilityInputs[i].value) then
      table.insert(availableResolutions, v.value)
      table.insert(selectedDivisionsAndRepeats, {division=divisions[i].value,repeats=minRepeats[i].value})
    end
  end

  --print("#availableResolutions", #availableResolutions)

  -- Check if we should use the global resolution
  if type(globalResolution) == "number" and type(useGlobalProbability) == "number" and getRandomBoolean(useGlobalProbability) then
    currentDuration = globalResolution
    --print("Set currentDuration from globalResolution", currentDuration)
  end

  -- Failsafe in case no resolutions are selected
  if #availableResolutions == 0 then
    if type(globalResolution) == "number" then
      return globalResolution, 1, durationRepeatProbability
    else
      return getResolution(17), 1, durationRepeatProbability
    end
  end

  local resolutionIndex = nil
  if tableIncludes(resolutions, currentDuration) then
    resolutionIndex = getIndexFromValue(currentDuration, resolutions)
  end

  -- Check resolution repeat by probability
  if type(currentDuration) == "number" then
    local durationRepeatProbabilityDecay = durationRepeatProbability * adjustForDuration(durationRepeatDecay, currentDuration)
    durationRepeatProbability = durationRepeatProbability - durationRepeatProbabilityDecay
    -- Repeat only if current resolution is still available
    if tableIncludes(availableResolutions, resolutionIndex) and getRandomBoolean(durationRepeatProbability) then
      --print("Repeating current duration", currentDuration)
      return currentDuration, 1, durationRepeatProbability
    end
  end

  -- Remove last known resolution if repeat was not selected
  if type(resolutionIndex) == "number" and type(currentDuration) == "number" and #availableResolutions > 1 then
    local removeIndex = getIndexFromValue(resolutionIndex, availableResolutions)
    table.remove(availableResolutions, removeIndex)
    table.remove(selectedDivisionsAndRepeats, removeIndex)
    --print("Remove current duration to avoid repeat", removeIndex)
  end

  local index = 1
  if #availableResolutions > 1 then
    index = getRandom(#availableResolutions)
    --print("Index selected by random", index)
  end

  -- Get resolution and divide by the selected division - not lower than system min res (1/128)
  globalResolution = getPlayDuration(getResolution(availableResolutions[index]) / selectedDivisionsAndRepeats[index].division)

  return globalResolution, selectedDivisionsAndRepeats[index].repeats, nil
end

function setNotesAndOctaves(notePanel, colours, noteLabel)
  local columnCount = 0
  for i=1,#noteNames do
    local note = notePanel:OnOffButton("Note" .. i, true)
    note.backgroundColourOff = "#ff084486"
    note.backgroundColourOn = "#ff02ACFE"
    note.textColourOff = "#ff22FFFF"
    note.textColourOn = "#efFFFFFF"
    note.displayName = noteNames[i]
    note.tooltip = "Toggle note on/off"
    note.size = {51,30}
    note.x = (columnCount * (note.width + 6.6)) + 5
    note.y = noteLabel.y + noteLabel.height + 5
  
    local noteProbability = notePanel:NumBox("NoteProbability" .. i, 100, 0, 100, true)
    noteProbability.unit = Unit.Percent
    noteProbability.textColour = colours.widgetTextColour
    noteProbability.backgroundColour = colours.widgetBackgroundColour
    noteProbability.showLabel = false
    noteProbability.tooltip = "Set the probability that '" .. noteNames[i] .. "' will be available when generating notes to play"
    noteProbability.width = note.width
    noteProbability.height = 22
    noteProbability.x = note.x
    noteProbability.y = note.y + note.height + 1
  
    table.insert(noteInputs, note)
    table.insert(noteProbabilityInputs, noteProbability)
  
    columnCount = columnCount + 1
  end
  
  columnCount = 0
  
  local rising = true
  local numStepsUpDown = math.floor(octaves / 2)
  local changePerStep = 100 / numStepsUpDown
  local startValue = 0
  for i=1,octaves do
    local octave = notePanel:OnOffButton("Octave" .. i, (startValue > 50))
    octave.backgroundColourOff = "#ff084486"
    octave.backgroundColourOn = "#ff02ACFE"
    octave.textColourOff = "#ff22FFFF"
    octave.textColourOn = "#efFFFFFF"
    octave.displayName = "Oct " .. i - 2
    octave.tooltip = "Toggle octave on/off"
    octave.width = (636 / octaves)
    octave.height = 30
    octave.x = (columnCount * (octave.width + 6.9)) + 5
    octave.y = 90
  
    local octaveProbabilityInput = notePanel:NumBox("OctaveProbability" .. i, 100, 0, 100, true)
    octaveProbabilityInput.unit = Unit.Percent
    octaveProbabilityInput.textColour = colours.widgetTextColour
    octaveProbabilityInput.backgroundColour = colours.widgetBackgroundColour
    octaveProbabilityInput.showLabel = false
    octaveProbabilityInput.tooltip = "Set the probability that octave " .. i - 2 .. " will be available when generating notes to play"
    octaveProbabilityInput.width = octave.width
    octaveProbabilityInput.height = 22
    octaveProbabilityInput.x = octave.x
    octaveProbabilityInput.y = octave.y + octave.height
  
    table.insert(octaveInputs, octave)
    table.insert(octaveProbabilityInputs, octaveProbabilityInput)
  
    if rising then
      startValue = startValue + changePerStep
      if startValue >= 100 then
        rising = false
      end
    else
      startValue = startValue - changePerStep
    end
  
    columnCount = columnCount + 1
  end

  local generateKey = notePanel:Menu("GenerateKey", noteNames)
  generateKey.tooltip = "Set selected notes from key"
  generateKey.showLabel = false
  generateKey.backgroundColour = colours.menuBackgroundColour
  generateKey.textColour = colours.widgetTextColour
  generateKey.arrowColour = colours.menuArrowColour
  generateKey.outlineColour = colours.menuOutlineColour
  generateKey.size = {102,20}
  generateKey.x = noteLabel.x + noteLabel.width + 10
  generateKey.y = noteLabel.y

  local generateScale = notePanel:Menu("GenerateScale", scaleNames)
  generateScale.selected = #scaleNames
  generateScale.tooltip = "Set selected notes from scale"
  generateScale.showLabel = false
  generateScale.backgroundColour = colours.menuBackgroundColour
  generateScale.textColour = colours.widgetTextColour
  generateScale.arrowColour = colours.menuArrowColour
  generateScale.outlineColour = colours.menuOutlineColour
  generateScale.size = generateKey.size
  generateScale.x = generateKey.x + generateKey.width + 10
  generateScale.y = generateKey.y

  generateKey.changed = function(self)
    setScale(generateScale.value, self.value)
  end

  generateScale.changed = function(self)
    setScale(self.value, generateKey.value)
  end
end

function setResolutions(resolutionPanel, colours, numResolutions)
  if type(numResolutions) == "nil" then
    numResolutions = 12
  end
  local offset = 5
  local perRow = 3
  local columnCount = 0
  local rowCount = 1
  for i=1,numResolutions do
    local toggleResolution = resolutionPanel:OnOffButton("ToggleResolution" .. i, (i == 1))
    toggleResolution.backgroundColourOff = "#ff084486"
    toggleResolution.backgroundColourOn = "#ff02ACFE"
    toggleResolution.textColourOff = "#ff22FFFF"
    toggleResolution.textColourOn = "#efFFFFFF"
    toggleResolution.displayName = " "
    toggleResolution.tooltip = "Toggle resolution on/off"
    toggleResolution.size = {23,20}
    toggleResolution.x = (columnCount * 232) + 5
    toggleResolution.y = ((toggleResolution.height + 5) * rowCount) + 5

    local resolution = resolutionPanel:Menu("Resolution" .. i, resolutionNames)
    if i == 1 then
      resolution.selected = 20
    elseif i == 2 then
      resolution.selected = 23
    elseif i == 6 then
      resolution.selected = 22
    elseif i == 7 then
      resolution.selected = 18
    elseif i > 9 then
      resolution.selected = i - 3
    else
      resolution.selected = offset
    end
    offset = offset + 3
    resolution.showLabel = false
    resolution.backgroundColour = colours.widgetBackgroundColour
    resolution.textColour = colours.widgetTextColour
    resolution.arrowColour = colours.menuArrowColour
    resolution.outlineColour = colours.menuOutlineColour
    resolution.tooltip = "Select resolution"
    resolution.size = {70,20}
    resolution.x = toggleResolution.x + toggleResolution.width + 1
    resolution.y = toggleResolution.y

    local resolutionProbability = resolutionPanel:NumBox("ResolutionProbability" .. i, 100, 0, 100, true)
    resolutionProbability.unit = Unit.Percent
    resolutionProbability.textColour = colours.widgetTextColour
    resolutionProbability.backgroundColour = colours.widgetBackgroundColour
    resolutionProbability.showLabel = false
    resolutionProbability.tooltip = "Probability of resolution being used"
    resolutionProbability.size = {42,20}
    resolutionProbability.x = resolution.x + resolution.width + 1
    resolutionProbability.y = resolution.y

    local minRepeatValue = 1
    if i == 6 then
      minRepeatValue = 3
    end
    local minRepeat = resolutionPanel:NumBox("MinRepeat" .. i, minRepeatValue, 1, 128, true)
    minRepeat.textColour = colours.widgetTextColour
    minRepeat.backgroundColour = colours.widgetBackgroundColour
    minRepeat.showLabel = false
    minRepeat.tooltip = "Set the minimum number of repeats for this resolution"
    minRepeat.size = {36,20}
    minRepeat.x = resolutionProbability.x + resolutionProbability.width + 1
    minRepeat.y = resolutionProbability.y

    local division = resolutionPanel:Menu("Division" .. i, divOpt)
    division.showLabel = false
    division.backgroundColour = colours.widgetBackgroundColour
    division.textColour = colours.widgetTextColour
    division.arrowColour = colours.menuArrowColour
    division.outlineColour = colours.menuOutlineColour
    division.tooltip = "Set a division for this resolution"
    division.size = {45,20}
    division.x = minRepeat.x + minRepeat.width + 1
    division.y = minRepeat.y

    table.insert(toggleResolutionInputs, toggleResolution)
    table.insert(resolutionInputs, resolution)
    table.insert(resolutionProbabilityInputs, resolutionProbability)
    table.insert(minRepeats, minRepeat)
    table.insert(divisions, division)

    columnCount = columnCount + 1
    if i % perRow == 0 then
      rowCount = rowCount + 1
      columnCount = 0
    end
  end
  return rowCount
end
