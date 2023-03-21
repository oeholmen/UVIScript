--------------------------------------------------------------------------------
-- Rythmic Fragments - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"
local rythmicFragments = require "includes.rythmicFragments"

local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local backgroundColour = "202020" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "CFFFFE" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local knobFillColour = "E6D5B8" -- Light
local sliderColour = "5FB5FF"

local colours = {
  backgroundColour = backgroundColour,
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
}

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local playIndex = 0 -- Holds the unique id for each playing voice
local playingIndex = {}
local channel = 1
local seqGateTable
local gateRandomization
local numVoices = 1
local maxVoices = 4
local playingVoices = {}
local roundCounterPerVoice = {}
local beatBase = 4
local beatResolution = 1
local recallStoredState = nil -- Holds the index of the stored fragment state to recall
local storedFragments = {} -- Holds stored fragment states
local partOrder = {} -- Holds the playing order of the parts
local partOrderButton
local evolveButton
local evolveFragmentProbability
local randomizeCurrentResolutionProbability
local adjustBias
local voiceToSourceMapping = {} -- Holds the sources for each voice
local fragmentSlots = {}

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function randomizeGate(gate)
  return gem.randomizeValue(gate, seqGateTable.min, seqGateTable.max, gateRandomization.value)
end

local function getGate(pos)
  return seqGateTable:getValue(pos), gem.inc(pos, 1, seqGateTable.length)
end

local function initVoices()
  playingVoices = {}
  playingIndex = {}
  roundCounterPerVoice = {}
  rythmicFragments.clearResolutionsForEvolve()
  for voice=1,numVoices do
    table.insert(playingVoices, false) -- Init voices
    table.insert(playingIndex, nil) -- Init index
    table.insert(roundCounterPerVoice, 0) -- Init rounds
  end
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive.textColourOn = "black"
  end
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentInputDirty = false
  end
end

local function getSourcesForVoice(voice)
  local sources = {}
  for source,v in ipairs(voiceToSourceMapping[voice]) do
    if gem.getRandomBoolean(v.value) then
      table.insert(sources, source)
      print("Added source for voice", source, voice)
    end
  end
  print("Voice #sources", voice, #sources)
  return sources
end

local function play(voice, uniqueId, partDuration)
  --print("voice, uniqueId, partDuration", voice, uniqueId, partDuration)
  local playDuration = 0 -- Keep track of the played duration
  local duration = nil
  local isFragmentStart = false
  local isRepeat = false
  local mustRepeat = false
  local rest = false
  local activeFragment = nil
  local fragmentPos = 0
  local fragmentRepeatProbability = 0
  local reverseFragment = false
  local fragmentRepeatCount = 0
  local velocity = 64
  local gatePos = 1
  local gate = nil
  -- Start loop
  while isPlaying and playingIndex[voice] == uniqueId do
    roundCounterPerVoice[voice] = roundCounterPerVoice[voice] + 1

    gate, gatePos = getGate(gatePos)

    local sources = getSourcesForVoice(voice)

    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = rythmicFragments.getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount, sources)

    if type(duration) == "nil" or activeFragment.i == 0 then-- or isNoteActive(voice) == false then
      -- Return voice to sequence runner
      playingVoices[voice] = false
      break
    end

    if type(partDuration) == "number" and (playDuration + duration) > partDuration then
      duration = partDuration - playDuration -- Remaining
    end

    -- Update total play duration
    playDuration = playDuration + duration

    local remainingDuration = duration
    if rest == false and gate > 0 then
      local noteDuration = resolutions.getPlayDuration(duration, randomizeGate(gate))
      remainingDuration = duration - noteDuration
      local id = playNote(0, velocity, -1, nil, (voice + channel - 1))
      print("Play duration/voice/channel", noteDuration, voice, (voice + channel - 1))
      waitBeat(noteDuration)
      releaseVoice(id)
      if type(activeFragment) == "table" then
        for i,v in ipairs(paramsPerFragment) do
          if activeFragment.i == i then
            spawn(rythmicFragments.flashFragmentActive, v.fragmentActive, duration)
          end
        end
      end
    end

    if type(partDuration) == "number" and playDuration == partDuration then
      print("playDuration == partDuration", playDuration, "voice " .. voice)
      playingVoices[voice] = false -- Break loop
      break
    end

    if activeFragment.i > 0 and paramsPerFragment[activeFragment.i].fragmentInputDirty then
      paramsPerFragment[activeFragment.i].fragmentInputDirty = false
      playingVoices[voice] = false -- Restart voice next bar to reload fragment input
      print("fragmentInputDirty", "voice " .. voice)
    end

    if remainingDuration > 0 then
      waitBeat(remainingDuration)
    end
  end
end

local function recall()
  -- Find the state we are to recall
  rythmicFragments.setFragmentState(storedFragments[recallStoredState])
  --print("Recalled fragments from stored state", recallStoredState)
  recallStoredState = nil
end

local function playVoices(partDuration)
  for voice=1,numVoices do
    if playingVoices[voice] == false then
      playingVoices[voice] = true--isNoteActive(voice)
      if playingVoices[voice] then
        print("Play voice", voice)
        playIndex = gem.inc(playIndex)
        playingIndex[voice] = playIndex
        spawn(play, voice, playIndex, partDuration)
      end
    end
  end
end

-- Parse the part order input
-- Format: <PART><x|e><REPEATS> separated by comma (use e instead of x to activate evolve). Example: 1x16,2e8,3
-- Set the part to zero "0" to use the current state instead of loading a part
local function setPartOrder(partOrderText)
  partOrder = {} -- Reset
  for s in string.gmatch(partOrderText, "[^,]+") do
    local evolve = type(string.find(s, "e", 1, true)) == "number" -- Check if "e" is given for evolve
    local part = tonumber(string.sub(s, 1, 1)) -- Parts are 1-8, so we get the first pos in the string
    local repeats = tonumber(string.sub(s, 3)) -- Get repeats from the third pos to the end - if any is set
    if type(repeats) ~= "number" then
      repeats = 1
    end
    if type(part) == "number" then
      --print("setPartOrder part, repeats, evolve", part, repeats, evolve)
      table.insert(partOrder, {part=part,repeats=repeats,evolve=evolve})
    end
  end
  --print("#partOrder", #partOrder)
  return partOrder
end

local function sequenceRunner(uniqueId)
  local previous = nil -- Previous resolution when using evolve
  local partOrderPos = 1 -- Position in the part order
  local partOrderRepeatCounter = 0 -- Counter for part repeats
  local slotIndex = nil -- The currently selected slot
  local remainingDuration = 0
  local partDuration = nil -- When using part order, this is the duration of the parts with repeats
  local partInfo = nil
  local startEvolve = false -- Can be set by part order
  local beatCounter = 1 -- Holds the beat count
  initVoices()
  while isPlaying and seqIndex == uniqueId do
    print("Playing beat", beatCounter)
    if beatCounter == 1 then
      if partOrderButton.value and #partOrder > 0 then
        if partOrderRepeatCounter == 0 then
          -- Start new part
          partInfo = partOrder[partOrderPos]
          slotIndex = partInfo.part
          partOrderRepeatCounter = partInfo.repeats
          startEvolve = partInfo.evolve
          --print("startEvolve, slotIndex, partOrderPos", startEvolve, slotIndex, partOrderPos)
          partDuration = partOrderRepeatCounter * beatBase * beatResolution
          remainingDuration = partDuration
          -- If slot is already selected, deactivate so we can select it again
          if slotIndex > 0 then
            print("slotIndex", slotIndex, type(fragmentSlots))
            if fragmentSlots[slotIndex].value == true then
              fragmentSlots[slotIndex]:setValue(false)
            end
            fragmentSlots[slotIndex]:setValue(true)
          end
          -- Increment part order position
          partOrderPos = gem.inc(partOrderPos, 1, #partOrder)
        end

        partOrderRepeatCounter = partOrderRepeatCounter - 1 -- Decrement repeat counter
        --print("Decrementing partOrderRepeatCounter", partOrderRepeatCounter)
      end

      if type(recallStoredState) == "number" then
        initVoices()
        recall()
        evolveButton:setValue(startEvolve)
      end

      --print("beatCounter, remainingDuration, partDuration", beatCounter, remainingDuration, partDuration)
      if type(partDuration) == "nil" or remainingDuration == partDuration or remainingDuration == 0 then
        playVoices(partDuration)
      end
    end

    waitBeat(beatResolution)

    if remainingDuration > 0 then
      remainingDuration = remainingDuration - beatResolution
      --print("SequenceRunner remainingDuration", remainingDuration)
    end

    beatCounter = gem.inc(beatCounter) -- Increment counter
    if beatCounter > beatBase then
      beatCounter = 1 -- Reset counter
      if evolveButton.value and gem.getRandomBoolean(evolveFragmentProbability.value) then
        previous = rythmicFragments.evolveFragments(previous, randomizeCurrentResolutionProbability.value, adjustBias.value)
      end
    end
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(sequenceRunner, seqIndex)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  initVoices()
end

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

local sequencerPanel = Panel("MotionSequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 0
sequencerPanel.y = 0
sequencerPanel.width = 720
sequencerPanel.height = 30

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "404040"
rythmPanel.x = sequencerPanel.x
rythmPanel.y = sequencerPanel.y + sequencerPanel.height + 0
rythmPanel.width = sequencerPanel.width
rythmPanel.height = (102 * (maxVoices / 2)) + 60

local voiceToSourceMappingPanel = widgets.panel({
  backgroundColour = "404040",
  x = rythmPanel.x,
  y = rythmPanel.y,
  width = rythmPanel.width,
  height = rythmPanel.height,
  visible = false,
})

--------------------------------------------------------------------------------
-- Sequencer Options
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("Label")
sequencerLabel.text = "Rythmic Fragments"
sequencerLabel.tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.position = {0,0}
sequencerLabel.size = {sequencerPanel.width,30}

local voicemappingButton = sequencerPanel:Button("VoicemappingButton")
voicemappingButton.displayName = "Settings"
voicemappingButton.tooltip = "Edit the voice to source mapping, and gate pattern"
voicemappingButton.size = {96,22}
voicemappingButton.x = sequencerPanel.width - (voicemappingButton.width * 5) - 25
voicemappingButton.y = 5
voicemappingButton.changed = function(self)
  rythmPanel.visible = rythmPanel.visible == false -- Toggle
  voiceToSourceMappingPanel.visible = rythmPanel.visible == false
  if voiceToSourceMappingPanel.visible then
    self.displayName = "Close"
  else
    self.displayName = "Settings"
  end
end

local numVoicesInput = sequencerPanel:NumBox("NumVoices", numVoices, 1, maxVoices, true)
numVoicesInput.displayName = "Voices"
numVoicesInput.tooltip = "Number of voices. Each voice is mapped to the corresponding channel."
numVoicesInput.size = voicemappingButton.size
numVoicesInput.x = voicemappingButton.x + voicemappingButton.width + 5
numVoicesInput.y = voicemappingButton.y
numVoicesInput.backgroundColour = menuBackgroundColour
numVoicesInput.textColour = menuTextColour
numVoicesInput.changed = function(self)
  numVoices = self.value
  for voice=1,maxVoices do
    for _,v in ipairs(voiceToSourceMapping[voice]) do
      v.enabled = voice <= numVoices
    end
  end

  initVoices()
end

local channelInput = sequencerPanel:NumBox("Channel", channel, 1, 16, true)
channelInput.displayName = "Channel"
channelInput.tooltip = "Send note events starting on this channel. If there are multiple voices, each voice is assigned to a separate channel, starting from the channel set here."
channelInput.size = numVoicesInput.size
channelInput.x = numVoicesInput.x + numVoicesInput.width + 5
channelInput.y = numVoicesInput.y
channelInput.backgroundColour = menuBackgroundColour
channelInput.textColour = menuTextColour
channelInput.changed = function(self)
  channel = self.value
end

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = backgroundColourOff
autoplayButton.backgroundColourOn = backgroundColourOn
autoplayButton.textColourOff = textColourOff
autoplayButton.textColourOn = textColourOn
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = channelInput.size
autoplayButton.x = channelInput.x + channelInput.width + 5
autoplayButton.y = channelInput.y

local playButton = sequencerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = backgroundColourOff
playButton.backgroundColourOn = backgroundColourOn
playButton.textColourOff = textColourOff
playButton.textColourOn = textColourOn
playButton.displayName = "Play"
playButton.size = autoplayButton.size
playButton.x = autoplayButton.x + autoplayButton.width + 5
playButton.y = autoplayButton.y
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, nil, colours, maxVoices, 18, 12)

--- Structure - Store/recall parts, set playing order etc. ---

local loadFragmentMenu = rythmPanel:Menu("LoadFragmentMenu", {"Load..."})
loadFragmentMenu.enabled = false

local storeButton = rythmPanel:Button("StoreButton")
storeButton.displayName = "Store"
storeButton.tooltip = "Store the current state of the fragments"
storeButton.width = 75
storeButton.height = 20
storeButton.x = 15
storeButton.y = 51 * maxVoices

local slotSpacing = 3
local unusedSlotDefaultText = "Unused"
local actions = {"Save..."}
local slotToStoredIndex = {} -- Holds the index of the stored fragment for each slot
for i=1,8 do
  local fragmentSlot = rythmPanel:OnOffButton("StoreFragmentSlot" .. i)
  fragmentSlot.backgroundColourOff = backgroundColourOff
  fragmentSlot.backgroundColourOn = backgroundColourOn
  fragmentSlot.textColourOff = textColourOff
  fragmentSlot.textColourOn = textColourOn
  fragmentSlot.displayName = "" .. i
  fragmentSlot.enabled = false
  fragmentSlot.tooltip = unusedSlotDefaultText
  fragmentSlot.width = 20
  fragmentSlot.height = storeButton.height
  fragmentSlot.x = storeButton.x + storeButton.width + ((i-1) * (fragmentSlot.width + slotSpacing)) + 10
  fragmentSlot.y = storeButton.y
  fragmentSlot.changed = function(self)
    if self.value then
      local storedIndex = slotToStoredIndex[i]
      if type(storedFragments[storedIndex]) == "table" then
        recallStoredState = storedIndex
        --print("Set part/recallStoredState", i, recallStoredState)
        -- If sequencer is not playing, we can recall right now
        if isPlaying == false then
          recall()
        end
      end
    end
    for j,v in ipairs(fragmentSlots) do
      if j ~= i then
        v:setValue(false, false)
      end
    end
  end
  table.insert(fragmentSlots, fragmentSlot)
  table.insert(slotToStoredIndex, nil)
  table.insert(actions, "Save to " .. i)
end

local slotActions = rythmPanel:Menu("SlotActions", actions)
slotActions.tooltip = "Save current fragment state to the selected slot"
slotActions.showLabel = false
slotActions.height = storeButton.height
slotActions.width = 90
slotActions.x = storeButton.x + storeButton.width + ((fragmentSlots[1].width + slotSpacing) * #fragmentSlots) + 15
slotActions.y = storeButton.y
slotActions.backgroundColour = menuBackgroundColour
slotActions.textColour = widgetTextColour
slotActions.arrowColour = menuArrowColour
slotActions.outlineColour = menuOutlineColour
slotActions.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local index = self.value - 1

  -- Save current fragment state
  -- TODO Add options to remove?
  if index <= #fragmentSlots then
    storeButton:changed() -- Store the current state
    slotToStoredIndex[index] = #storedFragments -- Set the most recent stored fragment to this slot
    fragmentSlots[index].tooltip = "Part " .. index .. " - Stored state " .. slotToStoredIndex[index]
    fragmentSlots[index].enabled = true
  end

  -- Must be last
  self:setValue(1, false)
end

loadFragmentMenu.tooltip = "Load a stored fragment state"
loadFragmentMenu.showLabel = false
loadFragmentMenu.height = storeButton.height
loadFragmentMenu.width = slotActions.width
loadFragmentMenu.x = slotActions.x + slotActions.width + 10
loadFragmentMenu.y = slotActions.y
loadFragmentMenu.backgroundColour = menuBackgroundColour
loadFragmentMenu.textColour = widgetTextColour
loadFragmentMenu.arrowColour = menuArrowColour
loadFragmentMenu.outlineColour = menuOutlineColour
loadFragmentMenu.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local index = self.value - 1

  if type(storedFragments[index]) == "table" then
    recallStoredState = index
    -- If sequencer is not playing, we can recall right now
    if isPlaying == false then
      recall()
    end  
  end

  -- Must be last
  self:setValue(1, false)
end

partOrderButton = rythmPanel:OnOffButton("PartOrderLabel")
partOrderButton.displayName = "Part Order"
partOrderButton.tooltip = "Activate part order"
partOrderButton.width = 60
partOrderButton.height = 20
partOrderButton.backgroundColourOff = backgroundColourOff
partOrderButton.backgroundColourOn = backgroundColourOn
partOrderButton.textColourOff = textColourOff
partOrderButton.textColourOn = textColourOn
partOrderButton.x = loadFragmentMenu.x + loadFragmentMenu.width + 10
partOrderButton.y = loadFragmentMenu.y

local partOrderInput = rythmPanel:Label("PartOrderInput")
partOrderInput.text = ""
partOrderInput.tooltip = "Set the playing order of the parts (1-8 as stored in the slots). Format <PART><x|e><REPEATS> separated by comma (use e instead of x to activate evolve). Example: 1x16,2e8,3"
partOrderInput.editable = true
partOrderInput.backgroundColour = "black"
partOrderInput.backgroundColourWhenEditing = "white"
partOrderInput.textColour = "white"
partOrderInput.textColourWhenEditing = "black"
partOrderInput.x = partOrderButton.x + partOrderButton.width
partOrderInput.y = partOrderButton.y
partOrderInput.width = 156
partOrderInput.height = 20
partOrderInput.fontSize = 15
partOrderInput.changed = function(self)
  setPartOrder(self.text)
end

--- Evolve ---

local recallButton = rythmPanel:Button("RecallButton")
recallButton.displayName = "Recall"
recallButton.enabled = false
recallButton.tooltip = "Recall the last stored fragment state"
recallButton.width = storeButton.width
recallButton.height = storeButton.height
recallButton.x = storeButton.x
recallButton.y = storeButton.y + storeButton.height + 10

evolveButton = rythmPanel:OnOffButton("EvolveActive", false)
evolveButton.backgroundColourOff = backgroundColourOff
evolveButton.backgroundColourOn = backgroundColourOn
evolveButton.textColourOff = textColourOff
evolveButton.textColourOn = textColourOn
evolveButton.displayName = "Evolve"
evolveButton.tooltip = "Activate evolve"
evolveButton.width = recallButton.width
evolveButton.height = recallButton.height
evolveButton.x = recallButton.x + recallButton.width + 10
evolveButton.y = recallButton.y

evolveFragmentProbability = rythmPanel:NumBox("EvolveFragmentProbability", 50, 0, 100, true)
evolveFragmentProbability.unit = Unit.Percent
evolveFragmentProbability.textColour = widgetTextColour
evolveFragmentProbability.backgroundColour = widgetBackgroundColour
evolveFragmentProbability.displayName = "Amount"
evolveFragmentProbability.tooltip = "Set the probability that fragments will change over time, using the resolutions present in the fragments"
evolveFragmentProbability.width = 105
evolveFragmentProbability.height = recallButton.height
evolveFragmentProbability.x = evolveButton.x + evolveButton.width + 10
evolveFragmentProbability.y = evolveButton.y

randomizeCurrentResolutionProbability = rythmPanel:NumBox("RandomizeCurrentResolutionProbability", 0, 0, 100, true)
randomizeCurrentResolutionProbability.unit = Unit.Percent
randomizeCurrentResolutionProbability.textColour = widgetTextColour
randomizeCurrentResolutionProbability.backgroundColour = widgetBackgroundColour
randomizeCurrentResolutionProbability.displayName = "Adjust"
randomizeCurrentResolutionProbability.tooltip = "Set the probability that evolve will adjust resolutions (double, half, dot/tri), based on the resolutions present in the fragments"
randomizeCurrentResolutionProbability.width = evolveFragmentProbability.width
randomizeCurrentResolutionProbability.height = evolveFragmentProbability.height
randomizeCurrentResolutionProbability.x = evolveFragmentProbability.x + evolveFragmentProbability.width + 10
randomizeCurrentResolutionProbability.y = evolveFragmentProbability.y

local biasLabel = rythmPanel:Label("BiasLabel")
biasLabel.text = "Bias slow > fast"
biasLabel.tooltip = "Adjust bias: <50=more slow resolutions, >50=more fast resolutions"
biasLabel.alpha = 0.5
biasLabel.fontSize = 15
biasLabel.width = 95
biasLabel.height = randomizeCurrentResolutionProbability.height
biasLabel.x = randomizeCurrentResolutionProbability.x + randomizeCurrentResolutionProbability.width + 10
biasLabel.y = randomizeCurrentResolutionProbability.y

adjustBias = rythmPanel:Knob("Bias", 50, 0, 100, true)
adjustBias.showLabel = false
adjustBias.showValue = false
adjustBias.displayName = "Bias"
adjustBias.tooltip = biasLabel.tooltip
adjustBias.backgroundColour = widgetBackgroundColour
adjustBias.fillColour = knobFillColour
adjustBias.outlineColour = widgetTextColour
adjustBias.width = 20
adjustBias.height = biasLabel.height
adjustBias.x = biasLabel.x + biasLabel.width
adjustBias.y = biasLabel.y

local minResLabel = rythmPanel:Label("MinResolutionsLabel")
minResLabel.text = "Min resolution"
minResLabel.alpha = 0.5
minResLabel.fontSize = 15
minResLabel.width = biasLabel.width
minResLabel.height = adjustBias.height
minResLabel.x = adjustBias.x + adjustBias.width + 10
minResLabel.y = adjustBias.y

local minResolution = rythmPanel:Menu("MinResolution", resolutions.getResolutionNames())
minResolution.displayName = minResLabel.text
minResolution.tooltip = "The highest allowed resolution for evolve adjustments"
minResolution.selected = 26
minResolution.showLabel = false
minResolution.width = 69
minResolution.height = adjustBias.height
minResolution.backgroundColour = widgetBackgroundColour
minResolution.textColour = widgetTextColour
minResolution.arrowColour = menuArrowColour
minResolution.outlineColour = menuOutlineColour
minResolution.x = minResLabel.x + minResLabel.width
minResolution.y = minResLabel.y
minResolution.changed = function(self)
  rythmicFragments.setMaxResolutionIndex(self.value)
end
minResolution:changed()

storeButton.changed = function(self)
  table.insert(storedFragments, rythmicFragments.getFragmentState())
  recallButton.enabled = true
  loadFragmentMenu.enabled = true
  loadFragmentMenu:addItem("State " .. #storedFragments)
end

recallButton.changed = function(self)
  recallStoredState = #storedFragments
  -- If sequencer is not playing, we can recall right now
  if isPlaying == false then
    recall()
  end
end

--------------------------------------------------------------------------------
-- Voice mapping panel
--------------------------------------------------------------------------------

widgets.setSection({
  x = 12,
  y = 12,
  xSpacing = 5,
  ySpacing = 5,
  width = (700 / 4) - 5,
  cols = 4,
})

widgets.button("All On", {
  tooltip = "Set all sources to 100% for all voices",
  changed = function()
    for voice,v in ipairs(voiceToSourceMapping) do
      for source,w in ipairs(v) do
        w.value = 100
      end
    end
  end
})

widgets.button("Voice To Source", {
  tooltip = "Map each voice to the corresponding source",
  changed = function()
    for voice,v in ipairs(voiceToSourceMapping) do
      for source,w in ipairs(v) do
        local val = 0
        if voice == source then
          val = 100
        end    
        w.value = val
      end
    end
  end
})

widgets.button("All Off", {
  tooltip = "Set all sources to 0% for all voices",
  changed = function()
    for voice,v in ipairs(voiceToSourceMapping) do
      for source,w in ipairs(v) do
        w.value = 0
      end
    end
  end
})

widgets.button("Randomize", {
  tooltip = "Set all sources to a random amount for all voices",
  changed = function()
    for voice,v in ipairs(voiceToSourceMapping) do
      for source,w in ipairs(v) do
        w.value = gem.getRandom(100)
      end
    end
  end
})

for voice=1,maxVoices do
  widgets.label("Voice " .. voice)
  voiceToSourceMapping[voice] = {}
end

for source=1,maxVoices do
  for voice=1,maxVoices do
    table.insert(voiceToSourceMapping[voice], widgets.numBox("Source " .. source, 100, {
      name = "source" .. source .. "voice" .. voice,
      tooltip = "Set source " .. source .. " probability for voice " .. voice,
      unit = Unit.Percent,
      enabled = voice <= numVoices
    }))
  end
end

widgets.setSection({
  x = 12,
  y = widgets.posUnder(voiceToSourceMapping[maxVoices][maxVoices]) + 5,
})

seqGateTable = widgets.table("Gate Pattern", 90, 8, {
  unit = Unit.Percent,
  tooltip = "Set gate pattern. If a gate step is set to zero, that step is muted.",
  showLabel = true,
  showPopupDisplay = true,
  width = 700,
  height = 60,
})

widgets.row(1,60)

widgets.numBox("Pattern Length", 8, {
  tooltip = "Length of gate pattern table",
  min = 1,
  max = 64,
  integer = true,
  changed = function(self)
    seqGateTable.length = self.value
  end
})

gateRandomization = widgets.numBox("Gate Randomization", 0, {
  tooltip = "Amount of radomization applied to note gate",
  unit = Unit.Percent,
})

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
   -- Reset play indexes
  seqIndex = 0
  playIndex = 0
end

function onNote(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(true)
  end
end

function onRelease(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(false)
  end
end

function onTransport(start)
  if autoplayButton.value == true then
    playButton:setValue(start)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local fragmentInputData = {}
  local fragmentSlotsData = {}

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  for _,v in ipairs(fragmentSlots) do
    table.insert(fragmentSlotsData, v.tooltip)
  end

  return {fragmentInputData, fragmentSlotsData, storedFragments, partOrderInput.text, slotToStoredIndex}
end

function onLoad(data)
  local fragmentInputData = data[1]
  local fragmentSlotsData = data[2]
  storedFragments = data[3]
  partOrderInput.text = tostring(data[4])
  slotToStoredIndex = data[5]

  setPartOrder(partOrderInput.text)

  if type(storedFragments) == "nil" then
    storedFragments = {}
  end

  if type(fragmentSlotsData) == "nil" then
    fragmentSlotsData = {}
  end

  if type(slotToStoredIndex) == "nil" then
    slotToStoredIndex = {}
    for i=1,#fragmentSlots do
      table.insert(slotToStoredIndex, nil)
    end
  end

  recallButton.enabled = #storedFragments > 0

  for i=1,#storedFragments do
    loadFragmentMenu:addItem("State " .. i)
  end
  loadFragmentMenu.enabled = #storedFragments > 0

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end

  for i,v in ipairs(fragmentSlotsData) do
    fragmentSlots[i].tooltip = v
    fragmentSlots[i].enabled = type(slotToStoredIndex[i]) == "number"
  end
end
