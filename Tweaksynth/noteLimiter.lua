--------------------------------------------------------------------------------
-- Note Limiter
--------------------------------------------------------------------------------
-- Limits note range and polyphony (0 ployphony blocks all incoming notes)
-- Notes outside range are transposed to the closest octave within range
-- Duplicate notes are removed
--------------------------------------------------------------------------------

local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local heldNotes = {}

setBackgroundColour("#292929")

local panel = Panel("Limiter")
panel.backgroundColour = "#00000000"
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 40

local label = panel:Label("Label")
label.text = "Note Limiter"
label.alpha = 0.5
label.backgroundColour = "#020202"
label.fontSize = 22
label.position = {0,0}
label.size = {120,25}

-- Polyphony
local polyphony = panel:NumBox("Polyphony", 16, 0, 16, true)
polyphony.displayName = "Polyphony"
polyphony.tooltip = "Limit polyphony to the set number of notes - 0 blocks all incoming notes"
polyphony.backgroundColour = menuBackgroundColour
polyphony.textColour = menuTextColour
polyphony.x = 200
polyphony.y = 3

-- Range
local noteMin = panel:NumBox("NoteMin", 0, 0, 127, true)
noteMin.unit = Unit.MidiKey
noteMin.backgroundColour = menuBackgroundColour
noteMin.textColour = menuTextColour
noteMin.displayName = "Min note"
noteMin.tooltip = "Lowest note - notes below this are transposed to closest octave within range"
noteMin.x = polyphony.x + polyphony.width + 60
noteMin.y = polyphony.y

local noteMax = panel:NumBox("NoteMax", 127, 0, 127, true)
noteMax.unit = Unit.MidiKey
noteMax.backgroundColour = menuBackgroundColour
noteMax.textColour = menuTextColour
noteMax.displayName = "Max note"
noteMax.tooltip = "Highest note - notes above this are transposed to closest octave within range"
noteMax.x = noteMin.x + noteMin.width + 10
noteMax.y = polyphony.y

-- Range must be at least one octave
noteMin.changed = function(self)
  noteMax:setRange((self.value+12), 127)
end

noteMax.changed = function(self)
  noteMin:setRange(0, (self.value-12))
end

function heldNotesInclude(note)
  for _,v in pairs(heldNotes) do
    if v.note == note then
      print("Note already included", note)
      return true
    end
  end
  return false
end

function transpose(note)
  if note < noteMin.value then
    while note < noteMin.value do
      note = note + 12
    end
  else
    while note > noteMax.value do
      note = note - 12
    end
  end
  return note
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  e.note = transpose(e.note)
  if heldNotesInclude(e.note) == false and #heldNotes < polyphony.value then
    postEvent(e)
    table.insert(heldNotes, e)
  end
  print("Current #heldNotes", #heldNotes)
end

function onRelease(e)
  e.note = transpose(e.note)
  for i,v in ipairs(heldNotes) do
    if v.note == e.note then
      table.remove(heldNotes, i)
      if #heldNotes == 0 then
        print("All held notes are released")
      end
    end
  end
  postEvent(e)
end
