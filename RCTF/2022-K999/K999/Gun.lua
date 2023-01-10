require("Bullet")

Gun = class("Gun", {
    rpm = 600,                --每分钟射速
    auto = true, 
    accuracy = 4*math.pi/180,
    maxAmmo = 30,
    reloadTime = 3,
    muzzleVelocity = 14,       -- 子弹初速
    fireTime = 0,             -- 记录上次开火的时间
    offset = {
      x = -8, 
      y = 2,},
  })

-- owner 必须是 GameObject
function Gun:init(owner)
  if isInstanceOfClass(owner, GameObject) then
    self.owner = owner
  end
  
  --开火效果
  local image = love.graphics.newImage('res/img/circle.png')
  self.ps = getPS('res/particle/Fire', image)
  self.image = love.graphics.newImage('res/img/gun.png')
  self.ammo = self.maxAmmo
  self.remainReloadTime = 0
end

function Gun:fire()
  if self.ammo <= 0 then return end --弹药不足不能开火
  if self.isFire then return end
  self.isFire = true
  if self.auto then self.fireTime = love.timer.getTime() end
end

function Gun:shot(dt)
  while self.fireTime < love.timer.getTime() and self.ammo > 0 do
    local angle = math.angle(self.owner.pos.x, self.owner.pos.y, world:mousePos())
    angle = angle + (love.math.random() - 0.5) * self.accuracy
    local bullet = Bullet:new(self.owner.pos.x, self.owner.pos.y)
    world:add(bullet)
    bullet:fly(self.muzzleVelocity, angle)
    self.ammo = self.ammo - 1
    self.fireTime = self.fireTime + 1/(self.rpm/60)
  end
end

function Gun:stop()
  self.isFire = false
end

function Gun:reload()
  self.remainReloadTime = self.reloadTime
end

function Gun:update(dt)
  if self.remainReloadTime > 0 then
    self.remainReloadTime = self.remainReloadTime - dt
    if self.remainReloadTime <= 0 then
      self.ammo = self.maxAmmo
    end
  end
  if self.isFire and self.auto then
    if self.ps then 
      self.ps:update(dt) 
    end
    self:shot()
    if self.ammo <= 0 and self.remainReloadTime <= 0 then
      self:stop()
      self:reload()
    end
  end
end

function Gun:draw()
  love.graphics.draw(self.image, self.owner.pos.x+self.offset.x, self.owner.pos.y+self.offset.y)
  if self.isFire and self.ps and self.auto then
    love.graphics.draw(self.ps, self.owner.pos.x, self.owner.pos.y)
  end
end