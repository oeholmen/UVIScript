--------------------------------------------------------------------------------
-- Common functions for working with rythmic fragments
--------------------------------------------------------------------------------

require "../includes/common"

local paramsPerFragment = {}

-- Expand defaults
local resolutionFragments = {
  {'1/16','1/16','1/8'},
  {'1/16','1/8','1/16'},
  {'1/4 dot','1/8'},
  {'1/4 dot','1/16','1/16'},
  {'1/4','1/8','1/8'},
  {'1/8','1/4','1/8'},
  {'1/4','1/8','1/16','1/16'},
  {'1/16','1/8 dot'},
  {'1/8 dot','1/16'},
  {'1/2 dot','1/4'},
  {'1/16','1/16','1/16','1/16','1/16','1/16','1/16','1/32','1/32'},
  {'1/8 dot'},
  {'2x'},
  {'4x'},
}

-- Turn all recognized fragment items into note names
function fragmentDefinitionToResolutionNames(fragmentDefinition)
  local resolutions = getResolutions()
  local parsed = {}
  for _,v in ipairs(fragmentDefinition) do
    local index = getIndexFromValue(v, resolutions)
    local text = v
    --print("index, text", index, text)
    if type(index) == "number" then
      text = getResolutionName(index)
      --print("text", text)
    end
    table.insert(parsed, text)
  end
  return parsed
end

function getBeatValueForResolutionName(val)
  local index = getIndexFromValue(val, getResolutionNames())
  if type(index) == "number" then
    return getResolution(index)
  end
  return val
end

function calculateFragmentDuration(fragmentText)
  local fragment = createFragmentFromText(fragmentText)
  local total = 0
  for _,v in ipairs(fragment) do
    total = total + v
    --print("calculateFragmentDuration v, total", v, total)
  end
  --print("TOTAL", total)
  return total
end

-- Get the fragment as text for fragment input
function getFragmentInputText(fragment)
  if #fragment == 0 then
    return ""
  end
  return table.concat(fragment, ",")
end

-- Include all durations faster than the total fragmentDuration
function addDurations(resolutions, durations, fragmentDuration)
  for _,i in ipairs(resolutions) do
    local duration = getResolution(i)
    if duration <= fragmentDuration then
      table.insert(durations, duration)
      --print("Inserted duration", duration)
    end
  end
  return durations
end

-- Auto generate fragment
-- durationType:
--    "Create fragment (even)" 1
--    "Create fragment (dot)" 2
--    "Create fragment (even+dot)" 3
--    "Create fragment (tri)" 4
--    "Create fragment (all)" 5
--    "Create fragment (extended)" 6
function createFragmentDefinition(durationType)
  if type(durationType) == "nil" then
    durationType = 1
  end
  local minResolution = 23
  local resolutionsByType = getResolutionsByType(minResolution, true)
  local currentDuration = 0
  local fragmentDuration = getRandomFromTable({1,2,4}) -- TODO Param?
  --print("Selected fragmentDuration", fragmentDuration)
  local definition = {}
  local durations = {}
  -- Add resolutions that can fit inside the fragmentDuration
  if durationType == 1 or durationType == 3 or durationType == 5 then
    durations = addDurations(resolutionsByType[1], durations, fragmentDuration)
  end
  if durationType == 2 or durationType == 3 or durationType == 5 then
    durations = addDurations(resolutionsByType[2], durations, fragmentDuration)
  end
  if durationType == 4 or durationType == 5 then
    durations = addDurations(resolutionsByType[3], durations, fragmentDuration)
  end
  if durationType == 6 then
    for _,v in ipairs(getResolutionsByType()) do
      durations = addDurations(v, durations, fragmentDuration)
    end
  end
  --print("Found durations", #durations)
  -- Select durations for the definition
  while currentDuration < fragmentDuration do
    local duration = getRandomFromTable(durations)
    if currentDuration + duration > fragmentDuration then
      duration = fragmentDuration - currentDuration
      --print("currentDuration + duration > fragmentDuration", currentDuration, duration, fragmentDuration)
    end
    currentDuration = currentDuration + duration
    table.insert(definition, duration)
    --print("Add duration", duration)
  end
  return definition
end

function parseToBeatValue(duration)
  if type(tonumber(duration)) == "number" then
    duration = tonumber(duration)
    --print("Duration is number", duration)
    return duration
  end

  --print("Duration is NOT a number, try to find beat value from name", duration)
  local index = getIndexFromValue(duration, getResolutionNames())
  if type(index) == "number" then
    return getResolution(index)
  end

  --print("Could not resolve duration, returning 0", duration)
  return 0
end

function createFragmentFromText(fragmentText)
  local fragment = {}
  if string.len(fragmentText) > 0 then
    for w in string.gmatch(fragmentText, "[^,]+") do
      --print("Before parse", w)
      w = parseToBeatValue(trimStartAndEnd(w))
      --print("Add to fragment", w)
      table.insert(fragment, w)
    end
  end
  return fragment
end

function parseFragment(fragmentInputIndex)
  if type(fragmentInputIndex) == "nil" then
    return
  end
  local fragmentInput = paramsPerFragment[fragmentInputIndex].fragmentInput
  local fragmentPlayProbability = paramsPerFragment[fragmentInputIndex].fragmentPlayProbability.value
  local fragmentActive = paramsPerFragment[fragmentInputIndex].fragmentActive.value
  if fragmentActive and string.len(fragmentInput.text) > 0 and getRandomBoolean(fragmentPlayProbability) then
    local fragment = createFragmentFromText(fragmentInput.text)
    local selectProbability = 100
    local repeatProbability = paramsPerFragment[fragmentInputIndex].fragmentRepeatProbability.value
    local repeatProbabilityDecay = paramsPerFragment[fragmentInputIndex].fragmentRepeatProbabilityDecay.value
    local minRepeats = paramsPerFragment[fragmentInputIndex].fragmentMinRepeats.value
    local reverseFragmentProbability = paramsPerFragment[fragmentInputIndex].reverseFragmentProbability.value
    local randomizeFragmentProbability = paramsPerFragment[fragmentInputIndex].randomizeFragmentProbability.value
    local restProbability = paramsPerFragment[fragmentInputIndex].restProbability.value
    -- i = the fragment input number
    -- f = the resolutions of the fragment definition (resolution name (1/8) or beat value (0.5))
    -- p = probability of include
    -- r = repeat probability
    -- d = repeat probability decay
    -- m = min repeats
    -- rev = reverse probability
    -- rnd = random order probability
    -- rst = rest probability
    return {
      f=fragment,
      i=fragmentInputIndex,
      p=selectProbability,
      r=repeatProbability,
      d=repeatProbabilityDecay,
      m=minRepeats,
      rnd=randomizeFragmentProbability,
      rev=reverseFragmentProbability,
      rst=restProbability,
    }
  end
end

function getSelectedFragments(fragmentIndexes)
  local selectedFragments = {}
  for i=1, #paramsPerFragment do
    local fragment = parseFragment(i)
    local includeFragment = type(fragmentIndexes) ~= "table" or tableIncludes(fragmentIndexes, i)
    if type(fragment) == "table" and includeFragment then
      table.insert(selectedFragments, fragment)
    end
  end
  return selectedFragments
end

function getFragment(fragmentIndexes)
  local fragment = getRandomFromTable(getSelectedFragments(fragmentIndexes))

  if type(fragment) == "table" then
    return fragment
  end

  return {f={}, i=0, p=0, r=0, d=0, rev=0, rnd=0, rst=0}
end

function getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount, sources)
  local isRepeat = false
  local isFragmentStart = type(activeFragment) == "nil" or (reverseFragment == false and fragmentPos == #activeFragment.f) or (reverseFragment and fragmentPos == 1)
  if isFragmentStart then
    local mustRepeat = false
    -- Start fragment (previous fragment is completed or no fragemt is selected)
    fragmentRepeatCount = fragmentRepeatCount + 1
    -- Check modulo for grouping/required number of repeats
    if type(activeFragment) == "table" and type(activeFragment.m) == "number" then
      --print("***MustRepeat?*** fragmentRepeatCount % activeFragment.m", fragmentRepeatCount, activeFragment.m, (fragmentRepeatCount % activeFragment.m))
      mustRepeat = fragmentRepeatCount % activeFragment.m > 0
    end

    -- Reload fragment in case parameters are changed
    if type(activeFragment) == "table" then
      local fragment = parseFragment(activeFragment.i)
      if type(fragment) == "table" or mustRepeat == false then
        activeFragment = fragment
      end
    end

    --print("FRAGMENT fragmentRepeatCount, mustRepeat", fragmentRepeatCount, mustRepeat)
    if type(activeFragment) == "table" and (mustRepeat or getRandomBoolean(fragmentRepeatProbability)) then
      -- REPEAT FRAGMENT
      isRepeat = true
      fragmentRepeatProbability = fragmentRepeatProbability - (fragmentRepeatProbability * (activeFragment.d / 100))
      --print("REPEAT FRAGMENT, fragmentRepeatProbability", fragmentRepeatProbability)
    else
      -- CHANGE FRAGMENT
      fragmentRepeatCount = 0 -- Init repeat counter
      -- Register old fragemnt index (if any)
      local prevFragmentIndex = nil
      if type(activeFragment) == "table" then
        prevFragmentIndex = activeFragment.i
      end
      -- Change to a new fragment input
      activeFragment = getFragment(sources)
      isRepeat = prevFragmentIndex == activeFragment.i -- Check if same as previous
      for i,v in ipairs(paramsPerFragment) do
        if i == activeFragment.i then
          v.fragmentActive.textColourOn = "white"
        else
          v.fragmentActive.textColourOn = "black"
        end
      end
      fragmentRepeatProbability = activeFragment.r
      --print("CHANGE FRAGMENT, #fragment, fragmentRepeatProbability", #activeFragment.f, fragmentRepeatProbability)
    end
    -- RANDOMIZE fragment
    randomizeFragment = #activeFragment.f > 1 and getRandomBoolean(activeFragment.rnd)
    if randomizeFragment then
      local tmp = {}
      local seen = {}
      local maxRounds = 100
      while #seen < #activeFragment.f and maxRounds > 0 do
        local i = getRandom(#activeFragment.f)
        --print("maxRounds outer", maxRounds)
        while tableIncludes(seen, i) do
          i = getRandom(#activeFragment.f)
          maxRounds = maxRounds - 1
          --print("maxRounds inner", maxRounds)
        end
        table.insert(tmp, activeFragment.f[i])
        table.insert(seen, i)
        --print("#seen, i", #seen, i)
      end
      activeFragment.f = tmp
      --print("randomizeFragment")
    end
    -- REVERSE fragment
    reverseFragment = #activeFragment.f > 1 and getRandomBoolean(activeFragment.rev)
    if reverseFragment then
      --print("REVERSE fragment", reverseFragment)
      fragmentPos = #activeFragment.f
    else
      fragmentPos = 1
    end
    --print("SET fragmentPos", fragmentPos)
  else
    -- INCREMENT fragment pos
    local increment = 1
    if reverseFragment then
      increment = -increment
    end
    fragmentPos = fragmentPos + increment
    --print("INCREMENT FRAGMENT POS", fragmentPos)
  end

  -- Get fragment at current position
  local duration = activeFragment.f[fragmentPos]

  --print("RETURN duration", duration)

  local rest = getRandomBoolean(activeFragment.rst)

  return duration, isFragmentStart, isRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount
end

function getParamsPerFragment(rythmPanel, rythmLabel, colours, numSelectors)
  if type(numSelectors) == "nil" then
    numSelectors = 4
  end
  local perColumn = 2
  local rowCounter = 0
  local columnCounter = 0
  for i=1,numSelectors do
    local offsetX = 354
    local offsetY = 100
    local defaultResolution = ""

    offsetX = offsetX * columnCounter
    offsetY = (offsetY * rowCounter) + 30
  
    if i == 1 then
      defaultResolution = "1/8"
    end

    -- Increment counters
    columnCounter = columnCounter + 1
    if columnCounter >= perColumn then
      columnCounter = 0
      rowCounter = rowCounter + 1
    end

    local fragmentActive = rythmPanel:OnOffButton("FragmentActive" .. i, true)
    fragmentActive.backgroundColourOff = colours.backgroundColourOff
    fragmentActive.backgroundColourOn = colours.backgroundColourOn
    fragmentActive.textColourOff = "black"
    fragmentActive.textColourOn = "black"
    fragmentActive.fontSize = 20
    fragmentActive.displayName = "" .. i
    fragmentActive.tooltip = "Toggle fragment on/off"
    fragmentActive.size = {24,24}
    fragmentActive.x = rythmLabel.x + offsetX
    fragmentActive.y = rythmLabel.y + rythmLabel.height + offsetY
    
    -- Fragment Input
    local fragmentInput = rythmPanel:Label("FragmentInput" .. i)
    fragmentInput.text = defaultResolution
    fragmentInput.label = "Input the resolutions of the fragment definition. Use resolution names (1/8) or beat values (0.5), separated by comma (,)"
    fragmentInput.tooltip = fragmentInput.label
    fragmentInput.editable = true
    fragmentInput.backgroundColour = colours.labelTextColour
    fragmentInput.backgroundColourWhenEditing = "white"
    fragmentInput.textColour = "white"
    fragmentInput.textColourWhenEditing = colours.labelTextColour
    fragmentInput.x = fragmentActive.x + fragmentActive.width + 3
    fragmentInput.y = fragmentActive.y + 0
    fragmentInput.width = 235
    fragmentInput.height = 24
    fragmentInput.fontSize = 14
    fragmentInput.changed = function(self)
      local total = calculateFragmentDuration(self.text)
      if total == 0 then
        fragmentInput.tooltip = fragmentInput.label
      else
        fragmentInput.tooltip = "Total beat duration is " .. total
      end
    end
  
    -- Menus
    local actions = {"Actions...", "Create fragment (even)", "Create fragment (dot)", "Create fragment (even+dot)", "Create fragment (tri)", "Create fragment (all)", "Create fragment (extended)"}
    local fragmentActions = rythmPanel:Menu("FragmentActions" .. i, actions)
    fragmentActions.tooltip = "Select an action (replaces current input!)"
    fragmentActions.showLabel = false
    fragmentActions.height = 20
    fragmentActions.width = 75
    fragmentActions.x = fragmentInput.x
    fragmentActions.y = fragmentInput.y - 24
    fragmentActions.backgroundColour = colours.menuBackgroundColour
    fragmentActions.textColour = colours.widgetTextColour
    fragmentActions.arrowColour = colours.menuArrowColour
    fragmentActions.outlineColour = colours.menuOutlineColour
    fragmentActions.changed = function(self)
      if self.value > 1 then
        -- Create
        local fragmentDefinition = fragmentDefinitionToResolutionNames(createFragmentDefinition(self.value-1))
        --print("#fragmentDefinition", #fragmentDefinition)
        fragmentInput.text = getFragmentInputText(fragmentDefinition)
      end
      -- Must be last
      self:setValue(1, false)
    end
  
    local resolutionsByType = getResolutionsByType(26, false)
    local addToFragment = {"Add..."}
    for i=1,3 do
      for _,v in ipairs(resolutionsByType[i]) do
        table.insert(addToFragment, getResolutionName(v))
      end
    end
  
    local fragmentAdd = rythmPanel:Menu("FragmentAdd" .. i, addToFragment)
    fragmentAdd.tooltip = "Add to the fragment"
    fragmentAdd.showLabel = false
    fragmentAdd.height = 20
    fragmentAdd.width = fragmentActions.width
    fragmentAdd.x = fragmentActions.x + fragmentActions.width + 5
    fragmentAdd.y = fragmentActions.y
    fragmentAdd.backgroundColour = colours.menuBackgroundColour
    fragmentAdd.textColour = colours.widgetTextColour
    fragmentAdd.arrowColour = colours.menuArrowColour
    fragmentAdd.outlineColour = colours.menuOutlineColour
    fragmentAdd.changed = function(self)
      if string.len(fragmentInput.text) == 0 then
        fragmentInput.text = self.selectedText
      else
        fragmentInput.text = fragmentInput.text .. "," .. self.selectedText
      end
      -- Must be last
      self:setValue(1, false)
    end
  
    local loadFragment = {"Load..."}
    for _,v in ipairs(resolutionFragments) do
      table.insert(loadFragment, getFragmentInputText(v))
    end
  
    local fragmentLoad = rythmPanel:Menu("FragmentLoad" .. i, loadFragment)
    fragmentLoad.tooltip = "Load fragment (replaces current input!)"
    fragmentLoad.showLabel = false
    fragmentLoad.height = 20
    fragmentLoad.width = fragmentActions.width
    fragmentLoad.x = fragmentAdd.x + fragmentAdd.width + 5
    fragmentLoad.y = fragmentAdd.y
    fragmentLoad.backgroundColour = colours.menuBackgroundColour
    fragmentLoad.textColour = colours.widgetTextColour
    fragmentLoad.arrowColour = colours.menuArrowColour
    fragmentLoad.outlineColour = colours.menuOutlineColour
    fragmentLoad.changed = function(self)
      fragmentInput.text = self.selectedText
      -- Must be last
      self:setValue(1, false)
    end
  
    -- Add p = play probability
    local fragmentPlayProbabilityLabel = rythmPanel:Label("FragmentPlayProbabilityLabel" .. i)
    fragmentPlayProbabilityLabel.text = "p"
    fragmentPlayProbabilityLabel.tooltip = "Probability that this fragment will be selected"
    fragmentPlayProbabilityLabel.textColour = colours.labelTextColour
    fragmentPlayProbabilityLabel.alpha = 0.5
    fragmentPlayProbabilityLabel.fontSize = 20
    fragmentPlayProbabilityLabel.width = 20
    fragmentPlayProbabilityLabel.x = fragmentInput.x
    fragmentPlayProbabilityLabel.y = fragmentInput.y + fragmentInput.height + 3
  
    local fragmentPlayProbability = rythmPanel:NumBox("FragmentPlayProbability" .. i, 100, 0, 100, true)
    fragmentPlayProbability.unit = Unit.Percent
    fragmentPlayProbability.showLabel = false
    fragmentPlayProbability.tooltip = fragmentPlayProbabilityLabel.tooltip
    fragmentPlayProbability.textColour = colours.widgetTextColour
    fragmentPlayProbability.backgroundColour = colours.widgetBackgroundColour
    fragmentPlayProbability.width = 36
    fragmentPlayProbability.x = fragmentPlayProbabilityLabel.x + fragmentPlayProbabilityLabel.width - 1
    fragmentPlayProbability.y = fragmentPlayProbabilityLabel.y
  
    -- Add r = repeat probability
    local fragmentRepeatProbabilityLabel = rythmPanel:Label("FragmentRepeatProbabilityLabel" .. i)
    fragmentRepeatProbabilityLabel.text = "r"
    fragmentRepeatProbabilityLabel.tooltip = "Probability that this rythmic fragment will be repeated"
    fragmentRepeatProbabilityLabel.textColour = colours.labelTextColour
    fragmentRepeatProbabilityLabel.alpha = 0.5
    fragmentRepeatProbabilityLabel.fontSize = 20
    fragmentRepeatProbabilityLabel.width = fragmentPlayProbabilityLabel.width
    fragmentRepeatProbabilityLabel.x = fragmentPlayProbability.x + fragmentPlayProbability.width + 5
    fragmentRepeatProbabilityLabel.y = fragmentPlayProbability.y
  
    local fragmentRepeatProbability = rythmPanel:NumBox("FragmentRepeatProbability" .. i, 100, 0, 100, true)
    fragmentRepeatProbability.unit = Unit.Percent
    fragmentRepeatProbability.showLabel = false
    fragmentRepeatProbability.tooltip = fragmentRepeatProbabilityLabel.tooltip
    fragmentRepeatProbability.textColour = colours.widgetTextColour
    fragmentRepeatProbability.backgroundColour = colours.widgetBackgroundColour
    fragmentRepeatProbability.width = fragmentPlayProbability.width
    fragmentRepeatProbability.x = fragmentRepeatProbabilityLabel.x + fragmentRepeatProbabilityLabel.width - 1
    fragmentRepeatProbability.y = fragmentRepeatProbabilityLabel.y
  
    -- Add d = repeat probability decay
    local fragmentRepeatProbabilityDecayLabel = rythmPanel:Label("FragmentRepeatProbabilityDecayLabel" .. i)
    fragmentRepeatProbabilityDecayLabel.text = "d"
    fragmentRepeatProbabilityDecayLabel.tooltip = "The reduction in repeat probability for each iteration of the fragment"
    fragmentRepeatProbabilityDecayLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    fragmentRepeatProbabilityDecayLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    fragmentRepeatProbabilityDecayLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    fragmentRepeatProbabilityDecayLabel.width = fragmentRepeatProbabilityLabel.width
    fragmentRepeatProbabilityDecayLabel.x = fragmentRepeatProbability.x + fragmentRepeatProbability.width + 5
    fragmentRepeatProbabilityDecayLabel.y = fragmentRepeatProbability.y
  
    local fragmentRepeatProbabilityDecay = rythmPanel:NumBox("FragmentRepeatProbabilityDecay" .. i, 25, 0, 100, true)
    fragmentRepeatProbabilityDecay.unit = Unit.Percent
    fragmentRepeatProbabilityDecay.showLabel = false
    fragmentRepeatProbabilityDecay.tooltip = fragmentRepeatProbabilityDecayLabel.tooltip
    fragmentRepeatProbabilityDecay.textColour = colours.widgetTextColour
    fragmentRepeatProbabilityDecay.backgroundColour = colours.widgetBackgroundColour
    fragmentRepeatProbabilityDecay.width = fragmentRepeatProbability.width
    fragmentRepeatProbabilityDecay.x = fragmentRepeatProbabilityDecayLabel.x + fragmentRepeatProbabilityDecayLabel.width - 1
    fragmentRepeatProbabilityDecay.y = fragmentRepeatProbabilityDecayLabel.y
  
    -- Add m = min repeats
    local fragmentMinRepeatsLabel = rythmPanel:Label("FragmentRepeatProbabilityDecayLabel" .. i)
    fragmentMinRepeatsLabel.text = "m"
    fragmentMinRepeatsLabel.tooltip = "Minimum repeats for this fragment"
    fragmentMinRepeatsLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    fragmentMinRepeatsLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    fragmentMinRepeatsLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    fragmentMinRepeatsLabel.width = fragmentRepeatProbabilityLabel.width
    fragmentMinRepeatsLabel.x = fragmentRepeatProbabilityDecay.x + fragmentRepeatProbabilityDecay.width + 5
    fragmentMinRepeatsLabel.y = fragmentRepeatProbabilityDecay.y
  
    local fragmentMinRepeats = rythmPanel:NumBox("FragmentMinRepeats" .. i, 1, 1, 64, true)
    fragmentMinRepeats.showLabel = false
    fragmentMinRepeats.tooltip = fragmentMinRepeatsLabel.tooltip
    fragmentMinRepeats.textColour = colours.widgetTextColour
    fragmentMinRepeats.backgroundColour = colours.widgetBackgroundColour
    fragmentMinRepeats.width = 26
    fragmentMinRepeats.x = fragmentMinRepeatsLabel.x + fragmentMinRepeatsLabel.width - 1
    fragmentMinRepeats.y = fragmentMinRepeatsLabel.y
  
    -- Randomize fragment probability
    local randomizeFragmentProbabilityLabel = rythmPanel:Label("RandomizeFragmentProbabilityLabel" .. i)
    randomizeFragmentProbabilityLabel.text = "rnd"
    randomizeFragmentProbabilityLabel.tooltip = "Probability that rythmic fragments will be played in random order"
    randomizeFragmentProbabilityLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    randomizeFragmentProbabilityLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    randomizeFragmentProbabilityLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    randomizeFragmentProbabilityLabel.width = 30
    randomizeFragmentProbabilityLabel.x = fragmentLoad.x + fragmentLoad.width + 0
    randomizeFragmentProbabilityLabel.y = fragmentLoad.y
  
    local randomizeFragmentProbability = rythmPanel:NumBox("RandomizeFragmentProbability" .. i, 0, 0, 100, true)
    randomizeFragmentProbability.unit = Unit.Percent
    randomizeFragmentProbability.showLabel = false
    randomizeFragmentProbability.tooltip = "Probability that rythmic fragments will be played in random order"
    randomizeFragmentProbability.textColour = colours.widgetTextColour
    randomizeFragmentProbability.backgroundColour = colours.widgetBackgroundColour
    randomizeFragmentProbability.width = fragmentRepeatProbability.width
    randomizeFragmentProbability.x = randomizeFragmentProbabilityLabel.x + randomizeFragmentProbabilityLabel.width - 1
    randomizeFragmentProbability.y = randomizeFragmentProbabilityLabel.y
  
    -- Reverse fragment probability
    local reverseFragmentProbabilityLabel = rythmPanel:Label("ReverseFragmentProbabilityLabel" .. i)
    reverseFragmentProbabilityLabel.text = "rev"
    reverseFragmentProbabilityLabel.tooltip = "Probability that rythmic fragments will be played backwards"
    reverseFragmentProbabilityLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    reverseFragmentProbabilityLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    reverseFragmentProbabilityLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    reverseFragmentProbabilityLabel.width = randomizeFragmentProbabilityLabel.width
    reverseFragmentProbabilityLabel.x = randomizeFragmentProbabilityLabel.x
    reverseFragmentProbabilityLabel.y = fragmentInput.y + 2
  
    local reverseFragmentProbability = rythmPanel:NumBox("ReverseProbability" .. i, 0, 0, 100, true)
    reverseFragmentProbability.unit = Unit.Percent
    reverseFragmentProbability.showLabel = false
    reverseFragmentProbability.tooltip = reverseFragmentProbabilityLabel.tooltip
    reverseFragmentProbability.textColour = colours.widgetTextColour
    reverseFragmentProbability.backgroundColour = colours.widgetBackgroundColour
    reverseFragmentProbability.width = fragmentRepeatProbability.width
    reverseFragmentProbability.x = reverseFragmentProbabilityLabel.x + reverseFragmentProbabilityLabel.width - 1
    reverseFragmentProbability.y = reverseFragmentProbabilityLabel.y
  
    -- Rest probability
    local restProbabilityLabel = rythmPanel:Label("RestProbabilityLabel" .. i)
    restProbabilityLabel.text = "rst"
    restProbabilityLabel.tooltip = "Probability that rythmic fragments will be include rests"
    restProbabilityLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    restProbabilityLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    restProbabilityLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    restProbabilityLabel.width = randomizeFragmentProbabilityLabel.width
    restProbabilityLabel.x = reverseFragmentProbabilityLabel.x
    restProbabilityLabel.y = fragmentMinRepeats.y
  
    local restProbability = rythmPanel:NumBox("RestProbability" .. i, 0, 0, 100, true)
    restProbability.unit = Unit.Percent
    restProbability.showLabel = false
    restProbability.tooltip = restProbabilityLabel.tooltip
    restProbability.textColour = colours.widgetTextColour
    restProbability.backgroundColour = colours.widgetBackgroundColour
    restProbability.width = fragmentRepeatProbability.width
    restProbability.x = restProbabilityLabel.x + restProbabilityLabel.width - 1
    restProbability.y = restProbabilityLabel.y

    table.insert(paramsPerFragment, {fragmentInput=fragmentInput, fragmentActive=fragmentActive, fragmentPlayProbability=fragmentPlayProbability, randomizeFragmentProbability=randomizeFragmentProbability, reverseFragmentProbability=reverseFragmentProbability, restProbability=restProbability, fragmentRepeatProbability=fragmentRepeatProbability, fragmentRepeatProbabilityDecay=fragmentRepeatProbabilityDecay, fragmentMinRepeats=fragmentMinRepeats})
  end
  return paramsPerFragment
end
