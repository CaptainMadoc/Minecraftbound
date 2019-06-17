module = {
	
}

function module:create(config, name)
	local attachment = {}
	
	local attach = attachmentSystem:getPart(name)

	flashlight:add(attach.part, attach.partTag, attach.partTagEnd, config.lightColor)
	lasermanager:add(attach.part, attach.partTag, attach.partTagEnd, config.laserColor)

	function attachment:refreshStats()
		local gottenStats = attachmentSystem:getStats()

		gottenStats.movingInaccuracy = gottenStats.movingInaccuracy / 2
		gottenStats.standingInaccuracy = gottenStats.standingInaccuracy / 2
		gottenStats.crouchInaccuracyMultiplier = gottenStats.crouchInaccuracyMultiplier / 2
		
		attachmentSystem:setStats(gottenStats)
	end

	function attachment:uninit()
	
	end
	
	return attachment
end
