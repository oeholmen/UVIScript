-------------------------------------------------------------------------------
-- Transpose incoming notes to octave
-------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "F8B400"

setBackgroundColour(backgroundColour)

local widgetWidth = 110

local panel = widgets.panel({
  backgroundColour = backgroundColour,
  x = 10,
  y = 10,
  width = 700,
  height = 36,
})

local label = panel:Label("Label")
label.text = "Random octave"
label.tooltip = "Set a random octave within the given range on incoming notes"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 140

local probability = panel:NumBox("Probability", 50, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Probability that incoming notes will be transposed"
probability.textColour = widgetTextColour
probability.backgroundColour = widgetBackgroundColour
probability.y = label.y
probability.x = label.x + label.width + 50
probability.width = widgetWidth

local octaveRange = panel:NumBox("OctaveRange", 1, 1, 4, true)
octaveRange.textColour = widgetTextColour
octaveRange.backgroundColour = widgetBackgroundColour
octaveRange.displayName = "Octave"
octaveRange.tooltip = "Set the available range for octaves"
octaveRange.width = widgetWidth
octaveRange.x = probability.x + probability.width + 10
octaveRange.y = probability.y

local bipolar = panel:OnOffButton("Bipolar", true)
bipolar.displayName = "Bipolar"
bipolar.tooltip = "Use both positive and negative octave"
bipolar.backgroundColourOff = "#ff084486"
bipolar.backgroundColourOn = "#ff02ACFE"
bipolar.textColourOff = "#ff22FFFF"
bipolar.textColourOn = "#efFFFFFF"
bipolar.fillColour = "#dd000061"
bipolar.width = widgetWidth
bipolar.x = octaveRange.x + octaveRange.width + 10
bipolar.y = octaveRange.y

function setOctave(note)
  if gem.getRandomBoolean(probability.value) == false then
    print("Note was note transposed", note)
    return note
  end
  local octave = octaveRange.default
  if octaveRange.value > 1 then
    octave = gem.getRandom(octaveRange.value)
  end
  if bipolar.value and gem.getRandomBoolean() then
    octave = -octave
  end
  local transposedNote = note + (octave * 12)
  if transposedNote > 127 or transposedNote < 0 then
    print("Out of range, note, transposedNote", note, transposedNote)
    return note
  end
  print("Note was transposed, note, transposedNote, octave", note, transposedNote, octave)
  return transposedNote
end

function onNote(e)
  local note = setOctave(e.note)
  playNote(note, e.velocity)
end
