attachmentSystem = {
	statsInited = false,
	statsChanges = {},
	config = {},
	modules = {},
	loadedScripts = {},
	originalStats = false,
	special = nil,
	specials = {},
	int_special = 1
}


function attachmentSystem:init()
	self.originalConfig = root.itemConfig({name = item.name(), count = 1}).config.attachments -- original attachment config from weapon
	self.config = config.getParameter("attachments")

	local finalconfig = sb.jsonMerge(self.originalConfig, self.config)
	for i,v in pairs(config.getParameter("giveback", {})) do
		player.giveItem(v)
	end
	activeItem.setInstanceValue("giveback", jarray())
	
	for i,v in pairs(finalconfig) do
		--error checking
		if (type(v) ~= "table") and not animator.partPoint(v.attachPart or "part", v.attachPartTag or "tag") then
			self.config[i] = nil
		else
			if not v.item and v.defaultItem then -- todo: maybe for use for ironsights removal
				v.item = copycat(v.defaultItem)
			end
			if v.gunTag then
				v.attachPartTag = v.gunTag
			end
			if v.gunTagEnd then
				v.attachPartTagEnd = v.gunTagEnd
			end
			if v.item then --if a item is stored in the attachment data it will proceed
				local originalItem = root.itemConfig({name = v.item.name, count = 1})
				local fp = {}

				if originalItem and --verify PGI
					((self.originalConfig[i] and self.originalConfig[i].part) or (v and v.part)) and --bunch of config verification
					((self.originalConfig[i] and self.originalConfig[i].attachPart) or (v and v.attachPart)) and 
					((self.originalConfig[i] and self.originalConfig[i].attachPartTag) or (v and v.attachPartTag)) and 
					((self.originalConfig[i] and self.originalConfig[i].transformationGroup) or (v and v.transformationGroup)) and
					((self.originalConfig[i] and self.originalConfig[i].attachPartTagEnd) or (v and v.attachPartTagEnd)) then

					fp = sb.jsonMerge(root.itemConfig(v.item).config, v.item.parameters)
					local current;
					
					if fp.attachment then
						animator.setPartTag(v.part or self.originalConfig[i].part, "selfimage", vDir(fp.attachment.image, originalItem.directory))
						self:createTransform(
							v.transformationGroup or self.originalConfig[i].transformationGroup,
							fp.attachment.offset,
							fp.attachment.scale,
							v.attachPart or self.originalConfig[i].attachPart,
							v.attachPartTag or self.originalConfig[i].gunPart,
							v.attachPartTagEnd or self.originalConfig[i].attachPartTagEnd
						)
						fp.attachment.directory = originalItem.directory
						if fp.attachment.script then
							self.modules[i] = requireUni:load(vDir(fp.attachment.script, originalItem), fp.attachment.class or "module"):create(fp.attachment, i, {name = v.item.name, count = 1, parameters = fp})
							if self.modules[i].special then
								table.insert(self.specials, i)
							end
						end
					end
				end
			end
		end

	end

	self:refreshStats()
end

function attachmentSystem:update(dt)
	for i,v in pairs(self.modules) do
		if self.modules[i].update then
			self.modules[i]:update(dt)
		end
	end
end

function attachmentSystem:uninit()
	for i,v in pairs(self.modules) do
		if self.modules[i].uninit then
			self.modules[i]:uninit(dt)
		end
	end
end

function attachmentSystem:rel(pos)	
	return vec2.add(mcontroller.position(), activeItem.handPosition(pos))
end

function attachmentSystem:newAttachment(name, e)

end

function attachmentSystem:createTransform(namee, offset, scale, attachPart, attachPartTag, attachPartTagEnd) -- for transforms.lua
	if not animator.partPoint(attachPart, attachPartTag) or not animator.partPoint(attachPart, attachPartTagEnd) then return end

	local somenewTransform = function(name, this, dt)
		if animator.hasTransformationGroup(name) then --Check to prevent crashing
			local setting  = {
				position = vec2.add(animator.partPoint(attachPart, attachPartTag), vec2.mul(offset or {0,0}, scale or {1,1})),
				scale = scale or {1,1},
				scalePoint = {0,0},
				rotation = vec2.angle(vec2.sub(animator.partPoint(attachPart, attachPartTagEnd), animator.partPoint(attachPart, attachPartTag))) or 0,
				rotationPoint = vec2.mul(offset or {0,0}, -1)
			}
			animator.resetTransformationGroup(name) 
			animator.scaleTransformationGroup(name, setting.scale, setting.scalePoint)
			animator.rotateTransformationGroup(name, setting.rotation, vec2.mul(setting.rotationPoint,setting.scale))
			animator.translateTransformationGroup(name, setting.position)
		end
	end

	transforms:lateAdd(namee, {}, somenewTransform)
end

--gun api

function attachmentSystem:triggerSpecial()
--	if self.special and self.modules[self.special] and self.modules[self.special].fireSpecial then
--		self.modules[self.special]:fireSpecial(fireMode, shiftHeld)
--	end
	if #self.specials > 0 then
		self.modules[self.specials[self.int_special]]:fireSpecial()
	end
end

function attachmentSystem:getSelectedSpecial()
	if #self.specials > 0 then
		return self.int_special
	else
		return nil
	end
end

function attachmentSystem:switchSpecial()
	if #self.specials > 0 then
		self.int_special = self.int_special + 1

		if self.int_special > #self.specials then
			self.int_special = 1
		end
	end
end

--stats API

function attachmentSystem:getPart(name)
	local a1 = self.config[name] or self.originalConfig[name]
	if a1 and 
		(a1.attachPart) and 
		(a1.attachPartTag or a1.gunTag) and 
		(a1.attachPartTagEnd or a1.gunTagEnd)
		then
		return {
			part = a1.attachPart,
			tag  = (a1.attachPartTag or a1.gunTag),
			tagEnd = (a1.attachPartTagEnd or a1.gunTagEnd)
		}
	end
end

function attachmentSystem:getConfig()
	return copycat(self.config)
end

function attachmentSystem:resetStats() -- do not use this. other attachments are not notified by this
	if self.originalStats then
		data.gunStats = copycat(self.originalStats)
		self.originalStats = false
		self.statsChanges = {}
	end
end

function attachmentSystem:refreshStats()
	self:resetStats()
	for i,v in pairs(self.modules) do
		if self.modules[i].refreshStats then
			self.modules[i]:refreshStats()
		end
	end
	magazine.size = data.gunStats.maxMagazine
end

function attachmentSystem:setFireSounds(sounds)
	if animator.hasSound("fireSounds") then
		animator.setSoundPool("fireSounds", sounds)
	end
end

function attachmentSystem:addStats(stats)
	if not self.originalStats then
		self.originalStats = copycat(data.gunStats)
	end
	for i,v in pairs(stats) do
		if data.gunStats[i] then
			data.gunStats[i] = math.max(data.gunStats[i] + v, 0)
			self.statsChanges[i] = math.max((self.statsChanges[i] or 0) + v, 0)
		end
	end
end

function attachmentSystem:setStats(stats)
	if not self.originalStats then
		self.originalStats = copycat(data.gunStats)
	end
	for i,v in pairs(stats) do
		if data.gunStats[i] then
			local copyed = copycat(v)
			data.gunStats[i] = copyed
			self.statsChanges[i] = copyed
		end
	end
end

function attachmentSystem:getStats(name)
	return copycat(data.gunStats)
end

function attachmentSystem:getStat(name)
	return copycat(data.gunStats[name])
end

function attachmentSystem:hideDefaultMagazine()
	animator.setGlobalTag("magazine","/assetmissing.png")
end

function attachmentSystem:showDefaultMagazine()
	local originConfig = root.itemConfig({name = item.name(), count = 1}).config.animationCustom -- original attachment config from weapon
	local currentConfig = config.getParameter("animationCustom")
	animator.setGlobalTag("magazine", self.currentConfig.globalTagDefaults.magazine or self.originalConfig.globalTagDefaults.magazine or "mag.png")
end

--


addClass("attachmentSystem")
