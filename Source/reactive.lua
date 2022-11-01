import "CoreLibs/graphics"

local graphics <const> = playdate.graphics
local sound <const> = playdate.sound
local cos <const> = math.cos
local sin <const> = math.sin
local random <const> = math.random

playdate.startAccelerometer()
sound.micinput.startListening()
graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)

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

wireframeAllowed = true
accelerometerMode = true
iX = 0
iY = 0

audLevel = 0.5
audAverage = 0.5
audFrame = 0
audScale = 0

donutTime = 0

DisplayModes = {ALWAYS_OFF = "0", ALWAYS_ON = "1", INTERMITTENT_OFF = "2", INTERMITTENT_ON = "3"}
orbitMode = DisplayModes.INTERMITTENT_ON
shapeMode = DisplayModes.ALWAYS_ON
wireframeMode = DisplayModes.INTERMITTENT_ON

roll = false
rollDirection = -3


-- Toast
toastText = ""
toastActive = false
toastStartMS = -1
TOAST_DISPLAY_MS = 1500
function toast(text)
	toastText = text
	toastActive = true
	toastStartMS = playdate.getCurrentTimeMilliseconds()
	print("Toast: " .. toastText)
end

-- Controls
function playdate.upButtonDown() 
	if(orbitMode == DisplayModes.ALWAYS_OFF) then
		orbitMode = DisplayModes.ALWAYS_ON
		toast("Orbit on")
	elseif(orbitMode == DisplayModes.ALWAYS_ON) then
		orbitMode = DisplayModes.INTERMITTENT_ON
		toast("Orbit intermittent")
	else
		orbitMode = DisplayModes.ALWAYS_OFF
		toast("Orbit off")
	end	
end

function playdate.downButtonDown() 
	if(shapeMode == DisplayModes.ALWAYS_OFF) then
		shapeMode = DisplayModes.ALWAYS_ON
		toast("Shape on")
	elseif(shapeMode == DisplayModes.ALWAYS_ON) then
		shapeMode = DisplayModes.INTERMITTENT_ON
		toast("Shape intermittent")
	else
		shapeMode = DisplayModes.ALWAYS_OFF
		toast("Shape off")
	end	
end

function playdate.leftButtonDown()
	if(wireframeMode == DisplayModes.ALWAYS_OFF) then
		wireframeMode = DisplayModes.ALWAYS_ON
		toast("Wireframe on")
	elseif(wireframeMode == DisplayModes.ALWAYS_ON) then
		wireframeMode = DisplayModes.INTERMITTENT_ON
		toast("Wireframe intermittent")
	else
		wireframeMode = DisplayModes.ALWAYS_OFF
		toast("Wireframe off")
	end
end 

function playdate.rightButtonDown() iY += 1 end 
function playdate.BButtonDown() wireframeAllowed = not wireframeAllowed end
function playdate.AButtonDown() 
	
end

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
		
		if(random() < 0.08) then 
			roll = false
			
			if(rollDirection == -3) then
				rollDirection = 3
			else
				rollDirection = -3
			end
		end
	end
	
	
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

	graphics.clear(graphics.kColorBlack)
		
	updateWireframeStatus()
	renderOrbit()
	renderShape()
	
	if(toastActive) then
		playdate.graphics.drawText(toastText, 10, 10)
		
		if(playdate.getCurrentTimeMilliseconds() - toastStartMS > TOAST_DISPLAY_MS) then
			toastActive = false
		end
	end
end

function updateWireframeStatus()
	if(wireframeMode == DisplayModes.INTERMITTENT_ON) then
		if(random() < 0.04)then
			wireframeMode = DisplayModes.INTERMITTENT_OFF
		end
	elseif(wireframeMode == DisplayModes.INTERMITTENT_OFF) then
		if(random() < 0.02)then
			wireframeMode = DisplayModes.INTERMITTENT_ON
		end
	end
	
	if(wireframeMode == DisplayModes.ALWAYS_ON or wireframeMode == DisplayModes.INTERMITTENT_ON)then
		sceneRootNode:setFilled(false)
		sceneRootNode:setWireframeMode(2)
	else
		sceneRootNode:setFilled(true)
		sceneRootNode:setWireframeMode(0)
	end
end

function renderShape()	
	if(shapeMode == DisplayModes.INTERMITTENT_OFF)then
		if(random() < 0.08)then
			shapeMode = DisplayModes.INTERMITTENT_ON
		end
	elseif (shapeMode == DisplayModes.INTERMITTENT_ON) then
		if(random() < 0.05)then
			shapeMode = DisplayModes.INTERMITTENT_OFF
		end
	end
	if(shapeMode == DisplayModes.ALWAYS_ON or shapeMode == DisplayModes.INTERMITTENT_ON) then 
		scene:draw()
	end	
end

function renderOrbit()
	if(orbitMode ~= DisplayModes.ALWAYS_OFF) then
		if(orbitMode == DisplayModes.INTERMITTENT_OFF)then
			if(random() < 0.05)then
				orbitMode = DisplayModes.INTERMITTENT_ON
			end
		elseif (orbitMode == DisplayModes.INTERMITTENT_ON) then
			if(random() < 0.1)then
				orbitMode = DisplayModes.INTERMITTENT_OFF
			end
		end
		
		if(orbitMode == DisplayModes.ALWAYS_ON or orbitMode == DisplayModes.INTERMITTENT_ON) then
		
			playdate.graphics.setColor(playdate.graphics.kColorWhite)
			playdate.graphics.setDitherPattern(0.7, playdate.graphics.image.kDitherTypeBayer4x4)
			donutTime += audScale/150
			for i = 90, 0, -1  do
			
				local q = (i * i)
				local Q = sin(q)
				
				local b
				if(roll) then
					if(rollDirection > 0)then
						b = i % 6 + donutTime + i
					else
						b = i % 6 - donutTime + i
					end
				else
					b = i % 6 + i
				end
			
				local p = i + donutTime
				local z = 5 + cos(b) * (audScale/8) + cos(p) * Q
				local s = 80 / z / z
							
				if(wireframeMode == DisplayModes.ALWAYS_OFF or wireframeMode == DisplayModes.INTERMITTENT_OFF) then
					playdate.graphics.setColor(playdate.graphics.kColorWhite)
					if(z < 3) then
						playdate.graphics.setDitherPattern(0.1, playdate.graphics.image.kDitherTypeBayer4x4)
					elseif(z < 4) then
						playdate.graphics.setDitherPattern(0.2, playdate.graphics.image.kDitherTypeBayer4x4)
					elseif(z < 5) then
						playdate.graphics.setDitherPattern(0.4, playdate.graphics.image.kDitherTypeBayer4x4)
					elseif(z < 6) then
						playdate.graphics.setDitherPattern(0.5, playdate.graphics.image.kDitherTypeBayer4x4)
					elseif(z < 7) then
						playdate.graphics.setDitherPattern(0.6, playdate.graphics.image.kDitherTypeBayer4x4)
					elseif(z < 8) then
						playdate.graphics.setDitherPattern(0.8, playdate.graphics.image.kDitherTypeBayer4x4)
					else
						playdate.graphics.setDitherPattern(0.8, playdate.graphics.image.kDitherTypeBayer4x4)
					end
					
					playdate.graphics.fillCircleAtPoint((200 * (z + sin(b) * 5 + sin(p) * Q) / z), (120 + 200 * (cos(q)- cos(b+donutTime))/z), s + (audScale/3))
				else
					playdate.graphics.setColor(playdate.graphics.kColorWhite)
					playdate.graphics.drawCircleAtPoint((200 * (z + sin(b) * 5 + sin(p) * Q) / z), (120 + 200 * (cos(q)- cos(b+donutTime))/z), s + (audScale/3))
				end
			end
		end
	end
end



