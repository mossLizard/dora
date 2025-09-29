-- tableDora the tableExplorer!
-- wrote this because I was tired of trying to manually edit JSON files and I wanted to view and edit it in a format that I somewhat recognize
-- there are actual programs for this out there Im sure but oh well.

--"dite/data/minecraft/worldgen/noise_settings/overworld.json"
local defaultPath = "dite/prog/sample.json"
local args = {...} --get args

local drawutils = require("lib/drawUtils")
local draw = drawutils.new(term, 3, 2)
draw.setPalette(drawutils.palette_traditional)

local needExplore = true
local needRedraw = true
local doLoop = true
local inputs = {}
local screenMode = "map"
local currentTab = "main"
local currentPath = {['main'] = "noise_router", ['#1'] = "", ['#2'] = "", ['#3'] = "", ['#4'] = ""}
local currentKeys = {['main'] = {}, ['#1'] = {}, ['#2'] = {}, ['#3'] = {}, ['#4'] = {}}
local currentTable = {['main'] = {}, ['#1'] = {}, ['#2'] = {}, ['#3'] = {}, ['#4'] = {}}
local currentSubdirs = {['main'] = {}, ['#1'] = {}, ['#2'] = {}, ['#3'] = {}, ['#4'] = {}}
local tableClipboard = {}
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

function matchTable(inTable, recurse)
  return false
end

function trySubdir(dirKey)
  if currentTable[dirKey] == nil then return false, "doesNotExist"
  elseif type(currentTable[dirKey]) ~= "table" then return false, "notATable"
  else
	currentPath[#currentPath+1] = dirKey
	needExplore = true
    return true
  end
end

function wrangleInputs() -- "handle" felt like too gentle a word for what I am doing here
  for i,event in ipairs(inputs) do
    if event[1] == "key" or event[1] == "mouse_click" or event[1] == "mouse_drag" or event[1] == "mouse_up" then
	  needRedraw = true
	end
	if screenMode == "map" then
	  if event[1] == "mouse_click" then
	    local mb, mx, my = event[2],event[3],event[4]
		if mx == 2 then --scrollbar
		  if my >=3 and my <= 7 then
		    mapScrollOfset = math.max(mapScrollOfset-1,0)
		  elseif my >=11 and my <= 15 then
		    mapScrollOfset = math.min(mapScrollOfset+1,math.max(1,#currentKeys-11))
		  end
		needRedraw = true
		trySound("ui.bip_0")
		elseif mx >= 3 and my >= 3 and my <= 15 then --clicked a directory
	      selcItem = my-3+mapScrollOfset
	      if (selcItem > 0 and selcItem <= #currentKeys) then
		    if selcItem == mapSelc then
	          trySubdir(currentKeys[selcItem])
		      trySound("ui.bip_0")
		      mapSelc = 0
		      mapScrollOfset = 0
		    else
		      mapSelc = selcItem
		      trySound("ui.bip_0")
		    end
	      else--if selcItem <= 0 and selcItem >= -1 and #currentPath > 0 then
	        currentPath[#currentPath] = nil
		    trySound("ui.bip_0")
			mapSelc = 0
			mapScrollOfset = 0
            needExplore = true
		  end
		elseif my == 17 then -- edit mode (TEMPORARY!!!!)
		  screenMode = 'edit'
		  if mapSelc > 0 then
		    tableClipboard = table.sort(currentTable)
	      end
		end
	  end
	elseif screenMode == 'edit' then
	  if event[1] == "mouse_click" then
	    local mb, mx, my = event[2],event[3],event[4]
		screenMode = 'map'
	  end
	end
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

templates = loadJson("dite/prog/templates_worldgen.json")

function getSubdir(path)
  if #path == 0 then return fileTable end
  -- read from the given "subdirectory" 
  ref = fileTable[path[1]]
  for i=2, #path do
    ref = ref[path[i]]
  end
  return ref
end

function strLikeDir(input)
  -- prints the path as if it were an actual file path
  local sto = '/'
  for i,v in ipairs(input) do
    sto = sto .. v .. '/'
  end
  return sto
end

function estimateChildCount(inTable)
  -- I say "estimate" here because inTable may have number AND string keys
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

function explore(path)
  currentTable = getSubdir(currentPath)
  currentKeys = {}
  local ic = 1
  for k,v in pairs(currentTable) do
    currentKeys[ic] = k
	ic = ic + 1
  end
  table.sort(currentKeys)
end

function contentDesc(input)
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


-- drawing functions

function drawScreen_imTheMap()
  -- main draw function for the single directory view
  -- shows a list of "subdirectories" and options for editing / navigating
  --local thisDir = currentTable
  draw.setColor(0,15)
  if #currentPath == 0 then
    draw.setColor(7,15)
    draw.write("..             | root",1,1) -- root has no parent
  else
    draw.write("..             : (up)",1,1)
  end
  draw.setColor(15,0)
  draw.write(fitRight(strLikeDir(currentPath),47),1,0) -- dir name
  local scrollBarText = string.char(127):rep(12) 
  if(#currentKeys <= 12 and mapScrollOfset == 0) then -- all elements shown
    draw.setColor(7,15)
  elseif (#currentKeys > mapScrollOfset+12 and mapScrollOfset > 0) then -- elements before AND after shown
    draw.setColor(15,0)
	scrollBarText = string.format("^^^ %.4d vvv",mapScrollOfset)
  elseif (#currentKeys <= mapScrollOfset+12 and mapScrollOfset > 0) then -- elements before shown
    draw.setColor(15,0)
	scrollBarText = string.format("^^^ %.4d |||",mapScrollOfset)
  elseif (#currentKeys > mapScrollOfset+12 and mapScrollOfset == 0) then -- elements after shown
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
  for ic = mapScrollOfset+1, math.min(#currentKeys, mapScrollOfset + 12) do
    k = currentKeys[ic]
	local thisItemSelected = (mapSelc == ic)
    local v = currentTable[k]
    local isTable = (type(v) == "table")
	local isSubdir = false
	local xOfset = 0
	if thisItemSelected then xOfset = -1 end
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
  -- tabs at top (leave room for multishell bar)
	draw.setColor(15,3)
	draw.write(string.format(" DORA - %15s - main #1 #2 #3 #4  [?] ","fileNameGoesHere"),-1,-1,49)
	--draw.write(textutils.serializeJSON(inputs), 1, 20)
	--draw.write("TICK "..tick..' '..ticksSinceInput, 1, 21)
	draw.setColor(15,3)
	draw.write(" [Edit] [Add ] [Remv] [Copy] [inSt]",-1,15,49)
  -- edt: alter this entry. option to replace with aux
  -- add: new entry in this dir, from primative or aux
  -- rmv: remove this entry. if dir, option to collapse or remove children as well.
  -- cpy: copy this entry to an aux
  -- ins: insert an aux or empty dir between this entry and its parent. if using an aux, the shallowest empty list will contain the entry after edit
  -- 
	draw.write(string.format(" [View]   MODE%8s|TICK%4.4x|TSLI%4.4x","readOnly", tick, ticksSinceInput),-1,16,49)
end

function drawAnims_imTheMap()
  draw.setColor(15,0)
  if #strLikeDir(currentPath) >= 47 then
    draw.write(scrollText(strLikeDir(currentPath),46, tick / 4, true),1,0)
    --draw.write(fitRight(strLikeDir(currentPath),47),1,0)
  end
  if mapSelc > 0 and (mapSelc-mapScrollOfset <= 12) then
    thisName = currentKeys[mapSelc-mapScrollOfset]
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
function drawScreen_editMode()
  draw.setColor(15,0)
  draw.write(fitRight(strLikeDir(currentPath),48),1,0) -- dir name
  draw.setColor(0,15)
  
  draw.write(textutils.serializeJSON(inputs), 1, 20)
end



function main()
  while doLoop do
    parallel.waitForAny(interval, getInputs)
	wrangleInputs()
	if needExplore then
	  explore(currentPath)
	  needExplore = false
	end
	if needRedraw then
    ticksSinceInput = 0
	  if screenMode == 'map' then 
        draw.clear(15)
        drawScreen_imTheMap()
		drawAnims_imTheMap()
	    needRedraw = false
	  elseif screenMode == 'edit' then
        draw.clear(15)
	    drawScreen_editMode()
	    needRedraw = true
	  end
	else
	  if screenMode == 'map' then
        drawAnims_imTheMap()
	  elseif screenMode == 'edit' then
	    --pass
	  end
	end
  end
end
main()
draw.setCursorPos(-1,-1)
print("DONE")
