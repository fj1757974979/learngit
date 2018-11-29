local modHintMgr = import("logic/hint/mgr.lua")

hasHint = function(hintName)
	return modHintMgr.pHintMgr:instance():hasHint(hintName)
end

fireNewSkillHint = function()
	modHintMgr.pHintMgr:instance():fireHint(HINT_NEW_SKILL)
end

fireNewSkillHintLvl = function()
	modHintMgr.pHintMgr:instance():fireHint(HINT_NEW_SKILL_LVL)
end

withDrawNewSkillHint = function()
	modHintMgr.pHintMgr:instance():withDrawHint(HINT_NEW_SKILL)
end

withDrawNewSkillHintLvl = function()
	modHintMgr.pHintMgr:instance():withDrawHint(HINT_NEW_SKILL_LVL)
end
