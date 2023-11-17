-- Print out all macros in the program --

local i = 1
local allMacros = {}

-- Collect all macros
while true do
    local macro = Program.modulations["Macro " .. i]
    if type(macro) == "nil" then
        break
    end
    print("Adding", "Macro " .. i)
    table.insert(allMacros, macro)
    i = i + 1
end

for i,macro in ipairs(allMacros) do
    print("Display", macro.name)
    local macroKnob = Knob("macro" .. i, 0, 0, 1)
    macroKnob.displayName = macro.name
    macroKnob.changed = function(self)
        macro:setParameter("Value", self.value)
    end
    macroKnob:changed() 
end
