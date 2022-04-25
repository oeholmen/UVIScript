--------------------------------------------------------------------------------
-- Velocity Limiter
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
panel.height = 40

local label = panel:Label("Label")
label.text = "Velocity Limiter"
label.alpha = 0.5
label.backgroundColour = "#020202"
label.fontSize = 22
label.position = {0,0}
label.size = {140,25}
label.y = 5

local velMin = panel:NumBox("VelMin", 1, 1, 127, true)
velMin.backgroundColour = menuBackgroundColour
velMin.textColour = menuTextColour
velMin.displayName = "Min"
velMin.x = label.x + label.width + 150
velMin.y = label.y

local velMax = panel:NumBox("VelMax", 127, 1, 127, true)
velMax.backgroundColour = menuBackgroundColour
velMax.textColour = menuTextColour
velMax.displayName = "Max"
velMax.x = velMin.x + velMin.width + 10
velMax.y = velMin.y

-- Range must be at least one octave
velMin.changed = function(self)
  velMax:setRange((self.value), 127)
end

velMax.changed = function(self)
  velMin:setRange(1, (self.value))
end

function adjust(velocity)
  if velocity < velMin.value then
    print("velocity < velMin.value", velocity, velMin.value)
    velocity = velMin.value
  elseif velocity > velMax.value then
    print("velocity > velMax.value", velocity, velMax.value)
    velocity = velMax.value
  end
  return velocity
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  e.velocity = adjust(e.velocity)
  postEvent(e)
end
