------------------------------------------------------------------------------
-- Vindinlua: Vindinium bot starter kit for Lua
-- Author: Michael Dowling
-- See: http://vindinium.org
-----------------------------------------------------------------------------

local json = require("dkjson")
local http = require("socket.http")

-- Available game modes and their relative URIs
local GAME_MODE_PATHS = {
  training = "/api/training",
  arena    = "/api/arena"
}

-- Valid directions for input
local VALID_MOVES = {
  Stay  = true,
  North = true,
  South = true,
  East  = true,
  West  = true
}

--------------------------------
--- Map definition
--------------------------------

local Map = {}
Map.__index = Map

-- Map tile enum
Map.TILE = {
  IMPASS = -1,
  EMPTY  = 0,
  HERO_1 = 1,
  HERO_2 = 2,
  HERO_3 = 3,
  HERO_4 = 4,
  MINE_0 = 5,
  MINE_1 = 6,
  MINE_2 = 7,
  MINE_3 = 8,
  MINE_4 = 9,
  TAVERN = 10
}

--------------------------------
--- Tile definition
--------------------------------

local Tile = {}
Tile.__index = Tile

--- Creates a new Tile.
Tile.new = function (id, heroId)
  local tile = {id = id, __heroId = heroId - 1 + Map.TILE.HERO_1}
  setmetatable(tile, Tile)
  return tile
end

--- Returns a number 0-4 if the tile is a mine where 0 represents an
-- unclaimed mine. Returns false if the tile is not a mine.
function Tile:isMine()
  if self.id >= Map.TILE.MINE_0 and self.id <= Map.TILE.MINE_4 then
    return self.id - Map.TILE.MINE_0
  else
    return false
  end
end

--- Returns true if the tile is your hero.
function Tile:isMyHero()
  return self.id == self.heroIdTile
end

--- Returns a number 1-4 if the tile is a hero, otherwise returns false.
function Tile:isHero()
  if self.id > Map.TILE.HERO_1 and self.id < Map.TILE.HERO_4 then
    return (self.id - Map.TILE.HERO_1) + 1
  else
    return false
  end
end

--- Returns true if the tile is a tavern.
function Tile:isTavern()
  return self.id == Map.TILE.TAVERN
end

--- Returns true if the tile is empty.
function Tile:isEmpty()
  return self.id == Map.TILE.EMPTY
end

--- Returns true if the tile is an impassable wood.
function Tile:isImpassable()
  return self.id == Map.TILE.IMPASS
end

--------------------------------
--- Map implementation
--------------------------------

--- Mapping of the serialized tile to the tile enum.
local PARSE_TILES = {
  ["##"] = Map.TILE.IMPASS,
  ["  "] = Map.TILE.EMPTY,
  ["[]"] = Map.TILE.TAVERN,
  ["$-"] = Map.TILE.MINE_0,
  ["$1"] = Map.TILE.MINE_1,
  ["$2"] = Map.TILE.MINE_2,
  ["$3"] = Map.TILE.MINE_3,
  ["$4"] = Map.TILE.MINE_4,
  ["@1"] = Map.TILE.HERO_1,
  ["@2"] = Map.TILE.HERO_2,
  ["@3"] = Map.TILE.HERO_3,
  ["@4"] = Map.TILE.HERO_4
}

-- Vindinium uses 0 as a base and swaps X and Y.
-- Lua uses 1 as a base, and we've coded things to use X, Y and to
-- start at 1 to match idiomatic Lua code.
local function fixMapPosition(pos)
  pos.x = pos.x + 1
  pos.y = pos.y + 1
end

-- Create a new map
-- @param json Table containing Vindinium JSON structured game state
function Map.new(json)
  local x, y = -1, 1
  local self = {
    id=json.game.id,
    turn=json.game.turn,
    maxTurns=json.game.maxTurns,
    hero=json.hero,
    heroes=json.game.heroes,
    viewUrl=json.viewUrl,
    playUrl=json.playUrl,
    grid={{}},
    mines={},
    taverns={},
    __tileCache={},
  }

  for i = 1, #json.game.board.tiles, 2 do
    -- Jump to the next row if needed.
    if x < json.game.board.size then
      x = x + 1
    else
      x = 1
      y = y + 1
      self.grid[y] = {}
    end
    local tile = string.sub(json.game.board.tiles, i, i + 1)
    local value = PARSE_TILES[tile]
    self.grid[y][x] = value
    if value == Map.TILE.TAVERN then
      self.taverns[#self.taverns + 1] = {pos = {x = x, y = y}}
    elseif value >= Map.TILE.MINE_0 and value <= Map.TILE.MINE_4 then
      self.mines[#self.mines + 1] = {
        pos = {x = x, y = y},
        owner = value - Map.TILE.MINE_0
      }
    end
  end

  -- Update the map with parsed variables
  fixMapPosition(self.hero.pos)
  fixMapPosition(self.hero.spawnPos)
  for i = 1, 4, 1 do
    fixMapPosition(self.heroes[i].pos)
    fixMapPosition(self.heroes[i].spawnPos)
  end

  setmetatable(self, Map)
  return self
end

--- Gets the neighboring tiles for the given coordinates.
-- @param x Integer
-- @param y Integer
-- @return Table Sequence of hashes, each containing: {x, y, tile}
function Map:getNeighbors(x, y)
  local results = {}
  for ox = x - 1, x + 1, 1 do
    for oy = y - 1, y + 1, 1 do
      if ox ~= x or oy ~= y then
        local check = self:getTile(ox, oy)
        if check ~= nil then
          results[#results + 1] = {x = ox, y = oy, tile = check}
        end
      end
    end
  end
  return results
end

--- Get the tile for the given grid position.
-- @param x Integer
-- @param y Integer
-- @return Tile or nil if not in bounds.
function Map:getTile(x, y)
  if y > #self.grid or y <= 0 then return nil end
  local tile = self.grid[y][x]
  if tile == nil then return nil end
  -- Add the tile to the cache if it is not present.
  if not self.__tileCache[tile] then
    self.__tileCache[tile] = Tile.new(tile, self.hero.id)
  end
  return self.__tileCache[tile]
end

--------------------------------
--- Public Vindinium interface
--------------------------------

local Vindinium = {
  -- Re-export the Map type.
  Map = Map,
  -- Default Vindinium host
  DEFAULT_HOST = "vindinium.org",
  -- Valid game modes
  GAME_MODES = {
    TRAINING = "training",
    ARENA = "arena"
  },
  -- Valid directions for input
  DIRECTIONS = {
    STAY = "Stay",
    N = "North",
    S = "South",
    E = "East",
    W = "West"
  },
}

-- Build a POST query string body from a table of fields
-- @param fields Hash table of key value pairs to POST
-- @return string
local function buildBody(fields)
  local buffer = {}
  for k, v in pairs(fields) do
    table.insert(buffer, k .. "=" .. v)
  end
  return table.concat(buffer, "&")
end

-- Sends a POST request to a Vindinium host
-- @param url    String URL
-- @param fields Table of POST fields
-- @return table Returns the parsed JSON result
local function request(url, fields)
  local responseBody = {}
  local requestBody = buildBody(fields)

  -- Send the HTTP POST request
  local res, code, headers = http.request{
    url     = url,
    method  = "POST",
    source  = ltn12.source.string(requestBody),
    sink    = ltn12.sink.table(responseBody),
    headers = {
      ["Content-Type"]   = "application/x-www-form-urlencoded",
      ["Content-Length"] = string.len(requestBody)
    }
  }

  -- Ensure that the request sent correctly
  assert(code == 200, "Request failed: " .. code
    .. ": " .. table.concat(responseBody))
  assert(type(responseBody) == 'table', 'Invalid response')
  -- Parse the JSON response
  local obj, pos, err = json.decode(table.concat(responseBody))
  assert(obj ~= nil, "Error decoding JSON: " .. (err or ""))
  return obj.finished, Map.new(obj)
end

-- Runs the main game loop
local function runMainLoop(game, map)
  local finished
  repeat
    -- Call the gameLoop function with the current state to get the move.
    local direction = game.bot(map)
    assert(VALID_MOVES[direction], "Invalid direction: " .. (direction or ""))
    -- Send the move to the server and update the game.
    finished, map = request(map.playUrl, {key=game.key, dir=direction})
  until finished == true
end

-- Create a new instance of Vindinlua and enter into the game loop
--
-- @param game A table containing the following keys:
--   key: API key (required)
--   host: Optional Vindinium game host
--   turns: Optional number of turns to play
--   map: Optional map to use when playing
--   mode: One of "training" or "arena". Defaults to "training"
--   bot: Bot function that accepts a State object and returns a direction
--     string. One of "Stay", "North", "South", "East", or "West".
function Vindinium.play(settings)
  assert((not settings) or type(settings) == "table")
  assert(type(settings.bot) == "function", "bot must be a function")
  local game = {
    key = assert(settings.key, "A key must be provided"),
    host = settings.host or Vindinium.DEFAULT_HOST,
    mode = settings.mode or "training",
    bot = bot,
    turns = settings.turns,
    map = settings.map
  }
  assert(GAME_MODE_PATHS[game.mode], "Invalid game mode: " .. game.mode)
  -- Establish the initial connection and game state.
  local url = "http://" .. game.host .. GAME_MODE_PATHS[game.mode]
  local connectConfig = {key=game.key, turns=game.turns, map=game.map}
  local _, initialState = request(url, connectConfig)
  assert(initialState, "Error connecting to " .. url)
  runMainLoop(game, initialState)
end

return Vindinium
