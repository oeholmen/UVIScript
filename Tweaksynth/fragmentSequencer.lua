-------------------------------------------------------------------------------
-- Sequencer using rythmic fragments
-------------------------------------------------------------------------------

require "common"

local isPlaying = false
local heldNotes = {}

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "F637EC"
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"

local colours = {
  backgroundColour = backgroundColour,
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = labelTextColour,
  menuBackgroundColour = menuBackgroundColour,
  menuArrowColour = menuArrowColour,
  menuOutlineColour = menuOutlineColour
}

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Rytmic Fragments
--------------------------------------------------------------------------------

local resolutionFragments = {
  {'1/16','1/16','1/8'},
  {'1/16','1/8','1/16'},
  {'1/4 dot','1/8'},
  {'1/4 dot','1/16','1/16'},
  {'1/4','1/8','1/8'},
  {'1/8','1/4','1/8'},
  {'1/16','1/8 dot'},
  {'2x'},
  {'4x'},
}

function getFragmentInputText(fragment)
  if #fragment == 0 then
    return ""
  end
  return table.concat(fragment, ",")
end

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

local sequencerPanel = Panel("RandomNoteGenerator")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 36

local settingsPanel = Panel("Settings")
settingsPanel.backgroundColour = backgroundColour
settingsPanel.x = sequencerPanel.x
settingsPanel.y = sequencerPanel.y + sequencerPanel.height + 5
settingsPanel.width = 700
settingsPanel.height = 30

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "505050"
rythmPanel.x = settingsPanel.x
rythmPanel.y = settingsPanel.y + settingsPanel.height
rythmPanel.width = 700
rythmPanel.height = 215

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("SequencerLabel")
sequencerLabel.text = "Fragment Sequencer"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.width = 210

local holdButton = sequencerPanel:OnOffButton("HoldOnOff", false)
holdButton.backgroundColourOff = "#ff084486"
holdButton.backgroundColourOn = "#ff02ACFE"
holdButton.textColourOff = "#ff22FFFF"
holdButton.textColourOn = "#efFFFFFF"
holdButton.displayName = "Hold"
holdButton.fillColour = "#dd000061"
holdButton.size = {102,22}
holdButton.x = sequencerPanel.width - holdButton.width
holdButton.y = 5
holdButton.changed = function(self)
  if self.value == false then
    heldNotes = {}
  end
end

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

local widgetWidth = 659 / 5

local playMode = settingsPanel:Menu("PlayMode", {"As Played", "Up", "Down", "Random", "Mono", "Duo", "Chord"})
playMode.showLabel = false
playMode.tooltip = "Select Play Mode"
playMode.x = 5
playMode.y = 0
playMode.width = widgetWidth
playMode.height = 20
playMode.backgroundColour = menuBackgroundColour
playMode.textColour = widgetTextColour
playMode.arrowColour = menuArrowColour
playMode.outlineColour = menuOutlineColour

local gateInput = settingsPanel:NumBox("Gate", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.textColour = widgetTextColour
gateInput.backgroundColour = widgetBackgroundColour
gateInput.displayName = "Gate"
gateInput.tooltip = "Note gate"
gateInput.width = widgetWidth
gateInput.x = playMode.x + playMode.width + 10
gateInput.y = playMode.y

local gateRandomization = settingsPanel:NumBox("GateRand", 0, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.width = widgetWidth
gateRandomization.x = gateInput.x + gateInput.width + 10
gateRandomization.y = gateInput.y

local velocityInput = settingsPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Note velocity"
velocityInput.width = widgetWidth
velocityInput.x = gateRandomization.x + gateRandomization.width + 10
velocityInput.y = gateRandomization.y

local velocityAccent = settingsPanel:NumBox("VelocityAccent", 64, 1, 127, true)
velocityAccent.textColour = widgetTextColour
velocityAccent.backgroundColour = widgetBackgroundColour
velocityAccent.displayName = "Accent"
velocityAccent.tooltip = "Velocity accent amount triggered on the start of a fragment"
velocityAccent.width = widgetWidth
velocityAccent.x = velocityInput.x + velocityInput.width + 10
velocityAccent.y = velocityInput.y

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythm"
--rythmLabel.tooltip = "Rythm"
rythmLabel.alpha = 0.75
rythmLabel.fontSize = 15
rythmLabel.width = 50

local paramsPerFragment = {}

for i=1,4 do
  local offsetX = 0
  local offsetY = 24
  local defaultResolution = ""

  if i == 1 then
    defaultResolution = "1/8"
  elseif i == 2 then
    offsetX = 354
  elseif i == 3 then
    offsetY = 123
  elseif i == 4 then
    offsetX = 354
    offsetY = 123
  end

  local fragmentActive = rythmPanel:OnOffButton("FragmentActive" .. i, true)
  fragmentActive.backgroundColourOff = backgroundColourOff
  fragmentActive.backgroundColourOn = backgroundColourOn
  fragmentActive.textColourOff = "black"
  fragmentActive.textColourOn = "black"
  fragmentActive.fontSize = 24
  fragmentActive.displayName = "" .. i
  fragmentActive.tooltip = "Set fragment active for selection"
  fragmentActive.size = {24,30}
  fragmentActive.x = rythmLabel.x + offsetX
  fragmentActive.y = rythmLabel.y + rythmLabel.height + offsetY
  
  -- Fragment Input
  local fragmentInput = rythmPanel:Label("FragmentInput" .. i)
  fragmentInput.text = defaultResolution -- TODO Set a default
  fragmentInput.tooltip = "Type resolutions of the fragment definition (resolution name (1/8) or beat value (0.5)), separated by comma (,)"
  fragmentInput.editable = true
  fragmentInput.backgroundColour = labelTextColour
  fragmentInput.backgroundColourWhenEditing = "white"
  fragmentInput.textColour = "white"
  fragmentInput.textColourWhenEditing = labelTextColour
  fragmentInput.x = fragmentActive.x + fragmentActive.width + 3
  fragmentInput.y = fragmentActive.y + 0
  fragmentInput.width = 235
  fragmentInput.height = 30
  fragmentInput.fontSize = 20

  -- Menus
  local actions = {"Actions...", "Create fragment (even)", "Create fragment (dot)", "Create fragment (even+dot)", "Create fragment (tri)", "Create fragment (all)", "Create fragment (extended)"}
  local fragmentActions = rythmPanel:Menu("FragmentActions" .. i, actions)
  fragmentActions.tooltip = "Select an action (replaces current input!)"
  fragmentActions.showLabel = false
  fragmentActions.height = 20
  fragmentActions.width = 75
  fragmentActions.x = fragmentInput.x
  fragmentActions.y = fragmentInput.y - 24
  fragmentActions.backgroundColour = menuBackgroundColour
  fragmentActions.textColour = widgetTextColour
  fragmentActions.arrowColour = menuArrowColour
  fragmentActions.outlineColour = menuOutlineColour
  fragmentActions.changed = function(self)
    if self.value > 1 then
      -- Create
      local resolutions = getResolutions()
      local fragmentDefinition = createFragmentDefinition(self.value-1)
      local tmp = {}
      for _,v in ipairs(fragmentDefinition) do
        local index = getIndexFromValue(v, resolutions)
        local text = v
        print("index, text", index, text)
        if type(index) == "number" then
          text = getResolutionName(index)
          print("text", text)
        end
        table.insert(tmp, text)
      end
      print("#tmp", #tmp)
      fragmentInput.text = getFragmentInputText(tmp)
    end
    -- Must be last
    self:setValue(1, false)
  end

  local resolutionsByType = getResolutionsByType(26)
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
  fragmentAdd.backgroundColour = menuBackgroundColour
  fragmentAdd.textColour = widgetTextColour
  fragmentAdd.arrowColour = menuArrowColour
  fragmentAdd.outlineColour = menuOutlineColour
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
  fragmentLoad.backgroundColour = menuBackgroundColour
  fragmentLoad.textColour = widgetTextColour
  fragmentLoad.arrowColour = menuArrowColour
  fragmentLoad.outlineColour = menuOutlineColour
  fragmentLoad.changed = function(self)
    fragmentInput.text = self.selectedText
    -- Must be last
    self:setValue(1, false)
  end

  -- Add p = play probability
  local fragmentPlayProbabilityLabel = rythmPanel:Label("FragmentPlayProbabilityLabel" .. i)
  fragmentPlayProbabilityLabel.text = "p"
  fragmentPlayProbabilityLabel.tooltip = "Probability that this fragment will be selected"
  fragmentPlayProbabilityLabel.textColour = labelTextColour
  fragmentPlayProbabilityLabel.alpha = 0.5
  fragmentPlayProbabilityLabel.fontSize = 20
  fragmentPlayProbabilityLabel.width = 20
  fragmentPlayProbabilityLabel.x = fragmentInput.x
  fragmentPlayProbabilityLabel.y = fragmentInput.y + fragmentInput.height + 3

  local fragmentPlayProbability = rythmPanel:NumBox("FragmentPlayProbability" .. i, 100, 0, 100, true)
  fragmentPlayProbability.unit = Unit.Percent
  fragmentPlayProbability.showLabel = false
  fragmentPlayProbability.tooltip = fragmentPlayProbabilityLabel.tooltip
  fragmentPlayProbability.textColour = widgetTextColour
  fragmentPlayProbability.backgroundColour = widgetBackgroundColour
  fragmentPlayProbability.width = 36
  fragmentPlayProbability.x = fragmentPlayProbabilityLabel.x + fragmentPlayProbabilityLabel.width - 1
  fragmentPlayProbability.y = fragmentPlayProbabilityLabel.y

  -- Add r = repeat probability
  local fragmentRepeatProbabilityLabel = rythmPanel:Label("FragmentRepeatProbabilityLabel" .. i)
  fragmentRepeatProbabilityLabel.text = "r"
  fragmentRepeatProbabilityLabel.tooltip = "Probability that this rythmic fragment will be repeated"
  fragmentRepeatProbabilityLabel.textColour = labelTextColour
  fragmentRepeatProbabilityLabel.alpha = 0.5
  fragmentRepeatProbabilityLabel.fontSize = 20
  fragmentRepeatProbabilityLabel.width = fragmentPlayProbabilityLabel.width
  fragmentRepeatProbabilityLabel.x = fragmentPlayProbability.x + fragmentPlayProbability.width + 5
  fragmentRepeatProbabilityLabel.y = fragmentPlayProbability.y

  local fragmentRepeatProbability = rythmPanel:NumBox("FragmentRepeatProbability" .. i, 100, 0, 100, true)
  fragmentRepeatProbability.unit = Unit.Percent
  fragmentRepeatProbability.showLabel = false
  fragmentRepeatProbability.tooltip = fragmentRepeatProbabilityLabel.tooltip
  fragmentRepeatProbability.textColour = widgetTextColour
  fragmentRepeatProbability.backgroundColour = widgetBackgroundColour
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
  fragmentRepeatProbabilityDecay.textColour = widgetTextColour
  fragmentRepeatProbabilityDecay.backgroundColour = widgetBackgroundColour
  fragmentRepeatProbabilityDecay.width = fragmentRepeatProbability.width
  fragmentRepeatProbabilityDecay.x = fragmentRepeatProbabilityDecayLabel.x + fragmentRepeatProbabilityDecayLabel.width - 1
  fragmentRepeatProbabilityDecay.y = fragmentRepeatProbabilityDecayLabel.y

  -- TODO Add m = min repeats
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
  fragmentMinRepeats.textColour = widgetTextColour
  fragmentMinRepeats.backgroundColour = widgetBackgroundColour
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
  randomizeFragmentProbability.textColour = widgetTextColour
  randomizeFragmentProbability.backgroundColour = widgetBackgroundColour
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
  reverseFragmentProbabilityLabel.y = fragmentInput.y + 5

  local reverseFragmentProbability = rythmPanel:NumBox("ReverseProbability" .. i, 0, 0, 100, true)
  reverseFragmentProbability.unit = Unit.Percent
  reverseFragmentProbability.showLabel = false
  reverseFragmentProbability.tooltip = reverseFragmentProbabilityLabel.tooltip
  reverseFragmentProbability.textColour = widgetTextColour
  reverseFragmentProbability.backgroundColour = widgetBackgroundColour
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
  restProbability.textColour = widgetTextColour
  restProbability.backgroundColour = widgetBackgroundColour
  restProbability.width = fragmentRepeatProbability.width
  restProbability.x = restProbabilityLabel.x + restProbabilityLabel.width - 1
  restProbability.y = restProbabilityLabel.y

  table.insert(paramsPerFragment, {fragmentInput=fragmentInput, fragmentActive=fragmentActive, fragmentPlayProbability=fragmentPlayProbability, randomizeFragmentProbability=randomizeFragmentProbability, reverseFragmentProbability=reverseFragmentProbability, restProbability=restProbability, fragmentRepeatProbability=fragmentRepeatProbability, fragmentRepeatProbabilityDecay=fragmentRepeatProbabilityDecay, fragmentMinRepeats=fragmentMinRepeats})
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

-- Include all durations faster than the total fragmentDuration
function addDurations(resolutions, durations, fragmentDuration)
  for _,i in ipairs(resolutions) do
    local duration = getResolution(i)
    if duration <= fragmentDuration then
      table.insert(durations, duration)
      print("Inserted duration", duration)
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
    durationType = 6
  end
  local minResolution = 23
  local resolutionsByType = getResolutionsByType(minResolution)
  local currentDuration = 0
  local fragmentDuration = getRandomFromTable({1,2,4,8}) -- TODO Param?
  print("Selected fragmentDuration", fragmentDuration)
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
  print("Found durations", #durations)
  -- Select durations for the definition
  while currentDuration < fragmentDuration do
    local duration = getRandomFromTable(durations)
    if currentDuration + duration > fragmentDuration then
      duration = fragmentDuration - currentDuration
      print("currentDuration + duration > fragmentDuration", currentDuration, duration, fragmentDuration)
    end
    currentDuration = currentDuration + duration
    table.insert(definition, duration)
    print("Add duration", duration)
  end
  return definition
end

function verifyInput(duration)
  if type(duration) == "number" then
    return true
  end

  return tableIncludes(getResolutionNames(), duration)
end

function parseFragment(fragmentInputIndex)
  if type(fragmentInputIndex) == "nil" then
    return
  end
  local fragmentInput = paramsPerFragment[fragmentInputIndex].fragmentInput
  local fragmentPlayProbability = paramsPerFragment[fragmentInputIndex].fragmentPlayProbability.value
  local fragmentActive = paramsPerFragment[fragmentInputIndex].fragmentActive.value
  if fragmentActive and string.len(fragmentInput.text) > 0 and getRandomBoolean(fragmentPlayProbability) then
    local fragment = {}
    for w in string.gmatch(fragmentInput.text, "[^,]+") do
      w = trimStartAndEnd(w)
      if verifyInput(w) then
        print("Add to fragment", w)
        table.insert(fragment, w)
      end
    end
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
      i=fragmentInputIndex,
      f=fragment,
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

function getSelectedFragments()
  local selectedFragments = {}
  for i=1, #paramsPerFragment do
    local fragment = parseFragment(i)
    if type(fragment) == "table" then
      table.insert(selectedFragments, fragment)
    end
  end
  print("Fragments selected from inputs", #selectedFragments)
  return selectedFragments
end

function getFragment()
  local fragment = getRandomFromTable(getSelectedFragments())

  if type(fragment) == "table" then
    return fragment
  end

  -- Return fallback value (1/8)
  return {f={0.5}, p=100, r=0, d=0, rev=0, rnd=0, rst=0}
end

function getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
  local velocity = velocityInput.value
  if type(activeFragment) == "nil" or (reverseFragment == false and fragmentPos == #activeFragment.f) or (reverseFragment and fragmentPos == 1) then
    velocity = velocityAccent.value
    -- END OF FRAGMENT (or no fragemt selected)
    fragmentRepeatCount = fragmentRepeatCount + 1
    -- Check modulo for grouping/required number of repeats
    local mustRepeat = false
    if type(activeFragment) == "table" and type(activeFragment.m) == "number" then
      print("***MustRepeat?*** fragmentRepeatCount % activeFragment.m", fragmentRepeatCount, activeFragment.m, (fragmentRepeatCount % activeFragment.m))
      mustRepeat = fragmentRepeatCount % activeFragment.m > 0
    end

    -- Reload fragment in case parameters are changed
    if type(activeFragment) == "table" then
      local fragment = parseFragment(activeFragment.i)
      if type(fragment) == "table" or mustRepeat == false then
        activeFragment = fragment
      end
    end

    print("FRAGMENT fragmentRepeatCount, mustRepeat", fragmentRepeatCount, mustRepeat)
    if type(activeFragment) == "table" and (mustRepeat or getRandomBoolean(fragmentRepeatProbability)) then
      -- REPEAT FRAGMENT
      fragmentRepeatProbability = fragmentRepeatProbability - (fragmentRepeatProbability * (activeFragment.d / 100))
      print("REPEAT FRAGMENT, fragmentRepeatProbability", fragmentRepeatProbability)
    else
      -- CHANGE FRAGMENT
      fragmentRepeatCount = 0 -- Init repeat counter
      -- Change to a new fragment input
      activeFragment = getFragment()
      for i,v in ipairs(paramsPerFragment) do
        if i == activeFragment.i then
          v.fragmentActive.textColourOn = textColourOn
        else
          v.fragmentActive.textColourOn = "black"
        end
      end
      fragmentRepeatProbability = activeFragment.r
      print("CHANGE FRAGMENT, #fragment, fragmentRepeatProbability", #activeFragment.f, fragmentRepeatProbability)
    end
    -- RANDOMIZE fragment
    randomizeFragment = getRandomBoolean(activeFragment.rnd)
    if randomizeFragment and #activeFragment.f > 1 then
      local tmp = {}
      local seen = {}
      local maxRounds = 100
      while #seen < #activeFragment.f and maxRounds > 0 do
        local i = getRandom(#activeFragment.f)
        print("maxRounds outer", maxRounds)
        while tableIncludes(seen, i) do
          i = getRandom(#activeFragment.f)
          maxRounds = maxRounds - 1
          print("maxRounds inner", maxRounds)
        end
        table.insert(tmp, activeFragment.f[i])
        table.insert(seen, i)
        print("#seen, i", #seen, i)
      end
      activeFragment.f = tmp
      print("randomizeFragment")
    end
    -- REVERSE fragment
    reverseFragment = getRandomBoolean(activeFragment.rev)
    if reverseFragment and #activeFragment.f > 1 then
      print("REVERSE fragment", reverseFragment)
      fragmentPos = #activeFragment.f
    else
      fragmentPos = 1
    end
    print("SET fragmentPos", fragmentPos)
  else
    -- INCREMENT fragment pos
    local increment = 1
    if reverseFragment then
      increment = -increment
    end
    fragmentPos = fragmentPos + increment
    print("INCREMENT FRAGMENT POS", fragmentPos)
  end

  -- Get fragment at current position
  local duration = activeFragment.f[fragmentPos]
  if type(duration) == "string" or type(duration) == "nil" then
    -- If duration is string, we must resolve it from resolution names
    local resolutionIndex = getIndexFromValue(duration, getResolutionNames())
    if type(resolutionIndex) == "nil" then
      resolutionIndex = 20 -- 1/8 as a failsafe in case the resolution could not be resolved
    else
      duration = getResolution(resolutionIndex)
    end
  end

  print("RETURN duration", duration)

  local rest = getRandomBoolean(activeFragment.rst)

  return duration, velocity, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount
end

function getNotes(heldNoteIndex)
  -- Reset notes table
  local notes = {} -- Holds the note(s) that plays at this position

  -- Increment held note position
  heldNoteIndex = heldNoteIndex + 1
  if heldNoteIndex > #heldNotes then
    heldNoteIndex = 1
  end

  -- Add notes to play
  -- "As Played", "Up", "Down", "Random", "Mono", "Duo", "Chord"
  local sortedNotes = {}
  for _,v in ipairs(heldNotes) do
    table.insert(sortedNotes, v.note)
  end
  if playMode.value == 3 then -- Down
    table.sort(sortedNotes, function(a,b) return a > b end)
  else
    table.sort(sortedNotes, function(a,b) return a < b end)
  end

  if playMode.value == 1 then
    -- As played
    table.insert(notes, heldNotes[heldNoteIndex].note)
  elseif playMode.value == 2 then
    -- Up
    table.insert(notes, sortedNotes[heldNoteIndex])
  elseif playMode.value == 3 then
    -- Down
    table.insert(notes, sortedNotes[heldNoteIndex])
  elseif playMode.value == 4 then
    -- Random
    table.insert(notes, getRandomFromTable(sortedNotes))
  elseif playMode.value == 5 then
    -- Mono (Last held)
    table.insert(notes, heldNotes[#heldNotes].note)
  elseif playMode.value == 6 then
    -- Duo (Lowest and highest held notes)
    table.insert(notes, sortedNotes[1])
    if #heldNotes > 1 then
      table.insert(notes, sortedNotes[#sortedNotes])
    end
  elseif playMode.value == 7 then
    -- Chord
    for i=1,#sortedNotes do
      table.insert(notes, sortedNotes[i])
    end
  end
  print("#notes", #notes)
  return notes, heldNoteIndex
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function play()
  local notes = {}
  local heldNoteIndex = 0
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatCount = 0
  local fragmentRepeatProbability = 0
  local duration = nil
  local rest = false
  local velocity = nil
  local reverseFragment = false
  while isPlaying do
    local offset = 0
    if #heldNotes == 0 then
      local buffer = 1 -- How long to wait for notes before stopping the sequencer
      wait(buffer)
      print("waiting for heldNotes", buffer)
      offset = offset + buffer
    end
    if #heldNotes == 0 then
      print("#heldNotes == 0 - stopping sequencer")
      isPlaying = false
      break
    end
    notes, heldNoteIndex = getNotes(heldNoteIndex)
    duration, velocity, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
    local gate = randomizeValue(gateInput.value, gateInput.min, gateInput.max, gateRandomization.value)
    local doPlayNote = gate > 0 and rest == false and #notes > 0
    if doPlayNote then
      velocity = velocity + heldNotes[heldNoteIndex].velocity / 2 -- 50% between played velocity and sequencer velocity
      for _,note in ipairs(notes) do
        playNote(note, velocity, beat2ms(getPlayDuration(duration, gate)) - offset)
      end
    end
    waitBeat(duration)
  end
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  if holdButton.value == true then
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        -- When hold button is active
        -- we remove the note from held notes
        -- if table has more than one note
        if #heldNotes > 1 then
          table.remove(heldNotes, i)
        end
        break
      end
    end
  end
  table.insert(heldNotes, e)
  if #heldNotes == 1 and isPlaying == false then
    isPlaying = true
    spawn(play)
  end
end

function onRelease(e)
  if holdButton.value == false then
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        table.remove(heldNotes, i)
      end
    end
    postEvent(e)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local fragmentInputData = {}

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  return {fragmentInputData}
end

function onLoad(data)
  local fragmentInputData = data[1]

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end
end
