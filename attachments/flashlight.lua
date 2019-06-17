module = {
	
}

function module:create(config, name)
	local attachment = {}
	
	local attach = attachmentSystem:getPart(name)

	flashlight:add(attach.part, attach.partTag, attach.partTagEnd, config.lightColor)
	
	function attachment:uninit()
	
	end
	
	return attachment
end
