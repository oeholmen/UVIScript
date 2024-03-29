-------------------------------------------------------------------------------
-- Beatbox using rythmic fragments (Fragmented Beats)
-------------------------------------------------------------------------------

local gem = require "includes.common"
local resolutions = require "includes.resolutions"
local rythmicFragments = require "includes.rythmicFragments"

local playIndex = 1
local beatResolution = 1
local beatBase = 4
local noteListen = nil
local numNotes = 8
local voices = 8
local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local playingVoices = {}
local playingIndex = {}
local roundCounterPerVoice = {}
local partInEditMode = nil
local paramsPerNote = {}
local paramsPerFragment = {}
local bounds = {}
local recallStoredState = nil -- Holds the index of the stored fragment state to recall
local storedFragments = {} -- Holds stored fragment states
local partOrder = {} -- Holds the playing order of the parts

-- Add maps for different setups
local noteMap = {36,38,42,39,41,49,54,66}
local noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Cymbal", "Tambourine", "Perc"}

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "3AB0FF"
local menuBackgroundColour = "01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"
local knobFillColour = "E6D5B8" -- Light
local outlineColour = "#FFB5FF"

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

local notePanel = Panel("Notes")
notePanel.backgroundColour = "202020"
notePanel.x = settingsPanel.x
notePanel.y = settingsPanel.y + settingsPanel.height + 5
notePanel.width = 700
notePanel.height = 106

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "505050"
rythmPanel.x = notePanel.x
rythmPanel.y = notePanel.y + notePanel.height + 5
rythmPanel.width = 700
rythmPanel.height = 470

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("SequencerLabel")
sequencerLabel.text = "Fragmented Beats"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.width = 160

meter = sequencerPanel:AudioMeter("OutputLevel", Part, false, 0, true)
meter.height = sequencerLabel.height
meter.width = sequencerLabel.width
meter.x = sequencerLabel.x + sequencerLabel.width + 15
meter.y = sequencerLabel.y
meter["0dBColour"] = "red"
meter["3dBColour"] = "orange"
meter["6dBColour"] = "yellow"
meter["10dBColour"] = "green"

local channelButton = sequencerPanel:OnOffButton("ChannelButton", false)
channelButton.backgroundColourOff = backgroundColourOff
channelButton.backgroundColourOn = backgroundColourOn
channelButton.textColourOff = textColourOff
channelButton.textColourOn = textColourOn
channelButton.displayName = "Multichannel"
channelButton.tooltip = "When multichannel mode is enabled, each voice is sent to a separate channel"
channelButton.size = {100,22}
channelButton.x = sequencerPanel.width - (channelButton.width * 3) - 10
channelButton.y = 5

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = backgroundColourOff
autoplayButton.backgroundColourOn = backgroundColourOn
autoplayButton.textColourOff = textColourOff
autoplayButton.textColourOn = textColourOn
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = channelButton.size
autoplayButton.x = channelButton.x + channelButton.width + 5
autoplayButton.y = channelButton.y

local playButton = sequencerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = backgroundColourOff
playButton.backgroundColourOn = backgroundColourOn
playButton.textColourOff = textColourOff
playButton.textColourOn = textColourOn
playButton.displayName = "Play"
playButton.size = autoplayButton.size
playButton.x = autoplayButton.x + autoplayButton.width + 5
playButton.y = channelButton.y
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

local widgetHeight = 20
local widgetWidth = 659 / 4

local timeSignatures = {"4/4", "3/4", "5/4", "6/8"}
local timeSignature = settingsPanel:Menu("TimeSignature", timeSignatures)
timeSignature.tooltip = "Select a time signature - this mostly just affects the accents"
timeSignature.showLabel = false
timeSignature.backgroundColour = colours.menuBackgroundColour
timeSignature.textColour = colours.widgetTextColour
timeSignature.arrowColour = colours.menuArrowColour
timeSignature.outlineColour = colours.menuOutlineColour
timeSignature.height = widgetHeight
timeSignature.width = widgetWidth
timeSignature.x = 5
timeSignature.y = 0
timeSignature.changed = function(self)
  local signature = {}
  for w in string.gmatch(self.selectedText, "%d+") do
    table.insert(signature, w)
  end
  beatBase = tonumber(signature[1])
  beatResolution = resolutions.getResolution(gem.getIndexFromValue("1/" .. signature[2], resolutions.getResolutionNames()))
end

local velocityInput = settingsPanel:NumBox("Velocity", 90, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Velocity amount triggered on beats that are not accented"
velocityInput.height = widgetHeight
velocityInput.width = timeSignature.width
velocityInput.x = timeSignature.x + timeSignature.width + 10
velocityInput.y = timeSignature.y

local velocityAccent = settingsPanel:NumBox("VelocityAccent", 127, 1, 127, true)
velocityAccent.textColour = widgetTextColour
velocityAccent.backgroundColour = widgetBackgroundColour
velocityAccent.displayName = "Accent"
velocityAccent.tooltip = "Velocity amount triggered on accented beats"
velocityAccent.height = widgetHeight
velocityAccent.width = velocityInput.width
velocityAccent.x = velocityInput.x + velocityInput.width + 10
velocityAccent.y = velocityInput.y

local templates = {
  "Tools...",
  --- Note Maps --
  "--- Mappings ---",
  "BeatBox Anthology 2",
  "Drum Designer",
  "Drumulation",
  "Percussion Factory",
  "Prime 8",
  "Program 24",
  "Soul Drums",
  "Super 7",
  --- Templates ---
  "--- Templates ---",
  "Kick on down, snare on up",
  "Four on the floor",
  --- Notes ---
  "--- Notes ---",
  "Mute all",
  "Unmute all",
  "Toggle mute",
  "Set all note probabilities to 100%",
  "Set all note probabilities to 0%",
  "Randomize note probabilities",
  "Randomize note triggers",
  --- Rests ---
  "--- Rests ---",
  "All rests off",
  "Randomize rests",
  --- Rythmic fragments ---
  "--- Rythmic fragments ---",
  "Clear fragments",
  "Randomize fragments",
  "Randomize fragments (single)",
  "Randomize fragments (slow)",
  "Randomize fragments (extended)",
  --- Part sources ---
  "--- Part sources ---",
  "Part to source",
  "All sources on",
  "All sources off",
  "Randomize source probability",
  --- All settings ---
  "--- All settings ---",
  "Set to default",
  "Set to zero",
  "Randomize",
}
local templateMenu = settingsPanel:Menu("Templates", templates)
templateMenu.tooltip = "Select a tool - NOTE: Will change current settings!"
templateMenu.showLabel = false
templateMenu.height = widgetHeight
templateMenu.width = widgetWidth
templateMenu.x = velocityAccent.x + velocityAccent.width + 10
templateMenu.y = velocityAccent.y
templateMenu.backgroundColour = colours.menuBackgroundColour
templateMenu.textColour = colours.widgetTextColour
templateMenu.arrowColour = colours.menuArrowColour
templateMenu.outlineColour = colours.menuOutlineColour
templateMenu.changed = function(self)
  if self.value == 1 then
    return
  end
  for part,v in ipairs(paramsPerNote) do
    for source,w in ipairs(v.sourceSelectors) do
      if self.selectedText == "Part to source" then
        if part == source then
          w:setValue(100)
        else
          w:setValue(0)
        end
      elseif self.selectedText == "Randomize" or self.selectedText == "Randomize source probability" then
        w:setValue(gem.getRandom(100))
      elseif self.selectedText == "All sources on" or self.selectedText == "Set to default" then
        w:setValue(100)
      elseif self.selectedText == "All sources off" or self.selectedText == "Set to zero" then
        w:setValue(0)
      end
    end
    if self.selectedText == "BeatBox Anthology 2" then
      noteMap = {36,38,42,39,41,49,54,66}
      noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Cymbal", "Tambourine", "Perc"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Drum Designer" then
      noteMap = {36,38,40,42,44,46,49,39}
      noteLabels = {"Kick", "Snare 1", "Snare 2", "Hihat 1", "Hihat 2", "Open HH", "Cymbal", "Clap"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Drumulation" then
      noteMap = {36,38,42,39,43,46,37,41}
      noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Open HH", "Rimshot", "Cowbell"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Percussion Factory" then
      noteMap = {24,26,28,29,31,33,35,36}
      noteLabels = {"Perc 1", "Perc 2", "Perc 3", "Perc 4", "Perc 5", "Perc 6", "Perc 7", "Perc 8"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Prime 8" then
      noteMap = {36,38,42,39,41,49,37,47}
      noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Cymbal", "Rimshot", "Cowbell"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Program 24" then
      noteMap = {36,38,42,39,41,49,37,48}
      noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Cymbal", "Snare 2", "Bongo"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Soul Drums" then
      noteMap = {36,38,42,39,41,49,37,54}
      noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Cymbal", "Rimshot", "Tambourine"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Super 7" then
      noteMap = {36,38,42,39,41,49,37,50}
      noteLabels = {"Kick", "Snare", "Hihat", "Clap", "Low Tom", "Cymbal", "Rimshot", "Perc"}
      v.noteInput.value = noteMap[part]
      v.noteInputLabel.text = noteLabels[part]
    elseif self.selectedText == "Mute all" then
      v.mute:setValue(true)
    elseif self.selectedText == "Unmute all" then
      v.mute:setValue(false)
    elseif self.selectedText == "All rests off" then
      v.restDownBeatProbability:setValue(0)
      v.restUpBeatProbability:setValue(0)
      v.restFirstInFragmentProbability:setValue(0)
    elseif self.selectedText == "Set all note probabilities to 100%" then
      v.noteProbability:setValue(100)
    elseif self.selectedText == "Set all note probabilities to 0%" then
      v.noteProbability:setValue(0)
    elseif self.selectedText == "Toggle mute" then
      v.mute:setValue(v.mute.value == false)
    elseif self.selectedText == "Clear fragments" then
      paramsPerFragment[part].fragmentInput.text = ""
    elseif self.selectedText == "Randomize fragments" then
      paramsPerFragment[part].fragmentInput.text = getRandomFragment(1)
    elseif self.selectedText == "Randomize fragments (single)" then
      paramsPerFragment[part].fragmentInput.text = getRandomFragment(2)
    elseif self.selectedText == "Randomize fragments (extended)" then
      paramsPerFragment[part].fragmentInput.text = getRandomFragment(3)
    elseif self.selectedText == "Randomize fragments (slow)" then
      paramsPerFragment[part].fragmentInput.text = getRandomFragment(4)
    elseif self.selectedText == "Randomize note probabilities" then
      v.noteProbability:setValue(gem.getRandom(100))
    elseif self.selectedText == "Randomize note triggers" then
      v.noteInput:setValue(gem.getRandom(21, 108))
    elseif self.selectedText == "Randomize rests" then
      v.restDownBeatProbability:setValue(gem.getRandom(100))
      v.restUpBeatProbability:setValue(gem.getRandom(100))
      v.restFirstInFragmentProbability:setValue(gem.getRandom(100))
    elseif self.selectedText == "Randomize" then
      paramsPerFragment[part].fragmentInput.text = getRandomFragment(1)
      v.mute:setValue(false)
      v.accentFragmentStart:setValue(gem.getRandomBoolean(25))
      v.accentDownBeat:setValue(gem.getRandomBoolean(25))
      v.accentUpBeat:setValue(gem.getRandomBoolean(25))
      --v.accent:setValue(gem.getRandom(v.accent.max))
      v.restDownBeatProbability:setValue(gem.getRandom(25))
      v.restUpBeatProbability:setValue(gem.getRandom(25))
      v.restFirstInFragmentProbability:setValue(gem.getRandom(25))
      v.noteProbability:setValue(gem.getRandom(100))
    elseif self.selectedText == "Set to default" then
      if part == 1 then
        paramsPerFragment[part].fragmentInput.text = "1/8"
      else
        paramsPerFragment[part].fragmentInput.text = ""
      end
      v.mute:setValue(false)
      v.accentFragmentStart:setValue(false)
      v.accentDownBeat:setValue(false)
      v.accentUpBeat:setValue(false)
      --v.accent:setValue(0)
      v.restDownBeatProbability:setValue(0)
      v.restUpBeatProbability:setValue(0)
      v.restFirstInFragmentProbability:setValue(0)
      v.noteProbability:setValue(100)
    elseif self.selectedText == "Set to zero" then
      paramsPerFragment[part].fragmentInput.text = ""
      v.mute:setValue(false)
      v.accentFragmentStart:setValue(false)
      v.accentDownBeat:setValue(false)
      v.accentUpBeat:setValue(false)
      --v.accent:setValue(0)
      v.restFirstInFragmentProbability:setValue(0)
      v.noteProbability:setValue(0)
      v.restDownBeatProbability:setValue(0)
      v.restUpBeatProbability:setValue(0)
    elseif self.selectedText == "Kick on down, snare on up" then
      if part == 1 then
        v.mute:setValue(false)
        v.sourceSelectors[1]:setValue(100)
        v.sourceSelectors[2]:setValue(100)
        v.noteProbability:setValue(100)
        v.restDownBeatProbability:setValue(0)
        v.restUpBeatProbability:setValue(100)
      elseif part == 2 then
        v.mute:setValue(false)
        v.sourceSelectors[1]:setValue(100)
        v.sourceSelectors[2]:setValue(100)
        v.noteProbability:setValue(100)
        v.restDownBeatProbability:setValue(100)
        v.restUpBeatProbability:setValue(0)
      end
    elseif self.selectedText == "Four on the floor" then
      if part == 1 then
        v.mute:setValue(false)
        v.sourceSelectors[1]:setValue(100)
        v.sourceSelectors[2]:setValue(100)
        v.noteProbability:setValue(100)
        v.restDownBeatProbability:setValue(0)
        v.restUpBeatProbability:setValue(0)
      elseif part == 2 then
        v.mute:setValue(false)
        v.sourceSelectors[1]:setValue(100)
        v.sourceSelectors[2]:setValue(100)
        v.noteProbability:setValue(100)
        v.restDownBeatProbability:setValue(100)
        v.restUpBeatProbability:setValue(0)
      end
    end
  end
  if self.selectedText == "Four on the floor" or self.selectedText == "Kick on down, snare on up" then
    paramsPerFragment[1].fragmentInput.text = "1/4"
  end
  -- Must be last
  self:setValue(1, false)
end

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local rowSpacing = 3

local noteLabel = notePanel:Label("NotesLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Select notes"
noteLabel.alpha = 0.75
noteLabel.fontSize = 15
noteLabel.width = 60
noteLabel.x = 0
noteLabel.y = 0

local all0Percent = notePanel:Button("All0Percent")
all0Percent.visible = false
all0Percent.displayName = "Set 0%"
all0Percent.tooltip = "Set all fragment probabilities to 0"
all0Percent.persistent = false
all0Percent.height = 18
all0Percent.width = 90
all0Percent.x = notePanel.width - (all0Percent.width * 3) - 24
all0Percent.y = rowSpacing
all0Percent.changed = function()
  if type(partInEditMode) == "number" then
    for _,v in ipairs(paramsPerNote[partInEditMode].sourceSelectors) do
      v:setValue(0)
    end
  end
end

local all100Percent = notePanel:Button("All100Percent")
all100Percent.visible = false
all100Percent.displayName = "Set 100%"
all100Percent.tooltip = "Set all fragment probabilities to 100"
all100Percent.persistent = false
all100Percent.height = all0Percent.height
all100Percent.width = all0Percent.width
all100Percent.x = all0Percent.x + all0Percent.width + 10
all100Percent.y = rowSpacing
all100Percent.changed = function()
  if type(partInEditMode) == "number" then
    for _,v in ipairs(paramsPerNote[partInEditMode].sourceSelectors) do
      v:setValue(100)
    end
  end
end

local setRandomPercent = notePanel:Button("SetRandomPercent")
setRandomPercent.visible = false
setRandomPercent.displayName = "Set random %"
setRandomPercent.tooltip = "Randomize fragment probabilities"
setRandomPercent.persistent = false
setRandomPercent.height = all0Percent.height
setRandomPercent.width = all0Percent.width
setRandomPercent.x = all100Percent.x + all100Percent.width + 10
setRandomPercent.y = rowSpacing
setRandomPercent.changed = function()
  if type(partInEditMode) == "number" then
    for _,v in ipairs(paramsPerNote[partInEditMode].sourceSelectors) do
      v:setValue(gem.getRandom(100))
    end
  end
end

for i=1,numNotes do
  local noteInputLabel = notePanel:Label("Label" .. i)
  noteInputLabel.tooltip = "Editable label for this note trigger"
  noteInputLabel.editable = true
  noteInputLabel.text = noteLabels[i]
  noteInputLabel.backgroundColour = menuBackgroundColour
  noteInputLabel.backgroundColourWhenEditing = "#cccccc"
  noteInputLabel.textColour = "9f9f9f"
  noteInputLabel.width = 76
  noteInputLabel.height = 22
  noteInputLabel.x = ((noteInputLabel.width + 10) * (i - 1)) + 10
  noteInputLabel.y = noteLabel.height + 5

  local noteInput = notePanel:NumBox("TriggerNote" .. i, noteMap[i], 0, 127, true)
  noteInput.displayName = "Note"
  noteInput.tooltip = "The note to trigger"
  noteInput.unit = Unit.MidiKey
  noteInput.showLabel = false
  noteInput.backgroundColour = menuBackgroundColour
  noteInput.textColour = menuTextColour
  noteInput.height = 22
  noteInput.width = 37
  noteInput.x = noteInputLabel.x
  noteInput.y = noteInputLabel.y + noteInputLabel.height + rowSpacing

  local noteProbability = notePanel:NumBox("NoteProbability" .. i, 100, 0, 100, true)
  noteProbability.tooltip = "Probability that note will be played"
  noteProbability.unit = Unit.Percent
  noteProbability.showLabel = false
  noteProbability.backgroundColour = menuBackgroundColour
  noteProbability.textColour = menuTextColour
  noteProbability.height = noteInput.height
  noteProbability.width = noteInput.width
  noteProbability.x = noteInput.x + noteInput.width + rowSpacing
  noteProbability.y = noteInput.y

  local listen = notePanel:OnOffButton("Listen" .. i)
  listen.displayName = "L"
  listen.tooltip = "Note learn"
  listen.persistent = false
  listen.textColourOff = "white"
  listen.backgroundColourOn = "green"
  listen.normalImage = "../resources/icons/headphone_inactive_grey.png"
  listen.pressedImage = "../resources/icons/headphone_active_white_no_check.png"
  listen.height = 24
  listen.width = 24
  listen.x = noteInput.x
  listen.y = noteInput.y + noteInput.height + rowSpacing
  listen.changed = function(self)
    if self.value then
      noteListen = i
    else
      noteListen = nil
    end
  end

  local edit = notePanel:OnOffButton("Edit" .. i)
  edit.displayName = "E"
  edit.tooltip = "Edit note details"
  edit.persistent = false
  edit.textColourOff = "white"
  edit.backgroundColourOn = "orange"
  edit.normalImage = "../resources/icons/edit_inactive_grey.png"
  edit.pressedImage = "../resources/icons/edit_active_white_no_check.png"
  edit.height = listen.height
  edit.width = listen.width
  edit.x = listen.x + listen.width + 2
  edit.y = listen.y
  edit.changed = function(self)
    if type(partInEditMode) == "nil" then
      for j,v in ipairs(paramsPerNote) do
        local isVisible = i == j
        if isVisible then
          partInEditMode = j
          --noteLabel.text = v.noteInputLabel.text
          -- Remember bounds
          bounds = {
            noteInputLabel=v.noteInputLabel.bounds,
            noteInput=v.noteInput.bounds,
            noteProbability=v.noteProbability.bounds,
            listen=v.listen.bounds,
            edit=v.edit.bounds,
            mute=v.mute.bounds
          }
          -- Set bounds for edit
          v.noteInputLabel.bounds = paramsPerNote[1].noteInputLabel.bounds
          v.noteInput.bounds = paramsPerNote[1].noteInput.bounds
          v.noteProbability.bounds = paramsPerNote[1].noteProbability.bounds
          v.listen.bounds = paramsPerNote[1].listen.bounds
          v.edit.bounds = paramsPerNote[1].edit.bounds
          v.mute.bounds = paramsPerNote[1].mute.bounds
        end
        for _,w in ipairs(v.sourceSelectors) do
          w.visible = isVisible
        end
        v.sourceSelectorAll.visible = isVisible
        v.noteInputLabel.visible = isVisible
        v.noteInput.visible = isVisible
        v.noteProbability.visible = isVisible
        v.accent.visible = isVisible
        v.accentTable.visible = isVisible
        v.pitch.visible = isVisible
        v.pitchTable.visible = isVisible
        v.pitchChangeProbability.visible = isVisible
        v.accentFragmentStart.visible = isVisible
        v.accentDownBeat.visible = isVisible
        v.accentUpBeat.visible = isVisible
        v.restFirstInFragmentProbability.visible = isVisible
        v.restDownBeatProbability.visible = isVisible
        v.restUpBeatProbability.visible = isVisible
        v.sourceLabel.visible = isVisible
        v.restLabel.visible = isVisible
        v.accentLabel.visible = isVisible
        v.listen.visible = isVisible
        v.edit.visible = isVisible
        v.edit.displayName = "X"
        v.mute.visible = isVisible
      end
      all0Percent.visible = true
      all100Percent.visible = true
      setRandomPercent.visible = true
    else
      for j,v in ipairs(paramsPerNote) do
        if i == j then
          v.noteInputLabel.bounds = bounds.noteInputLabel
          v.noteInput.bounds = bounds.noteInput
          v.noteProbability.bounds = bounds.noteProbability
          v.listen.bounds = bounds.listen
          v.edit.bounds = bounds.edit
          v.mute.bounds = bounds.mute
        end
        v.noteInputLabel.visible = true
        v.noteInput.visible = true
        v.noteProbability.visible = true
        v.listen.visible = true
        v.mute.visible = true
        v.edit.visible = true
        v.edit.displayName = "E"
        v.accent.visible = false
        v.accentTable.visible = false
        v.pitch.visible = false
        v.pitchTable.visible = false
        v.pitchChangeProbability.visible = false
        v.accentDownBeat.visible = false
        v.accentUpBeat.visible = false
        v.accentFragmentStart.visible = false
        v.restFirstInFragmentProbability.visible = false
        v.restDownBeatProbability.visible = false
        v.restUpBeatProbability.visible = false
        v.accentLabel.visible = false
        v.sourceLabel.visible = false
        v.restLabel.visible = false
        v.sourceSelectorAll.visible = false
        for _,w in ipairs(v.sourceSelectors) do
          w.visible = false
        end
      end
      all0Percent.visible = false
      all100Percent.visible = false
      setRandomPercent.visible = false
      partInEditMode = nil
    end
    --noteLabel.text = "Drums"
  end

  local mute = notePanel:OnOffButton("Mute" .. i)
  mute.displayName = "M"
  mute.tooltip = "Mute note"
  mute.textColourOff = "white"
  mute.backgroundColourOn = "red"
  mute.normalImage = "../resources/icons/mute_active_white_no_check.png"
  mute.pressedImage = "../resources/icons/mute_inactive_grey.png"
  mute.height = edit.height
  mute.width = edit.width
  mute.x = edit.x + edit.width + 2
  mute.y = edit.y

  local accentLabel = notePanel:Label("AccentLabel" .. i)
  accentLabel.visible = false
  accentLabel.text = "Accent/Pitch"
  accentLabel.tooltip = "Set accents and pitch offsets"
  accentLabel.height = noteInput.height
  accentLabel.width = 120
  accentLabel.x = noteInputLabel.width + 18
  accentLabel.y = noteLabel.y

  local accent = notePanel:NumBox("NoteAccent" .. i, 1, 1, 16, true)
  accent.visible = false
  accent.showLabel = false
  accent.tooltip = "Accent table lenght"
  accent.backgroundColour = menuBackgroundColour
  accent.textColour = menuTextColour
  accent.height = noteInput.height
  accent.width = 20
  accent.x = accentLabel.x
  accent.y = accentLabel.y + accentLabel.height + rowSpacing

  local accentTable = notePanel:Table("AccentTable" .. i, 1, velocityInput.default, 1, 127, true)
  accentTable.visible = false
  accentTable.showPopupDisplay = true
  accentTable.tooltip = "Set velocity for this voice"
  accentTable.fillStyle = "solid"
  accentTable.backgroundColour = "#9f02ACFE"
  accentTable.sliderColour = outlineColour
  accentTable.width = accentLabel.width - accent.width
  accentTable.height = accent.height
  accentTable.x = accent.x + accent.width
  accentTable.y = accent.y

  accent.changed = function(self)
    --print("accent.changed", self.value)
    accentTable.length = self.value
  end

  local pitch = notePanel:NumBox("NotePitch" .. i, 1, 1, 16, true)
  pitch.visible = false
  pitch.showLabel = false
  pitch.tooltip = "Pitch offset table lenght"
  pitch.backgroundColour = menuBackgroundColour
  pitch.textColour = menuTextColour
  pitch.height = noteInput.height
  pitch.width = 20
  pitch.x = accent.x
  pitch.y = accent.y + accent.height + rowSpacing

  local pitchTable = notePanel:Table("PitchOffsetTable" .. i, 1, 0, -12, 12, true)
  pitchTable.visible = false
  pitchTable.showPopupDisplay = true
  pitchTable.tooltip = "Set pitch offset for this voice"
  pitchTable.fillStyle = "solid"
  pitchTable.backgroundColour = "#9f02ACFE"
  pitchTable.sliderColour = outlineColour
  pitchTable.width = accentLabel.width - 50
  pitchTable.height = pitch.height
  pitchTable.x = pitch.x + pitch.width
  pitchTable.y = pitch.y

  local pitchChangeProbability = notePanel:NumBox("PitchChangeProbability" .. i, 0, 0, 100, true)
  pitchChangeProbability.unit = Unit.Percent
  pitchChangeProbability.visible = false
  pitchChangeProbability.showLabel = false
  pitchChangeProbability.displayName = "Pitch change probability"
  pitchChangeProbability.tooltip = "Probability that the pitch offset from another step will be used"
  pitchChangeProbability.backgroundColour = menuBackgroundColour
  pitchChangeProbability.textColour = menuTextColour
  pitchChangeProbability.height = pitch.height
  pitchChangeProbability.width = 30
  pitchChangeProbability.x = pitchTable.x + pitchTable.width
  pitchChangeProbability.y = pitchTable.y

  pitch.changed = function(self)
    --print("pitch.changed", self.value)
    pitchTable.length = self.value
  end

  local accentFragmentStart = notePanel:OnOffButton("AccentFragmentStart" .. i, false)
  accentFragmentStart.visible = false
  accentFragmentStart.displayName = "Start"
  accentFragmentStart.tooltip = "Accent note at the start of a fragment"
  accentFragmentStart.backgroundColourOff = backgroundColourOff
  accentFragmentStart.backgroundColourOn = backgroundColourOn
  accentFragmentStart.textColourOff = textColourOff
  accentFragmentStart.textColourOn = textColourOn
  accentFragmentStart.height = accent.height
  accentFragmentStart.width = accentLabel.width / 3
  accentFragmentStart.x = pitch.x
  accentFragmentStart.y = pitch.y + pitch.height + rowSpacing

  local accentDownBeat = notePanel:OnOffButton("AccentDownBeat" .. i, false)
  accentDownBeat.visible = false
  accentDownBeat.displayName = "Down"
  accentDownBeat.tooltip = "Accent note if triggered on the downbeat"
  accentDownBeat.backgroundColourOff = backgroundColourOff
  accentDownBeat.backgroundColourOn = backgroundColourOn
  accentDownBeat.textColourOff = textColourOff
  accentDownBeat.textColourOn = textColourOn
  accentDownBeat.height = accent.height
  accentDownBeat.width = accentFragmentStart.width
  accentDownBeat.x = accentFragmentStart.x + accentFragmentStart.width
  accentDownBeat.y = accentFragmentStart.y

  local accentUpBeat = notePanel:OnOffButton("AccentUpBeat" .. i, false)
  accentUpBeat.visible = false
  accentUpBeat.displayName = "Up"
  accentUpBeat.tooltip = "Accent note if triggered on the upbeat"
  accentUpBeat.backgroundColourOff = backgroundColourOff
  accentUpBeat.backgroundColourOn = backgroundColourOn
  accentUpBeat.textColourOff = textColourOff
  accentUpBeat.textColourOn = textColourOn
  accentUpBeat.height = accent.height
  accentUpBeat.width = accentDownBeat.width
  accentUpBeat.x = accentDownBeat.x + accentDownBeat.width
  accentUpBeat.y = accentDownBeat.y

  local restLabel = notePanel:Label("RestLabel" .. i)
  restLabel.visible = false
  restLabel.text = "Rests"
  restLabel.tooltip = "Set rests"
  restLabel.height = noteInput.height
  restLabel.width = accentLabel.width
  restLabel.x = accentLabel.x + accentLabel.width + 8
  restLabel.y = noteLabel.y

  local restDownBeatProbability = notePanel:NumBox("RestDownBeatProbability" .. i, 0, 0, 100, true)
  restDownBeatProbability.unit = Unit.Percent
  restDownBeatProbability.visible = false
  restDownBeatProbability.displayName = "Downbeat"
  restDownBeatProbability.tooltip = "Probability that a rest will be played if triggered at the start of a downbeat"
  restDownBeatProbability.backgroundColour = menuBackgroundColour
  restDownBeatProbability.textColour = menuTextColour
  restDownBeatProbability.height = restLabel.height
  restDownBeatProbability.width = restLabel.width
  restDownBeatProbability.x = restLabel.x
  restDownBeatProbability.y = restLabel.y + restLabel.height + rowSpacing

  local restUpBeatProbability = notePanel:NumBox("RestUpBeatProbability" .. i, 0, 0, 100, true)
  restUpBeatProbability.unit = Unit.Percent
  restUpBeatProbability.visible = false
  restUpBeatProbability.displayName = "Upbeat"
  restUpBeatProbability.tooltip = "Probability that a rest will be played if triggered at the start of an upbeat"
  restUpBeatProbability.backgroundColour = menuBackgroundColour
  restUpBeatProbability.textColour = menuTextColour
  restUpBeatProbability.height = restDownBeatProbability.height
  restUpBeatProbability.width = restDownBeatProbability.width
  restUpBeatProbability.x = restDownBeatProbability.x
  restUpBeatProbability.y = restDownBeatProbability.y + restDownBeatProbability.height + rowSpacing

  local restFirstInFragmentProbability = notePanel:NumBox("RestFirstInFragmentProbability" .. i, 0, 0, 100, true)
  restFirstInFragmentProbability.unit = Unit.Percent
  restFirstInFragmentProbability.visible = false
  restFirstInFragmentProbability.displayName = "Fragment"
  restFirstInFragmentProbability.tooltip = "Probability that a rest will be played at the start of a fragment"
  restFirstInFragmentProbability.backgroundColour = menuBackgroundColour
  restFirstInFragmentProbability.textColour = menuTextColour
  restFirstInFragmentProbability.height = restUpBeatProbability.height
  restFirstInFragmentProbability.width = restUpBeatProbability.width
  restFirstInFragmentProbability.x = restUpBeatProbability.x
  restFirstInFragmentProbability.y = restUpBeatProbability.y + restUpBeatProbability.height + rowSpacing

  local sourceLabel = notePanel:Label("SourceInput" .. i)
  sourceLabel.visible = false
  sourceLabel.text = "Sources"
  sourceLabel.tooltip = "Select the fragments that are available for this part - NOTE: If all are 0, then all fragments can be selected."
  sourceLabel.height = accent.height
  sourceLabel.width = 60
  sourceLabel.x = restLabel.x + restLabel.width + 8
  sourceLabel.y = noteLabel.y

  local sourceSelectors = {}
  local perColumn = 3
  local rowCounter = 1
  local columnCounter = 0
  for j=1,numNotes do
    local defaultValue = 0
    if j == i then
      defaultValue = 100
    end
    local sourceSelector = notePanel:NumBox("SourceSelector" .. i .. "_" .. j, defaultValue, 0, 100, true)
    sourceSelector.unit = Unit.Percent
    sourceSelector.visible = false
    sourceSelector.displayName = "Rythm " .. j
    sourceSelector.tooltip = "Probability of rythmic fragment " .. j .. " being used for this part"
    sourceSelector.backgroundColour = menuBackgroundColour
    sourceSelector.textColour = menuTextColour
    sourceSelector.size = {112,22}
    sourceSelector.x = sourceLabel.x + (columnCounter * (sourceSelector.width + 5))
    sourceSelector.y = sourceLabel.y + ((sourceLabel.height + rowSpacing) * rowCounter)
    table.insert(sourceSelectors, sourceSelector)
    columnCounter = columnCounter + 1
    if columnCounter >= perColumn then
      columnCounter = 0
      rowCounter = rowCounter + 1
    end
  end

  local sourceSelectorAll = notePanel:NumBox("SourceSelectorAll" .. i, 100, 0, 100, true)
  sourceSelectorAll.unit = Unit.Percent
  sourceSelectorAll.visible = false
  sourceSelectorAll.displayName = "All sources"
  sourceSelectorAll.tooltip = "Set value for all sources"
  sourceSelectorAll.backgroundColour = menuBackgroundColour
  sourceSelectorAll.textColour = menuTextColour
  sourceSelectorAll.size = {112,22}
  sourceSelectorAll.x = sourceLabel.x + (columnCounter * (sourceSelectorAll.width + 5))
  sourceSelectorAll.y = sourceLabel.y + ((sourceLabel.height + rowSpacing) * rowCounter)
  sourceSelectorAll.changed = function(self)
    for _,v in ipairs(sourceSelectors) do
      v:setValue(self.value)
    end
  end

  table.insert(paramsPerNote, {noteInputLabel=noteInputLabel, noteInput=noteInput, noteProbability=noteProbability, accent=accent, accentTable=accentTable, pitch=pitch, pitchTable=pitchTable, pitchChangeProbability=pitchChangeProbability, restFirstInFragmentProbability=restFirstInFragmentProbability, restDownBeatProbability=restDownBeatProbability, restDownBeatProbability=restDownBeatProbability, restUpBeatProbability=restUpBeatProbability, accentLabel=accentLabel, restLabel=restLabel, sourceLabel=sourceLabel, sourceSelectors=sourceSelectors, sourceSelectorAll=sourceSelectorAll, listen=listen, edit=edit, mute=mute, accentFragmentStart=accentFragmentStart, accentDownBeat=accentDownBeat, accentUpBeat=accentUpBeat})
end

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythmic fragments"
rythmLabel.alpha = 0.75
rythmLabel.fontSize = 15
rythmLabel.width = 120

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, rythmLabel, colours, numNotes)

local selectNone = rythmPanel:Button("SelectNone")
selectNone.displayName = "Select none"
selectNone.tooltip = "Deselect all fragments"
selectNone.persistent = false
selectNone.height = noteLabel.height
selectNone.width = 120
selectNone.x = rythmPanel.width - (selectNone.width * 4) - 36
selectNone.y = 5
selectNone.changed = function()
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive:setValue(false)
  end
end

local selectAll = rythmPanel:Button("SelectAll")
selectAll.displayName = "Select all"
selectAll.tooltip = "Select all fragments"
selectAll.persistent = false
selectAll.height = noteLabel.height
selectAll.width = selectNone.width
selectAll.x = selectNone.x + selectNone.width + 10
selectAll.y = 5
selectAll.changed = function()
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive:setValue(true)
  end
end

local invertSelection = rythmPanel:Button("InvertSelection")
invertSelection.displayName = "Invert selection"
invertSelection.tooltip = "Invert current selection"
invertSelection.persistent = false
invertSelection.height = noteLabel.height
invertSelection.width = selectAll.width
invertSelection.x = selectAll.x + selectAll.width + 10
invertSelection.y = 5
invertSelection.changed = function()
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive:setValue(v.fragmentActive.value == false and string.len(v.fragmentInput.text) > 0)
  end
end

local randomizeSelection = rythmPanel:Button("RandomizeSelection")
randomizeSelection.displayName = "Randomize selection"
randomizeSelection.tooltip = "Randomize fragment selection"
randomizeSelection.persistent = false
randomizeSelection.height = noteLabel.height
randomizeSelection.width = selectNone.width
randomizeSelection.x = invertSelection.x + invertSelection.width + 10
randomizeSelection.y = 5
randomizeSelection.changed = function()
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive:setValue(string.len(v.fragmentInput.text) > 0 and gem.getRandomBoolean())
  end
end

--- Structure - Store/recall parts, set playing order etc. ---

local loadFragmentMenu = rythmPanel:Menu("LoadFragmentMenu", {"Load..."})
loadFragmentMenu.enabled = false

local storeButton = rythmPanel:OnOffButton("StoreButton")
storeButton.displayName = "Store"
storeButton.tooltip = "Store the current state of the fragments"
storeButton.width = 75
storeButton.height = 20
storeButton.x = rythmLabel.x
storeButton.y = 417

local slotSpacing = 3
local unusedSlotDefaultText = "Unused"
local actions = {"Save..."}
local slotToStoredIndex = {} -- Holds the index of the stored fragment for each slot
local fragmentSlots = {}
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

local partOrderButton = rythmPanel:OnOffButton("PartOrderLabel")
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

local recallButton = rythmPanel:OnOffButton("RecallButton")
recallButton.displayName = "Recall"
recallButton.enabled = false
recallButton.tooltip = "Recall the last stored fragment state"
recallButton.width = storeButton.width
recallButton.height = storeButton.height
recallButton.x = storeButton.x
recallButton.y = storeButton.y + storeButton.height + 10

local evolveButton = rythmPanel:OnOffButton("EvolveActive", false)
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

local evolveFragmentProbability = rythmPanel:NumBox("EvolveFragmentProbability", 50, 0, 100, true)
evolveFragmentProbability.unit = Unit.Percent
evolveFragmentProbability.textColour = widgetTextColour
evolveFragmentProbability.backgroundColour = widgetBackgroundColour
evolveFragmentProbability.displayName = "Amount"
evolveFragmentProbability.tooltip = "Set the probability that fragments will change over time, using the resolutions present in the fragments"
evolveFragmentProbability.width = 105
evolveFragmentProbability.height = recallButton.height
evolveFragmentProbability.x = evolveButton.x + evolveButton.width + 10
evolveFragmentProbability.y = evolveButton.y

local randomizeCurrentResolutionProbability = rythmPanel:NumBox("RandomizeCurrentResolutionProbability", 0, 0, 100, true)
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

local adjustBias = rythmPanel:Knob("Bias", 50, 0, 100, true)
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
  self.value = false
end

recallButton.changed = function(self)
  recallStoredState = #storedFragments
  -- If sequencer is not playing, we can recall right now
  if isPlaying == false then
    recall()
  end
  self.value = false
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

-- Returns a fragment that can be set directly on fragmentInput.text
-- Used by the tools menu
-- 1 = Default (even+dot)
-- 2 = Single
-- 3 = Extended (fast+slow)
-- 4 = Slow
function getRandomFragment(definitionNumber)
  local fragmentDefinition = {}
  if definitionNumber == 2 then
    fragmentDefinition = {resolutions.getResolution(gem.getRandomFromTable(rythmicFragments.getSelectedResolutions()))} -- Single
  else
    fragmentDefinition = rythmicFragments.createFragmentDefinition(definitionNumber)
  end
  return rythmicFragments.getFragmentInputText(rythmicFragments.fragmentDefinitionToResolutionNames(fragmentDefinition))
end

function getNote(voice)
  local noteProbability = paramsPerNote[voice].noteProbability.value
  if gem.getRandomBoolean(noteProbability) then
    local pitchTable = paramsPerNote[voice].pitchTable
    local pitchChangeProbability = paramsPerNote[voice].pitchChangeProbability.value
    local pos = (roundCounterPerVoice[voice] % pitchTable.length) + 1

    -- Check for pitch change randomization
    if gem.getRandomBoolean(pitchChangeProbability) then
      -- Get pitch adjustment from random index in pitch table for current part
      pos = gem.getRandom(paramsPerNote[voice].pitch.value)
      --print("Playing pitch from random pos", pos)
    end

    local offset = pitchTable:getValue(pos)
    --print("Pitch offset/pos", offset, pos)
    return paramsPerNote[voice].noteInput.value + offset
  end
end

function startPlaying()
  if isPlaying then
    return
  end
  seqIndex = gem.inc(seqIndex)
  run(sequenceRunner, seqIndex)
end

function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  initNotes()
end

function getSources(voice)
  local sources = {}
  for i,v in ipairs(paramsPerNote[voice].sourceSelectors) do
    if gem.getRandomBoolean(v.value) then
      table.insert(sources, i)
    end
  end
  return sources
end

function hasActiveSources(voice)
  local sources = {}
  for i,v in ipairs(paramsPerNote[voice].sourceSelectors) do
    if v.value > 0 and string.len(paramsPerFragment[i].fragmentInput.text) > 0 then
      table.insert(sources, i)
    end
  end
  return #sources > 0
end

function getChannel(voice)
  local channel = nil
  if channelButton.value then
    channel = voice -- TODO Add offset: + channelOffset.value - 1
  end
  return channel
end

function isStartOfBeat(playDuration)
  return math.floor(playDuration) == playDuration
end

function isDownBeat(playDuration)
  return isStartOfBeat(playDuration) and (playDuration % beatBase == 0 or (beatBase > 3 and playDuration % math.ceil(beatBase / 2) == 0))
end

function isUpBeat(playDuration)
  return isStartOfBeat(playDuration) and isDownBeat(playDuration) == false
end

function isNoteActive(voice)
  return paramsPerNote[voice].noteProbability.value > 0 and paramsPerNote[voice].mute.value == false and hasActiveSources(voice)
end

function initNotes()
  playingVoices = {}
  playingIndex = {}
  roundCounterPerVoice = {}
  rythmicFragments.clearResolutionsForEvolve()
  for voice=1,numNotes do
    table.insert(playingVoices, false) -- Init voices
    table.insert(playingIndex, nil) -- Init index
    table.insert(roundCounterPerVoice, 0) -- Init rounds
    setSourceActive(voice)
  end
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive.textColourOn = "black"
  end
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentInputDirty = false
  end
end

function useAccent(voice, activeFragment, isFragmentStart, mustRepeat, isDownBeat, isUpBeat)
  if paramsPerNote[voice].accentDownBeat.value and isDownBeat then
    --print("ACCENT isDownBeat", isDownBeat)
    return true
  end
  
  if paramsPerNote[voice].accentUpBeat.value and isUpBeat then
    --print("ACCENT isUpBeat", isUpBeat)
    return true
  end

  if paramsPerNote[voice].accentFragmentStart.value and isFragmentStart then
    if #activeFragment.f > 1 then
      --print("ACCENT #activeFragment.f", #activeFragment.f)
      return true
    end
    if activeFragment.m > 1 and mustRepeat == false then
      --print("ACCENT activeFragment.m, mustRepeat", activeFragment.m, mustRepeat)
      return true
    end
  end

  return false
end

function flashNoteLabel(voice, duration)
  local flashDuration = 150--math.min(150, beat2ms(duration))
  if type(duration) == "number" then
    flashDuration = math.min(flashDuration, beat2ms(duration))
  end
  paramsPerNote[voice].noteInputLabel.textColour = "efefef"
  wait(flashDuration)
  paramsPerNote[voice].noteInputLabel.textColour = "9f9f9f"
end

-- Set textcolour on the active source for the given voice
function setSourceActive(voice, activeFragment)
  for i,v in ipairs(paramsPerNote[voice].sourceSelectors) do
    if type(activeFragment) == "table" and activeFragment.i == i then
      v.textColour = labelBackgoundColour
    else
      v.textColour = menuTextColour
    end
  end
end

function playVoices(partDuration)
  for voice=1,voices do
    if playingVoices[voice] == false then
      playingVoices[voice] = isNoteActive(voice)
      if playingVoices[voice] then
        print("Play voice", voice)
        playingIndex[voice] = playIndex
        spawn(play, voice, playIndex, partDuration)
        playIndex = gem.inc(playIndex)
      end
    end
  end
end

function recall()
  -- Find the state we are to recall
  rythmicFragments.setFragmentState(storedFragments[recallStoredState])
  --print("Recalled fragments from stored state", recallStoredState)
  recallStoredState = nil
end

-- Parse the part order input
-- Format: <PART><x|e><REPEATS> separated by comma (use e instead of x to activate evolve). Example: 1x16,2e8,3
-- Set the part to zero "0" to use the current state instead of loading a part
function setPartOrder(partOrderText)
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

function sequenceRunner(uniqueId)
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
  initNotes()
  while isPlaying and seqIndex == uniqueId do
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
            if fragmentSlots[slotIndex].value == true then
              fragmentSlots[slotIndex]:setValue(false)
            end
            fragmentSlots[slotIndex]:setValue(true)
          end
          -- Increment part order position
          partOrderPos = partOrderPos + 1
          if partOrderPos > #partOrder then
            partOrderPos = 1
          end
        end

        partOrderRepeatCounter = partOrderRepeatCounter - 1 -- Decrement repeat counter
        --print("Decrementing partOrderRepeatCounter", partOrderRepeatCounter)
      end

      if type(recallStoredState) == "number" then
        initNotes()
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

    beatCounter = beatCounter + 1 -- Increment counter
    print("Increment beat counter", beatCounter)
    if beatCounter > beatBase then
      beatCounter = 1 -- Reset counter
      if evolveButton.value and gem.getRandomBoolean(evolveFragmentProbability.value) then
        previous = rythmicFragments.evolveFragments(previous, randomizeCurrentResolutionProbability.value, adjustBias.value)
      end
    end
  end
end

function play(voice, uniqueId, partDuration)
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
  -- Start loop
  while playingIndex[voice] == uniqueId do
    roundCounterPerVoice[voice] = roundCounterPerVoice[voice] + 1

    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = rythmicFragments.getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount, getSources(voice))

    if type(duration) == "nil" or activeFragment.i == 0 or isNoteActive(voice) == false then
      -- Return voice to sequence runner
      setSourceActive(voice)
      playingVoices[voice] = false
      break
    end

    local isDownBeat = isDownBeat(playDuration)
    local isUpBeat = isUpBeat(playDuration)

    -- Check rest at start of downbeat
    if isDownBeat and rest == false and gem.getRandomBoolean(paramsPerNote[voice].restDownBeatProbability.value) then
      rest = true
    end

    -- Check rest at start of upbeat
    if isUpBeat and rest == false and gem.getRandomBoolean(paramsPerNote[voice].restUpBeatProbability.value) then
      rest = true
    end

    -- Check rest at start of fragment - only if fragment has more than one item
    if isFragmentStart and rest == false and (#activeFragment.f > 1 or (activeFragment.m > 1 and mustRepeat == false)) and gem.getRandomBoolean(paramsPerNote[voice].restFirstInFragmentProbability.value) then
      rest = true
    end

    if type(partDuration) == "number" and (playDuration + duration) > partDuration then
      duration = partDuration - playDuration -- Remaining
    end

    -- Update total play duration
    playDuration = playDuration + duration

    local note = getNote(voice)
    local doPlayNote = rest == false and type(note) == "number"
    if doPlayNote then
      local velocity = velocityInput.value
      local accentTable = paramsPerNote[voice].accentTable
      if accentTable.enabled then
        local pos = (roundCounterPerVoice[voice] % accentTable.length) + 1
        velocity = accentTable:getValue(pos)
        --print("Velocity set from accentTable at pos", velocity, pos)
      end
      if useAccent(voice, activeFragment, isFragmentStart, mustRepeat, isDownBeat, isUpBeat) then
        velocity = velocityAccent.value
      end
      playNote(note, velocity, beat2ms(resolutions.getPlayDuration(duration)), nil, getChannel())

      if isFragmentStart then
        setSourceActive(voice, activeFragment)
      end

      for i,v in ipairs(paramsPerFragment) do
        if activeFragment.i == i then
          spawn(rythmicFragments.flashFragmentActive, v.fragmentActive, duration)
        end
      end
      spawn(flashNoteLabel, voice, duration)
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

    if duration > 0 then
      waitBeat(duration)
    end
  end
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  if type(noteListen) == "number" then
    paramsPerNote[noteListen].noteInput:setValue(e.note)
    paramsPerNote[noteListen].listen:setValue(false)
  end
  for i,v in ipairs(paramsPerNote) do
    if v.noteInput.value == e.note then
      spawn(flashNoteLabel, i)
    end
  end
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
  local noteLabelData = {}
  local fragmentSlotsData = {}
  local accentTableData = {}
  local pitchTableData = {}

  for _,v in ipairs(paramsPerNote) do
    table.insert(noteLabelData, v.noteInputLabel.text)
    local accentData = {}
    for j=1, v.accent.value do
      table.insert(accentData, v.accentTable:getValue(j))
    end
    table.insert(accentTableData, accentData)
    local pitchData = {}
    for j=1, v.pitch.value do
      table.insert(pitchData, v.pitchTable:getValue(j))
    end
    table.insert(pitchTableData, pitchData)
  end

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  for _,v in ipairs(fragmentSlots) do
    table.insert(fragmentSlotsData, v.tooltip)
  end

  return {fragmentInputData, noteLabelData, fragmentSlotsData, storedFragments, partOrderInput.text, slotToStoredIndex, accentTableData, pitchTableData}
end

function onLoad(data)
  local fragmentInputData = data[1]
  local noteLabelData = data[2]
  local fragmentSlotsData = data[3]
  storedFragments = data[4]
  partOrderInput.text = tostring(data[5])
  slotToStoredIndex = data[6]
  local accentTableData = data[7]
  local pitchTableData = data[8]

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

  for i,v in ipairs(paramsPerNote) do
    v.noteInputLabel.text = noteLabelData[i]
    if type(accentTableData) == "table" then
      v.accent:setValue(#accentTableData[i])
      --print("Loading v.accent.value/v.accentTable.length", v.accent.value, v.accentTable.length)
      for j,a in ipairs(accentTableData[i]) do
        v.accentTable:setValue(j,a)
      end
    end
    if type(pitchTableData) == "table" then
      v.pitch:setValue(#pitchTableData[i])
      --print("Loading v.pitch.value/v.pitchTable.length", v.pitch.value, v.pitchTable.length)
      for j,a in ipairs(pitchTableData[i]) do
        v.pitchTable:setValue(j,a)
      end
    end
  end

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end

  for i,v in ipairs(fragmentSlotsData) do
    fragmentSlots[i].tooltip = v
    fragmentSlots[i].enabled = type(slotToStoredIndex[i]) == "number"
  end
end
