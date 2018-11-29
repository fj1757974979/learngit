
pSprite.setImage = function(self, path)
	self:setTexture(path, 0)
end

pSprite.getText = function(self, txt) return "" end

pSprite.setText = function(self, txt) end


pSprite.toTable = function(self)
	local t = pObject.toTable(self)
	if not t then return end
	t.keyPoint = {self:getResourceKX(), self:getResourceKY()}
	t.texturePath = self:getTexturePath()
	t.headPoint = {self:getHeadX(), self:getHeadY()}
	t.renderLayer = self:getSelfRenderLayer()
	t.rotZ = self:getRot()
	return t
end

pSprite.fromTable = function(self, conf, root)
	pObject.fromTable(self, conf, root)
	self:setResourceKeyPoint(unpack(conf.keyPoint))
	self:setTexture(conf.texturePath, 0)
	self:setHeadPoint(unpack(conf.headPoint or {0, 0}))
	if conf.renderLayer then
		self:setRenderLayer(conf.renderLayer)
	end
	if conf.rotZ then
		self:setRot(0, 0, conf.rotZ)
	end
end


local spriteConfig = nil

pSprite.getHitFrame = function(self)
	local conf = self:getConf()
	return conf.hitFrame or 0
end

pSprite.setHitFrame = function(self, frame)
	local conf = self:getConf()
	conf.hitFrame = frame
end

pSprite.setConfigZ = function(self, z)
	local conf = self:getConf()
	conf.z = z
end

pSprite.getConfigZ = function(self)
	local conf = self:getConf()
	return conf.z or 0
end

pSprite.getConfigZByPath = function(path)
	if not spriteConfig then
		pSprite.loadConfig()
	end
	if not spriteConfig[path] then
		return 0 
	end
	
	return spriteConfig[path].z or 0
end

pSprite.getConfigRepeat = function(self)
	local conf = self:getConf()
	return conf.repCnt or 1
end

-- 是否在脚下播放
pSprite.getConfigIsFoot = function(self)
	local conf = self:getConf()
	return conf.isFoot or 0
end

pSprite.setConfigIsFoot = function(self, val)
	local conf = self:getConf()
	if val and val ~= "" and val ~= 0 then
		conf.isFoot = 1
	else
		conf.isFoot = 0
	end
end

pSprite.getConfigIsFootByPath = function(path)
	if not spriteConfig then
		pSprite.loadConfig()
	end
	if not spriteConfig[path] then
		return false
	end

	return spriteConfig[path].isFoot == 1
end

pSprite.getConfigRepeatByPath = function(path)
	if not spriteConfig then
		pSprite.loadConfig()
	end
	if not spriteConfig[path] then
		return 1
	end
	
	return spriteConfig[path].repCnt or 1
end

pSprite.setConfigRepeat = function(self, repCnt)
	local conf = self:getConf()
	conf.repCnt = repCnt
end

pSprite.getConf = function(self)
	if not self:getTexturePath() then return {} end

	if not spriteConfig then
		pSprite.loadConfig()
	end
	spriteConfig[self:getTexturePath()] = spriteConfig[self:getTexturePath()] or {}
	return spriteConfig[self:getTexturePath()]
end

pSprite.loadConfig = function()
	local data = import("data/sprite_conf.lua")
	
	spriteConfig = data and data.data or {}
end

pSprite.saveConfig = function()
	table.save(spriteConfig, "home/script/data/sprite_conf.lua")
end

pSprite.getHitFrameByPath = function(path)
	local data = import("data/sprite_conf.lua") or {data = {} }
	if not data.data[path] then
		return 0 
	end
	
	return data.data[path].hitFrame or 0
end

pSprite.getCharacterHit = function(resid, action)
	return pSprite.getHitFrameByPath(string.format("character:%05d/%s.6.fsi", resid, action))
end

pSprite.getHitDelayByPath = function(path)
	local frame = pSprite.getHitFrameByPath(path)
	return frame * 4
end

pSprite.getCharacterDelay = function(resid, action)
	local frame = pSprite.getCharacterHit(resid, action)
	return frame * 4 + 2
end

pSprite.getDuration = function(self)
	local frame = self:getFrameCount()
	local speed = self:getSpeed()
	return frame*speed
end

