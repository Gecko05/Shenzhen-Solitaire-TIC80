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

endpiles = {{},
			        {},
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
trans = {}
hold = false
origin = 0
md = 0 -- mouse
mx = 0
my = 0
lx = 0
ly = 0
btn_red = 178
btn_blk = 180
btn_grn = 182
firstAnim = 0
tok = 0
justtwice = 1
justonce = 0
_move = 0
params = {0,0,0}
animData = {}
animCard = 0
movingToken = {0,0,0}
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
-- Paint cards
function drawCards()
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

function SCN(scnline)
end

function draw()
	cls(12)
	drawButtons()
	drawCards()
	drawDrag(mx-lx,my-ly)
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
	if firstAnim == 0 then 
		animData = getAnimParams(params)
		animCard = piles[params[1]][params[4]]
		table.remove(piles[params[1]], params[4])
		firstAnim = firstAnim + 1
	else 
		if firstAnim < 5 then 
			animData[1] = animData[1] -	animData[5]
			animData[2] = animData[2] - animData[6]
			drawCard(animData[1],animData[2],animCard) -- draw the anim card
			firstAnim = firstAnim + 1
		else
			if params[3] == 1 then 
				table.insert(tokpiles[params[2]],animCard)
			elseif params[3] == 2 then
				table.insert(endpiles[params[2]],animCard)
			end
			_move = 0
		end 
	end
end

function update() 
	-- Check for unblocked tokens
	valSum = {0,0,0,0}
	for k,vpile in pairs(piles) do
		if #vpile > 0 then 
			compVal = (vpile[#vpile] - 1)/10 - 2
			if valSum[compVal] ~= nil then
				valSum[compVal] = valSum[compVal] + 1
			end 
		end
	end
	for k,vpile in pairs(tokpiles) do
		if #vpile > 0 then 
			compVal = (vpile[#vpile] - 1)/10 - 2
			if valSum[compVal] ~= nil then
				valSum[compVal] = valSum[compVal] + 1
			end 
		end 
	end
	for i,v in ipairs(valSum) do
		if v == 4 and getEmptyTokPile() ~= nil then
			tokens[i] = 16
		end 
	end
	mx,my,md = mouse()
	-- DRAG / Click
	if hold == false and md then
		hold = true
		c = math.floor((mx - 30)/18)
		-- get index of last card in pile
		if piles[c] ~= nil then 
			lc = #piles[c]
		else
			lc = 300
		end
		maxy = 36 + ((lc - 1) * 6) + 23
		miny = 36 + ((lc - 1) * 6)
		-- check if dragging last card
		if my > miny and my < maxy then
			r = lc
		else
			r = math.floor((my - 30)/6)
		end
		if my > 10 and my < 34 and tokpiles[c]~=nil then
			lx = mx - (c*18 + 30)
			ly = my - (10)
			table.insert(drag,tokpiles[c][1])
			table.remove(tokpiles[c],1)
			tok = 1
			orig = c
		elseif isDraggable(c,r) then
			lx = mx - (c*18 + 30)
			ly = my - (r*6 + 30)
			while(piles[c][r] ~= nil) 
			do 
				table.insert(drag,piles[c][r])
				table.remove(piles[c],r)
			end
			tok = 0
			orig = c
		end
		-- check for token buttons
		if my > 10 and my < 34 and mx > 103 and mx < 117 then
			btnNum = (my - 10)//8 + 1
			if tokens[btnNum] == 16 then 
				tokens[btnNum] = 0
			end
		end
	end
	-- DROP
	if hold == true then
		if md == false then
			c = math.floor((mx - 30)/18)
			r = math.floor((my - 30)/6)
			-- Dropping on token piles
			if my > 10 and my < 34 and #drag == 1 and tokpiles[c]~=nil and isOrdered(tokpiles[c][1],drag[1]) then 
					moveHandToPile(tokpiles[c])
			-- Dropping on a pile 
			elseif piles[c]~=nil then
				if isOrdered(piles[c][#piles[c]],drag[1]) then
					moveHandToPile(piles[c])
				elseif #drag > 0 then
					if tok == 1 then
						moveHandToPile(tokpiles[orig])
					else
						moveHandToPile(piles[orig])
					end
				end
			-- Dropping elsewhere
			elseif #drag > 0 then
				if tok == 1 then
					moveHandToPile(tokpiles[orig])
				else
					moveHandToPile(piles[orig])
				end
			end
			hold = false
		end
	end

	--justonce = justonce + 1 
	if justonce == 100 and justtwice == 1 then 
		_move = 1
		params = {1,4,2,5}
		justtwice = 0
	end
end

function checkIfMove() 
	for i,tok in ipairs(tokens) do 
		if tok == 1 then
			movingToken[i] = 1
		end 
	end
	
end
----------------------------------------

function init()

end

init()

function TIC()
	if _move == 0 then 
		update()
	end 
	--checkIfMove()
	-- DRAW
	draw()
	-- Move a card with animation
	if _move == 1 then 
		animateCards()
	end 
end
