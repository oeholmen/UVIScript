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
  "Soft Sine", -- TODO Rename?
  "Sweet Sine",
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
  "triangleInPhase",
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
  "softSine",
  "sweetSine",
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
  triangleShaper = function(x, z)
    return math.min(2+2*x, math.abs((x-0.5)*2)-1) * z -- Unique
  end,
  sineShaper = function(x, z) return math.cos(x) * z end,
  sawInPhase = function(x, z) return (signA(x)-x) * z end,
  sinToNoise = function(x, z, i) return 2*gem.avg({math.sin(z*x*math.pi),(1-z)*gem.getRandom()}) end,
  wacky = function(x, z, i) return math.sin(((x)+1)^(z-1)*math.pi) end,
  hpfSqrToSqr = function(x, z, i)
    if x < 0 then
      return math.sin((z*0.5)*math.pi)^(x+1)
    end
    return -math.sin((z*0.5)*math.pi)^x
  end,
  windowYSqr = function(x, z, i)
    local v = 1
    if math.abs(x) > 0.5 then
      v = (1-math.abs(x))*2
    end
    return v * math.min(1, math.max(-1,8*math.sin((z+0.02)*x*math.pi*32)))
  end,
  filteredSquare = function(x, z, i)
    return (1.2*math.sin(x*math.pi)+0.31*math.sin(x*math.pi*3)+0.11*math.sin(x*math.pi*5)+0.033*math.sin(x*math.pi*7)) * z
  end,
  organIsh = function(x, z)
    return (math.sin(x*math.pi)+(0.16*(math.sin(2*x*math.pi)+math.sin(3*x*math.pi)+math.sin(4*x*math.pi)))) * z
  end,
}

local function getDefaultShapeOptions()
  return {
    z = 1,
    stepRange = 2,
    phase = -1,
    factor = 1,
  }
end

local shapeTemplates = {
  sine = {
    phase = -0.5,
    factor = math.pi,
  },
  triangleOffPhase = {
    phase = -0.5,
  },
  rampUp = {
    stepRange = 1,
    phase = 0.5,
  },
  rampDown = {
    stepRange = 1,
    phase = -0.5,
  },
  range1 = {
    stepRange = 1
  },
  phase0 = {
      phase = 0
  },
  zero = {
      z = 0
  },
  min = {
      z = -1
  },
}

-- sign function: -1 if x<0; 1 if x>0
local function signA(x)
  if x < 0 then
    return -1
  end
  return 1
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
  --print("defaultShapeOptions:stepRange, phase, factor, z", defaultShapeOptions.stepRange, defaultShapeOptions.phase, defaultShapeOptions.factor, defaultShapeOptions.z)
  return {
    stepRange = getValueOrDefault(overrides.stepRange, defaultShapeOptions.stepRange),
    phase = getValueOrDefault(overrides.phase, defaultShapeOptions.phase),
    factor = getValueOrDefault(overrides.factor, defaultShapeOptions.factor),
    z = getValueOrDefault(overrides.z, defaultShapeOptions.z),
  }
end

local function getShapeTemplate(options, shapeTemplate)
  if type(options) == "nil" then
    if type(shapeTemplate) == "string" then
      options = shapeTemplates[shapeTemplate]
    elseif type(shapeTemplate) == "table" then
      options = shapeTemplate
    end
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

local function createShape(shapeTable, options, shapeFunc, shapeTemplate)
  options = getShapeTemplate(options, shapeTemplate)
  local minValue = shapeTable.min
  local maxValue = shapeTable.max
  local numSteps = shapeTable.length
  local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(options.stepRange, numSteps)
  if type(shapeFunc) == "string" then
    shapeFunc = shapes[shapeFunc]
  end
  local shape = {}
  --print("Create shape, stepRange, phase, factor", options.stepRange, options.phase, options.factor)
  --print("minValue, maxValue, numSteps, changePerStep", minValue, maxValue, numSteps, changePerStep)
  for i=1,numSteps do
    local x = options.factor * ((changePerStep * (i-1)) + options.phase)
    local z = options.z
    local value = shapeFunc(x, z, i)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    --print("step, value, x", i, value, x)
    table.insert(shape, math.max(minValue, math.min(maxValue, value)))
    --table.insert(shape, value)
  end
  return shape, options
end

local function testShape(shapeTable, options)
  local shapeFunc = function(x, z, i)
    return x
  end
  if type(options) == "nil" then
    options = shapeTemplates.zero
  end
  return createShape(shapeTable, options, shapeFunc)
end

-- brassy sin(pi*sign(x)*(abs(x)^(((1-z)+0.1)*pi*pi)))
local function brassy(shapeTable, options)
  local shapeFunc = function(x, z, i)
    return math.sin(math.pi*signA(x)*(math.abs(x)^(((1-z)+0.1)*math.pi*math.pi)))
  end
  if type(options) == "nil" then
    options = shapeTemplates.zero
  end
  return createShape(shapeTable, options, shapeFunc)
end

-- taffy sin(x*pi*2)*cos(x*pi)*cos(z*pi*(abs((x*2)^3)-1)*pi)
local function taffy(shapeTable, options)
  local shapeFunc = function(x, z, i)
    return math.sin(x*math.pi*2)*math.cos(x*math.pi)*math.cos(z*math.pi*(math.abs((x*2)^3)-1)*math.pi)
  end
  if type(options) == "nil" then
    options = shapeTemplates.zero
  end
  return createShape(shapeTable, options, shapeFunc)
end

-- tripple-sin window
local function tripleSinWindow(shapeTable, options)
  local shapeFunc = function(x, z, i)
    return math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x))
  end
  if type(options) == "nil" then
    options = shapeTemplates.zero
  end
  return createShape(shapeTable, options, shapeFunc)
end

-- pwm 50-100 (x>z)?1:-1
local function pwm50to100(shapeTable, options)
  local shapeFunc = function(x, z, i)
    if x > z then
      return 1
    end
    return -1
  end
  return createShape(shapeTable, options, shapeFunc)
end

-- saw sin reveal (x+1>z*2)?(x):sin(x*pi)
local function sawSinReveal(shapeTable, options)
  local shapeFunc = function(x, z, i)
    if x + 1 > z * 2 then
      return x
    end
    return math.sin(x * math.pi)
  end
  if type(options) == "nil" then
    options = shapeTemplates.min
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function chaosToSine(shapeTable, options)
  local shapeFunc = function(x, z, i)
    return math.sin(math.pi*z*z*32*math.log(x+1))
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function randomAll(shapeTable, options)
  local shapeFunc = function(x, z)
    return ((gem.getRandom() * 2) - 1) * z
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function oddAndEven(shapeTable, options)
  local shapeFunc = function(x, z, i)
    x = 1
    if i % 2 == 0 then
      x = -1
    end
    return x * z
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function evenMax(shapeTable, options)
  if type(options) == "nil" then
    options = shapeTemplates.min
  end
  return oddAndEven(shapeTable, options)
end

local function oddMax(shapeTable, options)
  return oddAndEven(shapeTable, options)
end

local function minMaxZero(shapeTable, options)
  local shapeFunc = function(x, z)
    return z
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function zeroAll(shapeTable, options)
  if type(options) == "nil" then
    options = shapeTemplates.zero
  end
  return minMaxZero(shapeTable, options)
end

local function minAll(shapeTable, options)
  if type(options) == "nil" then
    options = shapeTemplates.min
  end
  return minMaxZero(shapeTable, options)
end

local function maxAll(shapeTable, options)
  return minMaxZero(shapeTable, options)
end

local function sweetSine(shapeTable, options)
  local shapeFunc = function(x, z)
    return 0.5*(math.cos(x*math.pi/2)*((math.sin((x)*math.pi)+(1-z)*(math.sin(z*((x*x)^z)*math.pi*32))))) -- Unique
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function softSine(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.sin(x*math.pi*(2+(62*z*z*z)))*math.sin(x*math.pi) -- Unique
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function tripleSin(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x)) -- Unique
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function hpfSaw(shapeTable, options)
  local shapeFunc = function(x, z)
    return (x-(0.635*math.sin(x*math.pi))) * z -- Unique
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function squareTri(shapeTable, options)
  local shapeFunc = function(x, z)
    return (-1*(signA(x)*0.5)+(math.abs(x)-0.5)) * z -- Unique
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function lofiTriangle(shapeTable, options)
  local shapeFunc = function(x, z)
    return ((gem.round(16*math.abs(x))/8.0)-1) * z -- Unique
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function tangent(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.tan(x * math.pi) * z
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function dome(shapeTable, options)
  local shapeFunc = function(x, z)
    return (2 * (math.sin(x * 1.5705) - 0.5)) * z -- Unique
  end
  -- Get from template
  if type(options) == "nil" then
    options = shapeTemplates.phase0
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function domeSmall(shapeTable, options)
  local shapeFunc = function(x, z)
    return (-1-1.275*math.sin(x*math.pi)) * z -- Unique
  end
  -- Get from template
  if type(options) == "nil" then
    options = shapeTemplates.range1
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function sawAnalog(shapeTable, options)
  local shapeFunc = function(x, z)
    return (2.001 * (math.sin(x * 0.7905) - 0.5)) * z
  end
  -- Get from template
  if type(options) == "nil" then
    options = shapeTemplates.phase0
  end
  return createShape(shapeTable, options, shapeFunc)
end

local function getShapeWidgets(width, showLabel)
  -- Widgets for controlling shape
  if type(width) == "nil" then
    width = 30
  end
  local shapeOptions = getShapeOptions()
  return {
    stepRange = widgets.numBox("Step Range", shapeOptions.stepRange, {
      name = "ShapeStepRange",
      tooltip = "Set step range for the shape. Mostly affects polarity of the shape.",
      width = width,
      showLabel = showLabel == true,
      min = 0,
      max = 4,
    }),
    factor = widgets.numBox("Shape Factor", shapeOptions.factor, {
      name = "ShapeFactor",
      tooltip = "Set the factor (multiplier) applied to the value of each step.",
      width = width,
      showLabel = showLabel == true,
      min = -8,
      max = 8,
    }),
    phase = widgets.numBox("Shape Phase", shapeOptions.phase, {
      name = "ShapePhase",
      tooltip = "Set the phase applied to the shape (move left/right).",
      width = width,
      showLabel = showLabel == true,
      min = -1,
      max = 1,
    }),
    z = widgets.numBox("Shape Morph", shapeOptions.z, {
      name = "ShapeMorph",
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
  tangent = tangent,
  sawSinReveal = sawSinReveal,
  dome = dome,
  domeSmall = domeSmall,
  hpfSaw = hpfSaw,
  sawAnalog = sawAnalog,
  sawInPhase = function(t,o) return createShape(t, o, 'sawInPhase') end,
  organIsh = function(t,o) return createShape(t, o, 'organIsh') end,
  triangleInPhase = function(t,o) return createShape(t, o, 'triangleShaper') end,
  rampUp = function(t,o) return createShape(t, o, 'triangleShaper', 'rampUp') end,
  rampDown = function(t,o) return createShape(t, o, 'triangleShaper', 'rampDown') end,
  triangleOffPhase = function(t,o) return createShape(t, o, 'triangleShaper', 'triangleOffPhase') end,
  squareTri = squareTri,
  lofiTriangle = lofiTriangle,
  testShape = testShape,
  sweetSine = sweetSine,
  softSine = softSine,
  tripleSin = tripleSin,
  sine = function(t,o) return createShape(t, o, 'sineShaper', 'sine') end,
  even = evenMax,
  odd = oddMax,
  zero = zeroAll,
  min = minAll,
  max = maxAll,
  chaosToSine = chaosToSine,
  pwm50to100 = pwm50to100,
  tripleSinWindow = tripleSinWindow,
  taffy = taffy,
  brassy = brassy,
  hpfSqrToSqr = function(t,o) return createShape(t, o, 'hpfSqrToSqr', {z = 0.01}) end,
  wacky = function(t,o) return createShape(t, o, 'wacky', {z = 0.84}) end,
  sinToNoise = function(t,o) return createShape(t, o, 'sinToNoise') end,
  filteredSquare = function(t,o) return createShape(t, o, 'filteredSquare') end,
  windowYSqr = function(t,o) return createShape(t, o, 'windowYSqr', {z = 0}) end,
  random = randomAll,
}
