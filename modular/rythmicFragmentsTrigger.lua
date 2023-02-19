--------------------------------------------------------------------------------
-- Rythmic Fragments - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
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

--setKeyColour(24, "FF0000")
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local playIndex = 1
local evolveFragmentProbability = 0
local randomizeCurrentResolutionProbability = 0
local adjustBias = 50
local channel = 1
--local seqVelTable
--local velocityRandomization
local seqGateTable
local gateRandomization
local numVoices = 1
local playingVoices = {}
local playingIndex = {}
local roundCounterPerVoice = {}
local beatBase = 4
local beatResolution = 1
local recallStoredState = nil -- Holds the index of the stored fragment state to recall
local storedFragments = {} -- Holds stored fragment states
local partOrder = {} -- Holds the playing order of the parts

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
  --local velocityPos = 1
  local velocity = 64--seqVelTable:getValue(velocityPos)
  local gatePos = 1
  local gate = seqGateTable:getValue(gatePos)
  -- Start loop
  while playingIndex[voice] == uniqueId do
    roundCounterPerVoice[voice] = roundCounterPerVoice[voice] + 1

    --velocity, velocityPos = getVelocity(velocityPos)
    gate, gatePos = getGate(gatePos)

    -- TODO Param?
    -- Default is multivoice uses the fragment that corresponds to the voice
    local sources = nil
    if numVoices > 1 then
      sources = {voice}
    end

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
      --print("Play velocity/gate/duration", velocity, gate, noteDuration)
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

local function playVoices(partDuration)
  for voice=1,numVoices do
    if playingVoices[voice] == false then
      playingVoices[voice] = true--isNoteActive(voice)
      if playingVoices[voice] then
        print("Play voice", voice)
        playingIndex[voice] = playIndex
        spawn(play, voice, playIndex, partDuration)
        playIndex = playIndex + 1
      end
    end
  end
end

local function sequenceRunner()
  local previous = nil -- Previous resolution when using evolve
  local partOrderPos = 1 -- Position in the part order
  local partOrderRepeatCounter = 0 -- Counter for part repeats
  local slotIndex = nil -- The currently selected slot
  local remainingDuration = 0
  local partDuration = nil -- When using part order, this is the duration of the parts with repeats
  local partInfo = nil
  local startEvolve = false -- Can be set by part order
  local beatCounter = 1 -- Holds the beat count
  playIndex = 1 -- Reset play index
  isPlaying = true
  initVoices()
  while isPlaying do
    print("Playing beat", beatCounter)
    if beatCounter == 1 then
      --[[ if partOrderButton.value and #partOrder > 0 then
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
      end ]]

      --[[ if type(recallStoredState) == "number" then
        --initVoices()
        recall()
        evolveButton:setValue(startEvolve)
      end ]]

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
      --[[ if evolveButton.value and gem.getRandomBoolean(evolveFragmentProbability.value) then
        previous = rythmicFragments.evolveFragments(previous, randomizeCurrentResolutionProbability.value, adjustBias.value)
      end ]]
    end
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  run(sequenceRunner)
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
rythmPanel.height = 264

--------------------------------------------------------------------------------
-- Sequencer Options
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("Label")
sequencerLabel.text = "Rythmic Fragments Trigger"
sequencerLabel.tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.position = {0,0}
sequencerLabel.size = {sequencerPanel.width,30}

local numVoicesInput = sequencerPanel:NumBox("NumVoices", numVoices, 1, 4, true)
numVoicesInput.displayName = "Voices"
numVoicesInput.tooltip = "Number of voices"
numVoicesInput.size = {90,22}
numVoicesInput.x = sequencerPanel.width - (numVoicesInput.width * 4) - 42
numVoicesInput.y = 5
numVoicesInput.backgroundColour = menuBackgroundColour
numVoicesInput.textColour = menuTextColour
numVoicesInput.changed = function(self)
  numVoices = self.value
  initVoices()
end

local channelInput = sequencerPanel:NumBox("Channel", channel, 1, 16, true)
channelInput.displayName = "Channel"
channelInput.tooltip = "Send note events starting on this channel"
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
autoplayButton.size = {100,22}
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

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, nil, colours, 4, 18, 12)

seqGateTable = rythmPanel:Table("Velocity", 8, 90, 0, 100, true)
seqGateTable.unit = Unit.Percent
seqGateTable.tooltip = "Set gate pattern. If a gate step is set to zero, that step is muted."
seqGateTable.showPopupDisplay = true
seqGateTable.fillStyle = "solid"
seqGateTable.sliderColour = sliderColour
seqGateTable.width = rythmPanel.width - 140
seqGateTable.height = 45
seqGateTable.x = 10
seqGateTable.y = 210

local gateTableLength = rythmPanel:NumBox("GateTableLength", 8, 1, 64, true)
gateTableLength.displayName = "Gate Len"
gateTableLength.tooltip = "Length of gate pattern table"
gateTableLength.width = 120
gateTableLength.height = seqGateTable.height / 2
gateTableLength.x = seqGateTable.x + seqGateTable.width + 1
gateTableLength.y = seqGateTable.y
gateTableLength.backgroundColour = menuBackgroundColour
gateTableLength.textColour = menuTextColour
gateTableLength.changed = function(self)
  seqGateTable.length = self.value
end

gateRandomization = rythmPanel:NumBox("GateRandomization", 15, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Amount of radomization applied to note gate"
gateRandomization.backgroundColour = menuBackgroundColour
gateRandomization.textColour = menuTextColour
gateRandomization.width = gateTableLength.width
gateRandomization.height = gateTableLength.height
gateRandomization.x = gateTableLength.x
gateRandomization.y = gateTableLength.y + gateTableLength.height + 1

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

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
