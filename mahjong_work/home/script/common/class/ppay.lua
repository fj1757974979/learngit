puppy.pPayment.getPayment = function()
	return puppy.pPayment.newPayment()
end

puppy.pPayment.onError = function(self, sid, code, reason)
	if self.onErrorCb then
		self.onErrorCb(sid, code, reason)
	end
end

puppy.pPayment.onGetProductInfo = function(self, sid, code, reason)
	if self.onGetProductInfoCb then
		self.onGetProductInfoCb(sid, code, reason)
	end
end

puppy.pPayment.onPayProductFinish = function(self, sid, code, reason, receipt)
	if self.onPayProductFinishCb then
		self.onPayProductFinishCb(sid, code, reason, receipt)
	end
end
