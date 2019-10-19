-- title:  Shenzhen I/O Solitaire
-- author: Gecko05
-- desc:   Solitaire from Shenzhen I/O
-- script: lua
-- input:  mouse
-- specials: 31 41 51
local piles = {{31,1,2,3,4,41},
        {5,6,7,8,9,41,41},
        {11,12,13,14,51,51},
        {15,16,17,18,19,51},
        {21,22,23,24,25,51},
        {27,28,31},
        {26,41,31},
        {31,31,61}}

local endpiles = {		{},
			        {},
			        {}
			        }

local tokpiles = {		{},
			        {},
			        {}
		 	        }
local flowerPile = {}
-- 	black, green, red
local tokenBtns = {0, 0, 0}
local drag = {}
local cursor = {x = 0,y = 0,c = 0,hold = false}
local origin = {x = 0,y = 0,col = 0,isTok = 0}
local btn_red = 178
local btn_blk = 180
local btn_grn = 182
local animContext = {x0 = 0,y0 = 0,x1 = 0,y1 = 0,xd = 0,yd = 0}
local animationQueue = {}

------------------------------ D R A W I N G -----------------------------

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

--Draw blank flower pile
function drawFlowerSpace(x0,y0)
	spr(6, x0,  y0,   2)
	spr(7, x0+8,y0,   2)
	spr(22,x0+0,y0+8, 2)
	spr(23,x0+8,y0+8, 2)
	spr(38,x0+0,y0+16,2)
	spr(39,x0+8,y0+16,2)
end

function drawPiledCard(x, y)
	spr(2, x,  y,   2)
	spr(3, x+8,y,   2)
	spr(18,x+0,y+8, 2)
	spr(19,x+8,y+8, 2)
	spr(34,x+0,y+16,2)
	spr(35,x+8,y+16,2)
end

function drawTokenPiles()
	-- Draw token piles
	for i,col in ipairs(tokpiles) do
		if #col <= 0 then
			drawSpace((i*18) + 30, 10)
		elseif #col < 4 then
			for j,num in ipairs(col) do
				x = (i * 18) + 30
				drawCard(x,10,num)
			end
		else
			drawPiledCard((i*18) + 30, 10)
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

function drawFlowerPile()
	if #flowerPile == 0 then
		drawFlowerSpace(120, 10)
	else
		drawCard(120,10,61)
	end
end

function drawEndPiles()
	-- Draw end piles
	for i,col in ipairs(endpiles) do
		if #col == 0 then
			drawSpace((i*18) + 120, 10)
		else 
			for j,num in ipairs(col) do
				x = (i * 18) + 120
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
	drawFlowerPile()
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
	spr(btn_blk-(tokenBtns[1]),102,10,2)
	spr(btn_blk+1-(tokenBtns[1]),110,10,2)
	spr(btn_grn-(tokenBtns[2]),102,18,2)
	spr(btn_grn+1-(tokenBtns[2]),110,18,2)
	spr(btn_red-(tokenBtns[3]),102,26,2)
	spr(btn_red+1-(tokenBtns[3]),110,26,2)
end

--------------------------- C A R D   P L A C I N G ----------------------

function getEmptyTokPile()
	local next = next
	for i,p in ipairs(tokpiles) do
		if next(tokpiles[i]) == nil then 
			return i
		end 
	end 
	return nil
end 

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

function isDraggingTokPiles(col)
	return (cursor.y > 10 and cursor.y < 34 
			and tokpiles[col] ~= nil and #tokpiles[col] == 1)
end

function isTokenDropAvailable(col)
	return (cursor.y > 10 and cursor.y < 34 and #drag == 1 
			and tokpiles[col]~=nil and isOrdered(tokpiles[col][1],drag[1]))
end

function dragCardFromTokPiles(col)
	origin.x = cursor.x - (col*18 + 30)
	origin.y = cursor.y - (10)
	table.insert(drag,tokpiles[col][1])
	table.remove(tokpiles[col],1)
	origin.isTok = 1
    origin.col = col
end

function dragStack(col,card)
	origin.x = cursor.x - (col*18 + 30)
	origin.y = cursor.y - (card*6 + 30)
	moveStackToHand(piles[col],card)
	origin.isTok = 0
	origin.col = col
end

function checkForFlower()
	for i,pile in ipairs(piles) do
		lastCard = #pile
		if pile[lastCard] == 61 then
			newAnimation(61,i,1,0,3)
		end
	end
end

-------------------------------- B U T T O N S --------------------------

function isPressingButton()
	return cursor.y > 10 and cursor.y < 34 and cursor.x > 103 and cursor.x < 117
end

function isButtonOn(btnNumber)
	return tokenBtns[btnNumber] == 16
end

function setButtonState(btnNumber, state)
	state = 16 * state
	tokenBtns[btnNumber] = state
end

function getButtonNum()
	return (cursor.y - 10)//8 + 1
end

function getTokenIndex(num)
	return (num - 1)/10 - 2
end

function isPileAvailable(num)
	local token = ((num + 2) * 10) + 1
	for i,pile in ipairs(tokpiles) do
		if pile[1] == token then
			return i
		end
	end
	return getEmptyTokPile()
end

function updateButtons()
	local tokReps = {0,0,0,0}
	-- Check for uncovered tokens in normal piles
	for i,pile in ipairs(piles) do
		local frontCard = pile[#pile]
		if frontCard ~= nil then 
			toki = getTokenIndex(frontCard)
			if tokReps[toki] ~= nil then
				tokReps[toki] = tokReps[toki] + 1
			end
		end
	end
	-- Check for uncovered tokens in token piles
	for i,pile in ipairs(tokpiles) do
		local frontCard = pile[1]
		if frontCard ~= nil then 
			toki = getTokenIndex(frontCard)
			if tokReps[toki] ~= nil then
				tokReps[toki] = tokReps[toki] + 1
			end 
		end 
	end
	-- Check the repetitions to activate token buttons
	for i,reps in ipairs(tokReps) do
		if reps == 4 and isPileAvailable(i) ~= nil then
			tokenBtns[i] = 16
		end 
	end
end

----------------------------- A N I M A T I O N S ----------------------

function getAnimParams(params)
	local x0 = params.orig*18 + 30 -- pile0n
	pile = piles[params.orig]
	lastCard = #pile
	local y0 = nil	-- last card's position in Y
	if params.pileType == 0 then
		y0 = lastCard*6 + 30 
	elseif params.pileType == 1 then
		y0 = lastCard*6 + 10
	end
	local x1 = 0
	if params.token == 1 then 
		x1 = params.dest*18 + 30 -- to Token Piles
	elseif params.token == 2 then
		x1 = params.dest*18 + 120 -- to End piles
	elseif params.token == 3 then
		x1 = 120 -- to Flower pile
	end
	local y1 = 10
	local xd = (x0 - x1) / 10
	local yd = (y0 - y1) / 10
	return x0,y0,x1,y1,xd,yd
end

function newAnimation(card, origPile, destPile, pileType, token)
	local animation = {card = card, orig = origPile, dest = destPile,
					   state = 0, pileType = pileType, token = token}
	table.insert(animationQueue,animation)
end

function playDrawSound()
	sfx(1,'G#1',3,0,10,2)
end

function pileTokens(tokenNum)
	local tokenCard = ((tokenNum + 2) * 10) + 1
	local pilePos = nil
	local cardPositions = {}
	local tokenPositions = {}
	-- Check if a token is already in a token pile
	for i,pile in ipairs(tokpiles) do
		if pile[1] == tokenCard and pilePos == nil then
			pilePos = i
		elseif pile[1] == tokenCard then
			table.insert(tokenPositions,i)
		end
	end
	-- Get an empty pile for tokens
	if pilePos == nil then 
		pilePos = getEmptyTokPile()
	end
	if pilePos == nil then
		return
	end
	-- Get the piles where every token is uncovered
	for i,pile in ipairs(piles) do
		local lastCard = #pile
		if #pile == 0 then
			break
		end
		if pile[lastCard] == tokenCard then 
			table.insert(cardPositions,i)
		end
	end
	for i,pile in ipairs(tokenPositions) do
		newAnimation(tokenCard,pile,pilePos,1,1)
	end
	for i,pile in ipairs(cardPositions) do
		newAnimation(tokenCard,pile,pilePos,0,1)
	end
end
----------------------------------------------------------------------
function DRAW()
	cls(12)
	drawButtons()
	drawCards()
end

function ANIMATE()
	-- Get current element to animate
	local anim = animationQueue[1]
	local context = animContext
	-- Start of animation
	if anim.state == 0 then 
		context.x0,context.y0,context.x1,
		context.y1,context.xd,context.yd = getAnimParams(anim)
		local pile = nil
		if anim.pileType == 0 then
			pile = piles[anim.orig]
		elseif anim.pileType == 1 then
			pile = tokpiles[anim.orig]
		end
		lastCard = #pile
		table.remove(pile, lastCard)
		anim.state = 1
		playDrawSound()
	else -- Animation cycle
		if anim.state < 10 then
			local x0 = context.x0
			local y0 = context.y0
			local xd = context.xd
			local yd = context.yd
			context.x0 = x0 - xd
			context.y0 = y0 - yd
			drawCard(context.x0,context.y0,anim.card)
			anim.state = anim.state + 1
		else
			if anim.token == 1 then 
				table.insert(tokpiles[anim.dest],anim.card)
			elseif anim.token == 2 then
				table.insert(endpiles[anim.dest],anim.card)
			elseif anim.token == 3 then
				table.insert(flowerPile,anim.card)
			end
			-- Remove processed animation from queue
			table.remove(animationQueue, 1)
		end
	end
end

function UPDATE() 
	-- Check for unblocked tokens
	updateButtons()
	checkForFlower()
	-- DRAG / Click
	cursor.x,cursor.y,cursor.c = mouse()
	if isClicking() then
		cursor.hold = true
		local col,card = getSelCardPos()
		if isDraggingTokPiles(col) then
			dragCardFromTokPiles(col)
		elseif isDraggable(col,card) then
			dragStack(col,card)
		end
		-- Check if a button is being clicked
		if isPressingButton() then
			local btnNum = getButtonNum()
			if isButtonOn(btnNum) then 
				setButtonState(btnNum, 0)
				pileTokens(btnNum)
			end
		end
	end
	if cursor.hold == true then
		-- DROP
		if cursor.c == false then
			local col = math.floor((cursor.x - 30)/18)
			--card = math.floor((cursor.y - 30)/6)
			if isTokenDropAvailable(col) then 
				moveHandToPile(tokpiles[col])
			-- Dropping on a pile 
			elseif piles[col]~=nil then
				if isOrdered(piles[col][#piles[col]],drag[1]) then
					moveHandToPile(piles[col])
				-- Return to origin if can't drop
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
			-- End of hold
			cursor.hold = false
		end
	end
end
------------------------------------------------------------------------

function init()
	--music(0,0,0,true)
end

init()

function TIC()
	if  #animationQueue == 0 then 
		UPDATE()
		DRAW()
	else
		DRAW()
		ANIMATE()
	end
end
