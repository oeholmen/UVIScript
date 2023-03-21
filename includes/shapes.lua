--------------------------------------------------------------------------------
-- Methods for working with shapes
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

local getUnipolar = function(v) return (v + 1) / 2 end

-- Holds the shape definitions - functions get the following variables
-- x is the current time-value getting plotted, from -1.0 to 1.0
-- z is the current table number, from -1.0 to 1.0
-- w is the current time-value getting plotted, from 0.0 to 1.0 (same as (x+1)/2)
-- y is the current table number, from 0.0 to 1.0 (same as (z+1)/2)
-- pos = current index (from 0)
-- b = bounds (min, max, length, unipolar, rand)
local shapes = {
  ramp = function(x, z, pos, b) return x * z end,
  triangleShaper = function(x, z, pos, b) return math.min(2+2*x, math.abs((x-0.5)*2)-1) * z end,
  sine = function(x, z, pos, b) return math.sin(x*math.pi) * z end,
  tangent = function(x, z, pos, b) return math.tan(x) * z end,
  sawInPhase = function(x, z, pos, b) return (gem.sign(x)-x) * z end,
  sinToNoise = function(x, z, pos, b) return 2*gem.avg({math.sin(z*x*math.pi),(1-z)*gem.getRandom()}) end,
  wacky = function(x, z, pos, b) return math.sin(((x)+1)^(z-1)*math.pi) end,
  hpfSqrToSqr = function(x, z, pos, b) if x < 0 then return math.sin((z*0.5)*math.pi)^(x+1) end return -math.sin((z*0.5)*math.pi)^x end,
  windowYSqr = function(x, z, pos, b) local v = 1 if math.abs(x) > 0.5 then v = (1-math.abs(x))*2 end return v * math.min(1, math.max(-1,8*math.sin((z+0.02)*x*math.pi*32))) end,
  filteredSquare = function(x, z, pos, b) return (1.2*math.sin(x*math.pi)+0.31*math.sin(x*math.pi*3)+0.11*math.sin(x*math.pi*5)+0.033*math.sin(x*math.pi*7)) * z end,
  organIsh = function(x, z, pos, b) return (math.sin(x*math.pi)+(0.16*(math.sin(2*x*math.pi)+math.sin(3*x*math.pi)+math.sin(4*x*math.pi)))) * z end,
  sawAnalog = function(x, z, pos, b) return (2.001 * (math.sin(x * 0.7905) - 0.5)) * z end,
  dome = function(x, z, pos, b) return (2 * (math.sin(x * 1.5705) - 0.5)) * z end,
  brassy = function(x, z, pos, b) return math.sin(math.pi*gem.sign(x)*(math.abs(x)^(((1-z)+0.1)*math.pi*math.pi))) end,
  taffy = function(x, z, pos, b) return math.sin(x*math.pi*2)*math.cos(x*math.pi)*math.cos(z*math.pi*(math.abs((x*2)^3)-1)*math.pi) end,
  random = function(x, z, pos, b) return ((gem.getRandom() * 2) - 1) * z end,
  harmonicSync = function(x, z, pos, b) return math.sin(x*math.pi*(2+(62*z*z*z)))*math.sin(x*math.pi) end,
  softSine = function(x, z, pos, b) return 0.5*(math.cos(x*math.pi/2)*((math.sin((x)*math.pi)+(1-z)*(math.sin(z*((x*x)^z)*math.pi*32))))) end,
  tripleSin = function(x, z, pos, b) return math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x)) end,
  pwm50to100 = function(x, z, pos, b) if x > z then return 1 end return -1 end,
  chaosToSine = function(x, z, pos, b) return math.sin(math.pi*z*z*32*math.log(x+1)) end,
  sawSinReveal = function(x, z, pos, b) if x + 1 > z * 2 then return x end return math.sin(x * math.pi) end,
  domeSmall = function(x, z, pos, b) return (-1-1.275*math.sin(getUnipolar(x)*math.pi)) * z end,
  zero = function(x, z, pos, b) if b.unipolar then return -1 end return 0 end,
  minMax = function(x, z, pos, b) return z end,
  oddAndEven = function(x, z, pos, b) x = -1 if pos % 2 == 0 then x = 1 end return x * z end,
  lofiTriangle = function(x, z, pos, b) return ((gem.round(16*math.abs(x))/8.0)-1) * z end,
  hpfSaw = function(x, z, pos, b) return (x-(0.635*math.sin(x*math.pi))) * z end,
  squareTri = function(x, z, pos, b) return (-1*(gem.sign(x)*0.5)+(math.abs(x)-0.5)) * z end,
  sineStrech = function(x, z, pos, b) return math.sin(x^(1+(gem.round(z*32)*2))*math.pi) end,
  squareSawBit = function(x, z, pos, b) return math.sin((2-(z/4))*x*x*math.pi)/gem.round(x*32*((z/4)*(z/4)-0.125)) end,
  loFiTriangles = function(x, z, pos, b) return (gem.round((2+(z*14))*math.abs(x))/(1+(z*7.0)))-1 end,
  talkative1 = function(x, z, pos, b) return 1.4*math.cos(x*math.pi/2)*(.5*math.sin(((z*5)+1)*3*x)+.10*math.sin(((z*6)+1)*2*x)+.08*math.sin((((1-z)*3)+1)*12*x)) end,
  sinClipper = function(x, z, pos, b) return math.sin(x*math.pi)*(((z*z)+0.125)*8) end,
  pitfall = function(x, z, pos, b) return (x*128)%(z*16)*0.25 end,
  nascaLines = function(x, z, pos, b) return math.sqrt(1/pos)*(((pos/2)*(z+0.1)*b.max)%3)*0.5 end,
  kick = function(x, z, pos, b) return math.sin(math.pi*z*z*32*math.log(x+1)) end,
  sinToSaw = function(x, z, pos, b) return math.sin(-x*math.pi)*(1-z)+(-x*z) end,
  zeroCrossing = function(x, z, pos, b) return math.sin((x+1)*math.pi*(z+1))*(-math.abs(x)^32+1) end,
  vosim = function(x, z, pos, b) return -(getUnipolar(x)-1)*math.sin(getUnipolar(x)*math.pi*8*(math.sin(z)+1.5))^2 end,
  vosimNormalized = function(x, z, pos, b) return (-(getUnipolar(x)-1)*math.sin(getUnipolar(x)*math.pi*9*(math.sin(getUnipolar(z))+1.3))^2-.5)*2 end,
  acos = function(x, z, pos, b) return math.acos(x) * z end,
  wings = function(x, z, pos, b) return math.acos((math.abs(-math.abs(x)+1) + -math.abs(x)+1)/2) * z end,
  crosser = function(x, z, pos, b) return gem.avg({x, getUnipolar(x)}) * z end,
  diracDelta = function(x, z, pos, b) return (math.exp(-1*(x/((0.0001+z)*2))^2))/(((0.0001+z)*2)*math.sqrt(math.pi)*16) end,
  diracDeltaFrexp = function(x, z, pos, b) return (math.frexp(-1*(x/((0.0001+z)*2))^2))/(((0.0001+z)*2)*math.sqrt(math.pi)*16) end,
  diracDeltaRand = function(x, z, pos, b) return (math.exp(-1*(x/((0.0001+z)*2))^2))/(((0.0001+z)*2)*math.sqrt(math.pi)*math.min(8, b.rand*32)) end,
  swipe1 = function(x, z, pos, b) return math.exp(math.abs(x)/getUnipolar(z)) * z end,
  swipe2 = function(x, z, pos, b) return math.exp(math.tan(x)/math.pi) * z end,
  swipe3 = function(x, z, pos, b) return math.exp(x-getUnipolar(z)) * z end,
  swipe4 = function(x, z, pos, b) return (math.exp(x)) * gem.avg({z, x}) end,
  mayhemInTheMiddle = function(x, z, pos, b) return math.sin((x * math.pi) + (z * math.tan(getUnipolar(x) * math.pi))) end,
  zeroDancer = function(x, z, pos, b) return math.sin(x / z + z) * z end,
  exponential = function(x, z, pos, b, percentPos, stepValue, o) return (stepValue + (2-stepValue)*percentPos^o.factor) * z + o.phase end,
  bridge = function(x, z, pos, b, percentPos, stepValue, o) return math.abs(x^2) * z end,
  gauss = function(x, z, pos, b, percentPos, stepValue, o) return (1 / (z+1) * math.sqrt(2*math.pi)) * gem.e^(-(x^2) / (2*z^2)) - 1 end,
  shakySine = function(x, z, pos, b, percentPos, stepValue)
    local f = 0
    local g = b.rand * percentPos
    if z < 0 then
      f = z - g
    elseif z > 0 then
      f = z + g
    end
    return math.sin(x * math.pi) * f
  end,
  testShape = function(x, z, pos, b, percentPos, stepValue, o)
    -- This is the formula for the standard normal distribution, which is a Gaussian curve with a mean of 0 and a standard deviation of 1. 
    -- Gaussian curve with a mean of 0 and a standard deviation of 1:
    -- (1 / σ√(2π)) * e^(-((x-μ)^2) / (2σ^2))
    -- Simplified: (1 / √(2π)) * e^(-(x^2) / 2)
    local mu = 0
    return (1 / (z+1) * math.sqrt(2*math.pi)) * gem.e^(-((x-mu)^2) / (2*z^2)) - 1
  end,
}

local shapeDefinitions = {
  {name = "Ramp Up", f = shapes.ramp, o = {z = 1}},
  {name = "Ramp Down", f = shapes.ramp, o = {z = -1}},
  {name = "Sine", f = shapes.sine},
  {name = "Triangle", f = shapes.triangleShaper},
  {name = "Triangle (Off Phs)", f = shapes.triangleShaper, o = {phase = -.5}},
  {name = "LoFi Triangle", f = shapes.lofiTriangle},
  {name = "Sqr/Tri", f = shapes.squareTri},
  {name = "Dome", f = shapes.dome, o = {phase = 0}},
  {name = "Dome Small", f = shapes.domeSmall, o = {phase = 1}},
  {name = "Saw", f = shapes.sawInPhase},
  {name = "HPF Saw", f = shapes.hpfSaw},
  {name = "Analog Saw", f = shapes.sawAnalog, o = {phase = 0}},
  {name = "Fltr Sqr",  f = shapes.filteredSquare},
  {name = "Organ-Ish", f = shapes.organIsh},
  {name = "Tangent", f = shapes.tangent},
  {name = "Acos", f = shapes.acos},
  {name = "Triple Sine", f = shapes.tripleSin},
  {name = "Harmonic Sync", f = shapes.harmonicSync},
  {name = "Soft Sine", f = shapes.softSine},
  {name = "Even", f = shapes.oddAndEven, o = {z = -1}},
  {name = "Odd", f = shapes.oddAndEven},
  {name = "Zero", f = shapes.zero},
  {name = "Min", f = shapes.minMax, o = {z = -1}},
  {name = "Max", f = shapes.minMax},
  {name = "Chaos To Sine", f = shapes.chaosToSine},
  {name = "Saw/Sin Reveal", f = shapes.sawSinReveal, o = {phase = -1}},
  {name = "PWM 50 to 100", f = shapes.pwm50to100},
  {name = "Triple-Sin Window", f = shapes.tripleSin, o = {z = 0}},
  {name = "Taffy", f = shapes.taffy, o = {z = 0}},
  {name = "Brassy", f = shapes.brassy, o = {z = 0}},
  {name = "HPF-Sqr To Sqr", f = shapes.hpfSqrToSqr, o = {z = .01}},
  {name = "Wacky", f = shapes.wacky, o = {z = .84}},
  {name = "Sine To Noise", f = shapes.sinToNoise},
  {name = "Sine Stretch", f = shapes.sineStrech, o = {z = .03}},
  {name = "SquareSaw Bit", f = shapes.squareSawBit},
  {name = "LoFi Triangles", f = shapes.loFiTriangles, o = {z = 0}},
  {name = "Talkative 1", f = shapes.talkative1},
  {name = "Sin Clipper", f = shapes.sinClipper, o = {z = 0}},
  {name = "Pitfall", f = shapes.pitfall, o = {z = .15}},
  {name = "Nasca Lines", f = shapes.nascaLines, o = {z = -.31}},
  {name = "Window-y SQR Sync", f = shapes.windowYSqr, o = {z = 0}},
  {name = "Kick", f = shapes.kick, o = {phase = 0, z = -.505}},
  {name = "Sin To Saw", f = shapes.sinToSaw, o = {z = 0}},
  {name = "Zero Crossing", f = shapes.zeroCrossing},
  {name = "VOSIM", f = shapes.vosim},
  {name = "VOSIM (Norm)", f = shapes.vosimNormalized},
  {name = "Crosser", f = shapes.crosser, o = {z = 0, factor = 4}},
  {name = "Mayhem Middle", f = shapes.mayhemInTheMiddle},
  {name = "Zero Dancer", f = shapes.zeroDancer},
  {name = "Wings", f = shapes.wings, o = {factor = .5}},
  {name = "Dirac Delta", f = shapes.diracDelta, o = {factor = .2, z = .02}},
  {name = "Dirac Delta (frexp)", f = shapes.diracDeltaFrexp, o = {z = .03}},
  {name = "Dirac Delta Rand", f = shapes.diracDeltaRand, o = {z = .06}},
  {name = "Swipe 1", f = shapes.swipe1},
  {name = "Swipe 2", f = shapes.swipe2},
  {name = "Swipe 3", f = shapes.swipe3},
  {name = "Swipe 4", f = shapes.swipe4, o = {z = -.25}},
  {name = "Shaky Sine", f = shapes.shakySine},
  {name = "Exponential", f = shapes.exponential, o = {factor = 4.5}},
  {name = "Bridge", f = shapes.bridge},
  {name = "Gauss", f = shapes.gauss, o = {z = .25}},
  {name = "Random", f = shapes.random},
  {name = "Test Shape", f = shapes.testShape},
}

local function getShapeIndexFromName(shapeName)
  for i,v in ipairs(shapeDefinitions) do
    if v.name == shapeName then
      return i
    end
  end
  return 1
end

local function getDefaultShapeOptions()
  return {
    z = 1,
    phase = -1,
    factor = 1,
    amount = 100,
  }
end

local function getShapeOptions(overrides)
  local defaultShapeOptions = getDefaultShapeOptions()
  if type(overrides) == "nil" then
    return defaultShapeOptions
  end
  return {
    z = gem.getValueOrDefault(overrides.z, defaultShapeOptions.z),
    phase = gem.getValueOrDefault(overrides.phase, defaultShapeOptions.phase),
    factor = gem.getValueOrDefault(overrides.factor, defaultShapeOptions.factor),
    amount = gem.getValueOrDefault(overrides.amount, defaultShapeOptions.amount),
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
    max = #shapeDefinitions
  end

  local items = {}

  for i,s in ipairs(shapeDefinitions) do
    table.insert(items, s.name)
    if i == max then
      break
    end
  end

  -- Add any options
  if type(options) == "table" then
    for _,o in ipairs(options) do
      table.insert(items, o)
    end
  end

  return items
end

local function getShapeBounds(shapeBounds)
  local bounds = {}
  if type(shapeBounds) == "nil" then
    shapeBounds = {}
  end
  bounds.min = gem.getValueOrDefault(shapeBounds.min, -1) -- x-azis max value
  bounds.max = gem.getValueOrDefault(shapeBounds.max, 1) -- x-azis min value
  bounds.length = gem.getValueOrDefault(shapeBounds.length, 128) -- y-axis steps
  bounds.unipolar = bounds.min >= 0 --  Whether the shape is unipolar
  bounds.rand = gem.getRandom() -- A random number that will be equal across all steps
  return bounds
end

local function createShape(shapeIndexOrName, shapeBounds, shapeOptions)
  if type(shapeIndexOrName) == "string" then
    shapeIndexOrName = getShapeIndexFromName(shapeIndexOrName)
  end
  local shape = {} -- Holds the values for each step
  local shapeDefinition = shapeDefinitions[shapeIndexOrName]
  local bounds = getShapeBounds(shapeBounds)
  local options = getShapeTemplate(shapeOptions, shapeDefinition.o)
  local stepValue = gem.getChangePerStep(2, bounds.length)
  for i=1,bounds.length do
    local pos = i - 1
    local value =  options.factor * stepValue * pos + options.phase
    local percentPos = pos / bounds.length
    local x = shapeDefinition.f(value, options.z, pos, bounds, percentPos, stepValue, options)
    if bounds.unipolar then
      x = getUnipolar(x)
    end
    x = (bounds.max * x) * (options.amount / 100)
    table.insert(shape, math.max(bounds.min, math.min(bounds.max, x)))
  end
  return shape, options
end

local function getAmountWidget(options, i)
  -- Widget for controlling shape amount
  if type(options) == "nil" then
    options = {}
  end
  if type(i) == "nil" then
    i = ""
  end
  options.name = gem.getValueOrDefault(options.name, "ShapeAmount" .. i)
  options.tooltip = gem.getValueOrDefault(options.tooltip, "Set the shape amount.")
  options.showLabel = gem.getValueOrDefault(options.showLabel, true)
  options.unit = gem.getValueOrDefault(options.unit, Unit.Percent)
  options.integer = gem.getValueOrDefault(options.integer, true)
  if type(options.width) ~= "nil" then
    options.width = options.width
  end
  return widgets.numBox("Shape Amount", getShapeOptions().amount, options)
end

local function getShapeWidgets(overrides, i)
  -- Widgets for controlling shape
  if type(i) == "nil" then
    i = ""
  end
  if type(overrides) == "nil" then
    overrides = {}
  end
  local shapeOptions = getShapeOptions()
  local factorOptions = {
    name = "ShapeFactor" .. i,
    tooltip = "Set the factor (multiplier) applied to the value of each step.",
    min = -8,
    max = 8,
  }
  local phaseOptions = {
    name = "ShapePhase" .. i,
    tooltip = "Set the phase applied to the shape (move left/right).",
  }
  local zOptions = {
    name = "ShapeMorph" .. i,
    tooltip = "Set the morph value. This value is mostly assigned to amplitude, but it depends on the shape.",
  }
  local options = {factor = factorOptions, phase = phaseOptions, z = zOptions}
  for _,v in pairs(options) do
    v.showLabel = gem.getValueOrDefault(overrides.showLabel, true)
    if type(overrides.width) ~= "nil" then
      v.width = overrides.width
    end
    if type(v.min) == "nil" then
      v.min = -1
    end
    if type(v.max) == "nil" then
      v.max = 1
    end
  end
  return {
    z = widgets.numBox("Shape Morph", shapeOptions.z, options.z),
    phase = widgets.numBox("Shape Phase", shapeOptions.phase, options.phase),
    factor = widgets.numBox("Shape Factor", shapeOptions.factor, options.factor),
  }
end

return {--shapes--
  getWidgets = getShapeWidgets,
  getAmountWidget = getAmountWidget,
  getShapeNames = getShapeNames,
  getShapeOptions = getShapeOptions,
  get = createShape,
}
