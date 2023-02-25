--------------------------------------------------------------------------------
-- Methods for working with shapes
--------------------------------------------------------------------------------

local gem = require "includes.common"

-- Keep in sync with function names
local shapeNames = {
  "Ramp Up",
  "Ramp Down",
  "Triangle",
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
  "Random",
  --"Test Shape",
}

local shapeFunctions = {
  "rampUp",
  "rampDown",
  "triangleShaper",
  "sineShaper",
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
  "evenOdd",
  "oddEven",
  "zeroAll",
  "minAll",
  "maxAll",
  "randomAll",
  --"testShape",
}

local defaultShapeOptions = {
  z = 1,
  stepRange = 2,
  phase = -1,
  factor = 1,
}

local function getValueOrDefault(value, default)
  if type(value) == "number" then
    return value
  end
  return default
end

local function getShapeOptions(overrides)
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

local shapeTemplates = {
  sine = getShapeOptions({
    phase = -0.5,
    factor = math.pi,
  }),
  triangleOffPhase = getShapeOptions({
    phase = -0.5,
  }),
  rampUp = getShapeOptions({
    stepRange = 1,
    phase = 0.5,
  }),
  rampDown = getShapeOptions({
    stepRange = 1,
    phase = -0.5,
  }),
  dome = getShapeOptions({
    phase = 0
  }),
  domeSmall = getShapeOptions({
    stepRange = 1
  }),
  sawAnalog = getShapeOptions({
      phase = 0
  }),
  even = getShapeOptions({
      z = -1
  }),
  zero = getShapeOptions({
      z = 0
  }),
  min = getShapeOptions({
      z = -1
  }),
  max = getShapeOptions({
      z = 1
  }),
}

local function randomAll(theTable, options)
  options = getShapeOptions(options)
  local values = {}
  for i=1,theTable.length do
    local value = gem.getRandom(theTable.min, theTable.max) * options.z * options.factor
    table.insert(values, value)
  end
  return values, options
end

local function oddEven(theTable, options)
  options = getShapeOptions(options)
  local values = {}
  local minValue = theTable.min
  local maxValue = theTable.max
  for i=1,theTable.length do
    local val = maxValue
    if i % 2 == 0 then
      val = minValue
    end
    table.insert(values, (val * options.z * options.factor))
  end
  return values, options
end

local function evenOdd(theTable, options)
  if type(options) == "nil" then
    options = shapeTemplates.even
  end
  return oddEven(theTable, options)
end

local function minMaxZero(theTable, options)
  options = getShapeOptions(options)
  local values = {}
  for i=1,theTable.length do
    table.insert(values, (theTable.max * options.z * options.factor))
  end
  return values, options
end

local function zeroAll(theTable, options)
  if type(options) == "nil" then
    options = shapeTemplates.zero
  end
  return minMaxZero(theTable, options)
end

local function minAll(theTable, options)
  if type(options) == "nil" then
    options = shapeTemplates.min
  end
  return minMaxZero(theTable, options)
end

local function maxAll(theTable, options)
  if type(options) == "nil" then
    options = shapeTemplates.max
  end
  return minMaxZero(theTable, options)
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

-- sign function: -1 if x<0; 1 if x>0
local function signA(x)
  if x < 0 then
    return -1
  end
  return 1
end

-- z = current table number, from -1.0 to 1.0
-- x = current time-value getting plotted, from -1.0 to 1.0 OR 0.0 to 1.0 (same as (x+1)/2) - depending on stepRange=1|2
local function createShape(shapeTable, shapeFunc, options)
  options = getShapeOptions(options)
  local minValue = shapeTable.min
  local maxValue = shapeTable.max
  local numSteps = shapeTable.length
  local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(options.stepRange, numSteps)
  local shape = {}
  print("Create shape, stepRange, phase, factor", options.stepRange, options.phase, options.factor)
  print("minValue, maxValue, numSteps, changePerStep", minValue, maxValue, numSteps, changePerStep)
  for i=1,numSteps do
    local x = options.factor * ((changePerStep * (i-1)) + options.phase)
    local z = options.z
    local value = shapeFunc(x, z)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value, x", i, value, x)
    table.insert(shape, value)
  end
  return shape, options
end

local function testShape(shapeTable, options)
  local shapeFunc = function(x, z)
    return x * z -- Unique
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function sineShaper(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.cos(x) * z -- Unique
  end
  -- Get from template
  if type(options) == "nil" then
    options = shapeTemplates.sine
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function sweetSine(shapeTable, options)
  local shapeFunc = function(x, z)
    return 0.5*(math.cos(x*math.pi/2)*((math.sin((x)*math.pi)+(1-z)*(math.sin(z*((x*x)^z)*math.pi*32))))) -- Unique
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function softSine(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.sin(x*math.pi*(2+(62*z*z*z)))*math.sin(x*math.pi) -- Unique
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function tripleSin(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x)) -- Unique
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function organIsh(shapeTable, options)
  local shapeFunc = function(x, z)
    return (math.sin(x*math.pi)+(0.16*(math.sin(2*x*math.pi)+math.sin(3*x*math.pi)+math.sin(4*x*math.pi)))) * z -- Unique
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function filteredSquare(shapeTable, options)
  local shapeFunc = function(x, z)
    return (1.2*math.sin(x*math.pi)+0.31*math.sin(x*math.pi*3)+0.11*math.sin(x*math.pi*5)+0.033*math.sin(x*math.pi*7)) * z -- Unique
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function hpfSaw(shapeTable, options)
  local shapeFunc = function(x, z)
    return (x-(0.635*math.sin(x*math.pi))) * z -- Unique
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function sawInPhase(shapeTable, options)
  local shapeFunc = function(x, z)
    return (signA(x)-x) * z -- Unique
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function squareTri(shapeTable, options)
  local shapeFunc = function(x, z)
    return (-1*(signA(x)*0.5)+(math.abs(x)-0.5)) * z -- Unique
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function lofiTriangle(shapeTable, options)
  local shapeFunc = function(x, z)
    return ((gem.round(16*math.abs(x))/8.0)-1) * z -- Unique
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function tangent(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.tan(x * math.pi) * z
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function dome(shapeTable, options)
  local shapeFunc = function(x, z)
    return (2 * (math.sin(x * 1.5705) - 0.5)) * z -- Unique
  end
  -- Get from template
  if type(options) == "nil" then
    options = shapeTemplates.dome
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function domeSmall(shapeTable, options)
  local shapeFunc = function(x, z)
    return (-1-1.275*math.sin(x*math.pi)) * z -- Unique
  end
  -- Get from template
  if type(options) == "nil" then
    options = shapeTemplates.domeSmall
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function sawAnalog(shapeTable, options)
  local shapeFunc = function(x, z)
    return (2.001 * (math.sin(x * 0.7905) - 0.5)) * z
  end
  -- Get from template
  if type(options) == "nil" then
    options = shapeTemplates.sawAnalog
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function triangleShaper(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.min(2+2*x, math.abs((x-0.5)*2)-1) * z -- Unique
  end
  return createShape(shapeTable, shapeFunc, options)
end

local function rampUp(shapeTable, options)
  -- Get from template
  if type(options) == "nil" then
    options = shapeTemplates.rampUp
  end
  return triangleShaper(shapeTable, options)
end

local function rampDown(shapeTable, options)
  -- Get from template
  if type(options) == "nil" then
    options = shapeTemplates.rampDown
  end
  return triangleShaper(shapeTable, options)
end

local function triangleInPhase(shapeTable, options)
  return triangleShaper(shapeTable, options)
end

local function triangleOffPhase(shapeTable, options)
  -- Get from template
  if type(options) == "nil" then
    options = shapeTemplates.triangleOffPhase
  end
  return triangleShaper(shapeTable, options)
end

return {--shapes--
  getShapeNames = getShapeNames,
  getShapeFunctions = getShapeFunctions,
  getShapeFunction = getShapeFunction,
  tangent = tangent,
  dome = dome,
  domeSmall = domeSmall,
  hpfSaw = hpfSaw,
  sawAnalog = sawAnalog,
  sawInPhase = sawInPhase,
  filteredSquare = filteredSquare,
  organIsh = organIsh,
  rampUp = rampUp,
  rampDown = rampDown,
  squareTri = squareTri,
  lofiTriangle = lofiTriangle,
  triangleInPhase = triangleInPhase,
  triangleOffPhase = triangleOffPhase,
  testShape = testShape,
  sweetSine = sweetSine,
  softSine = softSine,
  tripleSin = tripleSin,
  sineShaper = sineShaper,
  triangleShaper = triangleShaper,
  evenOdd = evenOdd,
  oddEven = oddEven,
  zeroAll = zeroAll,
  minAll = minAll,
  maxAll = maxAll,
  randomAll = randomAll,
}
