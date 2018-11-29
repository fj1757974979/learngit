
pTable = pTable or class()

pTable.init = function(self, num)
	-- 座位数量
	self.seatNum = num
	-- 玩家数据
	self.players = {}
	-- 卡牌数据
	self.cards = {}
end

pTable.addPlayer = function(self, seatid, uid)
	self.players[seatid] = new pPlayer(seatid, uid)
end

pTable.getPlayer = function(self, seatid)
	return self.players[seatid]
end


pCards = pCards or class()

pCards.init = function(self)
	-- 总数
	self.totalNum = 0
	-- 剩余
	self.remainNum = 0
	-- 已出
	self.outNum = 0
	-- 保留
	self.notUse = 0

	-- 玩家牌 seatID = { handcards = {}, outCards = {} }
	self.playerCards = {}
end


pPlayerCards = pPlayerCards or class()

pPlayerCards.init = function(self)
	self.handCards = {}
	self.outCards = {}
	self.scoreCards = {}
end

pPlayer = pPlayer or class()

pPlayer.init = function(self, seatid, uid)
	-- 对cards里面的playerCards引用，不能直接操作
	self.cards = {}
	-- 座位ID
	self.seatID = seatid
	-- 可执行操作
	self.op = {}
	-- 用户id
	self.uid = uid
	-- 用户姓名
	self.name = "test"
	-- 用户金币
	self.gold = 12345
end
