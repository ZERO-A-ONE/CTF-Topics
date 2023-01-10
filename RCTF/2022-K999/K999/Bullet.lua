Bullet = GameObject:extend("Bullet", {size = 2, linearDamping = 1, hit = 0})

local trackImage = gradient({{240,240,180,255},{255,255,255,0}})

local id = 1

function Bullet:init()
  self.pos = {}
end

function Bullet:init(posX, posY)
  self.super.init(self, posX, posY)
  id = id + 1
  self.id = id
  self.physic.body:setBullet(true)
  self.physic.body:setLinearDamping(self.linearDamping)
  self.physic.fixture:setCategory(Railgun.Const.Category.bullet)
  self.physic.fixture:setMask(Railgun.Const.Category.player)
end

function Bullet:deltaValue(speed, angle)
  self.dx = speed * math.cos(angle)
  self.dy = speed * math.sin(angle)
end

function Bullet:debugDraw()
  love.graphics.push('all')
  love.graphics.setPointSize(1)
  love.graphics.setColor(255, 0, 0, 255)
  love.graphics.points(self.pos.x, self.pos.y)
  love.graphics.print(self.id, self.pos.x, self.pos.y)
  love.graphics.pop()
end

function Bullet:draw()
  self.super.draw(self)
  drawInRect(trackImage, self.pos.x, self.pos.y, self.speed/30, 2, math.pi + self.angle)
end

function Bullet:update(dt)
  self.super.update(self, dt)
  self.speed, self.angle = getSpeed(self.physic.body)
  if self.speed  <= 30 then
    self.removed = true
  end
end

function Bullet:fly(speed, angle)
  self.angle = angle
  self:deltaValue(speed, angle)
  self.physic.body:applyLinearImpulse(self.dx, self.dy)
end

function Bullet:beginContact(other, contact)
  self.super.beginContact(self, other, contact)
  if isInstanceOfClass(other, Enemy) then
    local enemy = other
    if enemy.alive then
      self.hit = self.hit + 1
      if not (self.physic.body:getLinearDamping() == 100) then
        self.physic.body:setLinearDamping(100)
      end
      if world.debug then
        print(world.debug.frame .. ") bullet[".. self.id .. "] in enemy[" .. enemy.id .. "] speed:" .. self.speed)
      end
      enemy.bullets[self.id] = {speed = self.speed}
    end
  end
end

function Bullet:endContact(other, contact)
  self.super.beginContact(self, other, contact)
  if isInstanceOfClass(other, Enemy) then
    local enemy = other
    if enemy.alive then
      self.hit = self.hit - 1
      if self.hit <= 0 then
        self.physic.body:setLinearDamping(self.linearDamping)
      end
      local inSpeed = enemy.bullets[self.id].speed
      --enemy.bullets[self] = nil
      local damage = inSpeed - self.speed
      if damage > 30 then
        enemy:hit(damage)
      end
      
      if world.debug then
        print(world.debug.frame .. ") bullet[".. self.id .. "] out enemy[" .. enemy.id .. "] speed:" .. self.speed .. " hit:" .. self.hit .. " damge:" .. damage)
      end
    end
  end
end