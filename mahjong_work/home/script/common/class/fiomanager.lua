puppy.io.pIOServer.getFileContent = function(self, path)
	local stream = self:open(path)
	if stream then
		return stream:asBufferString()
	end
	log("error", "open ", path, " failed")
	return nil
end


puppy.io.pIOServer.fileExist = function(self, path)
	return self:exist(path, 0, true)
end

puppy.io.pIOServer.file_exist = puppy.io.pIOServer.fileExist

puppy.io.pIOServer.get_file_content = puppy.io.pIOServer.getFileContent
