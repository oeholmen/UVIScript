-----------------------------------------------------------------------
-- A script modulator that creates random multi-envelopes over time.
-----------------------------------------------------------------------

require "subdivision"

local heldNotes = {}
local minResolution = 0.03125 -- The lowest possible resolution

local backgroundColour = "303030" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "FF9551" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local secondRowY = 40
local widgetWidth = 129

setBackgroundColour(backgroundColour)

local panel = Panel("Toggle")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 200

local label = panel:Label("Label")
label.text = "Timed Enveloper"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 150
label.x = 0
label.y = 0

local sourceIndex = panel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.backgroundColour = widgetBackgroundColour
sourceIndex.textColour = widgetTextColour
sourceIndex.displayName = "Event Id"
sourceIndex.width = 100
sourceIndex.x = label.x + label.width + 10
sourceIndex.y = 0

local legato = panel:OnOffButton("Legato", false)
legato.displayName = "Legato"
legato.backgroundColourOff = "#ff084486"
legato.backgroundColourOn = "#ff02ACFE"
legato.textColourOff = "#ff22FFFF"
legato.textColourOn = "#efFFFFFF"
legato.fillColour = "#dd000061"
legato.width = 60
legato.x = panel.width - legato.width - 10
legato.y = 0

local loop = panel:OnOffButton("Loop", true)
loop.displayName = "Loop"
loop.backgroundColourOff = "#ff084486"
loop.backgroundColourOn = "#ff02ACFE"
loop.textColourOff = "#ff22FFFF"
loop.textColourOn = "#efFFFFFF"
loop.fillColour = "#dd000061"
loop.width = legato.width
loop.x = legato.x - legato.width - 10
loop.y = 0

local maxSteps = panel:NumBox("MaxSteps", 1, 1, 8, true)
maxSteps.displayName = "Max Steps"
maxSteps.tooltip = "Set the maximum number of steps that can be tied"
maxSteps.textColour = widgetTextColour
maxSteps.backgroundColour = widgetBackgroundColour
maxSteps.width = widgetWidth
maxSteps.x = 5
maxSteps.y = secondRowY

local minLevel = panel:NumBox("MinLevel", 50, 0, 100, true)
minLevel.unit = Unit.Percent
minLevel.displayName = "Spike Level"
minLevel.tooltip = "Set the minimum level for spikes"
minLevel.textColour = widgetTextColour
minLevel.backgroundColour = widgetBackgroundColour
minLevel.x = maxSteps.x + maxSteps.width + 10
minLevel.y = secondRowY
minLevel.width = widgetWidth

local attack = panel:NumBox("Attack", 0, 0, 100, true)
attack.unit = Unit.Percent
attack.displayName = "Attack"
attack.tooltip = "Set attack as percentage of duration - 0 = random variation"
attack.textColour = widgetTextColour
attack.backgroundColour = widgetBackgroundColour
attack.x = minLevel.x + minLevel.width + 10
attack.y = secondRowY
attack.width = widgetWidth

local decay = panel:NumBox("Decay", 0, 0, 100, true)
decay.unit = Unit.Percent
decay.displayName = "Decay"
decay.tooltip = "Set decay as percentage of rest duration - 0 = random variation"
decay.textColour = widgetTextColour
decay.backgroundColour = widgetBackgroundColour
decay.x = attack.x + attack.width + 10
decay.y = secondRowY
decay.width = widgetWidth

local bipolar = panel:NumBox("Bipolar", 0, 0, 100, true)
bipolar.unit = Unit.Percent
bipolar.displayName = "Bipolar"
bipolar.tooltip = "Set the probability that the returned value will be negative"
bipolar.textColour = widgetTextColour
bipolar.backgroundColour = widgetBackgroundColour
bipolar.x = decay.x + decay.width + 10
bipolar.y = secondRowY
bipolar.width = widgetWidth

--------------------------------------------------------------------------------
-- Resolution Panel
--------------------------------------------------------------------------------

local divOpt = {}
for i=1,128 do
  table.insert(divOpt, "/ " .. i)
end

local resolutions = getResolutions()
local resolutionNames = getResolutionNames()
local resolutionInputs = {}
local toggleResolutionInputs = {}
local resolutionProbabilityInputs = {}
local minRepeats = {}
local divisions = {}

local resLabel = panel:Label("ResolutionsLabel")
resLabel.text = "Resolutions"
resLabel.tooltip = "Set probability for each resolution to be selected"
resLabel.alpha = 0.75
resLabel.fontSize = 15
resLabel.width = 350
resLabel.x = 0
resLabel.y = 70

local clearResolutions = panel:Button("ClearResolutions")
clearResolutions.displayName = "All off"
clearResolutions.tooltip = "Deactivate all resolutions"
clearResolutions.persistent = false
clearResolutions.height = resLabel.height
clearResolutions.width = 90
clearResolutions.x = panel.width - (clearResolutions.width * 3) - 30
clearResolutions.y = resLabel.y
clearResolutions.changed = function()
  for i,v in ipairs(resolutionInputs) do
    toggleResolutionInputs[i]:setValue(false)
  end
end

local addResolutions = panel:Button("AddResolutions")
addResolutions.displayName = "All on"
addResolutions.tooltip = "Activate all resolutions"
addResolutions.persistent = false
addResolutions.height = clearResolutions.height
addResolutions.width = 90
addResolutions.x = clearResolutions.x + clearResolutions.width + 10
addResolutions.y = resLabel.y
addResolutions.changed = function()
  for i,v in ipairs(resolutionInputs) do
    toggleResolutionInputs[i]:setValue(true)
  end
end

local randomizeResolutions = panel:Button("RandomizeResolutions")
randomizeResolutions.displayName = "Randomize"
randomizeResolutions.tooltip = "Randomize selected resolutions"
randomizeResolutions.persistent = false
randomizeResolutions.height = clearResolutions.height
randomizeResolutions.width = 90
randomizeResolutions.x = addResolutions.x + addResolutions.width + 10
randomizeResolutions.y = resLabel.y
randomizeResolutions.changed = function()
  for i,v in ipairs(resolutionInputs) do
    toggleResolutionInputs[i]:setValue(getRandomBoolean())
  end
end

local offset = 5
local perRow = 3
local columnCount = 0
local rowCount = 1
for i=1,9 do
  local toggleResolution = panel:OnOffButton("ToggleResolution" .. i, (i == 1))
  toggleResolution.backgroundColourOff = "#ff084486"
  toggleResolution.backgroundColourOn = "#ff02ACFE"
  toggleResolution.textColourOff = "#ff22FFFF"
  toggleResolution.textColourOn = "#efFFFFFF"
  toggleResolution.displayName = " "
  toggleResolution.tooltip = "Toggle resolution on/off"
  toggleResolution.size = {23,20}
  toggleResolution.x = (columnCount * 232) + 5
  toggleResolution.y = resLabel.y + ((toggleResolution.height + 3) * rowCount) + 5

  local resolution = panel:Menu("Resolution" .. i, resolutionNames)
  if i == 1 then
    resolution.selected = 20
  elseif i == 2 then
    resolution.selected = 23
  elseif i == 6 then
    resolution.selected = 22
  elseif i == 7 then
    resolution.selected = 18
  else
    resolution.selected = offset
  end
  offset = offset + 3
  resolution.showLabel = false
  resolution.backgroundColour = widgetBackgroundColour
  resolution.textColour = widgetTextColour
  resolution.arrowColour = menuArrowColour
  resolution.outlineColour = menuOutlineColour
  resolution.tooltip = "Select resolution"
  resolution.size = {70,20}
  resolution.x = toggleResolution.x + toggleResolution.width + 1
  resolution.y = toggleResolution.y

  local resolutionProbability = panel:NumBox("ResolutionProbability" .. i, 100, 0, 100, true)
  resolutionProbability.unit = Unit.Percent
  resolutionProbability.textColour = widgetTextColour
  resolutionProbability.backgroundColour = widgetBackgroundColour
  resolutionProbability.showLabel = false
  resolutionProbability.tooltip = "Probability of resolution being used"
  resolutionProbability.size = {42,20}
  resolutionProbability.x = resolution.x + resolution.width + 1
  resolutionProbability.y = resolution.y

  local minRepeatValue = 1
  if i == 6 then
    minRepeatValue = 3
  end
  local minRepeat = panel:NumBox("MinRepeat" .. i, minRepeatValue, 1, 128, true)
  minRepeat.textColour = widgetTextColour
  minRepeat.backgroundColour = widgetBackgroundColour
  minRepeat.showLabel = false
  minRepeat.tooltip = "Set the minimum number of repeats for this resolution"
  minRepeat.size = {36,20}
  minRepeat.x = resolutionProbability.x + resolutionProbability.width + 1
  minRepeat.y = resolutionProbability.y

  local division = panel:Menu("Division" .. i, divOpt)
  division.showLabel = false
  division.backgroundColour = widgetBackgroundColour
  division.textColour = widgetTextColour
  division.arrowColour = menuArrowColour
  division.outlineColour = menuOutlineColour
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

local resLabel = panel:Label("ResolutionsLabel")
resLabel.text = "Base Resolution"
resLabel.alpha = 0.5
resLabel.fontSize = 15
resLabel.width = 106
resLabel.x = 5
resLabel.y = (25 * rowCount) + 70

local baseResolution = panel:Menu("BaseResolution", resolutionNames)
baseResolution.displayName = resLabel.text
baseResolution.tooltip = "The duration between resets"
baseResolution.selected = 11
baseResolution.showLabel = false
baseResolution.height = 20
baseResolution.width = 106
baseResolution.backgroundColour = widgetBackgroundColour
baseResolution.textColour = widgetTextColour
baseResolution.arrowColour = menuArrowColour
baseResolution.outlineColour = menuOutlineColour
baseResolution.x = resLabel.x + resLabel.width + 10
baseResolution.y = resLabel.y

local durationRepeatProbabilityInput = panel:NumBox("DurationRepeatProbability", 100, 0, 100, true)
durationRepeatProbabilityInput.unit = Unit.Percent
durationRepeatProbabilityInput.textColour = widgetTextColour
durationRepeatProbabilityInput.backgroundColour = widgetBackgroundColour
durationRepeatProbabilityInput.displayName = "Repeat Probability"
durationRepeatProbabilityInput.tooltip = "The probability that a resolution will be repeated"
durationRepeatProbabilityInput.size = {222,20}
durationRepeatProbabilityInput.x = baseResolution.x + baseResolution.width + 10
durationRepeatProbabilityInput.y = baseResolution.y

local durationRepeatDecay = panel:NumBox("DurationRepeatDecay", 1, 25., 100)
durationRepeatDecay.unit = Unit.Percent
durationRepeatDecay.textColour = widgetTextColour
durationRepeatDecay.backgroundColour = widgetBackgroundColour
durationRepeatDecay.displayName = "Probability Decay"
durationRepeatDecay.tooltip = "The reduction in repeat probability for each iteration of the playing voice"
durationRepeatDecay.size = durationRepeatProbabilityInput.size
durationRepeatDecay.x = durationRepeatProbabilityInput.x + durationRepeatProbabilityInput.width + 10
durationRepeatDecay.y = durationRepeatProbabilityInput.y

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

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

function getDuration(currentDuration, repeatCounter, durationRepeatProbability)
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

  -- Failsafe in case no resolutions are selected
  if #availableResolutions == 0 then
    return getResolution(17), 1, durationRepeatProbabilityInput.value
  end

  local resolutionIndex = nil
  if tableIncludes(resolutions, currentDuration) then
    resolutionIndex = getIndexFromValue(currentDuration, resolutions)
  end

  -- Check resolution repeat by probability
  if type(currentDuration) == "number" then
    local durationRepeatProbabilityDecay = durationRepeatProbability * adjustForDuration(durationRepeatDecay.value, currentDuration)
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
  local resolution = math.max(minResolution, (getResolution(availableResolutions[index]) / selectedDivisionsAndRepeats[index].division))

  return resolution, selectedDivisionsAndRepeats[index].repeats, durationRepeatProbabilityInput.value
end

function hasVoiceId(voiceId)
  for _,v in ipairs(heldNotes) do
    if v == voiceId then
      return true
    end
  end
  return false
end

-- https://www.uvi.net/uviscript/class_mapper.html
-- Linear: param = min + (max-min)*pos 
-- Exponential: param = min * (max/min)^pos
-- Exponential: return 10 * (controllerValue/max)^4 (controllerValueToWidgetValue)
-- TweakSynth line 808
function modulateExponential(modulationTime, startValue, endValue, voiceId)
  local millisecondsPerStep = 20
  print("Duration of modulation (ms):", modulationTime)
  print("Change from/to:", startValue, endValue)
  if modulationTime <= (millisecondsPerStep*9) then
    print("Short duration, modulate linear:")
    modulateLinear(modulationTime, startValue, endValue, voiceId)
    return
  end

  local diff = math.max(endValue, startValue) - math.min(endValue, startValue)

  local parts = {
    {duration=0.5,startValue=startValue,endValue=diff*0.2},
    {duration=0.3,startValue=diff*0.2,endValue=diff*0.2+diff*0.3},
    {duration=0.3,startValue=diff*0.2+diff*0.3,endValue=endValue},
  }

  for i,v in ipairs(parts) do
    local remainingTime = modulationTime * v.duration
    local diff = math.max(v.endValue, v.startValue) - math.min(v.endValue, v.startValue)
    local numberOfSteps = remainingTime / millisecondsPerStep
    local changePerStep = diff / numberOfSteps
    print("i, diff, numberOfSteps, changePerStep", i, diff, numberOfSteps, changePerStep)
  
    local currentValue = v.startValue
    if v.startValue < v.endValue then
      while remainingTime > 0 do
        print("currentValue, endValue", currentValue, v.endValue)
        local change = changePerStep
        nextValue = math.min((currentValue + change), v.endValue)
        modulateLinear(millisecondsPerStep, currentValue, nextValue, voiceId)
        wait(millisecondsPerStep)
        currentValue = nextValue -- Increment current value
        if remainingTime - millisecondsPerStep <= 0 then
          modulateLinear(remainingTime, currentValue, v.endValue, voiceId)
        end
        remainingTime = remainingTime - millisecondsPerStep
      end
    else
      modulateLinear(modulationTime, v.startValue, v.endValue, voiceId)
    end
  end
end

function modulateLinear(modulationTime, startValue, endValue, voiceId)
  print("sendScriptModulation2 startValue, endValue, modulationTime", startValue, endValue, modulationTime)
  sendScriptModulation2(sourceIndex.value, startValue, endValue, modulationTime, voiceId)
end

function attackDecay(targetVal, stepDuration, voiceId)
  -- FIND ATTACK TIME
  local attackValue = attack.value
  if attackValue == 0 then
    attackValue = getRandom(3,50) -- TODO Parameter for this?
  end
  local attackTime = stepDuration * (attackValue / 100)
  if true then --getRandomBoolean() then
    -- LINEAR
    modulateLinear(attackTime, 0, targetVal, voiceId)
  else
    -- EXPONENTIAL
    spawn(modulateExponential, attackTime, 0, targetVal, voiceId)
  end
  wait(attackTime)
  local restDuration = stepDuration - attackTime
  if restDuration > 1 then
    -- FIND DECAY TIME
    local decayValue = decay.value
    if decayValue == 0 then
      decayValue = getRandom(30,100) -- TODO Parameter for this?
    end
    local decayTime = restDuration * (decayValue / 100)
    modulateLinear(decayTime, targetVal, 0, voiceId)
  end
  wait(restDuration)
  if loop.value == false then
    if type(voiceId) == "nil" then
      heldNotes = {}
    else
      remove(voiceId)
    end
  end
end

function doModulation(waitDuration, durationRepeatProbability, repeatCounter, voiceId)
  local steps = 1
  if maxSteps.value > 1 then
    steps = getRandom(maxSteps.value)
  end
  waitDuration, repeatCounter, durationRepeatProbability = getDuration(waitDuration, repeatCounter, durationRepeatProbability)
  local val = 1 -- Spike level
  if minLevel.value < 100 then
    val = getRandom(math.max(1, minLevel.value), 100) / 100
  end
  if getRandomBoolean(bipolar.value) then
    val = -val
  end
  -- Do the attack/decay phase
  attackDecay(val, beat2ms(waitDuration * steps), voiceId)
  return waitDuration, durationRepeatProbability, repeatCounter
end

function modulateVoice(voiceId)
  local waitDuration = nil
  local durationRepeatProbability = durationRepeatProbabilityInput.value
  local repeatCounter = 1
  while hasVoiceId(voiceId) do
    waitDuration, durationRepeatProbability, repeatCounter = doModulation(waitDuration, durationRepeatProbability, repeatCounter, voiceId)
  end
end

function modulateBroadcast()
  local waitDuration = nil
  local durationRepeatProbability = durationRepeatProbabilityInput.value
  local repeatCounter = 1
  while #heldNotes > 0 do
    waitDuration, durationRepeatProbability, repeatCounter = doModulation(waitDuration, durationRepeatProbability, repeatCounter)
  end
end

function remove(voiceId)
  for i,v in ipairs(heldNotes) do
    if v == voiceId then
      table.remove(heldNotes, i)
    end
  end
end

function onNote(e)
  local voiceId = postEvent(e)
  --print("onNote voiceId", voiceId)
  table.insert(heldNotes, voiceId)
  if legato.value == true then
    if #heldNotes == 1 then
      modulateBroadcast()
    end
  else
    spawn(modulateVoice, voiceId)
  end
end

function onRelease(e)
  local voiceId = postEvent(e)
  remove(voiceId)
end
