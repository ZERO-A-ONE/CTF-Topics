PathFinder = class("PathFinder")

local Grid = require ("jumper.grid") -- The grid class
local Jumper = require ("jumper.pathfinder") -- The pathfinder lass

function PathFinder:init(map)
  local grid = Grid(map)
  self.pathFinder = Jumper(grid, 'JPS', 0)
end

function PathFinder:improvePath(path)
  if #path < 3 or not path then return path end
  
  local improvedPath = {}
  local direction = nil
  for index = 1, #path - 1 do
    local nextDirection = {}
    nextDirection.x = path[index].x - path[index+1].x
    nextDirection.y = path[index].y - path[index+1].y
    if not direction then
      table.insert(improvedPath, path[index])
    else 
      if direction.x ~= nextDirection.x or direction.y ~= nextDirection.y then
        table.insert(improvedPath, path[index])
      end
    end
    direction = nextDirection
  end
  if not (improvedPath[#improvedPath].x == path[#path].x and improvedPath[#improvedPath].y == path[#path].y) then
    table.insert(improvedPath, path[#path])
  end
  return improvedPath
end

function PathFinder:findPath(fromX, fromY, toX, toY)
  local time = love.timer.getTime()
	local path = self.pathFinder:getPath(fromX, fromY, toX, toY, false)
  --path = self:improvePath(path)
  local usage = love.timer.getTime()-time
  return path
end