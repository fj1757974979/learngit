gApplication = puppy.world.app.instance()
gGameConfig = gApplication:getConfig()

gWorld = gWorld or nil
gWidget = gWidget or nil

gGameWidth = 1024
gGameHeight = 768
gSceneScale = 1.0
gGameName = TEXT(56)

COLOR_WHITE = 0xffffffff
COLOR_GREEN = 0xff01f512
COLOR_BLUE  = 0xff00a8ff
COLOR_PURPLE= 0xfffe29e6
COLOR_GOLD  = 0xfff48b00

DIR_UP = 0
DIR_RIGHT_UP = 1
DIR_RIGHT = 2 
DIR_RIGHT_DOWN = 3
DIR_DOWN = 4
DIR_LEFT_UP = 5
DIR_LEFT = 6
DIR_LEFT_DOWN = 7

FPS = 30

__init__ = function(module)
	loadglobally(module)
end


