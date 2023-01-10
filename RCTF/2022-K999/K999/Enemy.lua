Enemy = GameObject:extend("Enemy", 
  {
    size = 8, 
    speed = 1200, 
    alive = true, 
    linearDamping = 8, 
    damge = 5,
    hp = 4000,
    bullets = {}, --击中当前敌人的子弹，用来计算伤害
    contactObjects = {count = 0}, --附近的敌人
    hitRate = 1, -- 一秒攻击一次
    lastHitTime = 0,
  })

if Railgun.Config.debug then
  Enemy.id = 0
end

function Enemy:init(posX, posY)
  self.super.init(self, posX, posY)
  self.physic.body:setLinearDamping(self.linearDamping)
  self.physic.fixture:setCategory(Railgun.Const.Category.enemy)
  self.physic.fixture:setMask(Railgun.Const.Category.bullet)
  self.currentTile = {}
  self:initSensor()
  if Railgun.Config.debug then
    if not Enemy.id then
      Enemy.id = 0
    end
    Enemy.id = Enemy.id + 1
    self.id = Enemy.id
  end
end

function Enemy:initSensor()
  self.physic.sensor = love.physics.newFixture(self.physic.body, self.physic.shape)
  self.physic.sensor:setDensity(0)
  self.physic.sensor:setSensor(true)
  self.physic.sensor:setUserData(self)
  self.physic.sensor:setMask(Railgun.Const.Category.player)
  self.physic.body:resetMassData()
end

function Enemy:draw()
  love.graphics.push('all')
  if self.alive then
    love.graphics.setColor(100, 0, 0, 255)
    love.graphics.circle('fill', self.pos.x, self.pos.y, self.size)
  elseif self.diePS then
    love.graphics.draw(self.diePS, self.pos.x, self.pos.y)
  end
  love.graphics.pop()
end

--向指定坐标移动
function Enemy:moveTo(pos, dt)
  local angle = math.angle(self.pos.x, self.pos.y, pos.x, pos.y)
  local dx = self.speed * math.cos(angle) * dt
  local dy = self.speed * math.sin(angle) * dt
  self.physic.body:applyLinearImpulse(dx, dy)
end

function Enemy:findPathTo(target)
  local startTime
  if world.debug then
    startTime = love.timer.getTime()
  end
  self.path = world.map:findPath(self.pos, target)
  if world.debug then
    world.debug.findPathCall = world.debug.findPathCall + 1
    world.debug.findPathUsage = world.debug.findPathUsage + (love.timer.getTime() - startTime)
  end
end

function Enemy:moveOnPath(dt)
  if not self.path or #self.path == 0 then return end
  local target = self.path[1]
  self.currentTile = world.map:tileCoordinates(self.pos)
  if self.currentTile.x == target.x and self.currentTile.y == target.y then
    table.remove(self.path, 1)
    target = self.path[1]
  end
  if not target then 
    self.path = nil 
    return 
  end
  self:moveTo(world.map:worldCoordinates(target), dt)
end

function Enemy:moveToTarget(dt)
  if self.debug then
    self:moveTo(self.target.pos, dt)
    return
  end
  
  -- 如果和目标之间没有阻挡，直接向目标移动
  local hasWall
  world.physics:rayCast(
    self.pos.x, 
    self.pos.y, 
    self.target.pos.x, 
    self.target.pos.y, 
    function (fixture, posX, posY, xn, yn, fraction) 
      if fixture:getCategory() == Railgun.Const.Category.wall then
        hasWall = true
        return 0
      end
      return 1
    end)
  if not hasWall then
    self:moveTo(self.target.pos, dt)
    return
  end
    
  if self.target.tileChanged or not self.path then
    self:findPathTo(self.target.pos)
  end
  self:moveOnPath(dt)
end

function Enemy:update(dt)
  self.super.update(self, dt)
  if self.alive then
    if self.target then
      self:moveToTarget(dt)
    end
    if self.contactObjects.count > 0 then
      self:attrck()
    end 
    
  elseif self.diePS then
    self.diePS:update(dt)
    if self.removeRemainTime <= 0 then
      self.removed = true
    end
    self.removeRemainTime = self.removeRemainTime - dt
  end
end

function Enemy:debugDraw()
  if not self.path then return end
  local startPos = self.pos
  for i, target in ipairs(self.path) do
    local pos = world.map:worldCoordinates(target)
    love.graphics.line(startPos.x, startPos.y, pos.x, pos.y)
    startPos = pos
  end
end

function Enemy:die()
  if not self.alive then return end
  world.enemyCount = world.enemyCount - 1
  world.KillenemyCount = world.KillenemyCount + 1
  self.alive = false
  if not self.diePS then
    local image = love.graphics.newImage('res/img/circle.png')
    self.diePS = getPS('res/particle/Blood', image)
    self.removeRemainTime = self.diePS:getEmitterLifetime()+math.max(self.diePS:getParticleLifetime())
  end
end

function Enemy:attrck()
  if self.lastHitTime < love.timer.getTime() - (1/self.hitRate) then
    for key, object in pairs(self.contactObjects) do
      if not (key == "count") then
        object:hit(self.damge)
      end
    end
    self.lastHitTime = love.timer.getTime()
  end
end

function Enemy:hit(damage)
  self.hp = self.hp - damage
  if self.hp <= 0 then
    self:die()
  end
end

function Enemy.Generate(posX, posY, size)
  if posX == nil then posX = world.size.width * love.math.random() end
  if posY == nil then posY = world.size.height * love.math.random() end
  if size == nil then size = 20 end
  local pos = {x = posX, y = posY}
  while world.map:isSolid(pos) do
    pos.x = world.size.width * love.math.random()
    pos.y = world.size.height * love.math.random()
  end
  local enemy = Enemy:new(pos.x, pos.y)
  enemy.target = world.player
  world:add(enemy)
end

function Enemy:beginContact(other, contact)
  self.super.beginContact(self, other, contact)
  if isInstanceOfClass(other, Player) then
    local player = other
    --怪物碰到玩家就会攻击
    if self.alive and player.alive then
      self.contactObjects[player] = player
      self.contactObjects.count = self.contactObjects.count + 1
    end
  end
end

function Enemy:endContact(other, contact)
  self.super.endContact(self, other, contact)
  if self.contactObjects[other] then
    self.contactObjects.count = self.contactObjects.count - 1
    self.contactObjects[other] = nil
  end
end