--------------------------------------------------------------------------------
-- Common Notes
--------------------------------------------------------------------------------

local notenames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

function getNoteNames()
  return notenames
end

-- Used for mapping - does not include octave, only name of note (C, C#...)
function getNoteMapping()
  local noteNumberToNoteName = {}
  local notenamePos = 1
  for i=0,127 do
    table.insert(noteNumberToNoteName, notenames[notenamePos])
    notenamePos = notenamePos + 1
    if notenamePos > #notenames then
      notenamePos = 1
    end
  end
  return noteNumberToNoteName
end

function transpose(note, min, max)
  --print("Check transpose", note)
  if note < min then
    print("note < min", note, min)
    while note < min do
      note = note + 12
      print("transpose note up", note)
    end
  elseif note > max then
    print("note > max", note, max)
    while note > max do
      note = note - 12
      print("transpose note down", note)
    end
  end
  return note
end

function getSemitonesBetweenNotes(note1, note2)
  return math.max(note1, note2) - math.min(note1, note1)
end

function getNoteAccordingToScale(scale, noteToPlay)
  for _,note in ipairs(scale) do
    if note == noteToPlay then
      return noteToPlay
    elseif note > noteToPlay then
      print("Change from noteToPlay to note", noteToPlay, note)
      return note
    end
  end
  return noteToPlay
end
