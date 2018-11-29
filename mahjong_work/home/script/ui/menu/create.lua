local modCreateParent = import("ui/create_main.lua")

pMainCreate = pMainCreate or class(modCreateParent.pCreate, pSingleton)

pMainCreate.init = function(self)
	modCreateParent.pCreate.init(self)
end

pMainCreate.getSaveFilePath = function(self)
	return "tmp:createroominfo_2.dat"
end

pMainCreate.destroy = function(self)
	pMainCreate:cleanInstance()
end
