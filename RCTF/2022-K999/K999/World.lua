require('Map')
require "light/postshader"
require "light/light"
require "Bonus"
local box2DDebugDraw = require('debugWorldDraw')
World = class("World")

local function instanceOfClass(aClass, object1, object2)
  if isInstanceOfClass(object1, aClass) then
    return object1
  end
  if isInstanceOfClass(object2, aClass) then
    return object2
  end
  return nil
end

local function beginContact(a, b, coll)
  if isInstanceOfClass(a:getUserData(), GameObject) and isInstanceOfClass(b:getUserData(), GameObject) then
    a:getUserData():beginContact(b:getUserData(), coll)
    b:getUserData():beginContact(a:getUserData(), coll)
  end
end

local function endContact(a, b, coll)
  if isInstanceOfClass(a:getUserData(), GameObject) and isInstanceOfClass(b:getUserData(), GameObject) then
    a:getUserData():endContact(b:getUserData(), coll)
    b:getUserData():endContact(a:getUserData(), coll)
  end
end

local function preSolve(a, b, coll)
  local enemy = instanceOfClass(Enemy, a:getUserData(), b:getUserData())
  
  --所有物体都不会和死掉的敌人发生碰撞
  if enemy and not enemy.alive then
    coll:setEnabled(false)
  end
end

local _objects = {}

--[[
  map: 创建世界时使用的地图，会覆盖 width 和 height 参数
]]
function World:init(option)
  -- 初始化物理引擎
  love.physics.setMeter(32)
  self.physics = love.physics.newWorld(0, 0, true)
  self.physics:setCallbacks(beginContact, endContact, preSolve)
  
  --self:initLight()
  
  self.size = {}
  -- 读取地图信息
  if option.mapPath then
    self:loadMap(option.mapPath)
  else 
    if not option.width then option.width = 0 end
    if not option.height then option.height = 0 end
    self.size.width = option.width
    self.size.height = option.height
  end
  

  self.focus = {x = self.size.width/2, y = self.size.height/2}
  self.enemyCount = 0
  self.KillenemyCount = 0
  self.bonusCount = 0
  
  self:initPlayer()
end

function World:initPlayer()
  self.player = Player:new()
  self.player.weapon = Gun:new(self.player)
  
  self:add(self.player)
  self.focus = self.player.pos
end

function World:initLight()
  -- light world
	self.light = love.light.newWorld()
  self.light.setAmbientColor(15, 15, 31) -- optional
  
  --[[ create light (x, y, red, green, blue, range)
    lightMouse = self.light.newLight(0, 0, 255, 127, 63, 300)
    lightMouse.setGlowStrength(0.3) -- optional ]]--
end

function World:loadMap(mapPath)
  self.map = Map:new(mapPath, self.physics, self.light)
  width, height = self.map:size()
  self.size.width = width
  self.size.height = height
end

function World:add(object)
  if object.body then
    object.body:setActive(true)
  end
  if object.light and self.light then
    object.light.object = self.light.newLight(0, 0, unpack(object.light.color), object.light.range)
  end
  _objects[#_objects+1] = object
end

function World:vision()
  local rect = {}
  rect.x, rect.y = self:worldCoordinates(0, 0)
  rect.width, rect.height = love.graphics.getWidth(), love.graphics.getHeight()
  return rect
end

local function removeUnusedObjects()
  local indexes = {}
  for i, object in ipairs(_objects) do
    if object.removed == true then 
      indexes[#indexes+1] = i 
      --print('['..frameIndex..']('..i..')'..object.name..':'..object.pos.x..','..object.pos.y)
    end
  end
  for i = #indexes, 1, -1 do
    local object = table.remove(_objects, indexes[i])
    if object.physic then object.physic.body:destroy() end
    --[[
    if object == nil then
      print('['..frameIndex..']'..'out of range')
    end
    ]]--
  end
end

function World:removeOutOfRangeObjects()
  for i,object in ipairs(_objects) do  
    if not object.solid then
      if object.pos.x < 0 or
         object.pos.y < 0 or
         object.pos.x > self.size.width or
         object.pos.y > self.size.height then
            if object == player then 
              player:die()
            else
              object.removed = true
            end
      end
    end
  end
end

function World:checkCircularCollision(ax, ay, bx, by, ar, br)
  if ar == nil then ar = 0 end
  if br == nil then br = 0 end
	local dx = bx - ax
	local dy = by - ay
	return dx^2 + dy^2 < (ar + br)^2
end

function World:CheckRectCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

function World:checkRectPointCollision(rectX, rectY, rectWidth, rectHeight, pointX, pointY)
  return self:CheckRectCollision(rectX, rectY, rectWidth, rectHeight, pointX, pointY, 0, 0)
end

function World:checkCircleRectCollision(circleX, circleY, circleRadius, rectX, rectY, rectWidth, rectHeight)
  if not circleRadius then circleRadius = 0 end
  
  local result = self:checkRectPointCollision(rectX-circleRadius, rectY-circleRadius, rectWidth+circleRadius*2, rectHeight+circleRadius*2, circleX, circleY)
  return result

--[[  
  --左上
  if self:checkRectPointCollision(rectX-circleRadius, rectY-circleRadius, circleRadius, circleRadius, circleX, circleY) then
    return World:checkCircularCollision(circleX, circleY, rectX, rectY, circleRadius)
  end
  
  --右上
  if self:checkRectPointCollision(rectX+rectWidth, rectY-circleRadius, circleRadius, circleRadius, circleX, circleY) then
    return World:checkCircularCollision(circleX, circleY, rectX+rectWidth, rectY, circleRadius)
  end
  
  --左下
  if self:checkRectPointCollision(rectX-circleRadius, rectY, circleRadius, circleRadius, circleX, circleY) then
    return World:checkCircularCollision(circleX, circleY, rectX, rectY+rectHeight, circleRadius)
  end
  
  --右下
  if self:checkRectPointCollision(rectX+rectWidth, rectY+rectHeight, circleRadius, circleRadius, circleX, circleY) then
    return World:checkCircularCollision(circleX, circleY, rectX+rectWidth, rectY+rectHeight, circleRadius)
  end
  
  return false
  --]]
end

function World:collide(object1, object2)
  local bullet, enemy, player
  bullet = instanceOfClass(Bullet, object1, object2)
  enemy = instanceOfClass(Enemy, object1, object2)
  player = instanceOfClass(Player, object1, object2)
  
  
end
-- 控制怪物的生成速度
local EnemyGenerateRate = 0.0001
local remainTime = 0

local BonusGenerateRate = 1
local bonusRemainTime = BonusGenerateRate

function World:update(dt)
  if world.debug then
    world.debug.findPathUsage = 0
    world.debug.findPathCall = 0
  end
  
  if self.pause then
    return
  end
  
  if Railgun.Config.Enemy.Generate and self.enemyCount < Railgun.Config.Enemy.Max then
    remainTime = remainTime - dt
    if remainTime <= 0 then
      Enemy.Generate()
      self.enemyCount = self.enemyCount + 1
      -- 控制怪物的生成速度
      remainTime = remainTime + EnemyGenerateRate
    end
  end
  
  if Railgun.Config.Bonus.Generate and self.bonusCount < Railgun.Config.Bonus.Max then
    bonusRemainTime = bonusRemainTime - dt
    if bonusRemainTime <= 0 then
      Bonus.Generate()
      self.bonusCount = self.bonusCount + 1
      bonusRemainTime = bonusRemainTime + BonusGenerateRate
    end
  end
  
  self.physics:update(dt)
  if self.debug then
    if not self.debug.frame then
      self.debug.frame = 0
    end
    self.debug.frame = self.debug.frame + 1
  end
  for i, object in ipairs(_objects) do
    if type(object.handleInput) == 'function' then
      object:handleInput(dt)
    end
  end
  
  for i, object in ipairs(_objects) do
    if type(object.update) == 'function' then
      object:update(dt)
    end
  end
  
  self.map:update(dt)
  
  self:removeOutOfRangeObjects()
  removeUnusedObjects()
  
  if lightMouse then
    lightMouse.setPosition(love.mouse.getX(), love.mouse.getY())
  end
  
  if world.debug then
    if world.debug.findPathUsage > 2/60 then
      print ("find path usage:" .. world.debug.findPathUsage .. "(" .. world.debug.findPathCall .. " times)")
    end
  end
end

function World:draw()
  love.graphics.push()
  love.graphics.translate(math.round(-self.focus.x+love.graphics.getWidth()/2), math.round(-self.focus.y+love.graphics.getHeight()/2))--love.graphics.rectangle('line', 0, 0, self.size.width, self.size.height)
  
  self.map:draw()
  
  local window = self:vision()
  --love.graphics.line(0, window.y+window.height, self.size.width, window.y+window.height)
  love.graphics.push('all')
  --box2DDebugDraw(self.physics, window.x, window.y, window.width, window.height)
  love.graphics.pop()
  
  for i, object in ipairs(_objects) do
    if object.forceDraw or self:checkCircleRectCollision(object.pos.x, object.pos.y, object.size, window.x, window.y, window.width, window.height) then
      love.graphics.push('all')
      object:draw()
      love.graphics.pop()
    end
  end
  
  if self.light then
    love.graphics.push()
    
    self.light.setTranslation(self.focus.x-love.graphics.getWidth()/2, self.focus.y-love.graphics.getHeight()/2)
    -- update lightmap (doesn't need deltatime)
    self.light.update()

    -- draw lightmap shadows
    self.light.drawShadow()

    -- draw lightmap shine
    self.light.drawShine()
    love.graphics.pop()
  end
  
  love.graphics.pop()
end

--将屏幕坐标转换为游戏坐标
function World:worldCoordinates(screenX, screenY)
  if screenX == nil or screenY == nil then return end
  return self.focus.x-love.graphics.getWidth()/2+screenX, self.focus.y-love.graphics.getHeight()/2+screenY
end

function World:screenCoordinates(worldX, worldY)
  if worldX == nil or worldY == nil then return end
  return worldX-(self.focus.x-love.graphics.getWidth()/2), worldY-(self.focus.y-love.graphics.getHeight()/2)
end

function World:mousePos()
  return self:worldCoordinates(love.mouse.getPosition())
end

function World:remove(target)
  local index = -1
  for i, object in ipairs(_objects) do
    if target == object then index = i; break end
  end
  table.remove(_objects, index)
end