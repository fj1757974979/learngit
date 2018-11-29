
pClubShareMgr = pClubShareMgr or class(pSingleton)

pClubShareMgr.init = function(self, name, id, desc, link)
	self.name = name
	self.id = id
	self.link = link
	self.desc = desc
end

pClubShareMgr.showSharePanel = function(self)
	local modClubSharePanel = import("ui/club/share.lua")	
	modClubSharePanel.pClubSharePanel:instance():open(self)
end

pClubShareMgr.getName = function(self)
	return self.name
end

pClubShareMgr.getId = function(self)
	return self.id
end

pClubShareMgr.getLink = function(self)
	return self.link
end

pClubShareMgr.getDesc = function(self)
	return self.desc
end

pClubShareMgr.destroy = function(self)
	self.name = nil
	self.id = nil
	self.link = nil
	self.desc = nil
	pClubShareMgr:cleanInstance()
end
