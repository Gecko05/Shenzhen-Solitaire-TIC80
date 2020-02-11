-- title:  Shenzhen I/O Solitaire
-- author: Gecko05
-- desc:   Solitaire from Shenzhen I/O
-- script: lua
-- input:  mouse
-- specials: 31 41 51
local piles = {{},
        {},
        {},
        {},
        {},
        {},
        {},
        {}}
		
local loadPiles = {{4,3,2,1,41},
        {9,8,7,6,5,41,41},
        {14,13,12,11,51,51},
        {19,18,17,16,15,51},
        {25,24,23,22,21,51},
        {29,28,27,31},
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
local pileCount = 1
local victory = false
local winCount = 0
local elapsed = 0
local intro = 0
local firstTime = 0
local insCount = 0
-- Timing
local elapsedTime = 0
local timer1

function resetTimer()
	elapsedTime = time()
end

function getElapsedTime()
	return time() - elapsedTime
end

------------------------------ D R A W I N G -----------------------------

-- Card dimensions 16 pixels x 32 pixels
function drawBlnkCard(x, y)
	spr(256,x,y,2,1,0,0,3,5)
end

function drawCard(x,y,num)
	drawBlnkCard(x, y)
	spr(num + 79,x + 2,y + 2,2)
	spr(math.floor(num/10)+144,x+6,y+14,2)
	spr(num+79,x+9,y+25,2,1,0,2)
end

function drawSpace(x,y)
	spr(259,x,y,2,1,0,0,3,5)
end

function drawTokSpace(x,y)
	spr(265,x,y,2,1,0,0,3,5)
end

function drawFlowerSpace(x,y)
	spr(262,x,y,2,1,0,0,3,5)
end

function drawPiledCard(x, y)
	spr(336,x,y,2,1,0,0,3,5)
end

function drawTokenPiles()
	-- Draw token piles
	for i,col in ipairs(tokpiles) do
		if #col <= 0 then
			drawTokSpace((i*24) + 2, 0)
		elseif #col < 4 then
			for j,num in ipairs(col) do
				x = (i * 24) + 2
				drawCard(x,0,num)
			end
		else
			drawPiledCard((i*24) + 2, 0)
		end
	end
end

function drawNormalPiles()
	-- Draw normal piles
	for i,col in ipairs(piles) do
		if #col == 0 then
			drawSpace((i*24 + 2), 38)
		else 
			for j,num in ipairs(col) do
				x = (i * 24 + 2)
				y = (j * 6) + 31
				drawCard(x,y,num)
			end
		end
	end
end

function drawFlowerPile()
	if #flowerPile == 0 then
		drawFlowerSpace(117, 0)
	else
		lastCard = flowerPile[#flowerPile]
		drawCard(117,0,lastCard)
	end
end

function drawEndPiles()
	-- Draw end piles
	for i,col in ipairs(endpiles) do
		if #col == 0 then
			drawTokSpace((i*24) + 122, 0)
		else 
			for j,num in ipairs(col) do
				x = (i * 24) + 122
				drawCard(x,0,num)
			end
		end
	end
end 

-- Draw cards in piles
function drawCards()
	drawTokenPiles()
	drawEndPiles()
	drawFlowerPile()
	drawNormalPiles()
	drawDrag(cursor.x - origin.x,cursor.y - origin.y)
end

function drawDrag(x,y)
	if #drag > 0 then
		for i,c in ipairs(drag) do
			drawCard(x,y,c)
			y = y + 6
		end
	end
end

function drawButtons()
	-- x 98 Y 1?
	spr(btn_blk-(tokenBtns[1]),95,4,2,1,0,0,2,1)
	spr(btn_grn-(tokenBtns[2]),95,14,2,1,0,0,2,1)
	spr(btn_red-(tokenBtns[3]),95,24,2,1,0,0,2,1)
end

function drawButtonsAt(x,y)
	spr(btn_blk-(tokenBtns[1]),x,y,2,1,0,0,2,1)
	spr(btn_grn-(tokenBtns[2]),x,y+10,2,1,0,0,2,1)
	spr(btn_red-(tokenBtns[3]),x,y+20,2,1,0,0,2,1)
end

function printScore()
	local c = winCount // 100
	local d = (winCount // 10) % 10
	local u = winCount % 10
	if c > 0 then
		c = getNumSprite(c)
		spr(c,29,126,2)
	end
	if d > 0 then
		d = getNumSprite(d)
		spr(d,33,126,2)
	end
	u = getNumSprite(u)
	spr(u,37,126,2)
	spr(214,198,126,2,1,0,0,4,1)
	spr(230,137,124,2,1,0,0,6,1)
	spr(249,12,127,2,1,0,0,2,1)
end

function drawTL()
	local x = 34
	drawCard(x,6,29)
	drawCard(x+21,6,19)
	drawCard(x+42,6,9)
	print("TO WIN,STACK THE THREE SUITS\n FROM 1 TO 9 IN THE TOP-RIGHT",
	14,45,15,false,1,true)
end

function drawBL()
	local x = 30
	drawCard(x,65,51)
	drawCard(x+21,65,13)
	drawTokSpace(x+42,65)
	drawButtonsAt(x+64,68)
	print("THE FREE CELLS IN THE TOP-LEFT\nCAN STORE ONE CARD OF ANY TYPE",
	11,104,15,false,1,true)
end

function drawTR()
	local exPile = {16,25,4,23}
	for i,card in ipairs(exPile) do
		drawCard(130,i*6-5,card)
	end
	for i = 1,3,1 do
		drawSpace(i*22+130,1)
	end
	print("         STACK CARDS\nALTERNATING SUITS AND\n    DECREASING VALUES",
	151,40,15,false,1,true)
end

function drawBR()
	local exPile = {51,51,51,51}
	for i,card in ipairs(exPile) do
		drawCard(125+i*6,65,card)
	end
	drawPiledCard(200,65)
	print("    FOUR MATCHING DRAGONS\nCAN BE MOVED TO A FREE CELL\n   BY PUSHING THEIR BUTTON",
	130,102,15,false,1,true)
end

function drawInstructions()
	map(30,1)
	printScore()
-- Draw each four quadrants
	drawTL()
	drawBL()
	drawTR()
	drawBR()
	cursor.x,cursor.y,cursor.c = mouse()
	if isClicking() then
		if isPressingInstructions() and intro == 2 then
			intro = 1
		end
		cursor.hold = true 
	elseif cursor.c == false then
		cursor.hold = false
	end
end

--------------------------- C A R D   P L A C I N G ----------------------

function getCardNumber(card)
	-- valid card to get number
	if card ~= nil and card < 30 then
		return card % 10
	end
	return -1
end

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
	if num1 == 31 or num1 == 41 or num1 == 51 then
		return false
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
	while drag[1] ~= nil and pile ~= nil do
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
	return (cursor.hold == false and cursor.c == true)
end

function getSelCol()
	local hit = 0
	local selectedCol = 0
	-- Check if the x position matches any columns
	local x = cursor.x - 26
	for i=1,8,1 do
		local border = (i - 1) * 24
		if x > border and x < border + 18 then
			selectedCol = i
		end
	end
	return selectedCol
end

function getSelCardPos()
	local hit = 0
	local selectedCol = 0
	-- Check if the x position matches any columns
	local x = cursor.x - 26
	for i=1,8,1 do
		local border = (i - 1) * 24
		if x > border and x < border + 18 then
			hit = 1
			selectedCol = i
		end
	end
	if hit ~= 1 then
		-- no columns selected
		return nil,nil
	end
	
	-- Get index of last card in pile
	if piles[selectedCol] ~= nil then 
		lastCard = #piles[selectedCol]
	else
		lastCard = nil
		return nil,nil
	end
	-- Get ranges to check if selecting last card
	maxy = 31 + (lastCard * 6) + 35
	miny = 31 + (lastCard * 6)
	-- check if dragging last card
	if cursor.y > miny and cursor.y < maxy then
		selectedCard = lastCard
	else
		selectedCard = (cursor.y - 31)//6
	end
	return selectedCol,selectedCard
end

function isDraggingTokPiles(col)
	return (cursor.y > 2 and cursor.y < 37 
			and tokpiles[col] ~= nil and #tokpiles[col] == 1)
end

function isTokenDropAvailable(col)
	return (cursor.y > 2 and cursor.y < 37 and #drag == 1 
			and tokpiles[col]~=nil and isOrdered(tokpiles[col][1],drag[1]))
end

function isEndDropAvailable(col)
	if cursor.x < 146 or cursor.x > 218 or cursor.y < 2 
		or cursor.y > 37 or #drag ~= 1 or col == nil or endpiles[col-5] == nil then
		return false
	end
	col = col - 5
	local lastCard = endpiles[col][#endpiles[col]]
	local endIndex = (drag[1] // 10) + 1
	local res = (((lastCard == nil and ((drag[1]%10) == 1))
			or (lastCard ~= nil and ((drag[1] - lastCard) == 1)))
			and endIndex == col)
	return res
end

function dragCardFromTokPiles(col)
	origin.x = cursor.x - (col*24 + 2)
	origin.y = cursor.y - (2)
	table.insert(drag,tokpiles[col][1])
	table.remove(tokpiles[col],1)
	origin.isTok = 1
    origin.col = col
end

function dragStack(col,card)
	origin.x = cursor.x - (col*24 + 2)
	origin.y = cursor.y - (card*6 + 31)
	moveStackToHand(piles[col],card)
	origin.isTok = 0
	origin.col = col
end

function getCardSuit(card)
	return (card // 10) + 1
end

function updateEndPiles()
	local reps = {0,0,0}
	local repsNum = 0
	local pilenumber = 0
	-- Count cards in endpiles to update pileCounter 
	local minim = 10
	for i,pile in ipairs(endpiles) do
		if pile[#pile] ~= nil then 
			local card = pile[#pile]
			local val = card % 10
			if val < minim then
				minim = val + 1
			end
		else
			minim = 1
		end
	end
	pileCount = minim
	-- Check for cards that are already in endpiles
	for i,pile in ipairs(endpiles) do
		if pile[pileCount] ~= nil and pile[pileCount] % 10 == pileCount then
			repsNum = repsNum + 1
		end
	end
	-- Check for cards that are already in standard piles
	for i,pile in ipairs(piles) do
		pilenumber = pilenumber + 1
		local lastCardNum = #pile
		local lastCard = getCardNumber(pile[lastCardNum])
		if pile[lastCardNum] == 61 and #drag == 0 then
			newAnimation(61,i,1,0,3)
		elseif (lastCard == 1 or lastCard == 2) and #drag == 0 then
			color = getCardSuit(pile[lastCardNum])
			if #endpiles[color] >= lastCard-1 then
				newAnimation(pile[lastCardNum],i,color,0,2)
			end
		elseif lastCard == pileCount and #drag == 0 then
			color = getCardSuit(pile[lastCardNum])
			reps[color] = pilenumber
			repsNum = repsNum + 1
		end
	end
	-- Check for auto-moving uncovered cards to endpiles
	if repsNum == 3 then
		for i=1,3,1 do
			if reps[i] ~= 0 and #drag == 0 then
				newAnimation(pileCount + ((i-1)*10),reps[i],i,0,2)
			end
		end
	end
	-- Check if tokens are complete
	completeToks = #tokpiles[1] + #tokpiles[2] + #tokpiles[3]
	if pileCount > 9 and #flowerPile == 1 and completeToks == 12 then
		if victory == false then 
			winCount = winCount + 1
			victory = true
		end
	end
end

function hasCardSpawned(card,deck)
	for i,c in ipairs(deck) do
		if c == card then
			return true
		end
	end
	return false
end

function createNewGame()
	piles = {{},{},{},{},{},{},{},{}}
	tokpiles = {{},{},{}}
	endpiles = {{},{},{}}
	flowerPile = {}
	victory = false
	pileCount = 1
	for i=1,27,1 do
		local card = math.random(1,29)
		while hasCardSpawned(card,flowerPile) or card == 10 or card == 20 do
			card = math.random(1,29)
		end
		table.insert(flowerPile,card)
	end
	local i = math.random(1,27)
	table.insert(flowerPile,i,61)
	for i=1,4,1 do
		i = math.random(1,27)
		table.insert(flowerPile,i,31)
		table.insert(flowerPile,i,41)
		table.insert(flowerPile,i,51)
	end
	local col = 1
	for i=#flowerPile,1,-1 do
		newAnimation(flowerPile[i], 1, col, 1, 0)
		if col >= 8 then
			col = 1
		else
			col = col + 1
		end
	end
end

function getNumSprite(number)
	local a = (number // 4) * 16
	local b = number % 4
	return a + b + 152
end

-------------------------------- B U T T O N S --------------------------

function isPressingButton()
	if cursor.x < 95 or cursor.x > 111 then 
		return false
	end
	for i=0,2,1 do
		local btnStart = i * 10 + 4
		if cursor.y >= btnStart and cursor.y <= btnStart + 8 then
			return true
		end
	end
	return false
end

function isButtonOn(btnNumber)
	return tokenBtns[btnNumber] == 16
end

function setButtonState(btnNumber, state)
	state = 16 * state
	tokenBtns[btnNumber] = state
end

function getButtonNum()
	local num = 0
	for i=0,2,1 do
		local btnStart = i * 10 + 4
		if cursor.y >= btnStart and cursor.y <= btnStart + 8 then
			num = i + 1
		end
	end
	return num
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
	if #drag ~= 0 then
		return
	end
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

function isPressingInstructions()
	if cursor.x > 128 and cursor.x < 192
	and cursor.y > 121 and cursor.y < 132 then
		return true 
	end
	return false
end

function isPressingNewGame()
	if cursor.x > 198 and cursor.x < 246 
	and cursor.y > 121 and cursor.y < 132 then
		return true 
	end
	return false
end

----------------------------- A N I M A T I O N S ----------------------

function getAnimParams(params)
	local x0 = params.orig*24 + 2 -- pile from origin
	if params.token == 0 then
		local temp = params.orig + 4
		x0 = temp*24 + 2
	end
	local pile = piles[params.orig]
	lastCard = #pile
	local y0 = nil	-- last card's position in Y
	if params.pileType == 0 then	-- From normal pile
		y0 = lastCard*6 + 31 
	elseif params.pileType == 1 then -- From Upper pile
		y0 = lastCard*6 + 10
	end
	local x1 = 0
	if params.token == 1 then 
		x1 = params.dest*24 + 2 -- to Token Piles
	elseif params.token == 2 then
		x1 = params.dest*24 + 122 -- to End piles
	elseif params.token == 3 then
		x1 = 117 				 -- to Flower pile
	elseif params.token == 0 then
		x1 = params.dest*24 + 2 -- to Normal pile
	end
	local y1 = 2
	if params.token == 0 then 
		local pileLen = piles[params.dest]
		local pileLen = #pileLen
		y1 = 31 + (6*pileLen)
	end
	local xd = (x0 - x1) / 8
	local yd = (y0 - y1) / 8
	return x0,y0,x1,y1,xd,yd
end

function newAnimation(card, origPile, destPile, pileType, token)
	local animation = {card = card, orig = origPile, dest = destPile,
					   state = 0, pileType = pileType, token = token}
	table.insert(animationQueue,animation)
end

function playDrawSound()
	sfx(1,'G-7',3,0,5,2)
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
		if pile[lastCard] == tokenCard and #pile ~= 0 then 
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

local trackId = 1
local trackN = 2
local trackLen = {24000,3000}
local trackRep = {3,2}
local trackCount = 0
local timerM

function playMusic()
	timerM = getElapsedTime()
	if timerM > trackLen[trackId] then
		resetTimer()
		if trackCount > trackRep[trackId] then
			trackId = trackId + 1
			if trackId > trackN then
				trackId = 1
			end
			trackCount = 0
		end
		music(trackId-1,0,0,false)
		trackCount = trackCount + 1
	end
end

-------------------------------- M U S I C ----------------------------

function DRAW()
	--cls(12)
	map()
	drawButtons()
	printScore()
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
		if anim.token == 0 then
			pile = flowerPile
		end
		lastCard = #pile
		table.remove(pile, lastCard)
		anim.state = 1
		playDrawSound()
	else -- Animation cycle
		if anim.state < 8 then
			local x0 = context.x0
			local y0 = context.y0
			local xd = context.xd
			local yd = context.yd
			context.x0 = x0 - xd
			context.y0 = y0 - yd
			drawCard(context.x0,context.y0,anim.card)
			anim.state = anim.state + 1
		else
			if anim.token == 0 then
				table.insert(piles[anim.dest],anim.card)
			elseif anim.token == 1 then 
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

-------------------------------- C O R E ------------------------------

function UPDATE() 
	-- Check for unblocked tokens
	updateButtons()
	updateEndPiles()
	-- DRAG / Click
	cursor.x,cursor.y,cursor.c = mouse()
	if isClicking() then
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
		elseif isPressingNewGame() then
			createNewGame()		
		elseif isPressingInstructions() then
			if intro == 1 then
				intro = 2
			end
		end
		cursor.hold = true
	elseif cursor.hold == true then
		-- DROP
		if cursor.c == false then
			local col = getSelCol()
			if isTokenDropAvailable(col) then 
				moveHandToPile(tokpiles[col])
			elseif isEndDropAvailable(col) then
				moveHandToPile(endpiles[col - 5])
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

function INTRO(loadTime)
	cls(0)
	x = 80
	y = 54
	spr(156,x,y,-1,1,0,0,2,2)
	spr(158,x+17,y,-1,1,0,0,2,2)
	spr(188,x+35,y-1,-1,1,0,0,2,2)
	spr(190,x+52,y-1,-1,1,0,0,2,2)
	print("CONCEPT OPERATING SYSTEM",69,72,15,false,1,true)
	rect(83,84,60,2,3)
	local loading = loadTime / 1100
	rect(83,84,60,2,3)
	rect(83,84,math.floor(60 * loading),2,15)
end
------------------------------------------------------------------------

function init()
	elapsed = time()
	createNewGame()
end

init()
function TIC()
	--drawInstructions()
	if intro == 0 then
		timer1 = time() - elapsed
		if timer1 < 1100 then
			INTRO(timer1)
			resetTimer()
		else
			intro = 1
		end
	elseif intro == 1 then
		if  #animationQueue == 0 then 
			if firstTime == 0 and intro == 1 then
				music(0,0,0,false)
				firstTime = 1
				resetTimer()
			end
			UPDATE()
			DRAW()
		else
			DRAW()
			ANIMATE()
		end
	elseif intro == 2 then
		drawInstructions()
	end
	playMusic()
end
