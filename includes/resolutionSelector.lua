--------------------------------------------------------------------------------
-- Common Generative Functions
--------------------------------------------------------------------------------

local gem = require "includes.common"
local resolutions = require "includes.resolutions"

--------------------------------------------------------------------------------
-- Resolution Parameters
--------------------------------------------------------------------------------

local divOpt = {}
for i=1,128 do
  table.insert(divOpt, "/ " .. i)
end

local globalResolution = nil -- Holds the global resolution for all voices
local resolutionInputs = {}
local toggleResolutionInputs = {}
local resolutionProbabilityInputs = {}
local minRepeats = {}
local divisions = {}

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function adjustForDuration(decay, currentDuration)
  -- TODO Param for adjusting decay
  -- TODO Increase decay for longer durations - less repetition of longer notes
  local middleIndex = 17 -- 1/4 (1 beat) -- TODO Param?
  local middleResolution = resolutions.getResolution(middleIndex)
  local increase = 0
  if currentDuration > middleResolution and gem.tableIncludes(resolutions.getResolutions(), currentDuration) then
    -- Note is longer than 1/4 - increase decay
    local resolutionIndex = gem.getIndexFromValue(currentDuration, resolutions.getResolutions())
    local percentIncrease = (middleIndex * resolutionIndex) / 100
    local factor = decay / percentIncrease
    increase = decay * (factor / 100)
    print("Decay adjusted decay, increase", decay, increase)
  end
  return math.min(100, (decay + increase)) / 100
end

local function getNoteDuration(currentDuration, repeatCounter, durationRepeatProbability, durationRepeatDecay, useGlobalProbability)
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
    if resolutionActive and gem.getRandomBoolean(resolutionProbabilityInputs[i].value) then
      table.insert(availableResolutions, v.value)
      table.insert(selectedDivisionsAndRepeats, {division=divisions[i].value,repeats=minRepeats[i].value})
    end
  end

  --print("#availableResolutions", #availableResolutions)

  -- Check if we should use the global resolution
  if type(globalResolution) == "number" and type(useGlobalProbability) == "number" and gem.getRandomBoolean(useGlobalProbability) then
    currentDuration = globalResolution
    --print("Set currentDuration from globalResolution", currentDuration)
  end

  -- Failsafe in case no resolutions are selected
  if #availableResolutions == 0 then
    if type(globalResolution) == "number" then
      return globalResolution, 1, durationRepeatProbability
    else
      return resolutions.getResolution(17), 1, durationRepeatProbability
    end
  end

  local resolutionIndex = nil
  if gem.tableIncludes(resolutions.getResolutions(), currentDuration) then
    resolutionIndex = gem.getIndexFromValue(currentDuration, resolutions.getResolutions())
  end

  -- Check resolution repeat by probability
  if type(currentDuration) == "number" then
    local durationRepeatProbabilityDecay = durationRepeatProbability * adjustForDuration(durationRepeatDecay, currentDuration)
    durationRepeatProbability = durationRepeatProbability - durationRepeatProbabilityDecay
    -- Repeat only if current resolution is still available
    if gem.tableIncludes(availableResolutions, resolutionIndex) and gem.getRandomBoolean(durationRepeatProbability) then
      --print("Repeating current duration", currentDuration)
      return currentDuration, 1, durationRepeatProbability
    end
  end

  -- Remove last known resolution if repeat was not selected
  if type(resolutionIndex) == "number" and type(currentDuration) == "number" and #availableResolutions > 1 then
    local removeIndex = gem.getIndexFromValue(resolutionIndex, availableResolutions)
    table.remove(availableResolutions, removeIndex)
    table.remove(selectedDivisionsAndRepeats, removeIndex)
    --print("Remove current duration to avoid repeat", removeIndex)
  end

  local index = 1
  if #availableResolutions > 1 then
    index = gem.getRandom(#availableResolutions)
    --print("Index selected by random", index)
  end

  -- Get resolution and divide by the selected division - not lower than system min res (1/128)
  globalResolution = resolutions.getPlayDuration(resolutions.getResolution(availableResolutions[index]) / selectedDivisionsAndRepeats[index].division)

  return globalResolution, selectedDivisionsAndRepeats[index].repeats, nil
end

local function createResolutionSelector(resolutionPanel, colours, numResolutions)
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

    local resolution = resolutionPanel:Menu("Resolution" .. i, resolutions.getResolutionNames())
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

return {--resolutionSelector--
  resolutionInputs = resolutionInputs,
  toggleResolutionInputs = toggleResolutionInputs,
  getNoteDuration = getNoteDuration,
  createResolutionSelector = createResolutionSelector,
}
