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
polyphony.x = priority.x + priority.width + 50
polyphony.y = priority.y

local buffer = panel:NumBox("Buffer", 1, 0, 100, true)
buffer.unit = Unit.MilliSeconds
buffer.backgroundColour = menuBackgroundColour
buffer.textColour = menuTextColour
buffer.displayName = "Buffer"
buffer.tooltip = "Time to wait for incoming notes - if input is from a human, 20-30 ms is recommended, 0 means no buffer (NOTE: this disables the polyphony limit)"
buffer.x = polyphony.x
buffer.y = polyphony.y + polyphony.height + 5
buffer.changed = function(self)
  polyphony.enabled = self.value > 0
end

function eventsIncludeNote(eventTable, note)
  for _,v in pairs(eventTable) do
    local event = v
    if type(v.event) == "table" then
      event = v.event
    end
    if event.note == note then
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
local heldNotes = {} -- Holds the notes that are currently held
local noteBuffer = {} -- Holds the original (untransposed) incoming notes for the active buffer
function onNote(e)
  if polyphony.value == 0 then
    return
  end
  local note = e.note -- The original note without transposition
  e.note = transpose(e.note)

  -- Add to held notes, unless duplicate
  if eventsIncludeNote(heldNotes, e.note) == false then
    table.insert(heldNotes, e)
    print("Added note to held notes original/transposed", note, e.note)
  end

  -- Add to buffer, unless duplicate
  if eventsIncludeNote(noteBuffer, e.note) == false then
    table.insert(noteBuffer, {event=e,note=note})
    print("Added note to buffer original/transposed", note, e.note)
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
  elseif priority.value == 3 then
    print("Sort highest")
    table.sort(noteBuffer, function(a,b) return a.note > b.note end)
  end

  print("Current #heldNotes", #heldNotes)
  print("Current #noteBuffer", #noteBuffer)

  if polyphony.value < #noteBuffer then
    local keep = {}
    local i = 1
    while #keep < polyphony.value and i <= #noteBuffer do
      local event = noteBuffer[i].event
      -- Pick random notes from the incoming notes
      if priority.value == 4 then
        event = noteBuffer[getRandom(#noteBuffer)].event
        while eventsIncludeNote(keep, event.note) == true do
          event = noteBuffer[getRandom(#noteBuffer)].event
        end
      end
      print("postEvent", event.note)
      postEvent(event)
      table.insert(keep, event)
      i = i + 1 -- Increment index
    end

    -- Any held not that is not kept, must be released, unless it is in the current note buffer (then it has not been played)
    for _,held in ipairs(heldNotes) do
      if eventsIncludeNote(keep, held.note) == false and eventsIncludeNote(noteBuffer, held.note) == false then
        held.type = Event.NoteOff -- Send a note off event
        held.velocity = 0 -- Set no velocity on release to avoid any sound on release
        postEvent(held)
      end
    end
    heldNotes = keep -- Update held notes
  else
    print("Play all the notes from the active buffer")
    for _,v in ipairs(noteBuffer) do
      postEvent(v.event)
    end
  end

  print("Kept #heldNotes", #heldNotes)

  bufferActive = false -- Reset buffer
  noteBuffer = {} -- Reset note buffer
end

function onRelease(e)
  if polyphony.value == 0 then
    return
  end
  print("onRelease note in", e.note)
  e.note = transpose(e.note) -- Transpose note
  e.velocity = 0 -- Set no velocity on release to avoid any sound on release
  for i,v in ipairs(heldNotes) do
    if v.note == e.note then
      table.remove(heldNotes, i)
      print("Released note", e.note)
    end
  end
  postEvent(e)
end
