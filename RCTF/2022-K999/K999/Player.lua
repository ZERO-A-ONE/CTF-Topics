require('Gun')
local anim8 = require "anim8.anim8"

Player = GameObject:extend("Player", 
  {playerName = "New Player",
   pos = {x = 50, y = 50},
   size = 16,
   speed = 1400,
   alive = true,
   hp = 100,
   forceDraw = true,
   linearDamping = 16,
   debug = false,
   animiatIndex = 1,
   status = "run",
   direction = {
     x = 1,
     y = 1,
   }})

function Player:init()
  self.super.init(self)
  self.slash = self.speed/2^0.5
  self.physic.body:setLinearDamping(self.linearDamping)
  self.physic.fixture:setCategory(Railgun.Const.Category.player)
  self:initAnimation()
  self.tile = {}
  self.light = {
    color = {255, 127, 63},
    range = 300
  }
  
end

function Player:initAnimation()
  local image = love.graphics.newImage("res/img/moe.png")
  local g = anim8.newGrid(32, 32, image:getWidth(), image:getHeight())
  self.frame = {
    ["image"] = image,
    front = {
      stand = {
        quads = g(1,1),
      },
      run = {
        quads = g("1-4",2),
      },
    },
    back = {
      stand = {
        quads = g(2,1),
      },
      run = {
        quads = g("1-4",3),
      },
    }
  }

  self.timer = love.timer.getTime()
end

function Player:setSpeed(speed)
  self.speed = speed
  self.slash = self.speed/2^0.5
end

function Player:draw()
  self.super.draw(self)
  
  local direction 
  if self.direction.y == 1 then
    direction = "front"
  else
    direction = "back"
  end
  
  local animate = self.frame[direction][self.status]
  local index = math.fmod(self.animiatIndex, #animate.quads) + 1
  love.graphics.draw(self.frame.image, animate.quads[index], self.pos.x, self.pos.y, 0, self.direction.x, 1, 16, 16)

  if self.weapon then
    self.weapon:draw()
  end
  
  -- 绘制阴影
  love.graphics.push("all")
  love.graphics.setColor(0,0,0, 100)
  love.graphics.ellipse("fill", self.pos.x, self.pos.y + self.size, 10, 2)
  love.graphics.pop()
end

function Player:debugDraw()
  self.super.debugDraw(self)
  love.graphics.setColor(100, 100, 255, 255)
  love.graphics.circle('line', self.pos.x, self.pos.y, self.size)
end

function Player:handleInput(dt)
  if love.mouse.isDown(1) then
    self.weapon:fire()
  else
    self.weapon:stop()
  end
  
  local downKeys = ''
  if love.keyboard.isDown('s') then downKeys = downKeys..'s' end
  if love.keyboard.isDown('w') then downKeys = downKeys..'w' end
  if love.keyboard.isDown('a') then downKeys = downKeys..'a' end
  if love.keyboard.isDown('d') then downKeys = downKeys..'d' end
  
  --local dx, dy = 0, 0
  if downKeys == 's'  then self.physic.body:applyLinearImpulse(0, self.speed*dt) end
  if downKeys == 'w'  then self.physic.body:applyLinearImpulse(0, -self.speed*dt) end
  if downKeys == 'a'  then self.physic.body:applyLinearImpulse(-self.speed*dt, 0) end
  if downKeys == 'd'  then self.physic.body:applyLinearImpulse(self.speed*dt, 0) end
  if downKeys == 'wa' then self.physic.body:applyLinearImpulse(-self.slash*dt, -self.slash*dt) end
  if downKeys == 'wd' then self.physic.body:applyLinearImpulse(self.slash*dt, -self.slash*dt) end
  if downKeys == 'sa' then self.physic.body:applyLinearImpulse(-self.slash*dt, self.slash*dt) end
  if downKeys == 'sd' then self.physic.body:applyLinearImpulse(self.slash*dt, self.slash*dt) end
  
  --self.pos.x = self.pos.x + dx * dt
  --self.pos.y = self.pos.y + dy * dt
end

function Player:update(dt)
  self.super.update(self, dt)
  local currentTile = {}
  currentTile = world.map:tileCoordinates(self.pos)
  if not (currentTile.x == self.tile.x) or not (currentTile.y == self.tile.y) then
    self.tileChanged = true
    self.tile = currentTile
  else
    self.tileChanged = false
  end
  if self.weapon then self.weapon:update(dt) end
  if self.light.object then
    self.light.object.setPosition(self.pos.x, self.pos.y)
  end
  
  local speed = getSpeed(self.physic.body, 1)
  
  local speedX, speedY = self.physic.body:getLinearVelocity()

  if math.abs(speedX) > 1 then
    if speedX > 0 then
      self.direction.x = 1
    else
      self.direction.x = -1
    end
  end
  
  if math.abs(speedY) > 1 then
    -- 这里 -10 是表示向上移动的速度大于 10 才绘制背朝屏幕的图片
    -- 因为横着走的时候也用背朝屏幕的图片感觉很怪
    if speedY > -10 then
      self.direction.y = 1
    else
      self.direction.y = -1
    end
  end
  
  -- 速度小于 20 在屏幕上就看不出角色在移动了
  if not (speed < 20) then
    self.status = "run"
  else
    self.status = "stand"
  end
  
  local fps = math.modf(speed/20)

  if love.timer.getTime() - self.timer > 1/fps then
    self.timer = love.timer.getTime()
    self.animiatIndex = self.animiatIndex + 1
  end
end

function Player:hit(damge)
  self.hp = self.hp - damge
  if self.hp <= 0 then
    self:die()
  end
end

function Player:die()
  self.alive = false
  self.removed = true
end
