-- Returns the angle between two points.
function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end

function math.round(num)
  local int, float = math.modf(num)
  if float >= 0.5 then
    return int + 1
  else 
    return int
  end
end

function isInstanceOfClass(instance, aClass)
  return class.isInstance(instance) and instance:instanceOf(aClass)
end

function getSpeed(body, returnCount)
  if not returnCount then returnCount = 4 end
  local speedX, speedY = body:getLinearVelocity()
  local speed, angle
  speed = math.sqrt(speedX * speedX + speedY * speedY)
  if returnCount >= 2 then
    angle = math.atan2(speedY, speedX)
  end
  
  if returnCount == 1 then
    return speed
  else
    return speed, angle, speedX, speedY
  end
end

-- 更新射线在屏幕边缘的位置
function updateEdgePoint()
  mouse.x, mouse.y = love.mouse.getPosition()
  local dx = mouse.x - player.pos.x
  local dy = mouse.y - player.pos.y
  local point = {}
  point.x = player.pos.x
  point.y = player.pos.y
  if dx == 0 then 
    if dy > 0 then
      point.y = love.graphics.getHeight()
    else
      point.y = 0
    end
  elseif dy == 0 then
    if dx > 0 then
      point.x = love.graphics.getWidth()
    else
      point.x = 0
    end
  else
    local k = dy/dx
    if dx > 0 then
      point.x = love.graphics.getWidth()
    else
      point.x = 0
    end
    point.y = ((point.x - mouse.x) * k) + mouse.y
  end
  return point
end

--生成粒子效果
function getPS(name, image)
    local ps_data = require(name)
    local particle_settings = {}
    particle_settings["colors"] = {}
    particle_settings["sizes"] = {}
    for k, v in pairs(ps_data) do
        if k == "colors" then
            local j = 1
            for i = 1, #v , 4 do
                local color = {v[i], v[i+1], v[i+2], v[i+3]}
                particle_settings["colors"][j] = color
                j = j + 1
            end
        elseif k == "sizes" then
            for i = 1, #v do particle_settings["sizes"][i] = v[i] end
        else particle_settings[k] = v end
    end
    local ps = love.graphics.newParticleSystem(image, particle_settings["buffer_size"])
    ps:setAreaSpread(string.lower(particle_settings["area_spread_distribution"]), particle_settings["area_spread_dx"] or 0 , particle_settings["area_spread_dy"] or 0)
    ps:setBufferSize(particle_settings["buffer_size"] or 1)
    local colors = {}
    for i = 1, 8 do 
        if particle_settings["colors"][i][1] ~= 0 or particle_settings["colors"][i][2] ~= 0 or particle_settings["colors"][i][3] ~= 0 or particle_settings["colors"][i][4] ~= 0 then
            table.insert(colors, particle_settings["colors"][i][1] or 0)
            table.insert(colors, particle_settings["colors"][i][2] or 0)
            table.insert(colors, particle_settings["colors"][i][3] or 0)
            table.insert(colors, particle_settings["colors"][i][4] or 0)
        end
    end
    ps:setColors(unpack(colors))
    ps:setColors(unpack(colors))
    ps:setDirection(math.rad(particle_settings["direction"] or 0))
    ps:setEmissionRate(particle_settings["emission_rate"] or 0)
    ps:setEmitterLifetime(particle_settings["emitter_lifetime"] or 0)
    ps:setInsertMode(string.lower(particle_settings["insert_mode"]))
    ps:setLinearAcceleration(particle_settings["linear_acceleration_xmin"] or 0, particle_settings["linear_acceleration_ymin"] or 0, 
                             particle_settings["linear_acceleration_xmax"] or 0, particle_settings["linear_acceleration_ymax"] or 0)
    if particle_settings["offsetx"] ~= 0 or particle_settings["offsety"] ~= 0 then
        ps:setOffset(particle_settings["offsetx"], particle_settings["offsety"])
    end
    ps:setParticleLifetime(particle_settings["plifetime_min"] or 0, particle_settings["plifetime_max"] or 0)
    ps:setRadialAcceleration(particle_settings["radialacc_min"] or 0, particle_settings["radialacc_max"] or 0)
    ps:setRotation(math.rad(particle_settings["rotation_min"] or 0), math.rad(particle_settings["rotation_max"] or 0))
    ps:setSizeVariation(particle_settings["size_variation"] or 0)
    local sizes = {}
    local sizes_i = 1 
    for i = 1, 8 do 
        if particle_settings["sizes"][i] == 0 then
            if i < 8 and particle_settings["sizes"][i+1] == 0 then
                sizes_i = i
                break
            end
        end
    end
    if sizes_i > 1 then
        for i = 1, sizes_i do table.insert(sizes, particle_settings["sizes"][i] or 0) end
        ps:setSizes(unpack(sizes))
    end
    ps:setSpeed(particle_settings["speed_min"] or 0, particle_settings["speed_max"] or 0)
    ps:setSpin(math.rad(particle_settings["spin_min"] or 0), math.rad(particle_settings["spin_max"] or 0))
    ps:setSpinVariation(particle_settings["spin_variation"] or 0)
    ps:setSpread(math.rad(particle_settings["spread"] or 0))
    ps:setTangentialAcceleration(particle_settings["tangential_acceleration_min"] or 0, particle_settings["tangential_acceleration_max"] or 0)
    ps:setRelativeRotation(true)
    return ps
end

--[[
生成渐变图
@param colors Array 颜色 RGBA 数组。
例如白色到透明的渐变：{{255,255,255,255},{255,255,255,0}}
Alpha 可以省略，默认为 255，不透明。
返回一张可拉伸的图片
]]
function gradient(colors)
    local result = love.image.newImageData(#colors, 1)
    for i, color in ipairs(colors) do
        local x, y = i - 1, 0
        result:setPixel(x, y, color[1], color[2], color[3], color[4] or 255)
    end
    result = love.graphics.newImage(result)
    result:setFilter('linear', 'linear')
    return result
end

--绘制渐变图案
function drawInRect(img, x, y, w, h, r, ox, oy, kx, ky)
    return -- tail call for a little extra bit of efficiency
    love.graphics.draw(img, x, y, r, w / img:getWidth(), h / img:getHeight(), ox, oy, kx, ky)
end