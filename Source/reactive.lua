import "CoreLibs/graphics"
import "CoreLibs/object"
import 'CoreLibs/timer'
import 'CoreLibs/animator'
import "CoreLibs/sprites"
import "intro"

local graphics <const> = playdate.graphics
local sound <const> = playdate.sound
local cos <const> = math.cos
local sin <const> = math.sin
local random <const> = math.random

playdate.startAccelerometer()
sound.micinput.startListening()

local orbImage = playdate.graphics.image.new("Images/orb_white")
local orbInverted = orbImage:invertedImage()
local orbSprite = playdate.graphics.sprite.new(orbImage)
orbSprite:moveTo(200, 120)
orbSprite:add()
local orbAngle = 1

CAM_ORIGIN = 40
SHAPE_POLYGONS = 6
ORBIT_ORBS = 60

scene = lib3d.scene.new()
scene:setCameraOrigin(0, 0, CAM_ORIGIN)
scene:setLight(0.2, 0.8, 0.4)

local randomShape = nil

function generateNewShape()
	randomShape = lib3d.shape.new()
	
	for i=1, SHAPE_POLYGONS do
		randomShape:addFace(
			lib3d.point.new(random(-10, 10), random(-10, 10), random(-10, 10)),		
			lib3d.point.new(random(-10, 10), random(-10, 10), random(-10, 10)),		
			lib3d.point.new(random(-10, 10), random(-10, 10), random(-10, 10)),		
			lib3d.point.new(random(-10, 10), random(-10, 10), random(-10, 10)),	
		0)
	end
	
	sceneRootNode = scene:getRootNode()
	sceneRootNode:addShape(randomShape)
end

generateNewShape()

audLevel = 0.5
audAverage = 0.5
audFrame = 0
audScale = 0

donutTime = 0

DisplayModes = {ALWAYS_OFF = "0", ALWAYS_ON = "1", INTERMITTENT_OFF = "2", INTERMITTENT_ON = "3"}
orbitMode = DisplayModes.ALWAYS_ON
shapeMode = DisplayModes.ALWAYS_ON
wireframeMode = DisplayModes.INTERMITTENT_ON
reactiveMode = DisplayModes.ALWAYS_ON
spriteMode = DisplayModes.ALWAYS_OFF

OrbitScaleModes = {NORMAL = "0", MASSIVE = "1"}
orbitScaleMode = OrbitScaleModes.NORMAL
orbitVerticalScale = 200

roll = false
rollDirection = -3

-- Intro:
local intro = Intro()
local showIntro = true
local introTime = true
local fadeInTime = false

if showIntro then
	local identPlayer = playdate.sound.fileplayer.new("Audio/ident")
	identPlayer:setVolume(0.35)
	identPlayer:play()
end

local duration = 1500
local animator = nil
local introBackgroundImage = playdate.graphics.image.new(400, 240, playdate.graphics.kColorWhite)
local fadetoImage = nil

if showIntro then
	playdate.timer.performAfterDelay(3500, function() 
		introTime = false
		fadeInTime = true
		animator = playdate.graphics.animator.new(duration, 100,0)
		
	end)
else
	introTime = false
end

function map(value, start1, stop1, start2, stop2)
	return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1))
end

function playdate.update()
	graphics.clear(graphics.kColorWhite)
	
	playdate.timer.updateTimers()
	renderOrb()
	
	
	local accY, accX = playdate.readAccelerometer()
	local crankChange, crankAccChange = playdate.getCrankChange()
	
	sceneRootNode:addTransform(lib3d.matrix.newRotation(accX * 4, 1, 0, 0))
	sceneRootNode:addTransform(lib3d.matrix.newRotation(accY * 4, 0, 1, 0))
	sceneRootNode:addTransform(lib3d.matrix.newRotation(crankChange / 2 , 0, 0, 1))
	
	updateRoll()		
	updateReactiveMode()
	updateWireframeStatus()
	renderOrbit()
	renderShape()
	

	-- INTRO/IDENT ----------------------------------------------------------------
	if showIntro and introTime then 
		intro:update()
	end
	
	if fadeInTime then
		local xx = 0
		local yy = 0
		alpha = animator:currentValue()
		introBackgroundImage:drawFaded(xx, yy, alpha/100.0, playdate.graphics.image.kDitherTypeBayer8x8)
		if alpha == 0 then 
			fadeInTime = false 
			--playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
			
		end
	end
	
	if(toastActive) then
		playdate.graphics.drawText(toastText, 10, 10)
		
		if(playdate.getCurrentTimeMilliseconds() - toastStartMS > TOAST_DISPLAY_MS) then
			toastActive = false
		end
	end
end

-- Not. this only deactivates roll. Activation happens in reactiveMode() if a louder than average sound event happens.
function updateRoll()
	if(roll) then
		sceneRootNode:addTransform(lib3d.matrix.newRotation(rollDirection , 0, 0, 1))
		
		if(random() < 0.12) then 
			roll = false
			
			if(rollDirection == -3) then
				rollDirection = 3
			else
				rollDirection = -3
			end
		end
	end
end

function updateReactiveMode()
	if(reactiveMode == DisplayModes.ALWAYS_ON) then
		audLevel = sound.micinput.getLevel()
		audFrame = audFrame + 1
		
		audAverage = audAverage * (audFrame - 1)/audFrame + audLevel / audFrame
	
		if(audLevel > (audAverage + (audAverage/10))) then
			audScale = math.min((audLevel * 1000), 15)
			scene:setCameraOrigin(0, 0, CAM_ORIGIN - audScale)
			
			if(random() < 0.1) then
				roll = true
			end
			
			if(orbitScaleMode == OrbitScaleModes.NORMAL)then
				if(random() < 0.01) then
					orbitScaleMode = OrbitScaleModes.MASSIVE
				end
			elseif(orbitScaleMode == OrbitScaleModes.MASSIVE) then
				if(random() < 0.02) then
					orbitScaleMode = OrbitScaleModes.NORMAL
				end
			end
		elseif(audLevel < (audAverage - (audAverage/10))) then
			audScale = math.min((audLevel * 1000), 15)
			scene:setCameraOrigin(0, 0, CAM_ORIGIN + audScale)
			
			if(orbitScaleMode == OrbitScaleModes.MASSIVE) then
				if(random() < 0.012) then
					orbitScaleMode = OrbitScaleModes.NORMAL
				end
			end
		end
	else
		audScale = 15
		scene:setCameraOrigin(0, 0, CAM_ORIGIN)
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
		sceneRootNode:setWireframeColor(1.0)
		sceneRootNode:setWireframeMode(2)
		sceneRootNode:setWireframeColor(1.0)
		sceneRootNode:setFilled(false) -- MUST be called after setWireframeMode
		sceneRootNode:setWireframeColor(1.0)
		sceneRootNode:setColorBias(0.0)
	else
		sceneRootNode:setWireframeMode(0)
		sceneRootNode:setFilled(true)
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
			playdate.graphics.setDitherPattern(0.7, playdate.graphics.image.kDitherTypeBayer4x4)
			donutTime += audScale/150
			for i = ORBIT_ORBS, 0, -1  do
			
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
				
				if(orbitScaleMode == OrbitScaleModes.NORMAL) then
					orbitVerticalScale = 200
				elseif(orbitScaleMode == OrbitScaleModes.MASSIVE) then
					orbitVerticalScale = 200 + (audScale * 100)
				end
							
				if(wireframeMode == DisplayModes.ALWAYS_OFF or wireframeMode == DisplayModes.INTERMITTENT_OFF) then

					if(z < 3) then
						playdate.graphics.setDitherPattern(0.0, playdate.graphics.image.kDitherTypeBayer4x4)
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
										
					playdate.graphics.fillCircleAtPoint((200 * (z + sin(b) * 5 + sin(p) * Q) / z), (120 + orbitVerticalScale * (cos(q)- cos(b+donutTime))/z), s + (audScale/2))
				else
					playdate.graphics.setColor(playdate.graphics.kColorBlack)
					playdate.graphics.drawCircleAtPoint((200 * (z + sin(b) * 5 + sin(p) * Q) / z), (120 + orbitVerticalScale * (cos(q)- cos(b+donutTime))/z), s + (audScale/2))
				end
			end
		end
	end
end

function renderOrb()
	
	if (spriteMode == DisplayModes.ALWAYS_OFF) then
		if(random() < 0.01) then 
			spriteMode = DisplayModes.ALWAYS_ON
		end
	else
		if(random() < 0.02) then 
			spriteMode = DisplayModes.ALWAYS_OFF
		end
	end
	
	if (spriteMode == DisplayModes.ALWAYS_ON) then
		playdate.graphics.sprite.update()
		orbAngle += 0.5
		orbSprite:setRotation(orbAngle)
		orbSprite:setScale(map(audScale, 1, 15, 0.5, 1.5))
	end
end

-- Toast
toastText = ""
toastActive = false
toastStartMS = -1
TOAST_DISPLAY_MS = 1500
hudActive = true
function toast(text)
	if(not hudActive) then
		return
	end
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

function playdate.rightButtonDown()
	if(reactiveMode == DisplayModes.ALWAYS_OFF) then
		reactiveMode = DisplayModes.ALWAYS_ON
		toast("Reactive audio on")
	elseif(reactiveMode == DisplayModes.ALWAYS_ON) then
		reactiveMode = DisplayModes.ALWAYS_OFF
		toast("Reactive audio off")
	end
end 

function playdate.BButtonDown() 
	if(hudActive) then
		toast("HUD off")
		hudActive = false
	else
		hudActive = true
		toast("HUD on")
	end
end

function playdate.AButtonDown() 
	if playdate.display.getInverted() == true then
		playdate.display.setInverted(false)		
	else
		playdate.display.setInverted(true)
	end
end



