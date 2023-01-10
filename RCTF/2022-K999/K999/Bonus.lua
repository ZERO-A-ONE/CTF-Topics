Bonus = GameObject:extend("Bonus", {
  size = 20,
})

function Bonus:init(x, y)
  self.super.init(self, x, y)
  self.physic.fixture:setSensor(true)
end

function Bonus:draw()
  self.super.draw(self)
  love.graphics.push("all")
  love.graphics.setColor(255,255,255,255)
  love.graphics.circle("fill", self.pos.x, self.pos.y, self.size)
  love.graphics.pop()
end

function Bonus:beginContact(other, contact)
  self.super.beginContact(self, other, contact)
  if isInstanceOfClass(other, Player) then
    local player = other
    player.hp = player.hp + 50
    if player.hp >= 100 then
      player.hp = 100
    end
    self.removed = true
  end
end

function Bonus.Generate(posX, posY)
  if posX == nil then posX = world.size.width * love.math.random() end
  if posY == nil then posY = world.size.height * love.math.random() end
  if size == nil then size = 20 end
  local pos = {x = posX, y = posY}
  while world.map:isSolid(pos) do
    pos.x = world.size.width * love.math.random()
    pos.y = world.size.height * love.math.random()
  end
  local bouns = Bonus:new(pos.x, pos.y)
  world:add(bouns)
end