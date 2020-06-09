--------------------------------------------------------------------------------
--! @example tremolo.lua
--! amplitude LFO
--------------------------------------------------------------------------------

lfoFreq = Knob("freq", 4.0, 0, 10) -- 4 Hz

function onNote(e)
  local id = postEvent(e)
  
  local duration = 0 -- in seconds
  local step = 5 -- ms
  while isNoteHeld() do
    local freq = lfoFreq.value * e.note/128.0
    local volume = 0.5 * ( 1 + math.sin(2 * math.pi * freq * duration))
    local pan = math.sin(2 * math.pi * freq * duration + math.pi/2)
    changeVolume(id, volume);
    changePan(id, pan);
    wait(step)
    duration = duration + step/1000.0
  end
end
