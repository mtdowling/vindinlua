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
      table.insert(map.taverns, {pos={x=x, y=y}})
    elseif string.sub(tile, 1, 1) == "$" then
      -- The tile number` is 0 for unclaimed or 1-4 for players
      -- This number is then added to the base of 5 for the tile value
      local owner = string.sub(tile, 2, 2)
      if owner == "-" then owner = 0 else owner = tonumber(owner) end
      table.insert(map.mines, {pos={x=x, y=y}, owner=owner})
      value = Map.MINE0 + owner
    else
      value = Map.EMPTY
    end

    map.grid[y][x] = value
    if value == Map.EMPTY or value == Map.PLAYER1 then
      map.collision_map[y][x] = false
    else
      map.collision_map[y][x] = true
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
  return assert(self.collision_map[y][x], "Invalid tile location")
end

-- Get the tile for the given grid position
-- @param x Integer
-- @param y Integer
-- @return integer
function Map:tile(x, y)
  return assert(self.grid[y][x], "Invalid tile location")
end

return Map
