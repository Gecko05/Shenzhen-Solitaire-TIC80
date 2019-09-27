-- title:  Shenzhen I/O Solitaire
-- author: Gecko05
-- desc:   Solitaire from Shenzhen I/O
-- script: lua
-- input:  mouse
 -- specials: 31 41 51
piles = {{31,1,2,3,4},
        {5,6,7,8,9},
        {11,12,13,14},
        {15,16,17,18,19},
        {21,22,23,24,25},
        {26,27,28,29},
        {31,41,51},
        {51,41,31}}

endpiles = {{},
            {},
            {},
            {}
            }
			
tokpiles = {{},
            {},
            {}
            }
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
function drawCards(x0,y0)
	for i,col in ipairs(piles) do
		if #col == 0 then
			drawSpace((i*18)+30, 36)
		else 
			for j,num in ipairs(col) do
			 x = (i * 18) + x0
				y = (j * 6) + y0
				drawCard(x,y,num)
			end
		end
	end
	for i,col in ipairs(tokpiles) do
		if #col == 0 then
			drawSpace((i*18)+30, 10)
		else 
			for j,num in ipairs(col) do
			 x = (i * 18) + x0
				y = (j * 6) + y0
				drawCard(x,y,num)
			end
		end
	end
	for i,col in ipairs(endpiles) do
		if #col == 0 then
			drawSpace((i*18)+102, 10)
		else 
			for j,num in ipairs(col) do
			 x = (i * 18) + x0
				y = (j * 6) + y0
				drawCard(x,y,num)
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
	spr(btn_red,102,10,2)
	spr(btn_red+1,110,10,2)
	spr(btn_grn,102,18,2)
	spr(btn_grn+1,110,18,2)
	spr(btn_blk,102,26,2)
	spr(btn_blk+1,110,26,2)
end

function SCN(scnline)
end

function draw()
	cls(12)
	drawButtons()
	drawCards(30,30)
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

function moveStackToHand(pile, n)
	while pile[n] ~= nil do
		table.insert(drag,pile[n])
		table.remove(pile,n)
	end
end
----------------------------------------

function init()

end

init()

function TIC()
	mx,my,md = mouse()
	local lpiles = piles
	-- DRAG
	if hold == false and md then
		hold = true
		c = math.floor((mx - 30)/18)
		-- get index of last card in pile
		if lpiles[c] ~= nil then 
			lc = #lpiles[c]
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
		if isDraggable(c,r) then
			lx = mx - (c*18 + 30)
			ly = my - (r*6 + 30)
			while(lpiles[c][r] ~= nil) 
			do 
				table.insert(drag,lpiles[c][r])
				table.remove(lpiles[c],r)
			end
			orig = c
		end
	end
	-- DROP
	if hold == true then
		if md == false then
			c = math.floor((mx - 30)/18)
			r = math.floor((my - 30)/6)
			if lpiles[c]~=nil then
				if isOrdered(lpiles[c][#lpiles[c]],drag[1]) then
					moveHandToPile(lpiles[c])
				elseif #drag > 0 then
					moveHandToPile(lpiles[orig])
				end
			elseif #drag > 0 then
				moveHandToPile(lpiles[orig])
			end
			hold = false
		end
	end
	draw()
end
