CenterPitch = Knob("PitchCenter", 64, 0, 127, true)
Horrors = Knob("HorrorLevel", 4, 0, 11, true)

function onNote(e)
    postEvent(e)
    local center = CenterPitch.value
    local delta = e.note - center
    local note = center - delta
    if Horrors.value > 0 and note >= 0 and note <= 127 then
        local i = 1
        while isNoteHeld() do
            if i > Horrors.value then
                break
            end
            waitBeat(0.5)
            local velocity = e.velocity / 2
            local id = playNote(note, velocity)
            changeTune(id, math.random(-i, i))
            i = i + 1
        end
    end
end

function onRelease(e)
    postEvent(e)
end

makePerformanceView()
