-- title:  Shenzhen I/O Solitaire
-- author: Gecko05
-- desc:   Solitaire from Shenzhen I/O
-- script: lua
-- input:  mouse
-- specials: 31 41 51
piles = {{31,1,2,3,4,41},
        {5,6,7,8,9,41,41},
        {11,12,13,14,51,51},
        {15,16,17,18,19,51},
        {21,22,23,24,25,51},
        {27,28,31},
        {26,41,41,31},
        {51,31,31,61}}

endpiles = {		{},
			        {},
			        {}
			        }

tokpiles = {		{},
			        {},
			        {}
		 	        }
-- 	black, green, red
tokens = {0, 0, 0}
drag = {}
local cursor = {x = 0,y = 0,c = 0,hold = false}
local origin = {x = 0,y = 0,col = 0,isTok = 0}
local btn_red = 178
local btn_blk = 180
local btn_grn = 182

local animContext = {first = 0,move = 0,params = {0,0,0},data = {},card = 0}
-- Draw a blank card
function drawBlnkCard(x, y)
	spr(0, x,  y,   2)
	spr(1, x+8,y,   2)
	spr(16,x+0,y+8, 2)
	spr(17,x+8,y+8, 2)
	spr(32,x+0,y+16,2)
	spr(33,x+8,y+16,2)
end
-- Draw a card
function drawCard(x,y,num)
	drawBlnkCard(x, y)
	spr(num + 79,x + 2,y + 2,2)
	spr(math.floor(num/10)+144,x+4,y+8,2)
	spr(num+79,x+6,y+13,2,1,0,2)
end
--Draw blank pile
function drawSpace(x0,y0)
	spr(4, x0,  y0,   2)
	spr(5, x0+8,y0,   2)
	spr(20,x0+0,y0+8, 2)
	spr(21,x0+8,y0+8, 2)
	spr(36,x0+0,y0+16,2)
	spr(37,x0+8,y0+16,2)
end
-- Gets the number of the first empty token pile
function getEmptyTokPile()
	local next = next
	for i,p in ipairs(tokpiles) do
		if next(tokpiles[i]) == nil then 
			return i
		end 
	end 
	return nil
end 

-- Check if cards have different color
function isDifColor(num0, num1)
	if num0 ~= nil and num1 ~= nil then
		res0 = math.floor(num0/10)
		res1 = math.floor(num1/10)
		if res0 == res1 then
			return false
		end
		return true
	end
	return false
end
-- Check if 1st card is bigger than 2nd one
function isOrdered(num0,num1)
	if num0 == nil then
		return true
	end
	if isDifColor(num0,num1) then
		n0 = num0 % 10
		n1 = num1 % 10
		if n0 - n1 == 1 then
			return true
		end
	end
	return false
end
-- Check if the card is draggable
function isDraggable(c,r)
 if piles[c] == nil or piles[c][r] == nil then
		return false
	end
	n = 1
	while piles[c][r+n]~=nil do
		num = piles[c][r+n]
		if isOrdered(piles[c][r+n-1],num)==false  then
			return false
		end
		n = n + 1
	end
	return true
end

function drawTokenPiles()
	-- Draw token piles
	for i,col in ipairs(tokpiles) do
		if #col == 0 then
			drawSpace((i*18) + 30, 10)
		else 
			for j,num in ipairs(col) do
				x = (i * 18) + 30
				drawCard(x,10,num)
			end
		end
	end
end

function drawNormalPiles()
	-- Draw normal piles
	for i,col in ipairs(piles) do
		if #col == 0 then
			drawSpace((i*18)+30, 36)
		else 
			for j,num in ipairs(col) do
				x = (i * 18) + 30
				y = (j * 6) + 30
				drawCard(x,y,num)
			end
		end
	end
end

function drawEndPiles()
	-- Draw end piles
	for i,col in ipairs(endpiles) do
		if #col == 0 then
			drawSpace((i*18) + 102, 10)
		else 
			for j,num in ipairs(col) do
				x = (i * 18) + 102
				drawCard(x,10,num)
			end
		end
	end
end 

-- Draw cards in piles
function drawCards()
	drawNormalPiles()
	drawTokenPiles()
	drawEndPiles()
	drawDrag(cursor.x - origin.x,cursor.y - origin.y)
end

function drawDrag(x,y)
	if #drag > 0 then
		for i,c in pairs(drag) do
			drawCard(x,y,c)
			y = y + 6
		end
	end
end

function drawButtons()
	spr(btn_blk-(tokens[1]),102,10,2)
	spr(btn_blk+1-(tokens[1]),110,10,2)
	spr(btn_grn-(tokens[2]),102,18,2)
	spr(btn_grn+1-(tokens[2]),110,18,2)
	spr(btn_red-(tokens[3]),102,26,2)
	spr(btn_red+1-(tokens[3]),110,26,2)
end

function draw()
	cls(12)
	drawButtons()
	drawCards()
end

-- Functions to move cards between piles
function moveHandToPile(pile)
	while drag[1] ~= nil do
		table.insert(pile,drag[1])
		table.remove(drag,1)
	end
end

function moveCardToPile(pile0,n,pile1)
	if pile0[n] == nil then
		return
	end
	table.insert(pile1,pile0[n])
	table.remove(pile0,n)
end

function moveStackToHand(pile,n)
	while pile[n] ~= nil do
		table.insert(drag,pile[n])
		table.remove(pile,n)
	end
end

function getAnimParams(cardParams)
	local x0 = cardParams[1]*18 + 30 -- pile0n
	local y0 = cardParams[4]*6 + 30 -- cardnum
	local x1 = 0
	if cardParams[3] == 1 then 
		x1 = cardParams[2]*18 + 30 -- pile1n
	elseif cardParams[3] == 2 then
		x1 = cardParams[2]*18 + 102 -- pile1n
	end
	local y1 = 10
	local xd = (x0 - x1) / 5
	local yd = (y0 - y1) / 5
	return {x0,y0,x1,y1,xd,yd}
end

function animateCards()
	-- variable params hold the data of the card to move with animation 
	-- params = {originPileNum,
	--			 cardNum,
	--  		 destPileNum,
	--			 TokPile?,
	--			 } 
	-- Start of animation
	local anim = animContext
	local params = anim.params
	local data = anim.data
	if anim.first == 0 then 
		anim.data = getAnimParams(params)
		anim.card = piles[params[1]][params[4]]
		table.remove(piles[params[1]], params[4])
		anim.first = anim.first + 1
	else -- Animation "cycle"
		if anim.first < 5 then 
			data[1] = data[1] -	data[5]
			data[2] = data[2] - data[6]
			drawCard(data[1],data[2],data) -- draw the anim card
			anim.first = anim.first + 1
		else
			if params[3] == 1 then 
				table.insert(tokpiles[params[2]],anim.card)
			elseif params[3] == 2 then
				table.insert(endpiles[params[2]],anim.card)
			end
			anim.move = 0
		end 
	end
end

function updateButtons()
	local valSum = {0,0,0,0}
	-- Check for uncovered tokens in normal piles
	for k,vpile in pairs(piles) do
		if #vpile > 0 then 
			compVal = (vpile[#vpile] - 1)/10 - 2
			if valSum[compVal] ~= nil then
				valSum[compVal] = valSum[compVal] + 1
			end 
		end
	end
	-- Check for uncovered tokens in token piles
	for k,vpile in pairs(tokpiles) do
		if #vpile > 0 then 
			compVal = (vpile[#vpile] - 1)/10 - 2
			if valSum[compVal] ~= nil then
				valSum[compVal] = valSum[compVal] + 1
			end 
		end 
	end
	-- Check the uncovered cards for every token to
	-- change the token buttons
	for i,v in ipairs(valSum) do
		if v == 4 and getEmptyTokPile() ~= nil then
			tokens[i] = 16
		end 
	end
end

function isClicking()
	return (cursor.hold == false and cursor.c)
end

function getSelCardPos()
	selectedCol = math.floor((cursor.x - 30)/18)
	-- Get index of last card in pile
	if piles[selectedCol] ~= nil then 
		lastCard = #piles[selectedCol]
	else
		lastCard = nil
		return nil,nil
	end
	-- Get ranges to check if selecting last card
	maxy = 36 + ((lastCard - 1) * 6) + 23
	miny = 36 + ((lastCard - 1) * 6)
	-- check if dragging last card
	if cursor.y > miny and cursor.y < maxy then
		selectedCard = lastCard
	else
		selectedCard = math.floor((cursor.y - 30)/6)
	end
	return selectedCol,selectedCard
end

function isDraggingTokPiles()
	return cursor.y > 10 and cursor.y < 34 and tokpiles[col] ~= nil
end

function update() 
	-- Check for unblocked tokens
	updateButtons()
	-- DRAG / Click
	cursor.x,cursor.y,cursor.c = mouse()
	if isClicking() then
		cursor.hold = true
		local col,card = getSelCardPos()
		-- Check if dragging from token piles
		if isDraggingTokPiles() then
			origin.x = cursor.x - (col*18 + 30)
			origin.y = cursor.y - (10)
			table.insert(drag,tokpiles[col][1])
			table.remove(tokpiles[col],1)
			origin.isTok = 1
			origin.col = col
		-- Check if card is draggable
		elseif isDraggable(col,card) then
			origin.x = cursor.x - (col*18 + 30)
			origin.y = cursor.y - (card*6 + 30)
			moveStackToHand(piles[col],card)
			origin.isTok = 0
			origin.col = col
		end
		-- check for token buttons
		if cursor.y > 10 and cursor.y < 34 and cursor.x > 103 and cursor.x < 117 then
			btnNum = (cursor.y - 10)//8 + 1
			if tokens[btnNum] == 16 then 
				tokens[btnNum] = 0
			end
		end
	end
	if cursor.hold == true then
		-- DROP
		if cursor.c == false then
			local col = math.floor((cursor.x - 30)/18)
			--card = math.floor((cursor.y - 30)/6)
			-- Dropping on token piles
			if cursor.y > 10 and cursor.y < 34 and #drag == 1 and tokpiles[col]~=nil and isOrdered(tokpiles[col][1],drag[1]) then 
				moveHandToPile(tokpiles[col])
			-- Dropping on a pile 
			elseif piles[col]~=nil then
				if isOrdered(piles[col][#piles[col]],drag[1]) then
					moveHandToPile(piles[col])
				elseif #drag > 0 then
					if origin.isTok == 1 then
						moveHandToPile(tokpiles[origin.col])
					else
						moveHandToPile(piles[origin.col])
					end
				end
			-- Dropping elsewhere
			elseif #drag > 0 then
				if origin.isTok == 1 then
					moveHandToPile(tokpiles[origin.col])
				else
					moveHandToPile(piles[origin.col])
				end
			end
			cursor.hold = false
		end
	end
end
----------------------------------------

function init()
	--music(0,0,23,true)
end

init()

function TIC()
	if  animContext.move == 0 then 
		update()
		draw()
	else
		animateCards()
		draw()
	end
end
