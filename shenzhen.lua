-- title:  Shenzhen I/O Solitaire
-- author: GG
-- desc:   Solitaire from Shenzhen I/O
-- script: lua
-- input:  mouse

piles = {{1,2,3,4,},
        {5,6,7,8,9,},
        {10,11,12,13,},
        {14,15,16,17,18},
        {19,20,21,22,23},
        {24,25,26,27}}
drag = {}
trans = {}
hold = false
origin = 0
md = 0 -- mouse
mx = 0
my = 0
lx = 0
ly = 0
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
 if isDifColor(num0,num1) then
		n0 = num0 % 9
		n1 = num1 % 9
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
end

function drawDrag(x,y)
	if #drag > 0 then
		for i,c in pairs(drag) do
			drawCard(x,y,c)
		end
	end
end

function SCN(scnline)
	cls(12)
	drawCards(30,30)
	drawDrag(mx-lx,my-ly)
end

function init()

end

init()

function TIC()
	mx,my,md = mouse()
	-- DRAG
	if hold == false and md then
		hold = true
		c = math.floor((mx - 30)/18)
		r = math.floor((my - 30)/6)
		if isDraggable(c,r) then
			lx = mx - (c*18 + 30)
		 ly = my - (r*6 + 30)
		 table.insert(drag,piles[c][r])
			table.remove(piles[c],r)
			orig = c
		end
	end
	-- DROP
 if hold == true then
	 if md == false then
		 c = math.floor((mx - 30)/18)
		 r = math.floor((my - 30)/6)
			if piles[c]~=nil then
				if isOrdered(piles[c][#piles[c]],drag[1]) then
					table.insert(piles[c], drag[1])
					table.remove(drag)
				elseif #drag >0 then
				 table.insert(piles[orig], drag[1])
					table.remove(drag)
				end
			elseif #drag > 0 then
			 table.insert(piles[orig], drag[1])
				table.remove(drag)
			end
			hold = false
		end
	end
end
