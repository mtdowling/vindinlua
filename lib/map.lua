-- Enum of map tile types
local Map = {
  IMPASS  = -1,
  EMPTY   = 0,
  PLAYER1 = 1,
  PLAYER2 = 2,
  PLAYER3 = 3,
  PLAYER4 = 4,
  MINE0   = 5,
  MINE1   = 6,
  MINE2   = 7,
  MINE3   = 8,
  MINE4   = 9,
  TAVERN  = 10
}

-- Vindinium uses 0 as a base and swaps X and Y
-- Lua uses 1 as a base, and we've coded things to use X, Y in a 
-- traditional sense
local function fix_position(pos)
  pos.x, pos.y = pos.y + 1, pos.x + 1
end

-- Private function used to parse a map
-- @param map Table with game and map data
local function parse(map)
  local x, y = 1, 1
  map.collision_map = {{}}
  map.grid = {{}}
  map.mines, map.taverns = {}, {}

  for i = 1, #map.game.board.tiles, 2 do
    local value
    local tile = string.sub(map.game.board.tiles, i, i + 1)
    if tile == "##" then
      value = Map.IMPASS
    elseif tile == "  " then
      value = Map.EMPTY
    elseif tile == "[]" then
      value = Map.TAVERN
      map.taverns[#map.taverns + 1] = {pos={x=x, y=y}}
    elseif string.sub(tile, 1, 1) == "$" then
      -- The tile number` is 0 for unclaimed or 1-4 for players
      -- This number is then added to the base of 5 for the tile value
      local owner = string.sub(tile, 2, 2)
      if owner == "-" then owner = 0 else owner = tonumber(owner) end
      map.mines[#map.mines + 1] = {pos={x=x, y=y}, owner=owner}
      value = Map.MINE0 + owner
    elseif string.sub(tile, 1, 1) == "@" then
      value = tonumber(string.sub(tile, 2, 2))
    else
      value = Map.EMPTY
    end

    map.grid[y][x] = value
    if value == Map.EMPTY or value == map.hero.id then
      map.collision_map[y][x] = true
    else
      map.collision_map[y][x] = false
    end

    if x < map.game.board.size then
      x = x + 1
    else
      x = 1
      y = y + 1
      map.grid[y], map.collision_map[y] = {}, {}
    end
  end

  map.grid[#map.grid] = null
  map.collision_map[#map.collision_map] = null

  -- Update the map with parsed variables
  fix_position(map.hero.pos)
  fix_position(map.game.heroes[1].pos)
  fix_position(map.game.heroes[2].pos)
  fix_position(map.game.heroes[3].pos)
  fix_position(map.game.heroes[4].pos)
  map.players = assert(map.game.heroes, "No heroes found")
end

-- Create a new map
-- @param state Table containing Vindinium JSON structured game state
function Map:new(state)
  -- Merge the state table into self
  for k,v in pairs(state) do self[k] = v end
  parse(self)

  -- Allow the Map to be cast to a string
  setmetatable(self, {__tostring = function (map)
    local buffer = {}
    for i = 1, #map.game.board.tiles do
      buffer[#buffer + 1] = string.sub(map.game.board.tiles, i, i)
      if i % (map.game.board.size * 2) == 0 then
        buffer[#buffer + 1] = "\n"
      end
    end
    return table.concat(buffer, "")
  end})

  return self
end

-- Checks if the given grid position is walkable
-- @param x Integer
-- @param y Integer
-- @return bool
function Map:walkable(x, y)
  return self.collision_map[y][x]
end

-- Get the tile for the given grid position
-- @param x Integer
-- @param y Integer
-- @return integer
function Map:tile(x, y)
  return self.grid[y][x]
end

local function get_neighbors(map, cur)
  local n = {}
  if cur.x > 1 then n[#n + 1] = {x=cur.x - 1, y=cur.y} end
  if cur.y < #map.grid then n[#n + 1] = {x=cur.x, y=cur.y + 1} end
  if cur.x < #map.grid then n[#n + 1] = {x=cur.x + 1, y=cur.y} end
  if cur.y > 1 then n[#n + 1] = {x=cur.x, y=cur.y - 1} end
  return n
end

-- Calculate a path from an (X, Y) tuple to an (X, Y) tuple
function Map:path(cur, to, path, visited)
  path = path or {}
  visited = visited or {}
  if not visited[cur.y] then visited[cur.y] = {} end
  -- Skip visited nodes
  if visited[cur.y][cur.x] then return nil end
  -- Mark as visited
  visited[cur.y][cur.x] = true
  path[#path + 1] = cur
  if cur.x == to.x and cur.y == to.y then return path end
  if self:walkable(cur.x, cur.y) then
    -- Try adjacent nodes to build up a path
    for i, n in pairs(get_neighbors(self, cur)) do
      local p = self:path(n, to, path, visited)
      if p then return p end
    end
  end
  -- Remove the dead-end node from the path
  path[#path] = nil
end

-- Return the next move of the hero based on a path iterator
-- @param dx Destination x position
-- @param dy Destination y position
-- @return string|nil
function Map:move_to(dx, dy)
  path = self:path({x=self.hero.pos.x, y=self.hero.pos.y}, {x=dx, y=dy})
  return self:first_in_path(path)
end

function Map:first_in_path(path)
  if not path or #path == 1 then return nil end
  if path[2].x < self.hero.pos.x then return "West" end
  if path[2].y < self.hero.pos.y then return "North" end
  if path[2].y > self.hero.pos.y then return "South" end
  if path[2].x > self.hero.pos.x then return "East" end
end

return Map
