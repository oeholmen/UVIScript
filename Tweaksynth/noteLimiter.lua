--------------------------------------------------------------------------------
-- Note Limiter
--------------------------------------------------------------------------------
-- Limits note range and polyphony (0 polyphony blocks all incoming notes)
-- Notes outside range are transposed to the closest octave within range
-- Duplicate notes are removed
--------------------------------------------------------------------------------

local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "#00000000"
local heldNotes = {}

setBackgroundColour("#292929")

local panel = Panel("Limiter")
panel.backgroundColour = "#00000000"
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 60

local label = panel:Label("Label")
label.text = "Note Limiter"
label.alpha = 0.5
label.backgroundColour = "#020202"
label.fontSize = 22
label.position = {0,0}
label.size = {120,25}

local rangeLabel = panel:Label("Range")
rangeLabel.text = "Note Range"
rangeLabel.x = 150
rangeLabel.y = 3


local noteMin = panel:NumBox("NoteMin", 0, 0, 127, true)
noteMin.unit = Unit.MidiKey
noteMin.backgroundColour = menuBackgroundColour
noteMin.textColour = menuTextColour
noteMin.displayName = "Min"
noteMin.tooltip = "Lowest note - notes below this are transposed to closest octave within range"
noteMin.x = rangeLabel.x
noteMin.y = rangeLabel.y + rangeLabel.height + 5

local noteMax = panel:NumBox("NoteMax", 127, 0, 127, true)
noteMax.unit = Unit.MidiKey
noteMax.backgroundColour = menuBackgroundColour
noteMax.textColour = menuTextColour
noteMax.displayName = "Max"
noteMax.tooltip = "Highest note - notes above this are transposed to closest octave within range"
noteMax.x = noteMin.x + noteMin.width + 10
noteMax.y = noteMin.y

-- Range must be at least one octave
noteMin.changed = function(self)
  noteMax:setRange((self.value+12), 127)
end

noteMax.changed = function(self)
  noteMin:setRange(0, (self.value-12))
end

local priority = panel:Menu("Priority", {"As Played", "Lowest", "Highest", "Random"})
priority.backgroundColour = menuBackgroundColour
priority.textColour = menuTextColour
priority.arrowColour = menuArrowColour
priority.outlineColour = menuOutlineColour
priority.displayName = "Priority"
priority.tooltip = "Priority of incoming notes if limited by polyphony"
priority.x = noteMax.x + noteMax.width + 50
priority.y = rangeLabel.y

local polyphony = panel:NumBox("Polyphony", 16, 0, 16, true)
polyphony.displayName = "Polyphony"
polyphony.tooltip = "Limit polyphony to the set number of notes - 0 blocks all incoming notes"
polyphony.backgroundColour = menuBackgroundColour
polyphony.textColour = menuTextColour
--polyphony.x = 150
--polyphony.y = 3
polyphony.x = priority.x + priority.width + 50
polyphony.y = priority.y

local buffer = panel:NumBox("Buffer", 1, 0, 100, true)
buffer.unit = Unit.MilliSeconds
buffer.backgroundColour = menuBackgroundColour
buffer.textColour = menuTextColour
buffer.displayName = "Buffer"
buffer.tooltip = "Time to wait for incoming notes - if input is from a human, 20-30 ms is recommended, 0 means no buffer"
buffer.x = polyphony.x
buffer.y = polyphony.y + polyphony.height + 5

function eventIncludesNote(eventTable, note)
  for _,v in pairs(eventTable) do
    if v.note == note then
      print("Note already included", note)
      return true
    end
  end
  return false
end

function transpose(note)
  print("Check transpose", note)
  if note < noteMin.value then
    print("note < noteMin.value", note, noteMin.value)
    while note < noteMin.value do
      note = note + 12
      print("transpose note up", note)
    end
  elseif note > noteMax.value then
    print("note > noteMax.value", note, noteMax.value)
    while note > noteMax.value do
      note = note - 12
      print("transpose note down", note)
    end
  end
  return note
end

function getRandom(min, max, factor)
  if type(min) == "number" and type(max) == "number" then
    local value = math.random(min, max)
    return value
  elseif type(min) == "number" then
    local value = math.random(min)
    return value
  end
  local value = math.random()
  if type(factor) == "number" then
    value = value * factor
  end
  return value
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

local bufferActive = false
local noteBuffer = {} -- Holds the original incoming notes
local noteIndex = 1
function onNote(e)
  local note = e.note
  e.note = transpose(e.note)
  -- Check for duplicates
  if eventIncludesNote(heldNotes, e.note) == false then
    table.insert(heldNotes, e)
    table.insert(noteBuffer, {index=noteIndex,note=note})
    print("Added note at original/transposed/index", note, e.note, noteIndex)
    noteIndex = noteIndex + 1 -- Increment note index
  end

  -- Collect notes while the buffer is active
  if buffer.value > 0 then
    if bufferActive == false then
      bufferActive = true
      print("buffering")
      wait(buffer.value)
      print("buffering finished")
    else
      print("buffer active...")
      return
    end
  end

  -- Priority: {"As Played", "Lowest", "Highest", "Random"}
  if priority.value == 2 then
    print("Sort lowest")
    table.sort(noteBuffer, function(a,b) return a.note < b.note end)
    --print("noteBuffer first/last", noteBuffer[1].note, noteBuffer[#noteBuffer].note)
  elseif priority.value == 3 then
    print("Sort highest")
    table.sort(noteBuffer, function(a,b) return a.note > b.note end)
    --print("noteBuffer first/last", noteBuffer[1].note, noteBuffer[#noteBuffer].note)
  end

  print("Current #heldNotes", #heldNotes)

  if polyphony.value < #heldNotes then
    -- Pick random notes from the incoming notes
    local keep = {}
    local counter = 1
    while #keep < polyphony.value and counter <= #heldNotes do
      print("Selecting from heldNotes at index", noteBuffer[counter].index)
      local event = heldNotes[noteBuffer[counter].index]
      if priority.value == 4 then
        event = heldNotes[getRandom(#heldNotes)]
        while eventIncludesNote(keep, event.note) do
          event = heldNotes[getRandom(#heldNotes)]
        end
      end
      print("postEvent", event.note)
      postEvent(event)
      table.insert(keep, event)
      counter = counter + 1
    end

    heldNotes = keep -- Update held notes
  else
    -- Play all the held notes
    print("Play all the held notes")
    for _,event in ipairs(heldNotes) do
      postEvent(event)
    end
  end

  print("Kept #heldNotes", #heldNotes)

  bufferActive = false -- Reset buffer
  noteBuffer = {} -- Reset note buffer
  noteIndex = 1 -- Reset note index
end

function onRelease(e)
  e.note = transpose(e.note)
  for i,v in ipairs(heldNotes) do
    if v.note == e.note then
      table.remove(heldNotes, i)
      postEvent(e)
    end
  end
end
