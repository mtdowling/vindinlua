------------------------------------------------------------------------------
-- Vindinlua: Vindinium bot starter kit for Lua
-- Author: Michael Dowling
-- See: http://vindinium.org
-----------------------------------------------------------------------------

local json = require("dkjson")
local http = require("socket.http")
local Map = require("map")

-- Available game modes and their relative URIs
local game_modes = {
  training = "/api/training",
  arena    = "/api/arena"
}

-- Valid directions for input
local valid_moves = {
  Stay  = true,
  North = true,
  South = true,
  East  = true,
  West  = true
}

-- Default host of Vindinium
local default_host = "vindinium.org"

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
-- @param game   Game to send the request for
-- @param url    String URL
-- @param fields Table of POST fields
-- @return table Returns the parsed JSON result
local function request(game, url, fields)
  local response_body = {}
  local request_body = buildBody(fields)

  -- Send the HTTP POST request
  local res, code, headers = http.request{
    url     = url or game.url,
    method  = "POST",
    source  = ltn12.source.string(request_body),
    sink    = ltn12.sink.table(response_body),
    headers = {
      ["Content-Type"]   = "application/x-www-form-urlencoded",
      ["Content-Length"] = string.len(request_body)
    }
  }

  -- Ensure that the request sent correctly
  assert(code == 200, "Request failed: " .. code 
    .. ": " .. table.concat(response_body))
  assert(type(response_body) == 'table', 'Invalid response')
  -- Parse the JSON response
  local obj, pos, err = json.decode(table.concat(response_body))
  assert(obj ~= nil, "Error decoding JSON: " .. (err or ""))
  return Map:new(obj)
end

-- Connect to Vindinium
-- @return table Returns the parsed JSON data
local function connect(game)
  local hash = {key = game.key}
  if game.turns then hash.turns = game.turns end
  if game.map then hash.map = game.map end
  return request(game, null, hash)
end

-- Runs the main game loop
-- @param state Table of initial connection data
local function game_loop(game, state)
  state.first_move = true
  while state.game.finished == false do
    direction = game.loop(state)
    assert(valid_moves[direction], "Invalid direction: " .. (direction or ""))
    state = request(game, state.playUrl, {key=game.key, dir=direction})
    state.first_move = false
  end
end

local V = {}

-- Create a new instance of Vindinlua and enter into the game loop
--
-- @param game A table containing the following keys:
--             key:   API key (required)
--             host:  Optional Vindinium game host
--             turns: Optional number of turns to play
--             map:   Optional map to use when playing
--             mode:  One of "training" or "arena". Defaults to "training"
--             loop:  Game loop function that accepts a State object and
--                    returns a direction string. One of "Stay", "North",
--                    "South", "East", or "West"
function V.play(settings)
  assert((not settings) or type(settings) == "table")
  local game = {
    key   = assert(settings.key, "A key must be provided"),
    host  = assert(settings.host or default_host),
    mode  = assert(settings.mode or "training"),
    loop  = assert(type(settings.loop) == "function" and settings.loop),
    turns = settings.turns,
    map   = settings.map
  }

  assert(game_modes[game.mode], "Invalid game mode: " .. game.mode)
  game.url = "http://" .. game.host .. game_modes[game.mode]
  state = assert(connect(game), "Error connecting")
  game_loop(game, state)
end

return V
