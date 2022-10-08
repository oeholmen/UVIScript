--------------------------------------------------------------------------------
-- Velocity Limiter
--------------------------------------------------------------------------------

require "../includes/common"

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "15133C" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour

setBackgroundColour(backgroundColour)

local panel = Panel("Limiter")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 40

local label = panel:Label("Label")
label.text = "Velocity Limiter"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {140,25}
label.y = 5

local velMin = panel:NumBox("VelMin", 1, 1, 127, true)
velMin.backgroundColour = widgetBackgroundColour
velMin.textColour = widgetTextColour
velMin.displayName = "Min"
velMin.x = label.x + label.width + 150
velMin.y = label.y

local velMax = panel:NumBox("VelMax", 127, 1, 127, true)
velMax.backgroundColour = widgetBackgroundColour
velMax.textColour = widgetTextColour
velMax.displayName = "Max"
velMax.x = velMin.x + velMin.width + 10
velMax.y = velMin.y

local velRandomization = panel:NumBox("VelocityRandomization", 0, 0, 100, true)
velRandomization.displayName = "Randomize"
velRandomization.tooltip = "Amount of radomization applied to velocity"
velRandomization.unit = Unit.Percent
velRandomization.backgroundColour = widgetBackgroundColour
velRandomization.textColour = widgetTextColour
velRandomization.x = velMax.x + velMax.width + 10
velRandomization.y = velMax.y

-- Avoid range crossing
velMin.changed = function(self)
  velMax:setRange((self.value), 127)
end

velMax.changed = function(self)
  velMin:setRange(1, (self.value))
end

function adjust(velocity)
  local velocityWasAdjusted = false
  if velocity < velMin.value then
    print("velocity < velMin.value", velocity, velMin.value)
    velocity = velMin.value
    velocityWasAdjusted = true
  elseif velocity > velMax.value then
    print("velocity > velMax.value", velocity, velMax.value)
    velocity = velMax.value
    velocityWasAdjusted = true
  end

  -- Randomize velocity if there was an adjustment made
  -- This is done to avoid a "hard" velocity limit
  local velRandomization = velRandomization.value
  if velocityWasAdjusted and velRandomization > 0 then
    local changeMax = getChangeMax(velMax.value, velRandomization)
    local min = velocity - changeMax
    local max = velocity + changeMax
    if min < velMin.value then
      min = velMin.value
    end
    if max > velMax.value then
      max = velMax.value
    end
    print("Before randomize velocity", velocity)
    velocity = getRandom(min, max)
    print("After randomize velocity/changeMax/min/max", velocity, changeMax, min, max)
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
