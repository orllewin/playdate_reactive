import "CoreLibs/graphics"

local graphics <const> = playdate.graphics
local sound <const> = playdate.sound
local cos <const> = math.cos
local sin <const> = math.sin
local random <const> = math.random

playdate.startAccelerometer()
sound.micinput.startListening()

CAM_ORIGIN = 40

scene = lib3d.scene.new()
scene:setCameraOrigin(0, 0, CAM_ORIGIN)
scene:setLight(0.2, 0.8, 0.4)

cube = lib3d.shape.new()

for i=1, 10 do
	cube:addFace(
		lib3d.point.new(random(-10, 10), random(-10, 10), random(-10, 10)),		
		lib3d.point.new(random(-10, 10), random(-10, 10), random(-10, 10)),		
		lib3d.point.new(random(-10, 10), random(-10, 10), random(-10, 10)),		
		lib3d.point.new(random(-10, 10), random(-10, 10), random(-10, 10)),	
	0)
end

sceneRootNode = scene:getRootNode()
sceneRootNode:addShape(cube)

filled = true
wireframeAllowed = false
wireframeMode = 0
accelerometerMode = true
iX = 0
iY = 0

audLevel = 0.5
audAverage = 0.5
audFrame = 0
audScale = 0

donutTime = 0
donut = true
drawDonut = false
donutModeAllowed = false
roll = false
rollDirection = -3

function playdate.upButtonDown() iX -= 1 end
function playdate.downButtonDown() iX += 1 end
function playdate.leftButtonDown() iY -= 1 end 
function playdate.rightButtonDown() iY += 1 end 
function playdate.BButtonDown() accelerometerMode = not accelerometerMode end
function playdate.AButtonDown() donutModeAllowed = not donutModeAllowed end

function playdate.update()

	local accY, accX = playdate.readAccelerometer()
	
	if(accelerometerMode)then
		sceneRootNode:addTransform(lib3d.matrix.newRotation(accX * 4, 1, 0, 0))
	else
		sceneRootNode:addTransform(lib3d.matrix.newRotation(iX, 1, 0, 0))
	end
	
	if(accelerometerMode)then
		sceneRootNode:addTransform(lib3d.matrix.newRotation(accY * 4, 0, 1, 0))
	else
		sceneRootNode:addTransform(lib3d.matrix.newRotation(iY, 0, 1, 0))
	end
	
	local crankChange, crankAccChange = playdate.getCrankChange()
	sceneRootNode:addTransform(lib3d.matrix.newRotation(crankChange / 2 , 0, 0, 1))
	
	if(roll) then
		sceneRootNode:addTransform(lib3d.matrix.newRotation(rollDirection , 0, 0, 1))
		
		if(random() < 0.05) then 
			roll = false
			
			if(rollDirection == -3) then
				rollDirection = 3
			else
				rollDirection = -3
			end
		end
	end
	
	sceneRootNode:setFilled(filled)
	
	audLevel = sound.micinput.getLevel()
	audFrame = audFrame + 1
	
	audAverage = audAverage * (audFrame - 1)/audFrame + audLevel / audFrame

	if(audLevel > (audAverage + (audAverage/10))) then
		audScale = math.min((audLevel * 1000), 15)
		scene:setCameraOrigin(0, 0, CAM_ORIGIN - audScale)
		
		if(random() < 0.1) then
			roll = true
		end
	elseif(audLevel < (audAverage - (audAverage/10))) then
		local audScale = math.min((audLevel * 1000), 15)
		scene:setCameraOrigin(0, 0, CAM_ORIGIN + audScale)
	end
	
	-- Favour filled mode, limit how often wireframe is shown
	if(wireframeAllowed)then
		if(filled)then
			if(random() < 0.1)then
				filled = false
				wireframeMode = 2
			end
		else
			if(random() < 0.2)then
				filled = true
				wireframeMode = 0
			end
		end
	end
		
	sceneRootNode:setWireframeMode(wireframeMode)

	graphics.clear(graphics.kColorBlack)
		
	-- Donut
	-- Make donut more likely to turn off than to be activated to limit its screen time.
	if(donutModeAllowed) then
		if(not drawDonut)then
			if(random() < 0.05)then
				drawDonut = true
			end
		else
			if(random() < 0.1)then
				drawDonut = false
			end
		end
				
		if(drawDonut) then
		
			playdate.graphics.setColor(playdate.graphics.kColorWhite)
			playdate.graphics.setDitherPattern(0.6, playdate.graphics.image.kDitherTypeBayer4x4)
			donutTime += audScale/150
			for i = 90, 0, -1  do
			
				local q = (i * i)
				local Q = sin(q)
				
				local b
				if(donut)then
					b = i % 6 + donutTime + i
				else
					b = i % 6 + donutTime
				end
			
				local p = i + donutTime
				local z = 5 + cos(b) * (audScale/8) + cos(p) * Q
				local s = 80 / z / z
			
				if(not wireframeAllowed or not filled) then
					playdate.graphics.fillCircleAtPoint((200 * (z + sin(b) * 5 + sin(p) * Q) / z), (120 + 200 * (cos(q)- cos(b+donutTime))/z), s + (audScale/3))
				else
					playdate.graphics.setColor(playdate.graphics.kColorWhite)
					playdate.graphics.drawCircleAtPoint((200 * (z + sin(b) * 5 + sin(p) * Q) / z), (120 + 200 * (cos(q)- cos(b+donutTime))/z), s + (audScale/3))
				end
			end
		end
	end

	-- ------------ End Donut
	scene:draw()	
end



