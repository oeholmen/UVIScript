-------------------------------------------------------------------------------
-- Sequencer using rythmic fragments
-------------------------------------------------------------------------------

local gem = require "includes.common"
local resolutions = require "includes.resolutions"
local rythmicFragments = require "includes.rythmicFragments"

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
local knobFillColour = "E6D5B8" -- Light

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
  knobFillColour = knobFillColour,
}

setBackgroundColour(backgroundColour)

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
rythmPanel.height = 218

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("SequencerLabel")
sequencerLabel.text = "Fragment Sequencer"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.width = 180

local activeButton = sequencerPanel:OnOffButton("Active", true)
activeButton.tooltip = "Deactivate to bypass sequencer"
activeButton.backgroundColourOff = "#ff084486"
activeButton.backgroundColourOn = "#ff02ACFE"
activeButton.textColourOff = "#ff22FFFF"
activeButton.textColourOn = "#efFFFFFF"
activeButton.displayName = "Active"
activeButton.fillColour = "#dd000061"
activeButton.size = {102,22}
activeButton.x = sequencerPanel.width - (activeButton.width * 2) - 5
activeButton.y = 5

local holdButton = sequencerPanel:OnOffButton("HoldOnOff", false)
holdButton.tooltip = "Activate to hold notes"
holdButton.backgroundColourOff = "#ff084486"
holdButton.backgroundColourOn = "#ff02ACFE"
holdButton.textColourOff = "#ff22FFFF"
holdButton.textColourOn = "#efFFFFFF"
holdButton.displayName = "Hold"
holdButton.fillColour = "#dd000061"
holdButton.size = {102,22}
holdButton.x = activeButton.x + activeButton.width + 5
holdButton.y = activeButton.y
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
velocityInput.tooltip = "Default velocity for played notes"
velocityInput.width = widgetWidth
velocityInput.x = gateRandomization.x + gateRandomization.width + 10
velocityInput.y = gateRandomization.y

local velocityAccent = settingsPanel:NumBox("VelocityAccent", 64, 1, 127, true)
velocityAccent.textColour = widgetTextColour
velocityAccent.backgroundColour = widgetBackgroundColour
velocityAccent.displayName = "Accent"
velocityAccent.tooltip = "Velocity used at the start of a fragment (if fragment has multiple resolutions)"
velocityAccent.width = widgetWidth
velocityAccent.x = velocityInput.x + velocityInput.width + 10
velocityAccent.y = velocityInput.y

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythm"
rythmLabel.alpha = 0.75
rythmLabel.fontSize = 15
rythmLabel.width = 156

local evolveFragmentProbability = rythmPanel:NumBox("EvolveFragmentProbability", 0, 0, 100, true)
evolveFragmentProbability.unit = Unit.Percent
evolveFragmentProbability.textColour = widgetTextColour
evolveFragmentProbability.backgroundColour = widgetBackgroundColour
evolveFragmentProbability.displayName = "Evolve"
evolveFragmentProbability.tooltip = "Set the probability that fragments will change over time, using the resolutions present in the fragments"
evolveFragmentProbability.width = 120
evolveFragmentProbability.height = 18
evolveFragmentProbability.x = rythmLabel.x + rythmLabel.width
evolveFragmentProbability.y = rythmLabel.y

local randomizeCurrentResolutionProbability = rythmPanel:NumBox("RandomizeCurrentResolutionProbability", 0, 0, 100, true)
randomizeCurrentResolutionProbability.unit = Unit.Percent
randomizeCurrentResolutionProbability.textColour = widgetTextColour
randomizeCurrentResolutionProbability.backgroundColour = widgetBackgroundColour
randomizeCurrentResolutionProbability.displayName = "Adjust"
randomizeCurrentResolutionProbability.tooltip = "Set the probability that evolve will adjust resolutions, based on the resolutions present in the fragments"
randomizeCurrentResolutionProbability.width = evolveFragmentProbability.width
randomizeCurrentResolutionProbability.height = evolveFragmentProbability.height
randomizeCurrentResolutionProbability.x = evolveFragmentProbability.x + evolveFragmentProbability.width + 10
randomizeCurrentResolutionProbability.y = evolveFragmentProbability.y

local biasLabel = rythmPanel:Label("BiasLabel")
biasLabel.text = "Bias slow > fast"
biasLabel.tooltip = "Adjust bias: <50=more slow resolutions, >50=more fast resolutions"
biasLabel.alpha = 0.5
biasLabel.fontSize = 15
biasLabel.width = 90
biasLabel.height = randomizeCurrentResolutionProbability.height
biasLabel.x = randomizeCurrentResolutionProbability.x + randomizeCurrentResolutionProbability.width + 10
biasLabel.y = randomizeCurrentResolutionProbability.y

local adjustBias = rythmPanel:Knob("Bias", 50, 0, 100, true)
adjustBias.showLabel = false
adjustBias.showValue = false
adjustBias.displayName = "Bias"
adjustBias.tooltip = biasLabel.tooltip
adjustBias.backgroundColour = widgetBackgroundColour
adjustBias.fillColour = knobFillColour
adjustBias.outlineColour = widgetTextColour
adjustBias.width = 18
adjustBias.height = biasLabel.height
adjustBias.x = biasLabel.x + biasLabel.width
adjustBias.y = biasLabel.y

local minResLabel = rythmPanel:Label("MinResolutionsLabel")
minResLabel.text = "Min resolution"
minResLabel.alpha = 0.5
minResLabel.fontSize = 15
minResLabel.width = 90
minResLabel.height = adjustBias.height
minResLabel.x = adjustBias.x + adjustBias.width + 10
minResLabel.y = adjustBias.y

local minResolution = rythmPanel:Menu("MinResolution", resolutions.getResolutionNames())
minResolution.displayName = minResLabel.text
minResolution.tooltip = "The highest allowed resolution for evolve adjustments"
minResolution.selected = 26
minResolution.showLabel = false
minResolution.width = 60
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

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, rythmLabel, colours)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

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
  local availableNotes = {}
  for _,v in ipairs(heldNotes) do
    table.insert(availableNotes, v.note)
  end

  if playMode.selectedText == "Up" then
    table.sort(availableNotes)
    table.insert(notes, availableNotes[heldNoteIndex])
  elseif playMode.selectedText == "Down" then
    table.sort(availableNotes, function(a,b) return a > b end)
    table.insert(notes, availableNotes[heldNoteIndex])
  elseif playMode.selectedText == "Random" then
    table.insert(notes, gem.getRandomFromTable(availableNotes))
  elseif playMode.selectedText == "Mono" then
    -- Last held
    table.insert(notes, heldNotes[#heldNotes].note)
  elseif playMode.selectedText == "Duo" then
    -- Lowest and highest held notes
    table.insert(notes, availableNotes[1])
    if #heldNotes > 1 then
      table.insert(notes, availableNotes[#availableNotes])
    end
  elseif playMode.selectedText == "Chord" then
    -- All held notes
    for i=1,#availableNotes do
      table.insert(notes, availableNotes[i])
    end
  else
    table.insert(notes, heldNotes[heldNoteIndex].note)
  end
  print("#notes", #notes)
  return notes, heldNoteIndex
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function stopPlaying()
  isPlaying = false
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive.textColourOn = "black"
  end
end

function play()
  local previous = nil
  local notes = {}
  local heldNoteIndex = 0
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatCount = 0
  local fragmentRepeatProbability = 0
  local duration = nil
  local rest = false
  local reverseFragment = false
  local durationCounter = 0
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
      stopPlaying()
      break
    end
    notes, heldNoteIndex = getNotes(heldNoteIndex)
    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = rythmicFragments.getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
    local gate = gem.randomizeValue(gateInput.value, gateInput.min, gateInput.max, gateRandomization.value)
    local doPlayNote = gate > 0 and rest == false and #notes > 0 and type(duration) == "number" and activeButton.value == true
    if doPlayNote then
      -- TODO Add option to accent every n-th beat?
      local velocity = velocityInput.value
      -- Use accent value in fragment start, if there is more than one resolution defined in the fragment
      if isFragmentStart and #activeFragment.f > 1 then
        velocity = velocityAccent.value
      end
      velocity = velocity + heldNotes[heldNoteIndex].velocity / 2 -- 50% between played velocity and sequencer velocity
      for _,note in ipairs(notes) do
        playNote(note, velocity, beat2ms(resolutions.getPlayDuration(duration, gate)) - offset)
      end
    end
    if type(duration) == "nil" then
      duration = 1 -- Failsafe
    end
    waitBeat(duration)
    durationCounter = durationCounter + duration
    if durationCounter >= 4 then
      durationCounter = 0 -- Reset counter
      if gem.getRandomBoolean(evolveFragmentProbability.value) then
        previous = rythmicFragments.evolveFragments(previous, randomizeCurrentResolutionProbability.value, adjustBias.value)
      end
    end
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
  if activeButton.value == false then
    postEvent(e)
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
