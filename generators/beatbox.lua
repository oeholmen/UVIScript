-------------------------------------------------------------------------------
-- Random note generator
-------------------------------------------------------------------------------

require "../includes/generative"
require "../includes/rythmicFragments"

local noteListen = nil
local voices = 8 -- Voices can be 8 or 1 - 8 is used primarily for drums, 1 is used primarily for tonal - this is changed by randomNoteMode button
local numNotes = 8 -- There are eight parts/notes
local beatCounter = 1
local isPlaying = false
local playingVoices = {}
local roundCounterPerVoice = {}
local partInEditMode = nil
local paramsPerNote = {}
local paramsPerFragment = {}
local bounds = {}

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "F637EC"
local menuBackgroundColour = "01011F"
local menuTextColour = "#9f02ACFE"
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
notePanel.height = 100

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "505050"
rythmPanel.x = notePanel.x
rythmPanel.y = notePanel.y + notePanel.height + 5
rythmPanel.width = 700
rythmPanel.height = 410

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("SequencerLabel")
sequencerLabel.text = "Beatbox"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.width = 80

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

local velocityInput = settingsPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Note velocity"
velocityInput.height = widgetHeight
velocityInput.width = widgetWidth
velocityInput.x = 5
velocityInput.y = 0

local velocityAccent = settingsPanel:NumBox("VelocityAccent", 64, 1, 127, true)
velocityAccent.textColour = widgetTextColour
velocityAccent.backgroundColour = widgetBackgroundColour
velocityAccent.displayName = "Accent"
velocityAccent.tooltip = "Velocity accent amount triggered on the start of a fragment"
velocityAccent.height = widgetHeight
velocityAccent.width = widgetWidth
velocityAccent.x = velocityInput.x + velocityInput.width + 10
velocityAccent.y = velocityInput.y

local randomNoteMode = settingsPanel:OnOffButton("RandomNoteMode", false)
randomNoteMode.displayName = "Random note"
randomNoteMode.tooltip = "When this is activated only one note is played at once, and notes are selected by random from the configured notes"
randomNoteMode.backgroundColourOff = backgroundColourOff
randomNoteMode.backgroundColourOn = backgroundColourOn
randomNoteMode.textColourOff = textColourOff
randomNoteMode.textColourOn = textColourOn
randomNoteMode.height = widgetHeight
randomNoteMode.width = velocityAccent.width
randomNoteMode.x = velocityAccent.x + velocityAccent.width + 10
randomNoteMode.y = velocityAccent.y
randomNoteMode.changed = function(self)
  if self.value then
    voices = 1
  else
    voices = numNotes
  end
  print("randomNoteMode, voices", self.value, voices)
end

local templates = {"Tools...", "--- Templates ---", "Kick on down, snare on up", "Four on the floor", "--- Downbeat/upbeat ---", "All downbeat/upbeat on", "Downbeat on even, upbeat on odd", "--- Fragment/sources ---", "Part to source", "All sources on", "All sources off", "Clear fragment inputs", "--- Notes ---", "Mute all", "Unmute all", "Toggle mute", "Set all note probabilities to 100%", "Set all note probabilities to 0%", "--- Randomize ---", "Randomize fragment inputs", "Randomize note probability", "Randomize downbeat/upbeat probability", "Randomize all settings", "--- Reset ---", "Reset to default settings", "Set all to zero"}
local templateMenu = settingsPanel:Menu("Templates", templates)
templateMenu.tooltip = "Select a tool - NOTE Will change current settings!"
templateMenu.showLabel = false
templateMenu.height = widgetHeight
templateMenu.width = randomNoteMode.width
templateMenu.x = randomNoteMode.x + randomNoteMode.width + 10
templateMenu.y = randomNoteMode.y
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
      elseif self.selectedText == "Randomize all settings" then
        w:setValue(getRandom(100))
      elseif self.selectedText == "All sources on" or self.selectedText == "Reset to default settings" then
        w:setValue(100)
      elseif self.selectedText == "All sources off" or self.selectedText == "Set all to zero" then
        w:setValue(0)
      end
    end
    if self.selectedText == "Mute all" then
      v.mute:setValue(true)
    elseif self.selectedText == "Unmute all" then
      v.mute:setValue(false)
    elseif self.selectedText == "All downbeat/upbeat on" then
      v.downBeatProbability:setValue(100)
      v.upBeatProbability:setValue(100)
    elseif self.selectedText == "Downbeat on even, upbeat on odd" then
      if part % 2 == 0 then
        v.downBeatProbability:setValue(0)
        v.upBeatProbability:setValue(100)
      else
        v.downBeatProbability:setValue(100)
        v.upBeatProbability:setValue(0)
      end
    elseif self.selectedText == "Set all note probabilities to 100%" then
      v.noteProbability:setValue(100)
    elseif self.selectedText == "Set all note probabilities to 0%" then
      v.noteProbability:setValue(0)
    elseif self.selectedText == "Toggle mute" then
      v.mute:setValue(v.mute.value == false)
    elseif self.selectedText == "Toggle mute" then
      v.mute:setValue(v.mute.value == false)
    elseif self.selectedText == "Clear fragment inputs" then
      paramsPerFragment[part].fragmentInput.text = ""
    elseif self.selectedText == "Randomize fragment inputs" then
      paramsPerFragment[part].fragmentInput.text = getFragmentInputText(fragmentDefinitionToResolutionNames(createFragmentDefinition(3)))
    elseif self.selectedText == "Randomize note probability" then
      v.noteProbability:setValue(getRandom(100))
    elseif self.selectedText == "Randomize downbeat/upbeat probability" then
      v.downBeatProbability:setValue(getRandom(100))
      v.upBeatProbability:setValue(getRandom(100))
    elseif self.selectedText == "Randomize all settings" then
      paramsPerFragment[part].fragmentInput.text = getFragmentInputText(fragmentDefinitionToResolutionNames(createFragmentDefinition(3)))
      v.mute:setValue(getRandomBoolean())
      v.accentFragmentStart:setValue(getRandomBoolean())
      v.accentDownBeat:setValue(getRandomBoolean())
      v.accentUpBeat:setValue(getRandomBoolean())
      v.accent:setValue(getRandom(v.accent.max))
      v.restFirstBeatProbability:setValue(getRandom(100))
      v.restFirstInFragmentProbability:setValue(getRandom(100))
      v.noteProbability:setValue(getRandom(100))
      v.downBeatProbability:setValue(getRandom(100))
      v.upBeatProbability:setValue(getRandom(100))
    elseif self.selectedText == "Reset to default settings" then
      if part == 1 then
        paramsPerFragment[part].fragmentInput.text = "1/8"
      else
        paramsPerFragment[part].fragmentInput.text = ""
      end
      v.mute:setValue(false)
      v.accentFragmentStart:setValue(false)
      v.accentDownBeat:setValue(false)
      v.accentUpBeat:setValue(false)
      v.accent:setValue(0)
      v.restFirstBeatProbability:setValue(0)
      v.restFirstInFragmentProbability:setValue(0)
      v.noteProbability:setValue(100)
      v.downBeatProbability:setValue(100)
      v.upBeatProbability:setValue(100)
    elseif self.selectedText == "Set all to zero" then
      paramsPerFragment[part].fragmentInput.text = ""
      v.mute:setValue(false)
      v.accentFragmentStart:setValue(false)
      v.accentDownBeat:setValue(false)
      v.accentUpBeat:setValue(false)
      v.accent:setValue(0)
      v.restFirstBeatProbability:setValue(0)
      v.restFirstInFragmentProbability:setValue(0)
      v.noteProbability:setValue(0)
      v.downBeatProbability:setValue(0)
      v.upBeatProbability:setValue(0)
    elseif self.selectedText == "Kick on down, snare on up" then
      if part == 1 then
        v.mute:setValue(false)
        v.sourceSelectors[1]:setValue(100)
        v.sourceSelectors[2]:setValue(100)
        v.noteProbability:setValue(100)
        v.downBeatProbability:setValue(100)
        v.upBeatProbability:setValue(0)
      elseif part == 2 then
        v.mute:setValue(false)
        v.sourceSelectors[1]:setValue(100)
        v.sourceSelectors[2]:setValue(100)
        v.noteProbability:setValue(100)
        v.downBeatProbability:setValue(0)
        v.upBeatProbability:setValue(100)
      end
    elseif self.selectedText == "Four on the floor" then
      if part == 1 then
        v.mute:setValue(false)
        v.sourceSelectors[1]:setValue(100)
        v.sourceSelectors[2]:setValue(100)
        v.noteProbability:setValue(100)
        v.downBeatProbability:setValue(100)
        v.upBeatProbability:setValue(100)
      elseif part == 2 then
        v.mute:setValue(false)
        v.sourceSelectors[1]:setValue(100)
        v.sourceSelectors[2]:setValue(100)
        v.noteProbability:setValue(100)
        v.downBeatProbability:setValue(0)
        v.upBeatProbability:setValue(100)
      end
    end
  end
  if self.selectedText == "Four on the floor" then
    paramsPerFragment[1].fragmentInput.text = "1/4"
  end
  -- Must be last
  self:setValue(1, false)
end

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local noteLabel = notePanel:Label("NotesLabel")
noteLabel.text = "Drums"
noteLabel.tooltip = "Select drums"
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
all0Percent.height = 20
all0Percent.width = 90
all0Percent.x = notePanel.width - (all0Percent.width * 4) - 39
all0Percent.y = 3
all0Percent.changed = function()
  if type(partInEditMode) == "number" then
    for _,v in ipairs(paramsPerNote[partInEditMode].sourceSelectors) do
      v:setValue(0)
    end
  end
end

local all50percent = notePanel:Button("All50percent")
all50percent.visible = false
all50percent.displayName = "Set 50%"
all50percent.tooltip = "Set all fragment probabilities to 50%"
all50percent.persistent = false
all50percent.height = all0Percent.height
all50percent.width = all0Percent.width
all50percent.x = all0Percent.x + all0Percent.width + 10
all50percent.y = 5
all50percent.changed = function()
  if type(partInEditMode) == "number" then
    for _,v in ipairs(paramsPerNote[partInEditMode].sourceSelectors) do
      v:setValue(50)
    end
  end
end

local all100Percent = notePanel:Button("All100Percent")
all100Percent.visible = false
all100Percent.displayName = "Set 100%"
all100Percent.tooltip = "Set all fragment probabilities to 100"
all100Percent.persistent = false
all100Percent.height = all50percent.height
all100Percent.width = all50percent.width
all100Percent.x = all50percent.x + all50percent.width + 10
all100Percent.y = 5
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
setRandomPercent.height = all100Percent.height
setRandomPercent.width = all100Percent.width
setRandomPercent.x = all100Percent.x + all100Percent.width + 10
setRandomPercent.y = 5
setRandomPercent.changed = function()
  if type(partInEditMode) == "number" then
    for _,v in ipairs(paramsPerNote[partInEditMode].sourceSelectors) do
      v:setValue(getRandom(100))
    end
  end
end

for i=1,numNotes do
  local types = {"Kick", "Snare", "Hihat", "Clap", "Toms", "Cymbal", "Tambourine", "Perc"}
  local typeLabel = notePanel:Label("Label" .. i)
  typeLabel.tooltip = "Part Label"
  typeLabel.editable = true
  typeLabel.text = types[i]
  typeLabel.backgroundColour = menuBackgroundColour
  typeLabel.backgroundColourWhenEditing = "#cccccc"
  typeLabel.textColour = "9f9f9f"
  typeLabel.width = 80
  typeLabel.height = 22
  typeLabel.x = ((typeLabel.width + 6) * (i - 1)) + 8
  typeLabel.y = noteLabel.height + 5

  local triggerNote = notePanel:NumBox("TriggerNote" .. i, 36, 0, 127, true)
  if i == 2 then
    triggerNote.value = 38
  elseif i == 3 then
    triggerNote.value = 42
  elseif i == 4 then
    triggerNote.value = 39
  elseif i == 5 then
    triggerNote.value = 41
  elseif i == 6 then
    triggerNote.value = 49
  elseif i == 7 then
    triggerNote.value = 54
  elseif i == 8 then
    triggerNote.value = 66
  end
  triggerNote.displayName = "Note"
  triggerNote.tooltip = "The note to trigger"
  triggerNote.unit = Unit.MidiKey
  triggerNote.showLabel = false
  triggerNote.backgroundColour = menuBackgroundColour
  triggerNote.textColour = menuTextColour
  triggerNote.height = 22
  triggerNote.width = 40
  triggerNote.x = typeLabel.x
  triggerNote.y = typeLabel.y + typeLabel.height

  local noteProbability = notePanel:NumBox("NoteProbability" .. i, 100, 0, 100, true)
  noteProbability.tooltip = "Probability that note will be played"
  noteProbability.unit = Unit.Percent
  noteProbability.showLabel = false
  noteProbability.backgroundColour = menuBackgroundColour
  noteProbability.textColour = menuTextColour
  noteProbability.height = triggerNote.height
  noteProbability.width = 40
  noteProbability.x = triggerNote.x + triggerNote.width
  noteProbability.y = triggerNote.y

  local listen = notePanel:OnOffButton("Listen" .. i)
  listen.displayName = "L"
  listen.tooltip = "Note learn"
  listen.persistent = false
  listen.textColourOff = "white"
  listen.backgroundColourOn = "green"
  listen.normalImage = "../resources/icons/headphone_inactive.png"
  listen.pressedImage = "../resources/icons/headphone_active.png"
  listen.height = 24
  listen.width = 24
  listen.x = triggerNote.x
  listen.y = triggerNote.y + triggerNote.height
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
  edit.normalImage = "../resources/icons/edit_inactive.png"
  edit.pressedImage = "../resources/icons/edit_active.png"
  edit.height = listen.height
  edit.width = listen.width
  edit.x = listen.x + listen.width + 4
  edit.y = listen.y
  edit.changed = function(self)
    if type(partInEditMode) == "nil" then
      for j,v in ipairs(paramsPerNote) do
        local isVisible = i == j
        if isVisible then
          partInEditMode = j
          --noteLabel.text = v.typeLabel.text
          -- Remember bounds
          bounds = {
            typeLabel=v.typeLabel.bounds,
            triggerNote=v.triggerNote.bounds,
            noteProbability=v.noteProbability.bounds,
            listen=v.listen.bounds,
            edit=v.edit.bounds,
            mute=v.mute.bounds
          }
          -- Set bounds for edit
          v.typeLabel.bounds = paramsPerNote[1].typeLabel.bounds
          v.triggerNote.bounds = paramsPerNote[1].triggerNote.bounds
          v.noteProbability.bounds = paramsPerNote[1].noteProbability.bounds
          v.listen.bounds = paramsPerNote[1].listen.bounds
          v.edit.bounds = paramsPerNote[1].edit.bounds
          v.mute.bounds = paramsPerNote[1].mute.bounds
        end
        for _,w in ipairs(v.sourceSelectors) do
          w.visible = isVisible
        end
        v.typeLabel.visible = isVisible
        v.triggerNote.visible = isVisible
        v.noteProbability.visible = isVisible
        v.accent.visible = isVisible
        v.accentFragmentStart.visible = isVisible
        v.accentDownBeat.visible = isVisible
        v.accentUpBeat.visible = isVisible
        v.restFirstBeatProbability.visible = isVisible
        v.restFirstInFragmentProbability.visible = isVisible
        v.downBeatProbability.visible = isVisible
        v.upBeatProbability.visible = isVisible
        v.sourceLabel.visible = isVisible
        v.accentLabel.visible = isVisible
        v.listen.visible = isVisible
        v.edit.visible = isVisible
        v.edit.displayName = "X"
        v.mute.visible = isVisible
      end
      all0Percent.visible = true
      all100Percent.visible = true
      all50percent.visible = true
      setRandomPercent.visible = true
    else
      for j,v in ipairs(paramsPerNote) do
        if i == j then
          v.typeLabel.bounds = bounds.typeLabel
          v.triggerNote.bounds = bounds.triggerNote
          v.noteProbability.bounds = bounds.noteProbability
          v.listen.bounds = bounds.listen
          v.edit.bounds = bounds.edit
          v.mute.bounds = bounds.mute
        end
        v.typeLabel.visible = true
        v.triggerNote.visible = true
        v.noteProbability.visible = true
        v.listen.visible = true
        v.mute.visible = true
        v.edit.visible = true
        v.edit.displayName = "E"
        v.accent.visible = false
        v.accentDownBeat.visible = false
        v.accentUpBeat.visible = false
        v.accentFragmentStart.visible = false
        v.restFirstBeatProbability.visible = false
        v.restFirstInFragmentProbability.visible = false
        v.downBeatProbability.visible = false
        v.upBeatProbability.visible = false
        v.accentLabel.visible = false
        v.sourceLabel.visible = false
        for _,w in ipairs(v.sourceSelectors) do
          w.visible = false
        end
      end
      all0Percent.visible = false
      all100Percent.visible = false
      all50percent.visible = false
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
  mute.normalImage = "../resources/icons/mute_inactive.png"
  mute.pressedImage = "../resources/icons/mute_active.png"
  mute.height = edit.height
  mute.width = edit.width
  mute.x = edit.x + edit.width + 4
  mute.y = edit.y

  local accentLabel = notePanel:Label("AccentLabel" .. i)
  accentLabel.visible = false
  accentLabel.text = "Accent"
  accentLabel.tooltip = "Set accents"
  accentLabel.height = triggerNote.height
  accentLabel.width = 120
  accentLabel.x = typeLabel.width + 20
  accentLabel.y = noteLabel.y

  local accent = notePanel:NumBox("NoteAccent" .. i, 0, 0, 16, true)
  accent.visible = false
  accent.displayName = "Every n-th note"
  accent.tooltip = "Accent every n-th note"
  accent.backgroundColour = menuBackgroundColour
  accent.textColour = menuTextColour
  accent.height = triggerNote.height
  accent.width = accentLabel.width
  accent.x = accentLabel.x
  accent.y = accentLabel.y + accentLabel.height + 5

  local accentFragmentStart = notePanel:OnOffButton("AccentFragmentStart" .. i, false)
  accentFragmentStart.visible = false
  accentFragmentStart.displayName = "Fragment Start"
  accentFragmentStart.tooltip = "When this is active, fragment start is accented"
  accentFragmentStart.backgroundColourOff = backgroundColourOff
  accentFragmentStart.backgroundColourOn = backgroundColourOn
  accentFragmentStart.textColourOff = textColourOff
  accentFragmentStart.textColourOn = textColourOn
  accentFragmentStart.height = accent.height
  accentFragmentStart.width = accent.width
  accentFragmentStart.x = accent.x
  accentFragmentStart.y = accent.y + accent.height

  local accentDownBeat = notePanel:OnOffButton("AccentDownBeat" .. i, false)
  accentDownBeat.visible = false
  accentDownBeat.displayName = "Downbeat"
  accentDownBeat.tooltip = "Accent note if triggered on the downbeat"
  accentDownBeat.backgroundColourOff = backgroundColourOff
  accentDownBeat.backgroundColourOn = backgroundColourOn
  accentDownBeat.textColourOff = textColourOff
  accentDownBeat.textColourOn = textColourOn
  accentDownBeat.height = accent.height
  accentDownBeat.width = accent.width / 2
  accentDownBeat.x = accentFragmentStart.x
  accentDownBeat.y = accentFragmentStart.y + accentFragmentStart.height

  local accentUpBeat = notePanel:OnOffButton("AccentUpBeat" .. i, false)
  accentUpBeat.visible = false
  accentUpBeat.displayName = "Upbeat"
  accentUpBeat.tooltip = "Accent note if triggered on the upbeat"
  accentUpBeat.backgroundColourOff = backgroundColourOff
  accentUpBeat.backgroundColourOn = backgroundColourOn
  accentUpBeat.textColourOff = textColourOff
  accentUpBeat.textColourOn = textColourOn
  accentUpBeat.height = accent.height
  accentUpBeat.width = accentDownBeat.width
  accentUpBeat.x = accentDownBeat.x + accentDownBeat.width
  accentUpBeat.y = accentDownBeat.y

  local sourceLabel = notePanel:Label("SourceInput" .. i)
  sourceLabel.visible = false
  sourceLabel.text = "Sources"
  sourceLabel.tooltip = "Select the fragments that are available for this part - NOTE: If all are 0, then all fragments can be selected."
  sourceLabel.height = accent.height
  sourceLabel.width = 60
  sourceLabel.x = accentLabel.x + accentLabel.width + 10
  sourceLabel.y = noteLabel.y

  local sourceSelectors = {}
  local rowCounter = 1
  local columnCounter = 0
  for j=1,numNotes do
    local sourceSelector = notePanel:NumBox("SourceSelector" .. i .. "_" .. j, 100, 0, 100, true)
    sourceSelector.unit = Unit.Percent
    sourceSelector.visible = false
    sourceSelector.displayName = "Rythm " .. j
    sourceSelector.tooltip = "Probability of rythmic fragment " .. j .. " being used for this part"
    sourceSelector.backgroundColour = menuBackgroundColour
    sourceSelector.textColour = menuTextColour
    sourceSelector.size = {112,22}
    sourceSelector.x = sourceLabel.x + (columnCounter * (sourceSelector.width + 5))
    sourceSelector.y = sourceLabel.y + (sourceLabel.height * rowCounter) + 5
    table.insert(sourceSelectors, sourceSelector)
    columnCounter = columnCounter + 1
    if j == numNotes / 2 then
      rowCounter = 2
      columnCounter = 0
    end
  end

  local downBeatProbability = notePanel:NumBox("DownBeatProbability" .. i, 100, 0, 100, true)
  downBeatProbability.unit = Unit.Percent
  downBeatProbability.visible = false
  downBeatProbability.displayName = "Downbeat"
  downBeatProbability.tooltip = "Probability of being played in the downbeat"
  downBeatProbability.backgroundColour = menuBackgroundColour
  downBeatProbability.textColour = menuTextColour
  downBeatProbability.height = triggerNote.height
  downBeatProbability.width = 112
  downBeatProbability.x = sourceLabel.x
  downBeatProbability.y = sourceLabel.y + (sourceLabel.height * 3) + 5

  local upBeatProbability = notePanel:NumBox("UpBeatProbability" .. i, 100, 0, 100, true)
  upBeatProbability.unit = Unit.Percent
  upBeatProbability.visible = false
  upBeatProbability.displayName = "Upbeat"
  upBeatProbability.tooltip = "Probability of being played in the upbeat"
  upBeatProbability.backgroundColour = menuBackgroundColour
  upBeatProbability.textColour = menuTextColour
  upBeatProbability.height = downBeatProbability.height
  upBeatProbability.width = downBeatProbability.width
  upBeatProbability.x = downBeatProbability.x + downBeatProbability.width + 5
  upBeatProbability.y = downBeatProbability.y

  local restFirstBeatProbability = notePanel:NumBox("RestFirstBeatProbability" .. i, 0, 0, 100, true)
  restFirstBeatProbability.unit = Unit.Percent
  restFirstBeatProbability.visible = false
  restFirstBeatProbability.displayName = "Rst 1st Bt"
  restFirstBeatProbability.tooltip = "Probability that a rest will be played if triggered at the start of a beat"
  restFirstBeatProbability.backgroundColour = menuBackgroundColour
  restFirstBeatProbability.textColour = menuTextColour
  restFirstBeatProbability.height = upBeatProbability.height
  restFirstBeatProbability.width = upBeatProbability.width
  restFirstBeatProbability.x = upBeatProbability.x + upBeatProbability.width + 5
  restFirstBeatProbability.y = upBeatProbability.y

  local restFirstInFragmentProbability = notePanel:NumBox("RestFirstInFragmentProbability" .. i, 0, 0, 100, true)
  restFirstInFragmentProbability.unit = Unit.Percent
  restFirstInFragmentProbability.visible = false
  restFirstInFragmentProbability.displayName = "Rst 1st Frg"
  restFirstInFragmentProbability.tooltip = "Probability that a rest will be played at the start of a fragment"
  restFirstInFragmentProbability.backgroundColour = menuBackgroundColour
  restFirstInFragmentProbability.textColour = menuTextColour
  restFirstInFragmentProbability.height = triggerNote.height
  restFirstInFragmentProbability.width = restFirstBeatProbability.width
  restFirstInFragmentProbability.x = restFirstBeatProbability.x + restFirstBeatProbability.width + 5
  restFirstInFragmentProbability.y = restFirstBeatProbability.y

  table.insert(paramsPerNote, {typeLabel=typeLabel, triggerNote=triggerNote, noteProbability=noteProbability, accent=accent, restFirstInFragmentProbability=restFirstInFragmentProbability, restFirstBeatProbability=restFirstBeatProbability, downBeatProbability=downBeatProbability, upBeatProbability=upBeatProbability, accentLabel=accentLabel, sourceLabel=sourceLabel, sourceSelectors=sourceSelectors, listen=listen, edit=edit, mute=mute, accentFragmentStart=accentFragmentStart, accentDownBeat=accentDownBeat, accentUpBeat=accentUpBeat})
end

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythm"
rythmLabel.alpha = 0.75
rythmLabel.fontSize = 15
rythmLabel.width = 50

paramsPerFragment = getParamsPerFragment(rythmPanel, rythmLabel, colours, numNotes)

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
    v.fragmentActive:setValue(string.len(v.fragmentInput.text) > 0 and getRandomBoolean())
  end
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function getNote(voice)
  local noteProbability = paramsPerNote[voice].noteProbability.value
  if getRandomBoolean(noteProbability) then
    return paramsPerNote[voice].triggerNote.value
  end
end

function startPlaying()
  if isPlaying then
    return
  end
  run(sequenceRunner)
end

function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  playingVoices = {}
  roundCounterPerVoice = {}
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive.textColourOn = "black"
  end
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function getSources(voice)
  local sources = {}
  for i,v in ipairs(paramsPerNote[voice].sourceSelectors) do
    if getRandomBoolean(v.value) then
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
    channel = voice
  end
  return channel
end

function isDownBeat()
  local beatBase = 2
  return beatCounter % beatBase > 0
end

function isUpBeat()
  return isDownBeat() == false
end

function getPlayOnUpBeat(voice)
  return getRandomBoolean(paramsPerNote[voice].upBeatProbability.value)
end

function getPlayOnDownBeat(voice)
  return getRandomBoolean(paramsPerNote[voice].downBeatProbability.value)
end

function isNoteActive(voice)
  return paramsPerNote[voice].noteProbability.value > 0 and paramsPerNote[voice].mute.value == false and hasActiveSources(voice)
end

function initNotes()
  playingVoices = {}
  roundCounterPerVoice = {}
  for voice=1,numNotes do
    table.insert(playingVoices, false) -- Init voices
    table.insert(roundCounterPerVoice, 0) -- Init rounds
  end
end

function selectNote(note)
  --print("selectNote", note)
  local activeNotes = {}
  local selectedNotes = {}
  for i=1,numNotes do
    --print("numNotes, note", numNotes, i)
    if isNoteActive(i) then
      --print("Note is active")
      table.insert(activeNotes, i)
      if getRandomBoolean(paramsPerNote[i].noteProbability.value) then
        --print("Note is selected")
        table.insert(selectedNotes, i)
      end
    end
  end
  --print("#selectedNotes, #activeNotes", #selectedNotes, #activeNotes)
  local newNote = getRandomFromTable(selectedNotes)
  if type(newNote) == "nil" and #activeNotes > 0 then
    newNote = getRandomFromTable(activeNotes)
  end
  --print("#selectedNotes, new, old", #selectedNotes, newNote, note)
  if type(newNote) == "number" and newNote ~= note then
    if type(note) == "number" then
      playingVoices[note] = false
    end
    note = newNote
    playingVoices[note] = true
  end
  return note
end

function hasPlayingVoice()
  for _,v in ipairs(playingVoices) do
    if v == true then
      return true
    end
  end
  return false
end

function useAccent(voice, isStartOfBeat)
  if paramsPerNote[voice].accentDownBeat.value and isStartOfBeat and isDownBeat() then
    return true
  end
  
  if paramsPerNote[voice].accentUpBeat.value and isStartOfBeat and isUpBeat() then
    return true
  end
  
  local accentEvery = paramsPerNote[voice].accent.value
  if accentEvery > 0 and roundCounterPerVoice[voice] % accentEvery == 0 then
    return true
  end

  if paramsPerNote[voice].accentFragmentStart.value and isFragmentStart and #activeFragment.f > 1 then
    return true
  end

  return false
end

function flashNoteLabel(voice, duration)
  local flashDuration = math.min(150, beat2ms(duration))
  paramsPerNote[voice].typeLabel.textColour = "efefef"
  wait(flashDuration)
  paramsPerNote[voice].typeLabel.textColour = "9f9f9f"
end

function sequenceRunner()
  local beat = 1 -- Base beat resolution
  isPlaying = true
  beatCounter = 1 -- Reset when starting sequencer
  initNotes()
  while isPlaying do
    --print("*** BEAT isDownBeat ***", beatCounter, isDownBeat())
    -- Check randomNoteMode
    if randomNoteMode.value then
      if hasPlayingVoice() == false then
        print("No playing voices")
        -- If no playing notes, select a new note
        local note = selectNote()
        print("Found note", note)
        if type(note) == "number" then
          playingVoices[note] = (isDownBeat() and getPlayOnDownBeat(note)) or (isUpBeat() and getPlayOnUpBeat(note))
          if playingVoices[note] then
            print("Play selected note", note)
            spawn(play, note)
          end
        end
      end
    else
      for voice=1,voices do
        if playingVoices[voice] == false then
          playingVoices[voice] = isNoteActive(voice) and ((isDownBeat() and getPlayOnDownBeat(voice)) or (isUpBeat() and getPlayOnUpBeat(voice)))
          if playingVoices[voice] then
            print("Play voice", voice)
            spawn(play, voice)
          end
        end
      end
    end
    waitBeat(beat)
    beatCounter = beatCounter + beat
  end
end

function play(voice)
  local playDuration = 0 -- Keep track of the played duration
  -- First
  local duration, isFragmentStart, isRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = getDuration(nil, 0, 0, false, 0, getSources(voice))
  -- Start loop
  while playingVoices[voice] do
    roundCounterPerVoice[voice] = roundCounterPerVoice[voice] + 1

    if type(duration) == "nil" or isNoteActive(voice) == false or (isDownBeat() and getPlayOnDownBeat(voice) == false) or (isUpBeat() and getPlayOnUpBeat(voice) == false) then
      -- Return voice to sequence runner
      print("BEFORE: Breaking loop for voice, isNoteActive(voice), duration", voice, isNoteActive(voice), duration)
      playingVoices[voice] = false
      break
    end

    -- Check rest at start of beat
    local isStartOfBeat = math.floor(playDuration) == playDuration
    if isStartOfBeat then
      if paramsPerNote[voice].restFirstBeatProbability.value == 0 then
        rest = false -- Make sure when probability is 0
      elseif rest == false and getRandomBoolean(paramsPerNote[voice].restFirstBeatProbability.value) then
        print("REST isStartOfBeat, voice", isStartOfBeat, voice)
        rest = true
      end
    end

    -- Check rest at start of fragment - only if fragment has more than one item
    if isFragmentStart and #activeFragment.f > 1 then
      if paramsPerNote[voice].restFirstInFragmentProbability.value == 0 then
        rest = false -- Make sure when probability is 0
      elseif rest == false and getRandomBoolean(paramsPerNote[voice].restFirstInFragmentProbability.value) then
        print("REST isFragmentStart, voice", isFragmentStart, voice)
        rest = true
      end
    end

    local note = getNote(voice)
    local doPlayNote = rest == false and type(note) == "number"
    if doPlayNote then
      local velocity = velocityInput.value
      if useAccent(voice, isStartOfBeat) then
        velocity = velocityAccent.value
      end
      --print("play: note, velocity, duration, voice", note, velocity, duration, voice)
      playNote(note, velocity, beat2ms(getPlayDuration(duration)), nil, getChannel())
      spawn(flashNoteLabel, voice, duration)
    end

    -- Update total play duration
    playDuration = playDuration + duration

    -- Store the current duration for waiting
    local waitDuration = duration

    -- Select a new note (voice) if in random note mode
    if randomNoteMode.value then
      voice = selectNote(voice)
    end

    -- Get next
    duration, isFragmentStart, isRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount, getSources(voice))

    -- Check if loop should be broken at the start of next round
    local remainingInBeat = math.ceil(playDuration) - playDuration
    --print("AFTER playDuration, remainingInBeat, isFragmentStart, isRepeat, voice", playDuration, remainingInBeat, isFragmentStart, isRepeat, "voice " .. voice)
    if type(duration) == "nil" or (remainingInBeat == 0 and roundCounterPerVoice[voice] > 1 and isFragmentStart == true and isRepeat == false) then
      print("AFTER: Breaking loop for voice, remainingInBeat, duration", voice, remainingInBeat, duration)
      playingVoices[voice] = false
    else
      --print("waitBeat(waitDuration)", waitDuration)
      waitBeat(waitDuration)
    end
  end
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  if type(noteListen) == "number" then
    paramsPerNote[noteListen].triggerNote:setValue(e.note)
    paramsPerNote[noteListen].listen:setValue(false)
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

  for _,v in ipairs(paramsPerNote) do
    table.insert(noteLabelData, v.typeLabel.text)
  end

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  return {fragmentInputData, noteLabelData}
end

function onLoad(data)
  local fragmentInputData = data[1]
  local noteLabelData = data[2]

  for i,v in ipairs(noteLabelData) do
    paramsPerNote[i].typeLabel.text = v
  end

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end
end
