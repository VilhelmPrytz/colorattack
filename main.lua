-- Color Attack
-- (c) Vilhelm Prytz 2019 <vilhelm@prytznet.se>
-- https://github.com/VilhelmPrytz/colorattack

-- make sure it's random
math.randomseed(os.time())

-- variables required at top
version = "development"
highscoreSave = "colorattack_highscore.txt"

api_endpoint = "http://colorattack.vilhelmprytz.se/api/v2/highscore/"

-- important functions
function newBullet(direction)
  -- for shotgun powerup
  if player.shotgun_enabled then
    table.insert(bullets, {player.bullet_x, player.bullet_y, 0})
    table.insert(bullets, {player.bullet_x, player.bullet_y, 1})
    table.insert(bullets, {player.bullet_x, player.bullet_y, 2})
    table.insert(bullets, {player.bullet_x, player.bullet_y, 3})
  else
    table.insert(bullets, {player.bullet_x, player.bullet_y, direction})
  end
end

function newZombie(x, y)
  table.insert(zombies, {x, y, zombieHealth})
end

function newPowerup(x, y)
  table.insert(powerups, {x, y, math.random(1, 3, math.random(1,3))})
end

function setZombieDifficulty()
  amountZombies = 3 + math.floor(score/10)
  zombieHealth = static.zombieHealth + math.floor(score/100)
  zombieSpeed = static.zombieSpeed + math.floor(score/400)
  amountPowerups = static.amountPowerups + math.floor(score/100)
end

function deadZombie()
  setZombieDifficulty()

  -- spawns in set amount of zombies
  while tablelength(zombies) < amountZombies do
    newZombie(randomCoords())
  end
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function randomCoords()
  x = math.random(0, static.mapWidth)
  y = math.random(0, static.mapHeight)

  -- f: forbidden
  f = {}
  f.x_min = player.bullet_x - 800/2
  f.x_max = player.bullet_x + 800/2

  f.y_min = player.bullet_y - 600/2
  f.y_max = player.bullet_y + 600/2

  -- Logic for rueling out forbidden X coordinates
  if x > f.x_min and x < f.x_max then
    if x-f.x_min < f.x_max-x then
      x = math.max(f.x_min, 0)
    else
      x = math.min(f.x_max, static.mapWidth)
    end
  end

  -- Logic for rueling out forbiden Y coordinates
  if y > f.y_min and y < f.y_max then
    if y-f.y_min < f.y_max-y then
      y = math.max(f.y_min, 0)
    else
      y = math.min(f.y_max, static.mapHeight)
    end
  end

  -- return our final variables
  return x,y
end

-- pure random function
function justRandom()
  x = math.random(0, static.mapWidth)
  y = math.random(0, static.mapHeight)

  return x,y
end

function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function readHighscore()
  if file_exists(highscoreSave) then
    file = io.open (highscoreSave, "r")

    io.input(file)
    currentHighscore = io.read()
    io.close(file)
  else
    file = io.open(highscoreSave, "w")

    io.output(file)
    io.write("0")
    io.close()

    currentHighscore = 0
  end
  return currentHighscore
end

function writeHighscore(number)
  file = io.open(highscoreSave, "w")

  io.output(file)
  io.write(number)
  io.close()
end

function saveHighscore(score, savedHighscore)
  if tonumber(score) > tonumber(savedHighscore) then
    writeHighscore(score)
    submitHighscore(score, highscore_name.input)
  end
end

function resetPowerups()
  player.active_bulletCooldown = static.bulletCooldown
  player.shotgun_enabled = false
  player.sprint_boost = 0
end

function submitHighscore(score, input_name)
  if input_name == "" then
    input_name = "None"
  end

  local http = require("socket.http")
  local body, code, headers, status = http.request(api_endpoint..score.."/"..input_name)

  print(api_endpoint..score.."/"..input_name)

  if status == "HTTP/1.1 200 OK" then
    player.newHighscore_error = false
  else
    print("unable to connect to leaderboard server")
    player.newHighscore_error = true
  end
end

function textRectangle(text, y)
  length = font:getWidth(text)
  length2 = font:getWidth(text)/2

  love.graphics.setColor(0,0,0)
  love.graphics.rectangle("fill", math.floor(width2-length2)-3, y, length+6, 15)
  love.graphics.setColor(255,255,255)

  love.graphics.print(text, math.floor(width2-length2), y)
end

-- variables
debug = false
zombie_show_coordinates = false

-- static variables; NEVER change modify values when running
static = {}

static.speed_normal = 2
static.speed_sprint = 4
static.bulletCooldown = 30
static.bulletSpeed = 7
static.zombieSpeed = 2
static.zombieHealth = 1

-- powerups
static.amountPowerups = 3
static.powerup_time = 180
static.spawn_powerup_time = 360

-- highscore_name
static.highscore_name_limit = 11

-- should never be changed
static.mapWidth = 1590
static.mapHeight = 1190

-- help
-- directions for bullets
-- 0: up
-- 1: down
-- 2: left
-- 3: right
--
-- which type of powerups there are
-- 1: shoot faster
-- 2: one in each direction
-- 3: sprint fast

-- player variables
player = {}
player.speed = static.speed_sprint
player.x = 0 -- coordinates for the map really
player.y = 0 -- yep
player.dead = false
-- for bullet coordination (which is really the coordinates of the player)
player.bullet_x = 400
player.bullet_y = 300
player.active_bulletCooldown = static.bulletCooldown

-- for powerups
player.powerup_timer = static.powerup_time
player.active_powerup = -1
player.sprint_boost = 0
player.shotgun_enabled = false

-- for highscore
player.newHighscore = false
player.newHighscore_count = 10
player.newHighscore_isSubmitting = false
player.newHighscore_done = false
player.newHighscore_error = false

-- for name input
highscore_name = {}
highscore_name.input = ""
highscore_name.isTyping = false
highscore_name.input_done = false

-- bullet related
bullets = {}
bulletCooldown = 0

-- zombies
zombies = {}
amountZombies = 3
zombieSpeed = static.zombieSpeed
zombieHealth = static.zombieHealth

-- powerups
powerups = {}
amountPowerups = static.amountPowerups
spawn_powerup_timer = static.spawn_powerup_time

-- game variables
game = {}
game.isPaused = false

-- other
score = 0
spawn_wait = 10

-- main load statement
function love.load()
  -- load highscore
  currentHighscore = readHighscore()

  -- title, resolution and so on
  love.window.setTitle("Color Attack "..version)

  -- load images
  skybox = love.graphics.newImage("skybox.jpg")
  -- map is in png as it supports transparent better
  map = love.graphics.newImage("map.png")

  -- load our font so that we can see how long text strings are
  font = love.graphics.newFont(12)

  -- add three powerups into the table
  i = 1
  while i <= amountPowerups do
    newPowerup(justRandom())
    i=i+1
  end
end

-- main draw function
function love.draw()
  -- get som important vars
  width = love.graphics.getWidth()
  height = love.graphics.getHeight()
  width2 = width/2
  height2 = height/2

  -- draw
  love.graphics.draw(skybox, 0, 0)
  love.graphics.draw(map, player.x, player.y)

  -- draw powerups
  if powerups ~= nil then
    love.graphics.setColor(255, 255, 0)
    for k, coords in pairs(powerups) do
      love.graphics.rectangle("fill", coords[1]+player.x, coords[2]+player.y, 15, 15)
    end
    love.graphics.setColor(255, 255, 255)
  end

  -- character
  love.graphics.setColor(0,0,0)
  love.graphics.rectangle("fill", width2, height2, 10, 10 )
  love.graphics.setColor(255,255,255)

  -- draw bullets
  if bullets ~= nil then
    for k, coords in pairs(bullets) do
      love.graphics.rectangle("fill", coords[1]+player.x, coords[2]+player.y, 10, 10 )
    end
  end

  -- draw zombies
  if zombies ~= nil then
    love.graphics.setColor(255,0,255)
    for k, coords in pairs(zombies) do
      if debug then
        if zombie_show_coordinates then
          nametag = ("["..tostring(coords[3]).."], ["..tostring(coords[1]).."], ["..tostring(coords[2]).."]")
          nametag_x = coords[1]+player.x-30
        else
          nametag = ("["..tostring(coords[3]).."]")
          nametag_x = coords[1]+player.x
        end
        love.graphics.setColor(255,255,255)
        love.graphics.print(nametag, nametag_x, coords[2]+player.y-15)
        love.graphics.setColor(255,0,255)
      end
      love.graphics.rectangle("fill", coords[1]+player.x, coords[2]+player.y, 20, 20)
    end
    love.graphics.setColor(255,255,255)
  end

  -- text
  love.graphics.print("Score:", 1, 1)
  love.graphics.print(tostring(score), 45, 1)

  -- high score
  love.graphics.print("Your highscore: "..tostring(currentHighscore), 1, height-15)

  if debug then
    love.graphics.print(player.x, 1, 15)
    love.graphics.print(player.y, 1, 25)

    love.graphics.print("bullets: ", 1, 40)
    love.graphics.print(tablelength(bullets), 50, 40)

    love.graphics.print("cooldown: ", 1, 60)
    love.graphics.print(bulletCooldown, 70, 60)

    love.graphics.print("bullet coordination", 1, 80)
    love.graphics.print(player.bullet_x, 1, 90)
    love.graphics.print(player.bullet_y, 1, 100)

    love.graphics.print("zombies: ", 1, 120)
    love.graphics.print(tablelength(zombies), 60, 120)

    love.graphics.print("zombieSpeed: ", 1, 135)
    love.graphics.print(zombieSpeed, 100, 135)

    love.graphics.print("zombieAmount: ", 1, 150)
    love.graphics.print(amountZombies, 100, 150)

    love.graphics.print("zombieHealth: "..tostring(zombieHealth), 1, 165)

    love.graphics.print("powerups: "..tostring(tablelength(powerups)), 1, 185)
    love.graphics.print("spwn_powerups: "..tostring(amountPowerups), 1, 200)
    love.graphics.print("spawn_powerup_timer: "..tostring(spawn_powerup_timer), 1, 215)

    love.graphics.print("player.dead: "..tostring(player.dead), 1, 230)
  end

  -- if game has ended
  if player.dead == true then
    textRectangle("Game Over", height2-50)
    textRectangle("Your score was: "..score, height2-35)
    textRectangle("Press RETURN (enter) to restart the game", height2+35)
    if player.newHighscore then
      if player.newHighscore_isSubmitting then
        highscore_text = "New highscore! Submitting score to leaderboard.."
      else
        if player.newHighscore_error then
          highscore_text = "New highscore! Unable to submit highscore to leaderboard (error)"
        else
          highscore_text = "New highscore! Score has been submitted to the leaderboard."
        end
      end

      textRectangle(highscore_text, height2+50)
    end

    -- also print message of where leaderboard is available
    textRectangle("You can find the leaderboard over at https://colorattack.vilhelmprytz.se", height2+175)
  end

  -- if input
  if highscore_name.isTyping then
    textRectangle("Enter your name (name will apear on leaderboard, max 11 characters, no space, no special characters): ", height2+70)
    textRectangle("Type here: "..highscore_name.input, height2+85)
  end

  -- print the current powerup
  if player.active_powerup ~= -1 then
    if player.active_powerup == 1 then
      powerup_name = "FAST SHOOT"
    elseif player.active_powerup == 2 then
      powerup_name = "SHOTGUN"
    elseif player.active_powerup == 3 then
      powerup_name = "FAST SPRINT"
    end

    love.graphics.print("POWERUP: "..powerup_name, width2-150, height2+135)

    percentage = player.powerup_timer/static.powerup_time
    love.graphics.rectangle("fill", width2-150, height2+150, 300, 10)

    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle("fill", width2-150, height2+150, 300*percentage, 10)
    love.graphics.setColor(255, 255, 255)
  end

  -- pause the game
  if game.isPaused == true then
    textRectangle("GAME PAUSED", height2)
  end

  -- print FPS, print version
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), width-100, 1)
  love.graphics.print(version, width-35, 15)

  -- print copyright
  love.graphics.print("© Vilhelm Prytz 2019", width-135, height-15)
end

-- main update function (catches stuff such as keypresses)
function love.update(dt)
  -- try to limit our framerate to 60 (THIS IS POOR CODING!)
  if dt < 1/60 then
		love.timer.sleep(1/60 - dt)
	end

  -- spawn zombie block
  if spawn_wait > 0 then
    spawn_wait = spawn_wait-1
  end
  if spawn_wait == 0 then
    -- add three random zombies into the table
    i = 1
    while i <= amountZombies do
      newZombie(randomCoords())
      i=i+1
    end

    spawn_wait = -1
  end

  -- submit highscore
  if player.newHighscore and highscore_name.input_done and player.newHighscore_done == false then
    -- save and submit new highscore
    saveHighscore(score, currentHighscore)

    -- read new highscore
    currentHighscore = readHighscore()
    player.newHighscore_isSubmitting = false
    player.newHighscore_done = true
  end

  -- UPDATE FOR WHEN PLAYER IS NOT DEAD & GAME IS NOT PAUSED
  -- UPDATE FOR WHEN PLAYER IS NOT DEAD & GAME IS NOT PAUSED
  -- UPDATE FOR WHEN PLAYER IS NOT DEAD & GAME IS NOT PAUSED
  -- UPDATE FOR WHEN PLAYER IS NOT DEAD & GAME IS NOT PAUSED

  if player.dead == false and game.isPaused == false then
    -- movement
    if love.keyboard.isDown("a") then
      if player.x < 400 then
        player.x = player.x+player.speed
        player.bullet_x = player.bullet_x-player.speed
      end
    end

    if love.keyboard.isDown("d") then
      if player.x > -1190 then
        player.x = player.x-player.speed
        player.bullet_x = player.bullet_x+player.speed
      end
    end

    if love.keyboard.isDown("w") then
      if player.y < 300 then
        player.y = player.y+player.speed
        player.bullet_y = player.bullet_y-player.speed
      end
    end

    if love.keyboard.isDown("s") then
      if player.y > -890 then
        player.y = player.y-player.speed
        player.bullet_y = player.bullet_y+player.speed
      end
    end

    -- cooldown
    if bulletCooldown > 0 then
      bulletCooldown = bulletCooldown-1
    end

    -- bullets
    if love.keyboard.isDown("up") then
      if bulletCooldown == 0 then
        newBullet(0)
        bulletCooldown = player.active_bulletCooldown
      end
    end

    if love.keyboard.isDown("down") then
      if bulletCooldown == 0 then
        newBullet(1)
        bulletCooldown = player.active_bulletCooldown
      end
    end

    if love.keyboard.isDown("left") then
      if bulletCooldown == 0 then
        newBullet(2)
        bulletCooldown = player.active_bulletCooldown
      end
    end

    if love.keyboard.isDown("right") then
      if bulletCooldown == 0 then
        newBullet(3)
        bulletCooldown = player.active_bulletCooldown
      end
    end

    -- other keys
    if love.keyboard.isDown("lshift") then
      player.speed = static.speed_sprint+player.sprint_boost
    else
      player.speed = static.speed_normal
    end

    -- move current bullets
    if bullets ~= nil then
      for k, coords in pairs(bullets) do
        -- up
        if coords[3] == 0 then
          coords[2] = coords[2]-static.bulletSpeed
        end

        -- down
        if coords[3] == 1 then
          coords[2] = coords[2]+static.bulletSpeed
        end

        -- left
        if coords[3] == 2 then
          coords[1] = coords[1]-static.bulletSpeed
        end

        -- right
        if coords[3] == 3 then
          coords[1] = coords[1]+static.bulletSpeed
        end
      end
    end

    -- move current zombies
    if zombies ~= nil then
      for k, coords in pairs(zombies) do
        if coords[1] ~= player.bullet_x then
          difference = coords[1] - player.bullet_x

          if difference < 0 then
            coords[1] = coords[1]+zombieSpeed
          elseif difference > 0 then
            coords[1] = coords[1]-zombieSpeed
          end
        end

        if coords[2] ~= player.bullet_y then
          if coords[2] ~= player.bullet_y then
            difference = coords[2] - player.bullet_y

            if difference < 0 then
              coords[2] = coords[2]+zombieSpeed
            elseif difference > 0 then
              coords[2] = coords[2]-zombieSpeed
            end
          end
        end
      end
    end

    -- check if bullets hit
    if bullets ~= nil then
      for zombieK, zombieCoords in pairs(zombies) do
        if zombies ~= nil then
          for bulletK, bulletCoords in pairs(bullets) do
            if CheckCollision(bulletCoords[1],bulletCoords[2],10,10, zombieCoords[1],zombieCoords[2],20,20) then
              zombieCoords[3] = zombieCoords[3]-1
              table.remove(bullets, bulletK)
              if zombieCoords[3] == 0 then
                score = score+1
                table.remove(zombies, zombieK)

                -- add new one
                deadZombie()
              end
            end
          end
        end
      end
    end

    -- check if player is dead
    if zombies ~= nil then
      for k, coords in pairs(zombies) do
        if CheckCollision(player.bullet_x,player.bullet_y,10,10, coords[1],coords[2],20,20) then
          player.dead = true
          player.newHighscore_done = true
          -- save the high score
          if tonumber(score) > tonumber(readHighscore()) then
            player.newHighscore = true
            player.newHighscore_done = false
            highscore_name.isTyping = true
            highscore_name.input = ""
          end
        end
      end
    end

    -- check if bullets are outside of the map and remove them
    if bullets ~= nil then
      for bulletK, bulletCoords in pairs(bullets) do
        if bulletCoords[1] < -10 or bulletCoords[1] > static.mapWidth+10 then
          table.remove(bullets, bulletK)
        elseif bulletCoords[2] < -10 or bulletCoords[2] > static.mapHeight+10 then
          table.remove(bullets, bulletK)
        end
      end
    end

    -- check if player touches any powerups
    if powerups ~= nil then
      for k, coords in pairs(powerups) do
        if CheckCollision(player.bullet_x,player.bullet_y,10,10, coords[1],coords[2],15,15) and player.active_powerup == -1 then
          table.remove(powerups, k)
          -- make sure no powerups are active
          resetPowerups()
          player.active_powerup = coords[3]
        end
      end
    end

    -- apply any active powerups
    if player.active_powerup == 1 then
      player.powerup_timer = player.powerup_timer-1
      player.active_bulletCooldown = 10
    elseif player.active_powerup == 2 then
      player.powerup_timer = player.powerup_timer-1
      player.shotgun_enabled = true
      player.active_bulletCooldown = 18
    elseif player.active_powerup == 3 then
      player.powerup_timer = player.powerup_timer-1
      player.sprint_boost = 3
    else
      -- reset
      resetPowerups()
    end

    if player.powerup_timer == 0 then
      player.active_powerup = -1
      player.powerup_timer = static.powerup_time
    end

    -- spawn new powerups if needed
    if tablelength(powerups) < amountPowerups then
      spawn_powerup_timer = spawn_powerup_timer-1
      if spawn_powerup_timer == 0 then
        spawn_powerup_timer = static.spawn_powerup_time
        newPowerup(justRandom())
      end
    end

  -- DO NOT PUT CODE THAT IS NOT SUPOSED TO RUN WHEN PLAYER IS DEAD BELOW
  -- DO NOT PUT CODE THAT IS NOT SUPOSED TO RUN WHEN PLAYER IS DEAD BELOW
  -- DO NOT PUT CODE THAT IS NOT SUPOSED TO RUN WHEN PLAYER IS DEAD BELOW
  elseif player.dead == true then
    if highscore_name.isTyping and player.newHighscore then
      if love.keyboard.isDown("return") then
        highscore_name.input_done = true
        highscore_name.isTyping = false
      end
    else
      if love.keyboard.isDown("return") and player.newHighscore_done then
        -- resetting
        player.speed = static.speed_sprint
        player.x = 0
        player.y = 0
        player.dead = false
        player.bullet_x = 400
        player.bullet_y = 300
        bullets = {}
        zombies = {}
        powerups = {}
        amountZombies = 3
        zombieSpeed = static.zombieSpeed
        player.active_powerup = -1
        score = 0
        spawn_powerup_timer = static.spawn_powerup_time
        player.powerup_timer = static.powerup_time
        player.newHighscore = false
        player.newHighscore_done = false
        highscore_name.input_done = false
        highscore_name.isTyping = false
        resetPowerups()
        i = 1
        while i <= amountPowerups do
          newPowerup(justRandom())
          i=i+1
        end

        -- trigger new zombie generation
        deadZombie()
      end
    end
  end
end

-- FOR TEXT INPUT WHEN SUBMITTING HIGHSCORES
function love.textinput(t)
  if t ~= " " and string.len(highscore_name.input) < static.highscore_name_limit then
    highscore_name.input = highscore_name.input .. t
  end
end

local utf8 = require("utf8")
function love.keypressed(key)
    if key == "backspace" then
        -- get the byte offset to the last UTF-8 character in the string.
        local byteoffset = utf8.offset(highscore_name.input, -1)

        if byteoffset then
            -- remove the last UTF-8 character.
            -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
            highscore_name.input = string.sub(highscore_name.input, 1, byteoffset - 1)
        end
    end
end

-- FOR DEBUG TOGGLE AND PAUSING THE GAME
function love.keyreleased(key)
   if key == "scrolllock" then
      if debug == false then
        debug = true
      elseif debug == true then
        debug = false
      end
   end

   if key == "pageup" then
     if debug == true then
       if zombie_show_coordinates == false then
         zombie_show_coordinates = true
       else
         zombie_show_coordinates = false
       end
     end
   end

   if key == "escape" then
     if game.isPaused == false and player.dead == false then
       game.isPaused = true
     else
       game.isPaused = false
     end
   end
end
