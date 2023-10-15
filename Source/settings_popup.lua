import 'CoracleViews/text_list'

class('SettingsPopup').extends(playdate.graphics.sprite)

local gfx <const> = playdate.graphics
local width = 175
local height = 122

gCornerRad = 5
gModuleMenuZ      = 29000

function generateModBackgroundWithShadow(w, h)
	local gfx <const> = playdate.graphics
	
	local shadowPadding = 7
	local shadowW = w + (shadowPadding*2)
	local shadowH = h + (shadowPadding*2)
	local backgroundShadowImage = gfx.image.new(shadowW, shadowH)
	gfx.pushContext(backgroundShadowImage)
	gfx.setColor(playdate.graphics.kColorBlack)
	gfx.fillRoundRect(shadowPadding/2, shadowPadding/2, shadowW - (shadowPadding/2), shadowH - (shadowPadding/2), gCornerRad)
	gfx.popContext()
	
	local backgroundImage = gfx.image.new(w, h)
	gfx.pushContext(backgroundImage)
	gfx.setLineWidth(2)
	gfx.setColor(playdate.graphics.kColorWhite)
	gfx.fillRoundRect(1, 1, w-2, h-2, gCornerRad)
	gfx.setColor(playdate.graphics.kColorBlack)
	gfx.drawRoundRect(1, 1, w-2, h-2, gCornerRad)	
	gfx.setLineWidth(1)
	gfx.popContext()
	
	local baseW = shadowW + (shadowPadding*2)
	local baseH = shadowH + (shadowPadding*2)
	local baseImage = gfx.image.new(baseW, baseH)
	gfx.pushContext(baseImage)
	backgroundShadowImage:drawBlurred((baseW - shadowW)/2, (baseH - shadowH)/2, 6, 2, playdate.graphics.image.kDitherTypeDiagonalLine)
	--backgroundShadowImage:draw(baseImagePadding, baseImagePadding)
	
	
	gfx.popContext()
	
	
	local baseImage2 = gfx.image.new(baseW, baseH)
	gfx.pushContext(baseImage2)
	baseImage:drawFaded(0, 0, 0.6, playdate.graphics.image.kDitherTypeScreen)
	backgroundImage:draw((baseW - w)/2, (baseH - h)/2)
	gfx.popContext()
	return baseImage2
end

function SettingsPopup:init(screenshot)
	SettingsPopup.super.init(self)
	--todo - use screenshot as background
	local backgroundImage = generateModBackgroundWithShadow(width, height)
	local bgW, bgH = backgroundImage:getSize()	
	--self:setIgnoresDrawOffset(true)
	self:setZIndex(gModuleMenuZ)
	self:setImage(backgroundImage)
	self:moveTo(295, 175)

end

function SettingsPopup:show(onSelect)
	self:add()
	
	gMenuShowing = true
	
	self:moveTo(305, 170)
	
	self.mods = {
		{
			category = "Main Shape",
			mods = {
				{
					label = "On",
					type = "main_shape_on"
				},
				{
					label = "Off",
					type = "main_shape_off"
				},
				{
					label = "Random",
					type = "main_shape_random"
				},
			}
		},
		{
			category = "Circle Orbit",
			mods = {
				{
					label = "On",
					type = "orbit_on"
				},
				{
					label = "Off",
					type = "orbit_off"
				},
				{
					label = "Random",
					type = "orbit_random"
				},
			}
		},
	}
	
	self.moduleList = TextList(self.mods, self.x - width/2 + 8, self.y - height/2 + 8, width - 16, height-2, 18, nil, function(index, item)
		if item.category ~= nil then
			print("Selected " .. item.category)
			self:updateCategory(item)
		else
			print("Mod Selected: " .. item.label .. " type: " .. item.type)
			self:dismiss()
			playdate.timer.performAfterDelay(100, function() 
				onSelect(item)
			end)
		end

	end, gModuleMenuZ + 1)
	
	self:setSelected(selectedIndex)
	
	self.modulePopupInputHandler = {
		
		BButtonDown = function()
			self:dismiss()
		end,
		
		AButtonDown = function()
			self.moduleList:tapA()
		end,
		
		leftButtonDown = function()
	
		end,
		
		rightButtonDown = function()
	
		end,
		
		upButtonDown = function()
			self.moduleList:goUp()
		end,
		
		downButtonDown = function()
			self.moduleList:goDown()
		end
	}
	playdate.inputHandlers.push(self.modulePopupInputHandler )
end

function SettingsPopup:updateCategory(category)
	self.moduleList:updateItems(category.mods)
end

function SettingsPopup:dismiss()
	print("SettingsPopup:dismiss()")
	playdate.inputHandlers.pop()
	self.moduleList:removeAll()
	self:remove()
	gMenuShowing = false
end

function SettingsPopup:setSelected(index)
	self.moduleList:setSelected(index)
end