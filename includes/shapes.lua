--------------------------------------------------------------------------------
-- Methods for working with shapes
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

-- Keep in sync with function names
local shapeNames = {
  "Ramp Up",
  "Ramp Down",
  "Sine",
  "Triangle",
  "Triangle (Off Phs)",
  "LoFi Triangle",
  "Sqr/Tri",
  "Dome",
  "Dome Small",
  "Saw",
  "HPF Saw",
  "Analog Saw",
  "Fltr Sqr", 
  "Organ-Ish",
  "Tangent",
  "Triple Sine",
  "Punk Sine",
  "Soft Sine",
  "Even",
  "Odd",
  "Zero",
  "Min",
  "Max",
  "Chaos To Sine",
  "Saw/Sin Reveal",
  "PWM 50 to 100",
  "Triple-Sin Window",
  "Taffy",
  "Brassy",
  "HPF-Sqr To Sqr",
  "Wacky",
  "Sine To Noise",
  "Window-y SQR Sync",
  "Random",
  --"Test Shape",
}

local shapeFunctions = {
  "rampUp",
  "rampDown",
  "sine",
  "triangle",
  "triangleOffPhase",
  "lofiTriangle",
  "squareTri",
  "dome",
  "domeSmall",
  "sawInPhase",
  "hpfSaw",
  "sawAnalog",
  "filteredSquare", 
  "organIsh",
  "tangent",
  "tripleSin",
  "punkSine",
  "softSine",
  "even",
  "odd",
  "zero",
  "min",
  "max",
  "chaosToSine",
  "sawSinReveal",
  "pwm50to100",
  "tripleSinWindow",
  "taffy",
  "brassy",
  "hpfSqrToSqr",
  "wacky",
  "sinToNoise",
  "windowYSqr",
  "random",
  "testShape",
}

-- Holds the shape definitions
-- x = current time-value getting plotted, from -1.0 to 1.0 OR 0.0 to 1.0 (same as (x+1)/2) - depending on stepRange=1|2
-- z = current table number, from -1.0 to 1.0
-- i = current index
local shapes = {
  triangleShaper = function(x, z) return math.min(2+2*x, math.abs((x-0.5)*2)-1) * z end,
  sineShaper = function(x, z) return math.cos(x) * z end,
  sawInPhase = function(x, z) return (gem.sign(x)-x) * z end,
  sinToNoise = function(x, z, i) return 2*gem.avg({math.sin(z*x*math.pi),(1-z)*gem.getRandom()}) end,
  wacky = function(x, z, i) return math.sin(((x)+1)^(z-1)*math.pi) end,
  hpfSqrToSqr = function(x, z, i) if x < 0 then return math.sin((z*0.5)*math.pi)^(x+1) end return -math.sin((z*0.5)*math.pi)^x end,
  windowYSqr = function(x, z, i) local v = 1 if math.abs(x) > 0.5 then v = (1-math.abs(x))*2 end return v * math.min(1, math.max(-1,8*math.sin((z+0.02)*x*math.pi*32))) end,
  filteredSquare = function(x, z, i) return (1.2*math.sin(x*math.pi)+0.31*math.sin(x*math.pi*3)+0.11*math.sin(x*math.pi*5)+0.033*math.sin(x*math.pi*7)) * z end,
  organIsh = function(x, z) return (math.sin(x*math.pi)+(0.16*(math.sin(2*x*math.pi)+math.sin(3*x*math.pi)+math.sin(4*x*math.pi)))) * z end,
  sawAnalog = function(x, z) return (2.001 * (math.sin(x * 0.7905) - 0.5)) * z end,
  dome = function(x, z) return (2 * (math.sin(x * 1.5705) - 0.5)) * z end,
  brassy = function(x, z, i) return math.sin(math.pi*gem.sign(x)*(math.abs(x)^(((1-z)+0.1)*math.pi*math.pi))) end,
  taffy = function(x, z, i) return math.sin(x*math.pi*2)*math.cos(x*math.pi)*math.cos(z*math.pi*(math.abs((x*2)^3)-1)*math.pi) end,
  random = function(x, z) return ((gem.getRandom() * 2) - 1) * z end,
  punkSine = function(x, z) return math.sin(x*math.pi*(2+(62*z*z*z)))*math.sin(x*math.pi) end,
  softSine = function(x, z) return 0.5*(math.cos(x*math.pi/2)*((math.sin((x)*math.pi)+(1-z)*(math.sin(z*((x*x)^z)*math.pi*32))))) end,
  tripleSin = function(x, z) return math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x)) end,
  pwm50to100 = function(x, z, i) if x > z then return 1 end return -1 end,
  chaosToSine = function(x, z, i) return math.sin(math.pi*z*z*32*math.log(x+1)) end,
  sawSinReveal = function(x, z, i) if x + 1 > z * 2 then return x end return math.sin(x * math.pi) end,
  domeSmall = function(x, z) return (-1-1.275*math.sin(x*math.pi)) * z end,
  minMaxZero = function(x, z) return z end,
  oddAndEven = function(x, z, i) x = 1 if i % 2 == 0 then x = -1 end return x * z end,
  tangent = function(x, z) return math.tan(x * math.pi) * z end,
  lofiTriangle = function(x, z) return ((gem.round(16*math.abs(x))/8.0)-1) * z end,
  hpfSaw = function(x, z) return (x-(0.635*math.sin(x*math.pi))) * z end,
  squareTri = function(x, z) return (-1*(gem.sign(x)*0.5)+(math.abs(x)-0.5)) * z end,
  testShape = function(x, z, i)
    return x
  end
}

local function getDefaultShapeOptions()
  return {
    z = 1,
    stepRange = 2,
    phase = -1,
    factor = 1,
  }
end

local function getValueOrDefault(value, default)
  if type(value) == "number" then
    return value
  end
  return default
end

local function getShapeOptions(overrides)
  local defaultShapeOptions = getDefaultShapeOptions()
  if type(overrides) == "nil" then
    return defaultShapeOptions
  end
  return {
    stepRange = getValueOrDefault(overrides.stepRange, defaultShapeOptions.stepRange),
    phase = getValueOrDefault(overrides.phase, defaultShapeOptions.phase),
    factor = getValueOrDefault(overrides.factor, defaultShapeOptions.factor),
    z = getValueOrDefault(overrides.z, defaultShapeOptions.z),
  }
end

local function getShapeTemplate(options, shapeTemplate)
  if type(options) == "nil" and type(shapeTemplate) == "table" then
    options = shapeTemplate
  end
  return getShapeOptions(options)
end

local function getShapeNames(options, max)
  if type(max) ~= "number" then
    max = #shapeNames
  end

  local res = {}

  for _,r in ipairs(shapeNames) do
    table.insert(res, r)
    if i == max then
      break
    end
  end

  -- Add any options
  if type(options) == "table" then
    for _,o in ipairs(options) do
      table.insert(res, o)
    end
  end

  return res
end

local function getShapeFunctions()
  return shapeFunctions
end

local function getShapeFunction(i)
  return shapeFunctions[i]
end

local function getShapeBounds(bounds, options)
  local shapeBounds = {}
  if type(bounds) == "nil" then
    bounds = {}
  end
  shapeBounds.min = getValueOrDefault(bounds.min, -1) -- x-azis max value
  shapeBounds.max = getValueOrDefault(bounds.max, 1) -- x-azis min value
  shapeBounds.length = getValueOrDefault(bounds.length, 128) -- y-axis steps
  shapeBounds.unipolar = shapeBounds.min == 0
  shapeBounds.changePerStep = gem.getChangePerStep(options.stepRange, shapeBounds.length)
  return shapeBounds
end

local function createShape(shapeBounds, options, shapeFunc, shapeTemplate)
  options = getShapeTemplate(options, shapeTemplate)
  shapeBounds = getShapeBounds(shapeBounds, options)
  if type(shapeFunc) == "string" then
    shapeFunc = shapes[shapeFunc]
  end
  local shape = {}
  --print("Create shape, stepRange, phase, factor", options.stepRange, options.phase, options.factor)
  --print("shapeBounds.min, shapeBounds.max, shapeBounds.length, shapeBounds.changePerStep", shapeBounds.min, shapeBounds.max, shapeBounds.length, shapeBounds.changePerStep)
  for i=1,shapeBounds.length do
    local x = options.factor * ((shapeBounds.changePerStep * (i-1)) + options.phase)
    local z = options.z
    local value = shapeFunc(x, z, i, shapeBounds.min, shapeBounds.max)
    if shapeBounds.unipolar then
      value = ((shapeBounds.max * value) + shapeBounds.max) / 2
    else
      value = shapeBounds.max * value
    end
    --print("step, value, x", i, value, x)
    table.insert(shape, math.max(shapeBounds.min, math.min(shapeBounds.max, value)))
    --table.insert(shape, value)
  end
  return shape, options
end

local function getShapeWidgets(width, showLabel, i)
  -- Widgets for controlling shape
  if type(width) == "nil" then
    width = 120
  end
  if type(i) == "nil" then
    i = ""
  end
  local shapeOptions = getShapeOptions()
  return {
    stepRange = widgets.numBox("Step Range", shapeOptions.stepRange, {
      name = "ShapeStepRange" .. i,
      tooltip = "Set step range for the shape. Mostly affects polarity of the shape.",
      width = width,
      showLabel = showLabel == true,
      min = 0,
      max = 4,
    }),
    factor = widgets.numBox("Shape Factor", shapeOptions.factor, {
      name = "ShapeFactor" .. i,
      tooltip = "Set the factor (multiplier) applied to the value of each step.",
      width = width,
      showLabel = showLabel == true,
      min = -8,
      max = 8,
    }),
    phase = widgets.numBox("Shape Phase", shapeOptions.phase, {
      name = "ShapePhase" .. i,
      tooltip = "Set the phase applied to the shape (move left/right).",
      width = width,
      showLabel = showLabel == true,
      min = -1,
      max = 1,
    }),
    z = widgets.numBox("Shape Morph", shapeOptions.z, {
      name = "ShapeMorph" .. i,
      tooltip = "Set the morph value. This value is mostly assigned to amplitude, but it depends on the shape.",
      width = width,
      showLabel = showLabel == true,
      min = -1,
      max = 1,
    })
  }
end

return {--shapes--
  getWidgets = getShapeWidgets,
  getShapeNames = getShapeNames,
  getShapeFunctions = getShapeFunctions,
  getShapeFunction = getShapeFunction,
  getShapeOptions = getShapeOptions,
  squareTri = function(t,o) return createShape(t, o, 'squareTri') end,
  hpfSaw = function(t,o) return createShape(t, o, 'hpfSaw') end,
  softSine = function(t,o) return createShape(t, o, 'softSine') end,
  punkSine = function(t,o) return createShape(t, o, 'punkSine') end,
  lofiTriangle = function(t,o) return createShape(t, o, 'lofiTriangle') end,
  tangent = function(t,o) return createShape(t, o, 'tangent') end,
  even = function(t,o) return createShape(t, o, 'oddAndEven', {z = -1}) end,
  odd = function(t,o) return createShape(t, o, 'oddAndEven') end,
  min = function(t,o) return createShape(t, o, 'minMaxZero', {z = -1}) end,
  max = function(t,o) return createShape(t, o, 'minMaxZero') end,
  zero = function(t,o) return createShape(t, o, 'minMaxZero', {z = 0}) end,
  domeSmall = function(t,o) return createShape(t, o, 'domeSmall', {stepRange = 1}) end,
  sawSinReveal = function(t,o) return createShape(t, o, 'sawSinReveal', {phase = -1}) end,
  dome = function(t,o) return createShape(t, o, 'dome', {phase = 0}) end,
  sawAnalog = function(t,o) return createShape(t, o, 'sawAnalog', {phase = 0}) end,
  sawInPhase = function(t,o) return createShape(t, o, 'sawInPhase') end,
  organIsh = function(t,o) return createShape(t, o, 'organIsh') end,
  triangle = function(t,o) return createShape(t, o, 'triangleShaper') end,
  rampUp = function(t,o) return createShape(t, o, 'triangleShaper', {stepRange = 1, phase = 0.5}) end,
  rampDown = function(t,o) return createShape(t, o, 'triangleShaper', {stepRange = 1, phase = -0.5}) end,
  triangleOffPhase = function(t,o) return createShape(t, o, 'triangleShaper', {phase = -0.5}) end,
  sine = function(t,o) return createShape(t, o, 'sineShaper', {phase = -0.5, factor = math.pi}) end,
  chaosToSine = function(t,o) return createShape(t, o, 'chaosToSine') end,
  pwm50to100 = function(t,o) return createShape(t, o, 'pwm50to100') end,
  tripleSin = function(t,o) return createShape(t, o, 'tripleSin') end,
  tripleSinWindow = function(t,o) return createShape(t, o, 'tripleSin', {z = 0}) end,
  taffy = function(t,o) return createShape(t, o, 'taffy', {z = 0}) end,
  brassy = function(t,o) return createShape(t, o, 'brassy', {z = 0}) end,
  hpfSqrToSqr = function(t,o) return createShape(t, o, 'hpfSqrToSqr', {z = 0.01}) end,
  wacky = function(t,o) return createShape(t, o, 'wacky', {z = 0.84}) end,
  sinToNoise = function(t,o) return createShape(t, o, 'sinToNoise') end,
  filteredSquare = function(t,o) return createShape(t, o, 'filteredSquare') end,
  windowYSqr = function(t,o) return createShape(t, o, 'windowYSqr', {z = 0}) end,
  random = function(t,o) return createShape(t, o, 'random') end,
  testShape = function(t,o) return createShape(t, o, 'testShape') end,
}
