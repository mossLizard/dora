drawutils = {}
-- A replacement and expansion of some monitor functions.

local function fitLeft(text, width, padding)
  padding = ' ' or padding
  return string.sub(text .. string.rep(padding, width), 1, width)
end
local function fitRight(text, width, padding)
  padding = ' ' or padding
  return string.sub(string.rep(padding, width) .. text, -width, -1)
end

drawutils.basex = 1
drawutils.greyValues = {15,7,8,0}
drawutils.screen = nil



function drawutils.new(screen, basex, basey)
  if screen == nil then return nil end
  drawutils.screen = screen
  drawutils.basex = basex or 1
  drawutils.basey = basey or 1
  screen.setGraphicsMode(0)
  return drawutils
end

function drawutils.timestamp(dayDigits)
  -- including this function because I keep using it.
  dayDigits = dayDigits or 8
  local sto = fitLeft( textutils.formatTime(os.time(), true),5)
  sto = '' .. fitRight(os.day(),dayDigits,'0') .. ' - ' .. sto 
  return (sto)
end

function drawutils.setScreen(newScreen)
  drawutils.screen = newScreen
end


function drawutils.setBasePosition(x,y)
  drawutils.basex = x
  drawutils.basey = y
end

function drawutils.cursorPos(x, y)
  x = x or 0
  y = y or 0
  drawutils.screen.setCursorPos(x + drawutils.basex, y + drawutils.basey)
end
drawutils.setCursorPos = drawutils.cursorPos

function drawutils.getCursorPos()
  return {drawutils.screen.getCursorPosition[1] - drawutils.basex, drawutils.screen.getCursorPosition[2] - drawutils.basey}
end

function drawutils.setColor(color, bgColor)
  if type(color) == "number" or (color == nil and type(bgColor) == "number") then
    --textColor = color or math.log(drawutils.screen.getTextColor(),2)
    if color ~= nil then drawutils.screen.setTextColor(2^color) end
    if bgColor ~= nil then drawutils.screen.setBackgroundColor(2^bgColor) end
	return 1
  elseif type(color) == "table" and bgColor == nil then
    if color[1] ~= nil then drawutils.screen.setTextColor(2^color[1]) end
    if color[2] ~= nil then drawutils.screen.setBackgroundColor(2^color[2]) end
	return 2
  end
  return -1
end
function drawutils.setColour(textColour, bgColour)
  return drawutils.setColour(textColour, bgColour)
end

function drawutils.getColor()
  textColor = math.log(drawutils.screen.getTextColor(),2)
  bgColor =  math.log(drawutils.screen.getBackgroundColor(),2)
  return {textColor, bgColor}
end
function drawutils.getColour()
  return drawutils.getColor()
end

function drawutils.swapColors()
  textColor = drawutils.screen.getTextColor()
  drawutils.screen.setTextColor(drawutils.screen.getBackgroundColor())
  drawutils.screen.setBackgroundColor(textColor)
end

function drawutils.getSize()
  return {drawutils.screen.getSize()}
end

function drawutils.setFrozen(frozen)
  return drawutils.screen.setFrozen(frozen)
end
function drawutils.getFrozen()
  return drawutils.screen.getFrozen()
end


function drawutils.clear(bgColor)
  if bgColor == nil then 
    drawutils.screen.clear()
  else
    prevColor = drawutils.screen.getBackgroundColor()
    drawutils.screen.setBackgroundColor(2^bgColor)
    drawutils.screen.clear()
    drawutils.screen.setBackgroundColor(prevColor)
  end
end

drawutils.palette_grayscale = {0xffffff,0xeeeeee,0xdddddd,0xcccccc,
                               0xbbbbbb,0xaaaaaa,0x999999,0x808080,
                               0x777777,0x666666,0x555555,0x444444,
							   0x333333,0x222222,0x111111,0x000000}               
drawutils.palette_alcaro = {0xf0f0f0,0xc93333,0xe8a150,0xfce89a,
                            0x4cc933,0x3a84c8,0x744a87,0x4c4c4c,
							0x999999,0x5a2424,0x9f7334,0xd9ae5e,
							0x086211,0x0c3861,0x25194f,0x111111}
drawutils.palette_traditional = {0xf0f0f0,0xf2b233,0xe57fd8,0x99b2f2,
                                 0xdede6c,0x7fcc19,0xf2b2cc,0x4c4c4c,
								 0x999999,0x4c99b2,0xb266e5,0x3366cc,
								 0x7f664c,0x57a64e,0xcc4c4c,0x111111}
drawutils.palette_ember0 = {0xfeb63c,0xd5640d,0xae2e14,0x772315,
                            0x4d120a,0x3a0d07,0x260508,0x100400,
                            0xffffff,0xcccccc,0xaaaaaa,0x999999,
							0x777777,0x555555,0x333333,0x000000}
function drawutils.setPalette(palette)
  for i, colr in ipairs(palette) do
	if type(palette[i]) == "string" then palette[i] = tonumber('0x'..palette[i]) end
    drawutils.screen.setPaletteColor(2^(i-1),palette[i])
   end
end

function drawutils.write(text, x, y, width)
  -- prints the given text at (x,y). Provide a width to automatically trim / add space.
  x = x or 0
  y = y or 0
  width = width or #text
  drawutils.cursorPos(x,y)
  drawutils.screen.write(fitLeft(text,width))
end

function drawutils.writeList(textList, x , y, width)
  -- prints each item in the list as a new line, starting at (x,y). unless width is specified, all items will be trimmed to the length of the first item.
  x = x or 0
  y = y or 0
  width = width or #textList[1]
  for itxt, vtxt in ipairs(textList) do
    drawutils.write(vtxt, x, y + itxt - 1, width)
  end
end

function drawutils.writeColorList(textList, colorList, x , y, width)
  -- prints each item in textList on a different line, and with a different color!
  x = x or 0
  y = y or 0
  width = width or nil
  --if #textList ~= #colorList then return nil end
  local prevColor = drawutils.getColor()
  local currentColor = {}
  for itxt, vtxt in ipairs(textList) do
    if colorList[itxt] == nil then
      --currentColor = prevColor
      --drawutils.setColor(currentColor[1],currentColor[2])
    elseif currentColor ~= colorList[itxt] then
      currentColor = colorList[itxt]
      drawutils.setColor(currentColor[1],currentColor[2])
    end
    drawutils.write(vtxt, x, y + itxt - 1, width)
  end
  drawutils.setColor(prevColor[1], prevColor[2])
end

function drawutils.writeWrapped(text, x, y, width)
  -- prints text and uses VERY basic and janky methods to wrap it to a new line. defining width is REQUIRED!!!!!
  for i = 1, math.ceil(#text/width) do
    drawutils.cursorPos(x,y+(i-1))
    drawutils.screen.write(string.sub(text,1+((i-1)*width),((i)*width)) )
  end
end

function drawutils.drawBox(drawX, drawY, sizeX, sizeY, fill)
  fill = fill or string.char(127)
  sizeX = sizeX or 5
  sizeY = sizeY or 3
  for i = 0, sizeY-1 do
    drawutils.cursorPos(drawX,drawY + i)
    drawutils.screen.write(string.rep(fill,sizeX))
  end
end


function drawutils.drawGrid(content, drawX, drawY, width, marginX, marginY)
  -- reads content as a column of rows of items, printing each item in a grid pattern.
  marginX = marginX or 5
  marginY = marginY or 2
  for i, v in pairs(content) do
    drawutils.cursorPos((drawX + math.floor((i-1) % width) * marginX),(drawY + math.floor((i-1) / width) * marginY))
    drawutils.screen.write(content[i])
  end
end  

function drawutils.drawColorGrid(content, colorList, drawX, drawY, width, marginX, marginY)
  -- like drawGrid, but with colors defined per item. I made this function for one single program but I still want to keep it around.
  marginX = marginX or 5
  marginY = marginY or 2
  local prevColor = drawutils.getColor()
  local currentColor = {0,15}
  for i, v in pairs(content) do
    if colorList[i] == nil then
      currentColor = prevColor
      drawutils.setColor(currentColor[1],currentColor[2])
    elseif currentColor ~= colorList[i] then
      currentColor = colorList[i]
      drawutils.setColor(currentColor[1],currentColor[2])
    end
    drawutils.cursorPos((drawX + math.floor((i-1) % width) * marginX),(drawY + math.floor((i-1) / width) * marginY))
    drawutils.screen.write(fitLeft(content[i],marginX-1))
  end
end

function drawutils.displayCharacterMap()
  drawutils.screen.setTextColor(1)
  drawutils.screen.setBackgroundColor(2^15)
  drawutils.screen.clear()
  drawutils.screen.setCursorPos(1,1)
  drawutils.screen.write('0123456789ABCDEF ---')
  hexi = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'}
  drawutils.screen.setCursorPos(1,2)
  lineIndx = 2
  for i = 1, 256 do
    drawutils.screen.write(string.char(i-1))
    if math.fmod(i,16) == 0 then 
	    drawutils.screen.write(' '..(i-16)) 
	    lineIndx = lineIndx + 1
      drawutils.screen.setCursorPos(1,lineIndx)
	  end
  end
  drawutils.screen.setCursorPos(1,20)
  for i = 0, 15 do  drawutils.screen.blit(hexi[i+1],hexi[i+1],hexi[16]) end
  drawutils.screen.write(' ')
  drawutils.screen.setCursorPos(1,21)
  for i = 0, 15 do  drawutils.screen.blit(hexi[i+1],hexi[1],hexi[i+1]) end
end


return drawutils