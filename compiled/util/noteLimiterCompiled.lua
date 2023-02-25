-- util/noteLimiter -- 
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
-- Common functions for notes
--------------------------------------------------------------------------------

local notenames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

local notes = {
  getNoteNames = function()
    return notenames
  end,
  
  -- Used for mapping - does not include octave, only name of note (C, C#...)
  getNoteMapping = function()
    local noteNumberToNoteName = {}
    local notenamePos = 1
    for i=0,127 do
      table.insert(noteNumberToNoteName, notenames[notenamePos])
      notenamePos = notenamePos + 1
      if notenamePos > #notenames then
        notenamePos = 1
      end
    end
    return noteNumberToNoteName
  end,
  
  transpose = function(note, min, max)
    --print("Check transpose", note)
    if note < min then
      print("note < min", note, min)
      while note < min do
        note = note + 12
        print("transpose note up", note)
      end
    elseif note > max then
      print("note > max", note, max)
      while note > max do
        note = note - 12
        print("transpose note down", note)
      end
    end
    -- Ensure note is inside given min/max values
    note = math.max(min, math.min(max, note))
    -- Ensure note is inside valid values
    return math.max(0, math.min(127, note))
  end,
  
  getSemitonesBetweenNotes = function(note1, note2)
    return math.max(note1, note2) - math.min(note1, note1)
  end,
  
  getNoteAccordingToScale = function(scale, noteToPlay)
    for _,note in ipairs(scale) do
      if note == noteToPlay then
        return noteToPlay
      elseif note > noteToPlay then
        print("Change from noteToPlay to note", noteToPlay, note)
        return note
      end
    end
    return noteToPlay
  end,
}

--------------------------------------------------------------------------------
-- Note Limiter
--------------------------------------------------------------------------------
-- Limits note range and polyphony (0 polyphony blocks all incoming notes)
-- Notes outside range are transposed to the closest octave within range
-- Duplicate notes are removed
--------------------------------------------------------------------------------

local backgroundColour = "1a4245" -- Light or Dark
local widgetBackgroundColour = "072227" -- Dark
local widgetTextColour = "4FBDBA" -- Light
local labelTextColour = "AEFEFF" -- Light
local menuArrowColour = "aa" .. widgetTextColour
local labelBackgoundColour = "ff" .. widgetBackgroundColour
local menuOutlineColour = "5f" .. widgetTextColour

setBackgroundColour(backgroundColour)

local panel = widgets.panel({
  backgroundColour = backgroundColour,
  x = 10,
  y = 10,
  width = 700,
  height = 60,
})

local label = panel:Label("Label")
label.text = "Note Limiter"
label.tooltip = "Limits note range and polyphony (0 polyphony blocks all incoming notes)"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {120,25}

local rangeLabel = panel:Label("Range")
rangeLabel.text = "Note Range"
rangeLabel.tooltip = "Set the range for incoming notes. If range is less than an octave, notes may be changed to fit the range."
rangeLabel.x = 150
rangeLabel.y = 3

local noteMin = panel:NumBox("NoteMin", 0, 0, 127, true)
noteMin.unit = Unit.MidiKey
noteMin.backgroundColour = widgetBackgroundColour
noteMin.textColour = widgetTextColour
noteMin.displayName = "Min"
noteMin.tooltip = "Lowest note - notes below this are transposed to closest octave within range"
noteMin.x = rangeLabel.x
noteMin.y = rangeLabel.y + rangeLabel.height + 5

local noteMax = panel:NumBox("NoteMax", 127, 0, 127, true)
noteMax.unit = Unit.MidiKey
noteMax.backgroundColour = widgetBackgroundColour
noteMax.textColour = widgetTextColour
noteMax.displayName = "Max"
noteMax.tooltip = "Highest note - notes above this are transposed to closest octave within range"
noteMax.x = noteMin.x + noteMin.width + 10
noteMax.y = noteMin.y

-- Range must not cross, but can be equal if limiting to one note
noteMin.changed = function(self)
  noteMax:setRange(self.value, 127)
end

noteMax.changed = function(self)
  noteMin:setRange(0, self.value)
end

local priority = panel:Menu("Priority", {"As Played", "Lowest", "Highest", "Random"})
priority.backgroundColour = widgetBackgroundColour
priority.textColour = widgetTextColour
priority.arrowColour = menuArrowColour
priority.outlineColour = menuOutlineColour
priority.displayName = "Priority"
priority.tooltip = "Priority of incoming notes if limited by polyphony"
priority.x = noteMax.x + noteMax.width + 50
priority.y = rangeLabel.y

local polyphony = panel:NumBox("Polyphony", 16, 0, 16, true)
polyphony.displayName = "Polyphony"
polyphony.tooltip = "Limit polyphony to the set number of notes - 0 blocks all incoming notes"
polyphony.backgroundColour = widgetBackgroundColour
polyphony.textColour = widgetTextColour
polyphony.x = priority.x + priority.width + 50
polyphony.y = priority.y

local buffer = panel:NumBox("Buffer", 1, 0, 100, true)
buffer.unit = Unit.MilliSeconds
buffer.backgroundColour = widgetBackgroundColour
buffer.textColour = widgetTextColour
buffer.displayName = "Buffer"
buffer.tooltip = "Time to wait for incoming notes when calculation polyphony - if input is from a human, 20-30 ms is recommended. 0 means no buffer (NOTE: this disables the polyphony limit)."
buffer.x = polyphony.x
buffer.y = polyphony.y + polyphony.height + 5
buffer.changed = function(self)
  polyphony.enabled = self.value > 0
end

function eventsIncludeNote(eventTable, note)
  for _,v in pairs(eventTable) do
    local event = v
    if type(v.event) == "table" then
      event = v.event
    end
    if event.note == note then
      print("Note already included", note)
      return true
    end
  end
  return false
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

local bufferActive = false
local heldNotes = {} -- Holds the notes that are currently held
local noteBuffer = {} -- Holds the original (untransposed) incoming notes for the active buffer
function onNote(e)
  if polyphony.value == 0 then
    return
  end
  local note = e.note -- The original note without transposition
  e.note = notes.transpose(e.note, noteMin.value, noteMax.value)

  -- Add to held notes, unless duplicate
  if eventsIncludeNote(heldNotes, e.note) == false then
    table.insert(heldNotes, e)
    print("Added note to held notes original/transposed", note, e.note)
  end

  -- Add to buffer, unless duplicate
  if eventsIncludeNote(noteBuffer, e.note) == false then
    table.insert(noteBuffer, {event=e,note=note})
    print("Added note to buffer original/transposed", note, e.note)
  end

  -- Collect notes while the buffer is active
  if buffer.value > 0 then
    if bufferActive == false then
      bufferActive = true
      print("buffering")
      wait(buffer.value)
      print("buffering finished")
    else
      print("buffer active...")
      return
    end
  end

  -- Priority: {"As Played", "Lowest", "Highest", "Random"}
  if priority.value == 2 then
    print("Sort lowest")
    table.sort(noteBuffer, function(a,b) return a.note < b.note end)
  elseif priority.value == 3 then
    print("Sort highest")
    table.sort(noteBuffer, function(a,b) return a.note > b.note end)
  end

  print("Current #heldNotes", #heldNotes)
  print("Current #noteBuffer", #noteBuffer)

  if polyphony.value < #noteBuffer then
    local keep = {}
    local i = 1
    while #keep < polyphony.value and i <= #noteBuffer do
      local event = noteBuffer[i].event
      -- Pick random notes from the incoming notes
      if priority.value == 4 then
        event = noteBuffer[gem.getRandom(#noteBuffer)].event
        while eventsIncludeNote(keep, event.note) == true do
          event = noteBuffer[gem.getRandom(#noteBuffer)].event
        end
      end
      print("postEvent", event.note)
      postEvent(event)
      table.insert(keep, event)
      i = i + 1 -- Increment index
    end

    -- Any held not that is not kept, must be released, unless it is in the current note buffer (then it has not been played)
    for _,held in ipairs(heldNotes) do
      if eventsIncludeNote(keep, held.note) == false and eventsIncludeNote(noteBuffer, held.note) == false then
        held.type = Event.NoteOff -- Send a note off event
        held.velocity = 0 -- Set no velocity on release to avoid any sound on release
        postEvent(held)
      end
    end
    heldNotes = keep -- Update held notes
  else
    print("Play all the notes from the active buffer")
    for _,v in ipairs(noteBuffer) do
      postEvent(v.event)
    end
  end

  print("Kept #heldNotes", #heldNotes)

  bufferActive = false -- Reset buffer
  noteBuffer = {} -- Reset note buffer
end

function onRelease(e)
  if polyphony.value == 0 then
    return
  end
  print("onRelease note in", e.note)
  e.note = notes.transpose(e.note, noteMin.value, noteMax.value) -- Transpose note
  e.velocity = 0 -- Set no velocity on release to avoid any sound on release
  for i,v in ipairs(heldNotes) do
    if v.note == e.note then
      table.remove(heldNotes, i)
      print("Released note", e.note)
    end
  end
  postEvent(e)
end
