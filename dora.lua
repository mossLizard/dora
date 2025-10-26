-- tableDora the tableExplorer!
-- wrote this because I was tired of trying to manually edit JSON files and I wanted to view and edit it in a format that I somewhat recognize
-- there are actual programs for this out there Im sure but oh well.

--"dite/data/minecraft/worldgen/noise_settings/overworld.json"
local defaultPath = "dite/prog/sample.json"
local args = {...} --get args
serl = textutils.serializeJSON

local drawutils = require("lib/drawUtils")
local draw = drawutils.new(term, 3, 2)
draw.setPalette(drawutils.palette_traditional)

local needExplore = true
local needRedraw = true
local doLoop = true
local inputs = {}
local screenMode = "map"
local editorMode = "none"
local currentTab = "main" -- board selected
local validTabs = {"main", "0","1","2","3","4","5","6","7","8","9"}
local currentPath = {['main'] = {"noise_router"}, ['0'] = {}, ['1'] = {"test_subdir"}, ['2'] = {}, ['3'] = {}} -- path of each board
local currentFiles = {['main'] = {}, ['0'] = {}, ['1'] = {["test_val"] = 27.4, ["test_bool"] = true, ["test_subdir"] = {["a"] = "a", ["b"] = "b", ["c"] = "c", ["d"] = { ["one"] = "one", ["two"] = 2}}, ["is_this_a_comically_long_key_name"] = "yes"}, ['2'] = {}, ['3'] = {}, ['4'] = {}}
local currentTable = {}
local currentKeys = {}
local tabColor = {}

function populateCurrents()
  for i,tab in ipairs(validTabs) do
    currentFiles[tab] = currentFiles[tab] or {}
    currentPath[tab] = currentPath[tab] or {}
	currentTable[tab] = currentTable[tab] or {}
	currentKeys[tab] = currentKeys[tab] or {}
	tabColor[tab] = {15,1+i} 
	--tabColor[tab] = 11 -- 3 is light blue
  end
end
populateCurrents()

local editorTable = {} -- selected item in the editor
local editorPath = {}  -- path to selected item, including table select
local tempTable = {}   -- for copy / paste operations
local currentSubdirs = {}
local mapDrawColors = {}
local mapScrollOfset = 0
local mapSelc = 3
function getInputs()
  inputs = {}
  local inputCount = 0
  while inputCount < 255 do
    local event = {os.pullEvent()}
	inputCount = inputCount + 1
	inputs[inputCount] = event
  end
end
tick = 0
ticksSinceInput = 0
function interval()
  tick = tick + 1
  --tick = (tick + 1) % (2^16)
  ticksSinceInput = ticksSinceInput + 1
  sleep(0.05)
end
local spkr = peripheral.wrap('spkr')
local hasSpkr = spkr ~= nil
local function trySound(soundName, volume, pitch)
  volume = (volume or 1) * 0.2
  pitch = pitch or 1
  if hasSpkr then
    return spkr.playSound("ui:"..soundName,volume,pitch)
  else
    return nil
  end
end
local function fitLeft(text, width, padding)
  padding = ' ' or padding
  return string.sub(text .. string.rep(padding, width), 1, width)
end
local function fitRight(text, width, padding)
  padding = ' ' or padding
  return string.sub(string.rep(padding, width) .. text, -width, -1)
end
local function scrollText(text, width, ofset, fitRightInstead, joint)
  joint = joint or '  -  ' --' ' .. string.char(127) .. ' '
  padding = ' '
  ofset = math.floor(ofset or 0)
  text = tostring(text)
  if #text <= width then
    if fitRightInstead then
      return fitRight(text, width, padding)
    else
      return fitLeft(text, width, padding)
    end
  else
    local strip = text .. joint .. text .. joint
    ofset = 1 + (ofset % (#text + #joint)) -- index starts at 1
    return string.sub(strip, ofset, ofset + width)
  end
end

local function drawSingleButton(bttn)
  if bttn.name == nil or bttn.pos == nil then
    return false
  end
  thisColor = bttn.color or {15,0}
  thisSize = bttn.size or {1,#bttn.name}
  draw.setColor(thisColor)
  draw.write(bttn.name, bttn.pos[1], bttn.pos[2])
  return true
end

local function drawButtons(buttonList) -- {name,{x,y},{tx,bg},func,argument2}
  for i,bttn in ipairs(buttonList) do
    drawSingleButton(bttn)
    --print(bttn)
	--sleep(0.1)
    --draw.setColor(bttn[3][1],bttn[3][2])
    --draw.write(bttn[1],bttn[2][1],bttn[2][2])
  end
end

local function checkButtons(buttonList, mouseClickEvent)
  -- goes through the list of buttons and finds the last one clicked by this mouse event. Returns true if a button was pressed, as well as the name of the button pressed. If the button had a function and parameters attached, the function is run and the results are returned as third value.
  --print()
  --print(serl(mouseClickEvent))
  mx, my = mouseClickEvent[3] - draw.basex, mouseClickEvent[4] - draw.basey
  for i,v in ipairs(buttonList) do
    bttn = buttonList[#buttonList + 1 - i] -- check in reverse order
	thisSize = (bttn.size or {#bttn.name,1})
	buttonBox = {bttn.pos[1], bttn.pos[1] + thisSize[1], bttn.pos[2], bttn.pos[2] + thisSize[2]}
    if true then -- same line
      if mx >= buttonBox[1] and mx < buttonBox[2] and my >= buttonBox[3] and my < buttonBox[4] then
	    buttonReturnName = bttn.returnName or bttn.name
	    --error("PRESSED!! "..bttn[1])
		if bttn.func == nil then
		  --print(serl(bttn))
		  --don't run the function because there is no function.
		  return true, bttn.name, nil
		else
		  if bttn.params == nil then
		    result = bttn.func(bttn.name,mx,my) -- pass name & coords if no params definde
		    return true, bttn.name, result
		  end
		    result = bttn.func(table.unpack(bttn.params))
		    return true, bttn.name, result
		end
	  end
	end
  end
  return false
end



function matchTable(inTable, recurse) -- STUB
  return false
end

function trySubdir(dirKey, tab)
  if currentTable[tab][dirKey] == nil then return false, "doesNotExist"
  elseif type(currentTable[tab][dirKey]) ~= "table" then return false, "notATable"
  else
	currentPath[tab][#currentPath[tab]+1] = dirKey
	needExplore = true
    return true
  end
end

function wrangleInputs() -- "handle" felt like too gentle a word for what I am doing here
  tab = currentTab
  for i,event in ipairs(inputs) do
    if event[1] == "key" or event[1] == "mouse_click" or event[1] == "mouse_drag" or event[1] == "mouse_up" then
	  needRedraw = true
	end
	
	-- I need to redo this entire thing :(
	if event[1] == "mouse_click" then
	  checkButtons(buttonTables.tablets, event)
	  checkButtons(buttonTables.menuBar, event)
	  checkButtons(buttonTables.itemList, event)
	end
  end
end

function handle_clickTab(tabName)
  --error("setTab"..tabName)
  if screenMode == "map" then -- set tab
    --setEditorState(tabName)
	currentTab = tabName
	mapSelc = 0
  end
end

function handle_clickItemList(indexOnScreen)
  if screenMode == "map" then
    selcItem = indexOnScreen-mapScrollOfset
    if indexOnScreen == 0 then
      mapSelc = 0
	  mapScrollOfset = 0
	  if #currentPath[currentTab] > 0 then
	    currentPath[currentTab][#currentPath[currentTab]] = nil
		needRedraw = true
		needExplore = true
	  end
	elseif(selcItem > 0 and selcItem <= #currentKeys[currentTab]) then -- is valid item?
	  if selcItem == mapSelc then -- double clicked?
	    trySubdir(currentKeys[currentTab][selcItem],currentTab)
		mapSelc = 0
		mapScrollOfset = 0
		needRedraw = true
		needExplore = true
	  else
	    mapSelc = selcItem
	  end
	end
  else
    error("undefined behaviour on clicking list when in mode "..tostring(screenMode) .."!")
  end
end

function handle_primitiveTool(toolType)
   
end

function setEditorState(newState)
  if newState == nil or newState == 'none' then
    editorPath = {}
	editorTable = {}
	editorMode = 'none'
	screenMode = 'map'
  else
    editorPath = climb(currentPath[currentTab])
	editorTable = climb(currentPath[currentTab])
	editorMode = 'copy'
	screenMode = 'edit'
  end
  
end


function loadJson(path)
  local f, message = fs.open(path,"r")
  if f == nil then
    print("  UNABLE TO FETCH FILE!", message or 'noMessage',"")
	sleep(2.0)
	return nil, message or "noFile"
  else
    print("  Fetch success!", message or 'noMessage')
    local contents, msg2 = textutils.unserializeJSON(f.readAll())
	f.close()
	--print(contents, msg2)
	if contents == nil then
	  print("  DECODE FAIL!", msg2)
	  sleep(2)
	  return contents, "notJson"
	else
	  print("  Decode success!", msg2)
	  sleep(0.5)
	  return contents, 'OK'
	end
  end
end


local fileTable = {}
local message = ""
if #args == 1 then 
  print("  SPECIFIED JSON:",args[1])
  fileTable, message = loadJson(args[1])
else
  print("  USING DEFAULT PATH:",defaultPath)
  fileTable, message = loadJson(defaultPath)
end
--textutils.pagedPrint(textutils.serializeJSON(fileTable))
currentFiles["main"] = fileTable

--templates = loadJson("dite/prog/templates_worldgen.json")

function getSubdir(sourceTable, path)
  -- read from the given "subdirectory" 
  if path == nil then
    return nil
  end
  print(serl(path))
  ref = sourceTable
  --if #path == 0 then return fileTable end
  --print(serl(ref))
  for i=1, #path do
    --print(serl(ref))
    ref = ref[path[i]]
	--print(serl(ref))
  end
  return ref
end

function strLikeDir(input, prefix)
  -- prints the path as if it were an actual file path
  local sto = '/'
  for i,v in ipairs(input) do
    sto = sto .. v .. '/'
  end
  if prefix ~= nil then sto = prefix..sto end
  return sto
end

function climb(tabel, path)
  -- returns the sub-table or element at the end of the path
  -- named because I pictured it as climbing up a tree of tables
  if path == nil or #path < 1 then
    return tabel
  elseif type(path) ~= "table" then
    error("Could not climb; path is not a table!")
  elseif #path == 1 then
    return tabel[path[1]]
  else
    tabel[path[1]] = tabel[path[1]] or {}
    np = {}
	for i=2,#path do
	  np[i-1] = path[i]
	end
	return climb(tabel[path[1]], np)
  end
end

function plant(tabel, path, val)
  -- sets the value at the end of the path to the given value
  -- like "planting" a flag at the top of a tree. Or in place of a branch.
  if path == nil then
    tabel = val
    return tabel
  elseif type(path) ~= "table" then
    error("Could not plant value; path is not a table!")
  elseif path == nil or #path <= 1 then
    tabel[path[1]] = val
	return tabel
  else
    np = {}
	for i=2,#path do
	  np[i-1] = path[i]
	end
	tabel = plant(tabel[path[1]], np, val)
	return tabel
  end
end

--plant(currentFiles, {"main","noise"}, {["beep"] = 27.4, ["boop"] = false})

function estimateChildCount(inTable)
  -- I say "estimate" here because inTable may have number AND string keys because lua is a sadist
  if inTable == {} then return 0, nil
  elseif #inTable > 0 then return #inTable, "number"
  else
    local acc = 0
	for k,v in pairs(inTable) do
	acc = acc + 1
	end
	return acc, "string"
  end
end

function exploreAll()
  --explore(currentPath[currentTab],"main")
  for i,v in ipairs(validTabs) do
    explore(currentPath[v],v)
  end
end

function explore(path, tab)
  climbResult = climb(currentFiles[tab], path)
  if climbResult == nil then
    currentFiles[tab] = {}
    plant(currentFiles[tab], path, {})
    climbResult = climb(currentFiles[tab], path)
  end
  currentTable[tab] = climbResult
  -- currentTable[tab] SHOULD now be updated
  currentKeys[tab] = {}
  local ic = 1
  for k,v in pairs(currentTable[tab]) do
    currentKeys[tab][ic] = k
	ic = ic + 1
  end
  table.sort(currentKeys[tab])
end

-- -- -- EDIT MODE FUNCTIONS -- -- --






-- -- -- DRAWING FUNCTIONS -- -- --

buttonTables = { -- predefining this so I don't have to keep building it
  ["menuBar"] = { 
    {["name"] = " DORA - ...... ...... ...... ", ["pos"] = {0,-1}, ["color"] = {15,3}},
    {["name"] = "[File]", ["pos"] = {8,-1}, ["color"] = {15,3}}, 
	{["name"] = "[View]", ["pos"] = {15,-1}, ["color"] = {15,3}}, 
	{["name"] = "[Help]", ["pos"] = {22,-1}, ["color"] = {15,3}} 
  },
    ["editButtons"] = { 
    {["name"] = "[Copy]", {0,16}, {15,3}}, 
	{["name"] = "[Add]", {15,16}, {15,3}}, 
	{"[Set]", {23,16}, {15,3}} 
  },
  ["itemList"] = {
    {["name"] = "parent", ["pos"] = {0,1}, ["size"] = {48,1}, ["func"] = handle_clickItemList, ["params"] = {0}}
  },
  ["tablets"] = {} --dynamically generated
}

for i=2, 13 do
  buttonTables.itemList[i] = {
	["name"] =  i-1,
	["pos"] = {1,i},
	["size"] = {48,1},
	["func"] = handle_clickItemList,
	["params"] = {i-1}
  }
end

function flipTabColors(tab, buttonList)
  -- manually check main and 0
  
  if tab == "main" then
    buttonList[1].color = {buttonList[1].color[2],buttonList[1].color[1]}
  elseif tab == "0" then
    buttonList[2].color = {buttonList[1].color[2],buttonList[1].color[1]}
  else
    tabColors[tab] = {tabColors[tab][2],tabColors[tab][1]}
  end
end


function drawMenuBar()
  draw.setColor(15,3)
  --draw.write(" DORA - [File] [View] [Help] - [main|==========] ",-1,-1,49)
  local tabButtons = {
    {["name"] = "[----|----------]", ["pos"] = {29,-1}, ["color"] = {15,3}},
    {["name"] = "main", ["pos"] = {30,-1}, ["color"] = {15,13}, ["func"] = handle_clickTab, ["params"] = {"main"}}, 
	{["name"] = "|0", ["pos"] = {34,-1}, ["color"] = tabColor["0"], ["func"] = handle_clickTab, ["params"] = {"0"}}
  } -- I have to generate this on-site because tab colors change
  for i,v in ipairs(validTabs) do
    if i >= 3 then -- manually ignore first 3 :(
	  tabButtons[i+1] = {
		["name"] = v, 
		["pos"] = {33+i, -1}, 
		["color"] = tabColor[v],
		["func"] = handle_clickTab
	}
	end
  end
  buttonTables.tablets = tabButtons
  drawButtons(buttonTables.menuBar)
  --drawButtons(buttonTables.editButtons)
  drawButtons(tabButtons)
  --drawButtons(buttonTables.itemList)
end

function contentDesc(input)
  -- display element info
  local toDisplay = "ERROR ???"
  local toColor = {15,0}
  bgAlternate = 15
  if type(input) == "table" then
    local childCount, childType, childPrint = estimateChildCount(input)
	if childCount == 0 then
	  toColor = {8,bgAlternate}
	  toDisplay = "table empty"
	else
	  isTemplate = {matchTable(input)}
      if isTemplate[1] then
	    toColor = {4,bgAlternate}
		toDisplay = string.format(isTemplate[2] .. " "..isTemplate[3][1], table.unpack(isTemplate[3][2]))
	  else
	    toColor = {11,bgAlternate}
	    toDisplay = ("table "..childCount.." subdirs")
	  end
	end
  elseif type(input) == "string" then
	toDisplay = input
	toColor = {14,bgAlternate}
  elseif type(input) == "number" then
	toDisplay = 'value '..tostring(input)
	toColor = {6,bgAlternate}
  elseif type(input) == "boolean" then
	toDisplay = 'bool  '..tostring(input)
	toColor = {13,bgAlternate}
  end
  return toDisplay, toColor
end

function drawScreen_imTheMap(tab)
  -- main draw function for the single directory view
  -- shows a list of "subdirectories" and options for editing / navigating
  --local thisDir = currentTable
  tab = tab or currentTab
  draw.setColor(0,15)
  if #currentPath[tab] == 0 then -- draw up button
    draw.setColor(7,15)
    draw.write("..             | root",1,1) -- root has no parent
  else
    draw.write("..             : (up)",1,1)
  end
  draw.setColor(15,0)
  draw.write(fitRight(strLikeDir(currentPath[tab],tab),47),1,0) -- draw dir name
  local scrollBarText = string.char(127):rep(12) 
  if(#currentKeys[tab] <= 12 and mapScrollOfset == 0) then -- all elements shown
    draw.setColor(7,15)
  elseif (#currentKeys[tab] > mapScrollOfset+12 and mapScrollOfset > 0) then -- elements before AND after shown
    draw.setColor(15,0)
	scrollBarText = string.format("^^^ %.4d vvv",mapScrollOfset)
  elseif (#currentKeys[tab] <= mapScrollOfset+12 and mapScrollOfset > 0) then -- elements before shown
    draw.setColor(15,0)
	scrollBarText = string.format("^^^ %.4d |||",mapScrollOfset)
  elseif (#currentKeys[tab] > mapScrollOfset+12 and mapScrollOfset == 0) then -- elements after shown
    draw.setColor(15,0)
	scrollBarText = string.format("||| %.4d vvv",mapScrollOfset)
  else
    draw.setColor(14,15)
  end
  --draw.drawBox(-1,2,1,12)
  draw.writeWrapped(scrollBarText,-1,2,1)
  draw.setColor(0,15)
  mapDrawColors = {}
  
  --for ic,k in ipairs(currentKeys) do
  
  -- draw list of elements
  for ic = mapScrollOfset+1, math.min(#currentKeys[tab], mapScrollOfset + 12) do
    k = currentKeys[tab][ic]
	local thisItemSelected = (mapSelc == ic)
    local v = currentTable[tab][k]
    local isTable = (type(v) == "table")
	local isSubdir = false
	local xOfset = 0
	if thisItemSelected then xOfset = -1 end -- selected element is shifted over
	--local bgAlternate = 7+(ic%2)*8
	local bgAlternate = 15
	local thisItemDisplay, thisItemColors = contentDesc(v)
	mapDrawColors[ic] = thisItemColors
	if thisItemSelected then 
	  mapDrawColors[ic] = {thisItemColors[2],thisItemColors[1]}
	end
	draw.setColor(mapDrawColors[ic])
	
	--draw.drawBox(1,1+ic-mapScrollOfset,48,1,' ')
	draw.write(k,1+xOfset,1+ic-mapScrollOfset,16-xOfset)
	draw.write(": "..tostring(thisItemDisplay),16,1+ic-mapScrollOfset,32)
  end
  drawMenuBar()
end

function drawAnims_imTheMap(tab)
  tab = tab or currentTab
  draw.setColor(15,0)
  if #strLikeDir(currentPath[tab]) >= 47 then
    draw.write(scrollText(strLikeDir(currentPath[tab]),46, tick / 4, true),1,0)
    --draw.write(fitRight(strLikeDir(currentPath),47),1,0)
  end
  if mapSelc > 0 and (mapSelc-mapScrollOfset <= 12) then
    thisName = currentKeys[tab][mapSelc-mapScrollOfset]
  if thisName == nil then
	  draw.write("!!ERROR NIL NAME!!",0,1+mapSelc-mapScrollOfset,16)
	elseif #thisName > 16 then
	  draw.setColor(mapDrawColors[mapSelc-mapScrollOfset])
	  draw.write(scrollText(thisName, 15, ticksSinceInput / 4),0,1+mapSelc-mapScrollOfset,16)
	end
  end
end


-- if current name matches an element in current directory, we are editing.
-- on matching name, ask to keep or overwrite or cancel
-- else, we are adding an element or inserting it
function drawMockup_editScreen()
  draw.setColor(3,15)
  draw.drawBox(-1,15,49,2)
  draw.drawBox(-1,-1,49,1)
  draw.setColor(15,0)
  draw.write(fitRight(strLikeDir(currentPath[tab]),47),1,0) -- dir name
  
  draw.setColor(8,15)
  draw.drawBox(16,1,32,14) -- window area
  
  draw.setColor(0,7)
  draw.writeWrapped("|::<::::::::::",16,1,1)
  draw.write(" COPY : editing Clipboard 0    ", 17, 2)
  draw.write("      :                        ", 17, 3)
  draw.write(" Type : [b] [n] string [t] [!] ", 17, 4)
  draw.write(" Key  : noMoreLonelyNights     ", 17, 5)
  draw.write(" Val  : two love stories       ", 17, 10)
  draw.write(" [Cancel]   [Save]   [Delete]  ", 17, 11)
  draw.write(" [Copy to...]  [Set from...]   ", 17, 12)
  draw.setColor(8,7)
  draw.write(" [Insert from...]  [Collapse]  ", 17, 13)
  --draw.write(textutils.serializeJSON(inputs), 1, 20)
  bttnList = {{"beep",{12,2},{0,15}}, {"boop",{32,3},{7,2}}}
  drawButtons(bttnList)
end


function main()
  while doLoop do
    parallel.waitForAny(interval, getInputs)
	wrangleInputs()
	if needExplore then
	  --explore(currentPath[currentTab],"main")
	  exploreAll()
	  needExplore = false
	end
	if needRedraw then
    ticksSinceInput = 0
	  if screenMode == 'map' then 
        draw.clear(15)
        drawScreen_imTheMap(currentTab)
		drawAnims_imTheMap(currentTab)
	    needRedraw = false
	  elseif screenMode == 'edit' then
        draw.clear(15)
	    drawMockup_editScreen()
	    needRedraw = true
	  end
	else
	  if screenMode == 'map' then
        drawAnims_imTheMap()
	  elseif screenMode == 'edit' then
	    drawMockup_editScreen()
	  end
	end
  end
end
main()
draw.setCursorPos(-1,-1)
print("DONE")
