--------------------------------------------------------------------------------
-- Methods for working with shapes
--------------------------------------------------------------------------------

local gem = require "includes.common"

-- Keep in sync with function names
local shapeNames = {
  "Ramp Up",
  "Ramp Down",
  "Triangle 1",
  "Triangle 2",
  "Triangle 3",
  "LoFi Triangle",
  "Sqr/Tri",
  "Sine",
  "Cosine",
  "Sine Rev", 
  "Cosine Rev",
  "Double Sine",
  "Double Cosine",
  "Dome",
  "Dome Small",
  "Saw",
  "HPF Saw",
  "Analog Saw",
  "Double Saw",
  "Fltr Sqr", 
  "Organ-Ish",
  "Tangent",
  "Triple Sine",
  "Drop",
  "Soft Sine",
  "Sweet Sine",
  "Test Shape",
}

local shapeFunctions = {
  "rampUp",
  "rampDown",
  "triangleInPhase",
  "triangleOffPhase",
  "triangleOffPhaseReverse",
  "lofiTriangle",
  "squareTri", 
  "sine",
  "cosine",
  "sineRev", 
  "cosineRev",
  "doubleSine",
  "doubleCosine",
  "dome",
  "dome50",
  "sawInPhase",
  "hpfSaw",
  "sawAnalog",
  "doubleSaw",
  "filteredSquare", 
  "organIsh",
  "tangent",
  "tripleSin",
  "drop",
  "softSine",
  "sweetSine",
  "testShape",
}

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

-- sign function oposite: 1 if x<0; -1 if x>0
local function signB(x)
  if x < 0 then
    return 1
  end
  return -1
end


local function setShapeOptions(options, shapeOptions)
  if type(options) ~= "table" then
    options = {}
  end
  if type(shapeOptions.stepRange) == "number" then
    options.stepRange = shapeOptions.stepRange
  end
  if type(shapeOptions.xOffset) == "number" then
    options.xOffset = shapeOptions.xOffset
  end
  if type(shapeOptions.xMultiple) == "number" then
    options.xMultiple = shapeOptions.xMultiple
  end
  if type(shapeOptions.z) == "number" then
    options.z = shapeOptions.z
  end
  return options
end

-- z = current table number, from -1.0 to 1.0
-- w = x current time-value getting plotted, from 0.0 to 1.0 same as (x+1)/2
local function createShape(shapeTable, shapeFunc, options)
  if type(options) == "nil" then
    options = {}
  end
  if type(options.z) == "nil" then
    options.z = 0
  end
  if type(options.stepRange) == "nil" then
    options.stepRange = 2
  end
  if type(options.xOffset) == "nil" then
    options.xOffset = -1
  end
  if type(options.xMultiple) == "nil" then
    options.xMultiple = 1
  end
  local minValue = shapeTable.min
  local maxValue = shapeTable.max
  local numSteps = shapeTable.length
  local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(options.stepRange, numSteps)
  local shape = {}
  print("Create shape, stepRange, xOffset, xMultiple", options.stepRange, options.xOffset, options.xMultiple)
  print("minValue, maxValue, numSteps, changePerStep", minValue, maxValue, numSteps, changePerStep)
  for i=1,numSteps do
    local x = options.xMultiple * ((changePerStep * (i-1)) + options.xOffset)
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
  return shape
end

local function ramp(shapeTable, options, stepRange, xOffset)
  local shapeFunc = function(x, z)
    return math.min(2+2*x, math.abs((x-0.5)*2)-1)
  end
  --options = setShapeOptions(options, {stepRange = stepRange, xOffset = xOffset})
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(1, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) + f
    local value = math.min(2+2*x, math.abs((x-0.5)*2)-1)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

local function testShape(shapeTable, options)
  local shapeFunc = function(w, z)
    return math.sin(w*math.pi*(2+(62*z*z*z)))*math.sin(w*math.pi)
  end
  return createShape(shapeTable, shapeFunc, options)
end

-- 0.5*(cos(x*pi/2)*((sin((x)*pi)+(1-z)*(sin(z*((x*x)^z)*pi*32)))))
local function sweetSine(shapeTable, options)
  local shapeFunc = function(x, z)
    return 0.5*(math.cos(x*math.pi/2)*((math.sin((x)*math.pi)+(1-z)*(math.sin(z*((x*x)^z)*math.pi*32)))))
  end
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 0
    local x = (changePerStep * (i-1)) - 1
    local w = x
    local value = 0.5*(math.cos(x*math.pi/2)*((math.sin((x)*math.pi)+(1-z)*(math.sin(z*((x*x)^z)*math.pi*32)))))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

-- sin(w*pi*(2+(62*z*z*z)))*sin(w*pi)
local function softSine(shapeTable, options)
  local shapeFunc = function(w, z)
    return math.sin(w*math.pi*(2+(62*z*z*z)))*math.sin(w*math.pi)
  end
  options = setShapeOptions(options, {stepRange = 1})
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(1, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = -0
    local x = (changePerStep * (i-1)) - 1
    local w = x
    local value = math.sin(w*math.pi*(2+(62*z*z*z)))*math.sin(w*math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

-- sin(w*pi*(2+(62*z*z*z)))*sin(w*pi)
local function drop(shapeTable, options)
  local shapeFunc = function(w, z)
    return math.sin(w*math.pi*(2+(62*z*z*z)))*math.sin(w*math.pi)
  end
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 1
    local x = (changePerStep * (i-1)) - 1
    local w = x
    local value = math.sin(w*math.pi*(2+(62*z*z*z)))*math.sin(w*math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

-- cos(x*pi/2)*1.6*(.60*sin( ((z*16)+1)*3*x ) + .20*sin( ((z*16)+1)*9*x ) + .15*sin( ((z*16)+1)*15*x))
local function tripleSin(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x))
  end
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 0
    local x = (changePerStep * (i-1)) - 1
    local value = math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

-- organish sin(x*pi)+(0.16*(sin(2*x*pi)+sin(3*x*pi)+sin(4*x*pi)))
local function organIsh(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.sin(x*math.pi)+(0.16*(math.sin(2*x*math.pi)+math.sin(3*x*math.pi)+math.sin(4*x*math.pi)))
  end
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = math.sin(x*math.pi)+(0.16*(math.sin(2*x*math.pi)+math.sin(3*x*math.pi)+math.sin(4*x*math.pi)))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

-- filtered sqr 1.2*sin(x*pi)+0.31*sin(x*pi*3)+0.11*sin(x*pi*5)+0.033*sin(x*pi*7)
local function filteredSquare(shapeTable, options)
  local shapeFunc = function(x, z)
    return 1.2*math.sin(x*math.pi)+0.31*math.sin(x*math.pi*3)+0.11*math.sin(x*math.pi*5)+0.033*math.sin(x*math.pi*7)
  end
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = 1.2*math.sin(x*math.pi)+0.31*math.sin(x*math.pi*3)+0.11*math.sin(x*math.pi*5)+0.033*math.sin(x*math.pi*7)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

-- hpf saw x-(0.635*sin(x*pi))
local function hpfSaw(shapeTable, options)
  local shapeFunc = function(x, z)
    return x-(0.635*math.sin(x*math.pi))
  end
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = x-(0.635*math.sin(x*math.pi))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

-- sin(x*pi)
--[[ local function shape(shapeTable, mathFunc)
  local minValue = shapeTable.min
  local maxValue = shapeTable.max
  local numSteps = shapeTable.length
  local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1))
    local value = math[shapeFunc](x * math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  if shapeFunc == 'sin' or shapeFunc == 'tan' then
    shape[#shape] = shape[1]
  else
    shape[#shape] = maxValue
  end
  return shape
end ]]

--[[ local function shapeReverse(shapeTable, mathFunc)
  local minValue = shapeTable.min
  local maxValue = shapeTable.max
  local numSteps = shapeTable.length
  local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = math[shapeFunc](x * math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  if shapeFunc == 'sin' or shapeFunc == 'tan' then
    shape[#shape] = shape[1]
  else
    shape[#shape] = maxValue
  end
  return shape
end ]]

--[[ local function shapeDouble(shapeTable, mathFunc)
  local minValue = shapeTable.min
  local maxValue = shapeTable.max
  local numSteps = shapeTable.length
  local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = 2 * (changePerStep * (i-1))
    local value = math[shapeFunc](x * math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  if shapeFunc == 'sin' or shapeFunc == 'tan' then
    shape[#shape] = shape[1]
  else
    shape[#shape] = maxValue
  end
  return shape
end ]]

-- Saw in phase x < 0 ? -1-x : 1-x
local function sawInPhase(shapeTable, options)
  local shapeFunc = function(x, z)
    return signA(x)-x
  end
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = signA(x)-x
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

-- SquareTri -1*(sign(x)*0.5)+(abs(x)-0.5)
local function squareTri(shapeTable, options)
  local shapeFunc = function(x, z)
    return -1*(signA(x)*0.5)+(math.abs(x)-0.5)
  end
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = -1*(signA(x)*0.5)+(math.abs(x)-0.5)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

-- rint = round to nearest integer
--(rint(16*abs(x))/8.0)-1
local function lofiTriangle(shapeTable, options)
  local shapeFunc = function(x, z)
    return (gem.round(16*math.abs(x))/8.0)-1
  end
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = (gem.round(16*math.abs(x))/8.0)-1
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

local function doubleSaw(shapeTable, options)
  local shapeFunc = function(x, z)
    return x+signB(x)
  end
  options = setShapeOptions(options, {xMultiple = 2})
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = (x*2)+signB(x)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

local function dome50(shapeTable, options)
  local shapeFunc = function(x, z)
    return -1-1.275*math.sin(x*math.pi)
  end
  options = setShapeOptions(options, {stepRange = 1})
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(1, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = -1-1.275*math.sin(x*math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

local function sawAnalog(shapeTable, options)
  local shapeFunc = function(x, z)
    return 2.001 * (math.sin(x * 0.7905) - 0.5)
  end
  options = setShapeOptions(options, {xOffset = 0})
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1))
    local value = 2.001 * (math.sin(x * 0.7905) - 0.5)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

local function dome(shapeTable, options)
  local shapeFunc = function(x, z)
    return 2 * (math.sin(x * 1.5705) - 0.5)
  end
  options = setShapeOptions(options, {xOffset = 0})
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - .0
    local value = 2 * (math.sin(x * 1.5705) - 0.5)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

local function triangleInPhase(shapeTable, options)
  return ramp(shapeTable, options, 2, -1)
  --[[ local shapeFunc = function(x, z)
    return math.min(2+2*x, math.abs((x-0.5)*2)-1)
  end
  return createShape(shapeTable, shapeFunc, options) ]]
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = math.min(2+2*x, math.abs((x-0.5)*2)-1)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

local function triangleOffPhase(shapeTable, options)
  local shapeFunc = function(x, z)
    return math.abs(x*2)-1
  end
  return createShape(shapeTable, shapeFunc, options)
  --[[ local unipolar = minValue == 0
  local changePerStep = gem.getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = math.abs(x*2)-1
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape ]]
end

local function triangleOffPhaseReverse(shapeTable, options)
  local minValue = shapeTable.min
  local maxValue = shapeTable.max
  local numSteps = shapeTable.length
  local rising = true
  local numStepsUpDown = math.floor(numSteps / 2)
  local valueRange = maxValue - minValue
  local changePerStep = gem.getChangePerStep(valueRange, numStepsUpDown)
  local startValue = minValue
  local shape = {}
  for i=1,numSteps do
    table.insert(shape, startValue)
    if rising then
      startValue = startValue + changePerStep
      if startValue >= maxValue then
        rising = false
      end
    else
      startValue = startValue - changePerStep
    end
  end
  shape[#shape] = minValue
  return shape
end

local function rampUp(shapeTable, options)
  return ramp(shapeTable, options, 1, .5)
end

local function rampDown(shapeTable, options)
  return ramp(shapeTable, options, 1, -.5)
end

return {--shapes--
  getShapeNames = getShapeNames,
  getShapeFunctions = getShapeFunctions,
  getShapeFunction = getShapeFunction,
  sine = function(shapeTable, options)
    local shapeFunc = function(x, z)
      return math.sin(x * math.pi)
    end
    options = setShapeOptions(options, {xOffset = 0})
    return createShape(shapeTable, shapeFunc, options)
  end,
  cosine = function(shapeTable, options)
    local shapeFunc = function(x, z)
      return math.cos(x * math.pi)
    end
    options = setShapeOptions(options, {xOffset = 0})
    return createShape(shapeTable, shapeFunc, options)
  end,
  --cosine = function(theTable) return shape(theTable, 'cos') end,
  --sineRev = function(theTable) return shapeReverse(theTable, 'sin') end,
  --cosineRev = function(theTable) return shapeReverse(theTable, 'cos') end,
  sineRev = function(shapeTable, options)
    local shapeFunc = function(x, z)
      return math.sin(x * math.pi)
    end
    return createShape(shapeTable, shapeFunc, options)
  end,
  cosineRev = function(shapeTable, options)
    local shapeFunc = function(x, z)
      return math.cos(x * math.pi)
    end
    return createShape(shapeTable, shapeFunc, options)
  end,
  --doubleSine = function(theTable) return shapeDouble(theTable, 'sin') end,
  --doubleCosine = function(theTable) return shapeDouble(theTable, 'cos') end,
  --[[ doubleSine = function(shapeTable, options)
    local shapeFunc = function(x, z)
      return math.sin(x * math.pi)
    end
    options = setShapeOptions(options, {xOffset = 0, xMultiple = 2})
    return createShape(shapeTable, shapeFunc, options)
  end,
  doubleCosine = function(shapeTable, options)
    local shapeFunc = function(x, z)
      return math.cos(x * math.pi)
    end
    options = setShapeOptions(options, {xOffset = 0, xMultiple = 2})
    return createShape(shapeTable, shapeFunc, options)
  end, ]]
  --tangent = function(theTable) return shape(theTable, 'tan') end,
  tangent = function(shapeTable, options)
    local shapeFunc = function(x, z)
      return math.tan(x * math.pi)
    end
    --options = setShapeOptions(options, {xOffset = 0, xMultiple = 2})
    return createShape(shapeTable, shapeFunc, options)
  end,
  dome = dome,
  dome50 = dome50,
  hpfSaw = hpfSaw,
  sawAnalog = sawAnalog,
  sawInPhase = sawInPhase,
  doubleSaw = doubleSaw,
  filteredSquare = filteredSquare,
  organIsh = organIsh,
  rampUp = rampUp,
  rampDown = rampDown,
  squareTri = squareTri,
  triangle = triangleOffPhaseReverse,
  lofiTriangle = lofiTriangle,
  triangleInPhase = triangleInPhase,
  triangleOffPhase = triangleOffPhase,
  triangleOffPhaseReverse = triangleOffPhaseReverse,
  testShape = testShape,
  sweetSine = sweetSine,
  softSine = softSine,
  drop = drop,
  tripleSin = tripleSin,
}
