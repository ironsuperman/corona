
local sprite = require "sprite"

---------------
-- PHYSICS SETUP
---------------
local physics = require "physics"

physics.start()
physics.setGravity( 0, 0 )
--physics.setDrawMode( "hybrid" )

---------------
-- RNG
---------------
local mRand = math.random

---------------
-- SCREEN DIMENSIONS
---------------
local screenW, screenH = display.contentWidth, display.contentHeight

---------------
-- BACKGROUND
---------------
local background = display.newImage( "assets/images/metal_bg.jpg", true )
background.x = screenW / 2
background.y = screenH / 2
background.label = "background"

---------------
-- BORDER
---------------
borderBody = { density = 1.0, friction=0, bounce=0 }

-- Left border that the ball bounces off of
local borderLeft = display.newRect( 0, 1, 1, 480 )
borderLeft:setFillColor(255, 255, 255, 0)
physics.addBody( borderLeft, "static",  borderBody )
borderLeft.label = "border"
 
-- Right border that the ball bounces off of
local borderRight = display.newRect( 319, 1, 1, 480 )
borderRight:setFillColor(255, 255, 255, 0)
physics.addBody( borderRight, "static",  borderBody )
borderRight.label = "border"

-- Top border that the ball bounces off of
local borderTop = display.newRect( 0, 0, 320, 1 )
borderTop:setFillColor(255, 255, 255, 0)
physics.addBody( borderTop, "static",  borderBody )
borderTop.label = "border"
 
-- Bottom sensor that lights up when the ball passes it
local borderBottom = display.newRect( 0, 479, 320, 5 )
borderBottom:setFillColor(255, 255, 255, 0)
physics.addBody( borderBottom, "static", borderBody )
borderBottom.isSensor = true
borderBottom.label = "borderBottom"
 

---------------
-- BALL
---------------
local ball = display.newCircle( screenW * 0.5, screenH * 0.5, 14)
ball:setFillColor(255, 255, 255, 255)
--ball.x = screenW * 0.5
--ball.y = screenH * 0.2
ball.label = "ball"

physics.addBody( ball, { density = 0, friction = 0, bounce = 1.01,  radius = ( ball.width / 2 ) } )
ball.isBullet = true
ball:setLinearVelocity( -100, 300 )

---------------
-- PADDLE
---------------
local paddleSpriteData  = require( "assets/data/paddleSpriteData" )
local paddleSpriteSheet = sprite.newSpriteSheetFromData( "assets/images/paddle.png", paddleSpriteData.getSpriteSheetData() )
local paddleSpriteSet   = sprite.newSpriteSet( paddleSpriteSheet, 1, 9)
local paddle = sprite.newSprite( paddleSpriteSet )
paddle:setReferencePoint( display.TopLeftReferencePoint )
paddle:scale( 0.9, 0.9 )

sprite.add( paddleSpriteSet, "paddleHit", 1, 9, 75, 1 )
paddle:prepare( "paddleHit" )
paddle.x = 100
paddle.y = 420

local paddleShape = { -paddle.width * 0.5 * paddle.xScale, -paddle.height * 0.5 * paddle.yScale + 8,
					   0							     , -paddle.height * 0.5 * paddle.yScale,
					   paddle.width * 0.5 * paddle.xScale, -paddle.height * 0.5 * paddle.yScale + 8,
					   paddle.width * 0.5 * paddle.xScale,  paddle.height * 0.5 * paddle.yScale,
					  -paddle.width * 0.5 * paddle.xScale,  paddle.height * 0.5 * paddle.yScale }

physics.addBody( paddle, "kinematic", { density = 3, friction = 0, bounce = 0, shape = paddleShape } )
paddle.label = "paddle"

---------------
-- BLOCKS
---------------
local blocks = {}
local blockGutter = 50
local blockGap = 10

local blockSpriteData  = require( "assets/data/blockSpriteData" )
local blockSpriteSheet = sprite.newSpriteSheetFromData( "assets/images/blockSpriteData.png", blockSpriteData.getSpriteSheetData() )
local blockSpriteSet   = sprite.newSpriteSet( blockSpriteSheet, 1, 9)

---------------
-- GAMEPLAY
---------------
local ballInPlay = true

---------------
-- SOUND
---------------
local blockBreakSound = audio.loadSound( "assets/sound/blockBreak.wav"  )
local ballBounceSound = audio.loadSound( "assets/sound/ballBounce1.wav" )
local ballLostSound   = audio.loadSound( "assets/sound/ballLost.wav"    )

audio.setVolume( 0.5, { channel = 1 } )
audio.setVolume( 0.35, { channel = 2 } )
audio.setVolume( 1, { channel = 3 } )

-------------------------------------------
-- Set a value to bounds
-------------------------------------------
local function clamp(value, low, high)
    if value < low then value = low
    elseif high and value > high then value = high end
    return value
end

-- A general function for dragging objects
local function handleTouch( event )
	local t = event.target
	local phase = event.phase
	
	--print( "touch event called for: " .. t.label )
	
	if phase == "began" then
		
		-- If the ball is being reset 
		if t.label == "background" and not ballInPlay then
			ball.x = event.x
			ball.y = event.y
			t = ball
			
			background:removeEventListener("touch",handleTouch )
		end
		
		-- Store initial position
		t.x0 = event.x - t.x
		
		display.getCurrentStage():setFocus( t )
		t.isFocus = true	
	elseif t.isFocus then
		if "moved" == phase then
			if t.label == "paddle" then
				paddle.x = clamp( event.x - t.x0, 0, screenW - ( paddle.width * paddle.xScale ) ) 
				
				-- Move the paddle offset if the player keeps dragging past the edge of the screen
				if paddle.x ~= event.x - t.x0 and clamp( event.x, 0, screenW ) == event.x then
					t.x0 = event.x - t.x
				end
			elseif t.label == "ball" then
				ball.x = event.x
				ball.y = event.y
			end
		elseif "ended" == phase or "cancelled" == phase then
			display.getCurrentStage():setFocus( nil )
			t.isFocus = false
			
			if t.label == "ball" then
				ball.isBodyActive = true
				ballInPlay = true
				ball:setLinearVelocity( -50, 300 )
				ball:removeEventListener( "touch",handleTouch )
			end
				
		end
	end

	-- Stop further propagation of touch event!
	return true
end		

-- Destroy the given ball
local function ballLost( targetBall )

	-- Start listening for touching anywhere on the background (to reset the ball)
	targetBall:addEventListener( "touch",handleTouch )
	background:addEventListener("touch",handleTouch )
	ballInPlay = false
	
	audio.play( ballLostSound )
	
	targetBall:setLinearVelocity( 0, 0 )
	print( "ball lost!" )
	
end

local function processAnimation( event )
	if event.phase == "end" and event.sprite.label == "block" then
		table.remove( blocks, table.indexOf( blocks, event.sprite ) )
		event.sprite:removeSelf()
		print( "block removed (" .. #blocks .. " blocks left)" )
	end
end

-- Load a grid of blocks
local function loadBlocks( width, height )

	print( "Building new " .. width .. "x" .. height .. " level" )

	local blockWidth = ( screenW - ( blockGutter * 2 ) - ( blockGap * ( width - 1 ) ) ) / width
	local blockHeight = 20
	local blockXscale = blockWidth / 40
	
	local blockShape = { -blockWidth * 0.5, -blockHeight * 0.5,
						  blockWidth * 0.5, -blockHeight * 0.5,
						  blockWidth * 0.5,  blockHeight * 0.5,
						 -blockWidth * 0.5,  blockHeight * 0.5 }

	
	--blocks = {}
	
	for blockX = 0, width - 1 do
		for blockY = 0, height - 1 do
			
			local block = sprite.newSprite( blockSpriteSet )
			block:scale( blockXscale, 1 )
			block:setReferencePoint( display.TopLeftReferencePoint )
			
			sprite.add( blockSpriteSet, "blockHit", 1, 9, 10, 1 )
			block:prepare( "blockHit" )
			block.x = blockGutter + blockX * ( blockWidth + blockGap )
			block.y = blockGutter + blockY * ( blockHeight + blockGap )

			physics.addBody( block, "kinematic", { density = 1.0, friction = 0, bounce = 0, shape = blockShape } )
			block.label = "block"
			blocks[ #blocks + 1 ] = block
			
			block:addEventListener( "sprite", processAnimation )
		end
	end	
end

-- Process the ball collisions
local function processBallCollision( self, event )

	if event.phase == "began" then
		-- If the ball collides with the paddle, animate the paddle
		if event.other.label == "paddle" then
			paddle:prepare( "paddleHit" )
			paddle:play()
			audio.play( ballBounceSound )
		-- If the ball collides with a block, start the destroy animation
		elseif event.other.label == "block" then
			event.other:play()
			audio.play( blockBreakSound )
		-- If the ball collides with a border, play a bounce sound
		elseif event.other.label == "border" then
			audio.play( ballBounceSound )
		end
	elseif event.phase == "ended" then
		-- If a block collision is over, disable the block
		if event.other.label == "block" then
			local disableBlock = function()
				event.other.isBodyActive = false
			end
			
			timer.performWithDelay( 1, disableBlock , 1 )
		
		-- If the ball has passed through the floor, destroy it
		elseif event.other.label == "borderBottom" then
			ballLost( self )
		end		
	end
end


-- Load a random set of blocks
loadBlocks( mRand( 3, 7 ), mRand( 2, 5 ) )

---------------
-- EVENT LISTENERS
---------------
ball.collision = processBallCollision
ball:addEventListener("collision", ball )

paddle.collision = processCollision
paddle:addEventListener( "touch", handleTouch )
