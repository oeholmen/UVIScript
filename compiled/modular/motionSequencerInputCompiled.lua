-- modular/motionSequencerInput -- 
--------------------------------------------------------------------------------
-- Common methods
--------------------------------------------------------------------------------

local function getRandom(min, max, factor)
  if type(min) == "number" and type(max) == "number" and min < max then
    return math.random(min, max)
  elseif type(min) == "number" then
    return math.random(min)
  end
  local value = math.random()
  if type(factor) == "number" then
    value = value * factor
  end
  return value
end

local function getRandomBoolean(probability)
  -- Default probability of getting true is 50%
  if type(probability) ~= "number" then
    probability = 50
  end
  return getRandom(100) <= probability
end

local function getChangeMax(max, probabilityLevel)
  return math.ceil(max * (probabilityLevel / 100))
end

local function getIndexFromValue(value, selection)
  for i,v in ipairs(selection) do
    if v == value then
      return i
    end
  end
  return nil
end

local function randomizeValue(value, limitMin, limitMax, randomizationAmount)
  if randomizationAmount > 0 then
    local limitRange = limitMax - limitMin
    local changeMax = getChangeMax(limitRange, randomizationAmount)
    local min = math.max(limitMin, (value - changeMax))
    local max = math.min(limitMax, (value + changeMax))
    --print("Before randomize value", value)
    value = getRandom(min, max)
    --print("After randomize value/changeMax/min/max", value, changeMax, min, max)
  end
  return value
end

local function round(value)
  local int, frac = math.modf(value)
  --print("int/frac", int, frac)
  if math.abs(frac) < 0.5 then
    value = int
  elseif value < 0 then
    value = int - 1
  else
    value = int + 1
  end
  return value
end

local function tableIncludes(theTable, theItem)
  return type(getIndexFromValue(theItem, theTable)) == "number"
end

local function getRandomFromTable(theTable, except)
  if #theTable == 0 then
    return nil
  end
  if #theTable == 1 then
    return theTable[1]
  end
  local index = getRandom(#theTable)
  local value = theTable[index]
  --print("getRandomFromTable index, value", index, value)
  if type(except) ~= "nil" then
    local maxRounds = 10
    while value == except and maxRounds > 0 do
      value = theTable[getRandom(#theTable)]
      maxRounds = maxRounds - 1
      --print("getRandomFromTable except, maxRounds", except, maxRounds)
    end
  end
  return value
end

local function trimStartAndEnd(s)
  return s:match("^%s*(.-)%s*$")
end

local function getChangePerStep(valueRange, numSteps)
  return valueRange / (numSteps - 1)
end

local function inc(val, inc, resetAt, resetTo)
  if type(inc) ~= "number" then
    inc = 1
  end
  if type(resetTo) ~= "number" then
    resetTo = 1
  end
  val = val + inc
  if type(resetAt) == "number" then
    if (inc > 0 and val > resetAt) or (inc < 0 and val < resetAt) then
      val = resetTo
    end
  end
  return val
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

-- z = current table number, from -1.0 to 1.0
-- w = x current time-value getting plotted, from 0.0 to 1.0 same as (x+1)/2
-- When a 'q' is preset in the formula, the function plots to the FFT bins instead of plotting the to the waveform display. q iterates from 1 to 512 for the respective harmonics/bins. **
local function testShape(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 0
    local q = 1
    local x = (changePerStep * (i-1)) - 1
    local w = x
    local value = x
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- 0.5*(cos(x*pi/2)*((sin((x)*pi)+(1-z)*(sin(z*((x*x)^z)*pi*32)))))
local function sweetSine(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 0
    local q = 1
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
  return shape
end

-- sin(w*pi*(2+(62*z*z*z)))*sin(w*pi)
local function softSine(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(1, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = -0
    local q = 1
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
  return shape
end

-- sin(w*pi*(2+(62*z*z*z)))*sin(w*pi)
local function drop(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 1
    local q = 1
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
  return shape
end

-- cos(x*pi/2)*1.6*(.60*sin( ((z*16)+1)*3*x ) + .20*sin( ((z*16)+1)*9*x ) + .15*sin( ((z*16)+1)*15*x))
local function tripleSin(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
  return shape
end

-- organish sin(x*pi)+(0.16*(sin(2*x*pi)+sin(3*x*pi)+sin(4*x*pi)))
local function organIsh(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
  return shape
end

-- filtered sqr 1.2*sin(x*pi)+0.31*sin(x*pi*3)+0.11*sin(x*pi*5)+0.033*sin(x*pi*7)
local function filteredSquare(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
  return shape
end

-- hpf saw x-(0.635*sin(x*pi))
local function hpfSaw(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
  return shape
end

-- sin(x*pi)
local function shape(minValue, maxValue, numSteps, shapeFunc)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
end

local function shapeReverse(minValue, maxValue, numSteps, shapeFunc)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
end

local function shapeDouble(minValue, maxValue, numSteps, shapeFunc)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
end

-- Saw in phase x < 0 ? -1-x : 1-x
local function sawInPhase(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
  return shape
end

-- SquareTri -1*(sign(x)*0.5)+(abs(x)-0.5)
local function squareTri(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
  return shape
end

-- rint = round to nearest integer
--(rint(16*abs(x))/8.0)-1
local function lofiTriangle(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = (round(16*math.abs(x))/8.0)-1
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function doubleSaw(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
  return shape
end

local function dome50(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(1, numSteps)
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
  return shape
end

local function sawAnalog(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
  return shape
end

local function dome(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
  return shape
end

local function triangleInPhase(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
  return shape
end

local function triangleOffPhase(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
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
  return shape
end

local function triangleOffPhaseReverse(minValue, maxValue, numSteps)
  local rising = true
  local numStepsUpDown = math.floor(numSteps / 2)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numStepsUpDown)
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

local function ramp(minValue, maxValue, numSteps, f)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(1, numSteps)
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
  return shape
end

local function rampUp(minValue, maxValue, numSteps)
  return ramp(minValue, maxValue, numSteps, .5)
end

local function rampDown(minValue, maxValue, numSteps)
  return ramp(minValue, maxValue, numSteps, -.5)
end

local gem = {
  inc = inc,
  round = round,
  shape = shape,
  shapeReverse = shapeReverse,
  shapeDouble = shapeDouble,
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
  getRandom = getRandom,
  getChangeMax = getChangeMax,
  tableIncludes = tableIncludes,
  randomizeValue = randomizeValue,
  trimStartAndEnd = trimStartAndEnd,
  getRandomBoolean = getRandomBoolean,
  getIndexFromValue = getIndexFromValue,
  getRandomFromTable = getRandomFromTable,
}

--------------------------------------------------------------------------------
-- Functions for creating an positioning widgets
--------------------------------------------------------------------------------

local panelNameIndex = 1
local widgetNameIndex = 1
local currentX = 0
local currentY = 0

local widgetDefaults = {
  panel = Panel("DefaultPanel"),
  width = 120,
  height = 20,
  menuHeight = 45,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
  col = 0,
  row = 0,
  cols = 6
}

local widgetColours = {
  backgroundColour = "202020",
  widgetBackgroundColour = "01011F", -- Dark
  menuBackgroundColour = "01011F", -- widgetBackgroundColour
  widgetTextColour = "9f02ACFE", -- Light
  tableBackgroundColour = "191E25",
  sliderColour = "5FB5FF", -- Table slider colour
  labelTextColour = "black", -- Light
  labelBackgroundColour = "CFFFFE",
  menuArrowColour = "66AEFEFF", -- labelTextColour
  menuOutlineColour = "5f9f02ACFE", -- widgetTextColour
  menuTextColour = "9f02ACFE",
  backgroundColourOff = "ff084486",
  backgroundColourOn = "ff02ACFE",
  textColourOff = "ff22FFFF",
  textColourOn = "efFFFFFF",
}

local function getValueOrDefault(value, default)
  if type(value) == "nil" then
    return default
  end
  return value
end

local function setColours(colours)
  widgetColours.backgroundColour = getValueOrDefault(colours.backgroundColour, widgetColours.backgroundColour)
  widgetColours.widgetBackgroundColour = getValueOrDefault(colours.widgetBackgroundColour, widgetColours.widgetBackgroundColour)
  widgetColours.menuBackgroundColour = getValueOrDefault(colours.menuBackgroundColour, widgetColours.menuBackgroundColour)
  widgetColours.widgetTextColour = getValueOrDefault(colours.widgetTextColour, widgetColours.widgetTextColour)
  widgetColours.tableBackgroundColour = getValueOrDefault(colours.tableBackgroundColour, widgetColours.tableBackgroundColour)
  widgetColours.sliderColour = getValueOrDefault(colours.sliderColour, widgetColours.sliderColour)
  widgetColours.labelTextColour = getValueOrDefault(colours.labelTextColour, widgetColours.labelTextColour)
  widgetColours.labelBackgroundColour = getValueOrDefault(colours.labelBackgroundColour, widgetColours.labelBackgroundColour)
  widgetColours.menuArrowColour = getValueOrDefault(colours.menuArrowColour, widgetColours.menuArrowColour)
  widgetColours.menuOutlineColour = getValueOrDefault(colours.menuOutlineColour, widgetColours.menuOutlineColour)
  widgetColours.menuTextColour = getValueOrDefault(colours.menuTextColour, widgetColours.menuTextColour)
  widgetColours.backgroundColourOff = getValueOrDefault(colours.backgroundColourOff, widgetColours.backgroundColourOff)
  widgetColours.backgroundColourOn = getValueOrDefault(colours.backgroundColourOn, widgetColours.backgroundColourOn)
  widgetColours.textColourOff = getValueOrDefault(colours.textColourOff, widgetColours.textColourOff)
  widgetColours.textColourOn = getValueOrDefault(colours.textColourOn, widgetColours.textColourOn)
end

local function setSection(settings)
  if type(settings) ~= "table" then
    settings = {}
  end
  widgetDefaults.width = getValueOrDefault(settings.width, widgetDefaults.width)
  widgetDefaults.height = getValueOrDefault(settings.height, widgetDefaults.height)
  widgetDefaults.menuHeight = getValueOrDefault(settings.menuHeight, widgetDefaults.menuHeight)
  widgetDefaults.xOffset = getValueOrDefault(settings.xOffset, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getValueOrDefault(settings.yOffset, widgetDefaults.yOffset)
  widgetDefaults.xOffset = getValueOrDefault(settings.x, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getValueOrDefault(settings.y, widgetDefaults.yOffset)
  widgetDefaults.xSpacing = getValueOrDefault(settings.xSpacing, widgetDefaults.xSpacing)
  widgetDefaults.ySpacing = getValueOrDefault(settings.ySpacing, widgetDefaults.ySpacing)
  widgetDefaults.cols = getValueOrDefault(settings.cols, widgetDefaults.cols)
  widgetDefaults.col = getValueOrDefault(settings.col, 0)
  widgetDefaults.row = getValueOrDefault(settings.row, 0)
  setColours(settings)
  currentX = widgetDefaults.xOffset
  currentY = widgetDefaults.yOffset
end

local function getWidgetName(name, displayName, useDisplayNameAsWidgetName, panel)
  if panel then
    name = getValueOrDefault(name, "Panel" .. panelNameIndex)
    panelNameIndex = panelNameIndex + 1
  elseif type(name) == "nil" then
    name = ""
    if useDisplayNameAsWidgetName and type(displayName) == "string" then
      name = string.gsub(displayName, "[^a-zA-Z]+", "")
    end
    if string.len(name) == 0 then
      name = "Widget" .. widgetNameIndex
      widgetNameIndex = widgetNameIndex + 1
    end
  end
  print("Widget name", name)
  return name
end

local function incrementRow(row, h)
  if type(row) == "nil" then
    row = 1
  end
  if type(h) == "nil" then
    h = widgetDefaults.height
  end
  widgetDefaults.row = widgetDefaults.row + row
  widgetDefaults.col = 0
  currentX = widgetDefaults.xOffset

  local height = math.max(1, row) * h
  local ySpacing = math.max(1, row) * widgetDefaults.ySpacing
  currentY = currentY + height + ySpacing
end

local function incrementCol(col, w, h)
  if type(col) == "nil" then
    col = 1
  end
  if type(w) == "nil" then
    w = widgetDefaults.width
  end

  local width = math.max(1, col) * w
  local xSpacing = math.max(1, col) * widgetDefaults.xSpacing
  currentX = currentX + width + xSpacing

  widgetDefaults.col = widgetDefaults.col + col
  if widgetDefaults.col >= widgetDefaults.cols then
    incrementRow(1, h)
  end
end

local function getWidgetBounds(options, increment)
  local x = getValueOrDefault(options.x, currentX)
  local y = getValueOrDefault(options.y, currentY)
  local w = getValueOrDefault(options.width, widgetDefaults.width)
  local h = getValueOrDefault(options.height, widgetDefaults.height)

  if type(options.y) == "number" then
    print("options.y, y", options.y, y)
  end

  if type(options.x) == "number" then
    print("options.x, x", options.x, x)
  end

  -- Increment position
  if increment then
    if type(options.increment) == "boolean" then
      if options.increment then
        options.increment = 1
      else
        options.increment = 0
      end
    end
    local i = getValueOrDefault(options.increment, 1)
    incrementCol(i, w, h)
  end

  return {x, y, w, h}
end

local function getWidgetOptions(options, displayName, default, panel)
  if type(options) ~= "table" then
    options = {}
  end
  options.default = getValueOrDefault(default, options.default)
  options.name = getWidgetName(options.name, displayName, type(default) ~= "nil", panel)
  options.displayName = getValueOrDefault(displayName, options.name)
  options.tooltip = getValueOrDefault(options.tooltip, options.displayName)
  options.integer = getValueOrDefault(options.integer, (options.unit == Unit.Percent or options.unit == Unit.MidiKey))
  options.min = getValueOrDefault(options.min, 0)
  options.default = getValueOrDefault(options.default, options.min)
  if options.unit == Unit.MidiKey then
    options.max = getValueOrDefault(options.max, 127)
  elseif options.unit == Unit.Percent then
    options.max = getValueOrDefault(options.max, 100)
  else
    options.max = getValueOrDefault(options.max, 1)
  end
  return options
end

local function setOptional(widget, options)
  if type(options.changed) == "function" then
    widget.changed = options.changed
  end
  if type(options.alpha) == "number" then
    widget.alpha = options.alpha
  end
  if type(options.fontSize) == "number" then
    widget.fontSize = options.fontSize
  end
  if type(options.unit) == "number" then
    widget.unit = options.unit
  end
  if type(options.showLabel) == "boolean" then
    widget.showLabel = options.showLabel
  end
  if type(options.persistent) == "boolean" then
    widget.persistent = options.persistent
  end
  if type(options.enabled) == "boolean" then
    widget.enabled = options.enabled
  end
  if type(options.showPopupDisplay) == "boolean" then
    widget.showPopupDisplay = options.showPopupDisplay
  end
  if type(options.editable) == "boolean" then
    widget.editable = options.editable
  end
  if type(options.visible) == "boolean" then
    widget.visible = options.visible
  end
  if type(options.backgroundColour) == "string" then
    widget.backgroundColour = options.backgroundColour
  end
  if type(options.fillStyle) == "string" then
    widget.fillStyle = options.fillStyle
  end
  if type(options.sliderColour) == "string" then
    widget.sliderColour = options.sliderColour
  end
  if type(options.backgroundColourWhenEditing) == "string" then
    widget.backgroundColourWhenEditing = options.backgroundColourWhenEditing
  end
  if type(options.textColourWhenEditing) == "string" then
    widget.textColourWhenEditing = options.textColourWhenEditing
  end
  if type(options.textColour) == "string" then
    widget.textColour = options.textColour
  end
  if type(options.backgroundColourOff) == "string" then
    widget.backgroundColourOff = options.backgroundColourOff
  end
  if type(options.backgroundColourOn) == "string" then
    widget.backgroundColourOn = options.backgroundColourOn
  end
  if type(options.textColourOff) == "string" then
    widget.textColourOff = options.textColourOff
  end
  if type(options.textColourOn) == "string" then
    widget.textColourOn = options.textColourOn
  end
end

local widgets = {
  setColours = setColours,
  setSection = setSection,
  channels = function()
    local channels = {"Omni"}
    for j=1,16 do
      table.insert(channels, "" .. j)
    end
    return channels
  end,
  getColours = function() return widgetColours end,
  getPanel = function(options) return widgetDefaults.panel end,
  xOffset = function(val) widgetDefaults.xOffset = val end,
  yOffset = function(val) widgetDefaults.yOffset = val end,
  xSpacing = function(val) widgetDefaults.xSpacing = val end,
  ySpacing = function(val) widgetDefaults.ySpacing = val end,
  posSide = function(widget) return widget.x + widget.width + widgetDefaults.xSpacing end,
  posUnder = function(widget) return widget.y + widget.height + widgetDefaults.ySpacing end,
  width = function(val) widgetDefaults.width = val end,
  height = function(val) widgetDefaults.height = val end,
  col = function(i) incrementCol(i) end,
  row = function(i) incrementRow(i) end,
  panel = function(options)
    -- The first time, we use the default panel
    local create = panelNameIndex > 1
    if create == false then
      options.name = widgetDefaults.panel.name
    end
    options = getWidgetOptions(options, nil, nil, true)
    if create then
      widgetDefaults.panel = Panel(options.name)
      --print("Created panel", options.name)
    end
    widgetDefaults.panel.backgroundColour = widgetColours.backgroundColour
    widgetDefaults.panel.bounds = getWidgetBounds(options, false)
    setOptional(widgetDefaults.panel, options)
    return widgetDefaults.panel
  end,
  button = function(displayName, default, options)
    local isOnOff = true
    if type(default) == "table" then
      options = default
      default = nil
      isOnOff = false
    end
    options = getWidgetOptions(options, displayName, default)
    local widget
    if isOnOff then
      widget = widgetDefaults.panel:OnOffButton(options.name, (options.default == true))
    else
      widget = widgetDefaults.panel:Button(options.name)
    end
    widget.backgroundColourOff = widgetColours.backgroundColourOff
    widget.backgroundColourOn = widgetColours.backgroundColourOn
    widget.textColourOff = widgetColours.textColourOff
    widget.textColourOn = widgetColours.textColourOn
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  label = function(displayName, options)
    options = getWidgetOptions(options, displayName)
    local widget = widgetDefaults.panel:Label("Label")
    widget.text = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.labelBackgroundColour
    widget.textColour = widgetColours.labelTextColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  menu = function(displayName, default, items, options)
    if type(default) == "table" then
      options = items
      items = default
      default = 1
    end
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:Menu(options.name, items)
    widget.selected = options.default
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.menuBackgroundColour
    widget.textColour = widgetColours.menuTextColour
    widget.arrowColour = widgetColours.menuArrowColour
    widget.outlineColour = widgetColours.menuOutlineColour
    setOptional(widget, options)
    if widget.showLabel == true then
      options.height = getValueOrDefault(options.height, widgetDefaults.menuHeight)
    end
    widget.bounds = getWidgetBounds(options, true)
    return widget
  end,
  numBox = function(displayName, default, options)
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:NumBox(options.name, options.default, options.min, options.max, options.integer)
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.widgetBackgroundColour
    widget.textColour = widgetColours.widgetTextColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  table = function(displayName, default, size, options)
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:Table(options.name, size, options.default, options.min, options.max, options.integer)
    widget.fillStyle = "solid"
    widget.backgroundColour = widgetColours.tableBackgroundColour
    widget.sliderColour = widgetColours.sliderColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
}

--------------------------------------------------------------------------------
-- Common functions for working with event processor that act as modular inputs
--------------------------------------------------------------------------------

local activeVoices = {}

local function isNoteInActiveVoices(note)
  for _,v in ipairs(activeVoices) do
    if v.note == note then
      return true
    end
  end
  return false
end

local function isTrigger(e, channel)
  local isListeningForEvent = channel == 0 or channel == e.channel
  local isTrigger = e.note == 0 -- Note 0 is used as trigger
  return isTrigger and isListeningForEvent
end

local function handleTrigger(e, note, data)
  if type(note) == "number" and isNoteInActiveVoices(note) == false then
    local id = playNote(note, e.velocity, -1, nil, e.channel)
    table.insert(activeVoices, {id=id,note=note,channel=e.channel,data=data})
    return true
  end
  return false
end

local function handleReleaseTrigger(e)
  for i,v in ipairs(activeVoices) do
    if v.channel == e.channel then
      releaseVoice(v.id)
      table.remove(activeVoices, i)
      return true
    end
  end
  return false
end

local modular = {
  releaseVoices = function()
    for i,v in ipairs(activeVoices) do
      releaseVoice(v.id)
    end
    activeVoices = {}
  end,
  isTrigger = isTrigger,
  handleTrigger = handleTrigger,
  handleReleaseTrigger = handleReleaseTrigger,
  getNumVoices = function() return #activeVoices end,
  getActiveVoices = function() return activeVoices end,
}

--------------------------------------------------------------------------------
-- Common Scales
--------------------------------------------------------------------------------

-- Make sure these are in sync with the scale names
-- Scales are defined by distance to the next step
local scaleDefinitions = {
  {2,2,1,2,2,2,1}, -- Major (Ionian mode)
  {2,1,2,2,1,2,2}, -- Minor (Aeolian mode)
  {2,1,2,2,2,1,2}, -- Dorian mode
  {1,2,2,2,1,2,2}, -- Phrygian mode
  {2,2,2,1,2,2,1}, -- Lydian mode
  {2,2,1,2,2,1,2}, -- Mixolydian mode
  {1,2,2,1,2,2,2}, -- Locrian mode
  {2,2,2,1,2,1,2}, -- Acoustic
  {2,1,2,1,1,3,2}, -- Blues
  {1,2,1,3,1,2,2}, -- Alterated
  {2,2,3,2,3}, -- Major Pentatonic
  {3,2,2,3,2}, -- Minor Pentatonic
  {3}, -- Diminished
  {2}, -- Whole tone scale
  {1}, -- Chomatic
}

local scaleNames = {
  "Major (Ionian)",
  "Minor (Aeolian)",
  "Dorian",
  "Phrygian",
  "Lydian",
  "Mixolydian",
  "Locrian",
  "Acoustic",
  "Blues",
  "Alterated",
  "Major Pentatonic",
  "Minor Pentatonic",
  "Diminished",
  "Whole tone",
  "Chomatic",
}

local scales = {
  getScaleDefinitions = function()
    return scaleDefinitions
  end,

  getScaleNames = function()
    return scaleNames
  end,

  createScale = function(scaleDefinition, rootNote, maxNote)
    if type(maxNote) ~= "number" then
      maxNote = 127
    end
    rootNote = math.max(0, rootNote)
    maxNote = math.min(127, maxNote)
    local scale = {}
    -- Find notes for scale
    local pos = 1
    while rootNote <= maxNote do
      table.insert(scale, rootNote)
      rootNote = rootNote + scaleDefinition[pos]
      pos = pos + 1
      if pos > #scaleDefinition then
        pos = 1
      end
    end
    return scale
  end
}

--------------------------------------------------------------------------------
-- Common functions for processors using table motion
--------------------------------------------------------------------------------

local directionStartModes = {"Up", "Down", "Even Up", "Even Down", "Odd Up", "Odd Down", "Random"}
local speedTypes = {"Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Random"}
local startModes = {
  "Ramp Up", "Ramp Down", "Triangle 1", "Triangle 2", "Triangle 3", "LoFi Triangle", "Sqr/Tri", "Sine", "Cosine", "Sine Rev", 
  "Cosine Rev", "Double Sine", "Double Cosine", "Dome", "Dome (50%)", "Saw", "HPF Saw", "Analog Saw", "Double Saw", "Fltr Sqr", 
  "Organ-Ish", "Tangent", "Even", "Odd", "Zero", "Min", "Max",
  "tripleSin", "drop", "softSine", "sweetSine", "testShape",
  "Keep State", "Random",
}

local motionOptions = {
  factor = 2,
  factorMin = 0,
  factorMax = 8,
  moveSpeed = 25,
  moveSpeedMin = 5,
  moveSpeedMax = 500,
  speedType = speedTypes[1],
  startMode = startModes[1],
  directionStartMode = directionStartModes[1],
  speedRandomizationAmount = 0,
  tableLength = 32,
}

local function getStartDirection(i)
  local direction = 1
  if motionOptions.directionStartMode == "Down" then
    direction = -1
  elseif motionOptions.directionStartMode == "Even Up" then
    if i % 2 == 0 then
      direction = 1
    else
      direction = -1
    end
  elseif motionOptions.directionStartMode == "Even Down" then
    if i % 2 == 0 then
      direction = -1
    else
      direction = 1
    end
  elseif motionOptions.directionStartMode == "Odd Up" then
    if i % 2 == 0 then
      direction = -1
    else
      direction = 1
    end
  elseif motionOptions.directionStartMode == "Odd Down" then
    if i % 2 == 0 then
      direction = 1
    else
      direction = -1
    end
  elseif motionOptions.directionStartMode == "Random" then
    if gem.getRandomBoolean() then
      direction = 1
    else
      direction = -1
    end
  end
  return direction
end

local function setTableZero(theTable)
    for i=1,theTable.length do
      theTable:setValue(i, 0)
    end  
end

local function setStartMode(theTable)
  -- Reset table according to start mode
  local values = {}
  if motionOptions.startMode == "Keep State" then
    return
  elseif motionOptions.startMode == "Ramp Up" then
    values = gem.rampUp(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Ramp Down" then
    values = gem.rampDown(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Triangle 1" then
    values = gem.triangleInPhase(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Triangle 2" then
    values = gem.triangleOffPhase(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Triangle 3" then
    values = gem.triangleOffPhaseReverse(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "LoFi Triangle" then
    values = gem.lofiTriangle(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Sqr/Tri" then
    values = gem.squareTri(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Fltr Sqr" then
    values = gem.filteredSquare(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Organ-Ish" then
    values = gem.organIsh(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Sine" then
    values = gem.shape(theTable.min, theTable.max, theTable.length, 'sin')
  elseif motionOptions.startMode == "Cosine" then
    values = gem.shape(theTable.min, theTable.max, theTable.length, 'cos')
  elseif motionOptions.startMode == "Sine Rev" then
    values = gem.shapeReverse(theTable.min, theTable.max, theTable.length, 'sin')
  elseif motionOptions.startMode == "Cosine Rev" then
    values = gem.shapeReverse(theTable.min, theTable.max, theTable.length, 'cos')
  elseif motionOptions.startMode == "Double Sine" then
    values = gem.shapeDouble(theTable.min, theTable.max, theTable.length, 'sin')
  elseif motionOptions.startMode == "Double Cosine" then
    values = gem.shapeDouble(theTable.min, theTable.max, theTable.length, 'cos')
  elseif motionOptions.startMode == "Dome" then
    values = gem.dome(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Dome (50%)" then
    values = gem.dome50(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Analog Saw" then
    values = gem.sawAnalog(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Saw" then
    values = gem.sawInPhase(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "HPF Saw" then
    values = gem.hpfSaw(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Double Saw" then
    values = gem.doubleSaw(theTable.min, theTable.max, theTable.length)
  elseif motionOptions.startMode == "Tangent" then
    values = gem.shape(theTable.min, theTable.max, theTable.length, 'tan')
  elseif motionOptions.startMode == "Random" then
    for i=1,theTable.length do
      table.insert(values, gem.getRandom(theTable.min, theTable.max))
    end
  elseif motionOptions.startMode == "Min" then
    for i=1,theTable.length do
      table.insert(values, theTable.min)
    end
  elseif motionOptions.startMode == "Max" then
    for i=1,theTable.length do
      table.insert(values, theTable.max)
    end
  elseif motionOptions.startMode == "Even" then
    local minValue = theTable.min
    local maxValue = theTable.max
    for i=1,theTable.length do
      local val = minValue
      if i % 2 == 0 then
        val = maxValue
      end
      table.insert(values, val)
    end
  elseif motionOptions.startMode == "Odd" then
    local minValue = theTable.min
    local maxValue = theTable.max
    for i=1,theTable.length do
      local val = maxValue
      if i % 2 == 0 then
        val = minValue
      end
      table.insert(values, val)
    end
  elseif motionOptions.startMode == "Zero" then
    setTableZero(theTable)
    return
  else
    values = gem[motionOptions.startMode](theTable.min, theTable.max, theTable.length)
  end
  for i,v in ipairs(values) do
    theTable:setValue(i, math.floor(v))
  end
end

local function moveTable(theTable, i, value, direction)
  local middle = math.floor(theTable.length / 2)
  -- Increment value
  local amount = i - 1
  if (i > middle and motionOptions.speedType == "Triangle") or motionOptions.speedType == "Ramp Down" then
    amount = theTable.length - i
  elseif motionOptions.speedType == "Random" then
    amount = gem.getRandom(theTable.length) - 1
  elseif (motionOptions.speedType == "Even" and i % 2 == 0) or (motionOptions.speedType == "Odd" and i % 2 > 0) then
    amount = 0
  elseif motionOptions.speedType == "Even" and i == 1 then
    amount = i
  end
  local min = theTable.min
  local max = theTable.max
  local duration = gem.randomizeValue(motionOptions.moveSpeed, motionOptions.moveSpeedMin, motionOptions.moveSpeedMax, motionOptions.speedRandomizationAmount) + (amount * motionOptions.factor) -- TODO Param for operator?
  theTable:setValue(i, value)
  value = gem.inc(value, direction)
  if value < min then
    if true or gem.getRandomBoolean() then
      value = min
      direction = 1
      --print("Change direction", direction)
    else
      value = max
    end
    --print("Reset value", value)
  elseif value > max then
    if true or gem.getRandomBoolean() then
      value = max
      direction = -1
      --print("Change direction", direction)
    else
      value = min
    end
    --print("Reset value", value)
  end
  local valueBeforeWait = theTable:getValue(i)
  wait(duration)
  -- If value has been manually changed during the wait, we continue from that value
  if valueBeforeWait ~= theTable:getValue(i) then
    value = theTable:getValue(i)
  end
  return value, direction
end

local tableMotion = {
  setRange = function(theTable, tableRange, bipolar)
    if bipolar then
      theTable:setRange(-tableRange, tableRange)
    else
      theTable:setRange(0, tableRange)
    end
  end,
  getStartDirection = getStartDirection,
  moveTable = moveTable,
  setStartMode = setStartMode,
  setTableZero = setTableZero,
  directionStartModes = directionStartModes,
  speedTypes = speedTypes,
  startModes = startModes,
  options = motionOptions
}

----------------------------------------------------------------------------------
-- Motion Sequencer - Listens for incoming note events (rythm) on note number 0
----------------------------------------------------------------------------------

local backgroundColour = "606060"
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local sequencerResolution = 0.25 -- Fallback value
local baseNote = 60 -- Option
local octaveRange = 2 -- Option
local bipolar = true -- Option
local pitchOffsetPos = 1
local positionTable
local motionTable
local scalesNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinitionIndex = #scalesNames
local activeScale = {} -- Holds the active scale
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local movingCells = {}
local forward = false
local channel = 0

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetPitches()
  pitchOffsetPos = 1
  tableMotion.setTableZero(positionTable)
  tableMotion.setStartMode(motionTable, startMode)
end

local function setScale()
  local scaleDefinition = scaleDefinitions[scaleDefinitionIndex]
  local oneOctScale = scales.createScale(scaleDefinition, 0, 11)
  --print("#oneOctScale", #oneOctScale)
  -- Check octave range / bipolar before setting the table range
  local tableRange = #oneOctScale * octaveRange
  --print("tableRange", tableRange)
  tableMotion.setRange(motionTable, tableRange, bipolar)
  local startNote = baseNote
  if bipolar then
    startNote = startNote - (octaveRange * 12)
  end
  local maxNote = baseNote + (octaveRange * 12)
  activeScale = scales.createScale(scaleDefinition, startNote, maxNote)
  --print("#activeScale, startNote, maxNote", #activeScale, startNote, maxNote)
  resetPitches()
end

local function move(i, uniqueId)
  local direction = 1
  local value = motionTable:getValue(i)
  while isPlaying and movingCells[i] == uniqueId do
    value, direction = tableMotion.moveTable(motionTable, i, value, direction)
  end
end

local function startMoving()
  movingCells = {} -- Reset index to stop motion
  for i=1,motionTable.length do
    table.insert(movingCells, uniqueIndex)
    spawn(move, i, uniqueIndex)
    uniqueIndex = gem.inc(uniqueIndex)
  end
end

local function getNote()
  for i=1,motionTable.length do
    local val = 0
    if i == pitchOffsetPos then
      val = 1
    end
    positionTable:setValue(i, val)
  end
  local scalePos = motionTable:getValue(pitchOffsetPos) + 1
  if motionTable.min < 0 then
    scalePos = scalePos + math.abs(motionTable.min)
  end
  --print("#activeScale, scalePos", #activeScale, scalePos)
  local note = activeScale[scalePos]
  pitchOffsetPos = gem.inc(pitchOffsetPos, 1, motionTable.length)
  --print("pitchOffsetPos", pitchOffsetPos)
  return note
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  startMoving()
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetPitches()
end

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

local sequencerPanel = widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Motion Sequencer Input", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 90,
  xOffset = 531,
  yOffset = 5,
  xSpacing = 5,
  ySpacing = 5,
})

widgets.button("Forward", forward, {
  tooltip = "Forward triggers (note=0 events) to the next processor",
  changed = function(self) forward = self.value end,
})

local channelInput = widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

widgets.setSection({
  width = sequencerPanel.width,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
})

local notePanel = widgets.panel({
  backgroundColour = backgroundColour,
  y = widgets.posUnder(sequencerPanel),
  height = 250,
})

positionTable = widgets.table("Position", 0, tableMotion.options.tableLength, {
  enabled = false,
  persistent = false,
  sliderColour = "green",
  backgroundColour = "CFFFFE",
  height = 6,
})

widgets.setSection({
  height = 160,
  y = widgets.posUnder(positionTable),
})

motionTable = widgets.table("Motion", 0, tableMotion.options.tableLength, {
  showPopupDisplay = true,
  backgroundColour = "191E25",
  min = -24,
  max = 24,
  integer = true,
})

local noteWidgetHeight = 20
local noteWidgetWidth = 130
local noteWidgetRowSpacing = 5
local noteWidgetCellSpacing = 14
local firstRowY = motionTable.y + motionTable.height + 10

widgets.setSection({
  width = noteWidgetWidth,
  height = noteWidgetHeight,
  menuHeight = 45,
  xOffset = 10,
  yOffset = firstRowY,
  xSpacing = noteWidgetCellSpacing,
  ySpacing = noteWidgetRowSpacing,
})

widgets.menu("Speed Type", tableMotion.speedTypes, {
  changed = function(self) tableMotion.options.speedType = self.selectedText end
})

widgets.menu("Start Mode", 9, tableMotion.startModes, {
  changed = function(self)
    tableMotion.options.startMode = self.selectedText
    resetPitches()
  end
}):changed()

local scaleMenu = widgets.menu("Scale", #scalesNames, scalesNames, {
  width = 90,
  changed = function(self)
    scaleDefinitionIndex = self.value
    setScale()
  end
})

local noteInput = widgets.numBox("Base Note", baseNote, {
  width = 33,
  x = widgets.posSide(scaleMenu) - 7,
  y = firstRowY + 25,
  unit = Unit.MidiKey,
  showLabel = false,
  tooltip = "Set the root note",
  changed = function(self)
    baseNote = self.value
    setScale()
  end
})

local moveSpeedInput = widgets.numBox("Motion Speed", tableMotion.options.moveSpeed, {
  x = widgets.posSide(noteInput),
  name = "MoveSpeed",
  min = tableMotion.options.moveSpeedMin,
  max = tableMotion.options.moveSpeedMax,
  tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller",
  unit = Unit.MilliSeconds,
  changed = function(self) tableMotion.options.moveSpeed = self.value end
})

widgets.row()
widgets.col(3)

local factorInput = widgets.numBox("Speed Factor", tableMotion.options.factor, {
  name = "Factor",
  min = tableMotion.options.factorMin,
  max = tableMotion.options.factorMax,
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. Controlled by the Y-axis on the XY controller",
  changed = function(self) tableMotion.options.factor = self.value end
})

widgets.row()

local motionTableLengthInput = widgets.numBox("Length", tableMotion.options.tableLength, {
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the table length",
  changed = function(self)
    tableMotion.options.tableLength = self.value
    positionTable.length = tableMotion.options.tableLength
    motionTable.length = tableMotion.options.tableLength
    pitchOffsetPos = 1 -- Reset pos on length change
    resetPitches()
    startMoving()
    end
})

local bipolarButton = widgets.button("Bipolar", bipolar, {
  width = (noteWidgetWidth / 2) - (noteWidgetCellSpacing / 2),
  changed = function(self)
    bipolar = self.value
    setScale()
  end
})

widgets.button("Reset", false, {
  width = bipolarButton.width,
  changed = function(self)
    resetPitches()
    startMoving()
    self.value = false
  end
})

local octaveRangeInput = widgets.numBox("Octave Range", octaveRange, {
  tooltip = "Set the octave range",
  min = 1,
  max = 4,
  integer = true,
  changed = function(self)
    octaveRange = self.value
    setScale()
  end
})

local speedRandomizationAmountInput = widgets.numBox("Speed Rand", tableMotion.options.speedRandomizationAmount, {
  unit = Unit.Percent,
  tooltip = "Set the radomization amount applied to speed",
  changed = function(self) tableMotion.options.speedRandomizationAmount = self.value end
})

local xySpeedFactor = notePanel:XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = widgets.posSide(moveSpeedInput) - 5
xySpeedFactor.width = noteWidgetWidth
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  uniqueIndex = 1
  setScale()
end

function onNote(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    startPlaying()
    modular.handleTrigger(e, getNote())
  else
    postEvent(e)
  end
end

function onRelease(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    modular.handleReleaseTrigger(e)
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start == true then
    startPlaying()
  else
    stopPlaying()
  end
end
