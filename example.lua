-- Simple Vindinlua example demonstrating a bot that moves randomly
-- and prints out the map to the console.

-- Add lib to the include path
package.path = package.path .. ';./lib/?.lua'

-- Require the vindinium module
v = require("vindinlua")

-- CHANGE YOUR API KEY HERE
local api_key = arg[1] or "my_api_key"

-- Create a game loop. The game loop is a function that accepts a Map object
-- and returns a direction string. The direction can be one of "Stay", 
-- "North", "South", "East", or "West".
--
-- @param map Table containing game state
-- @return string Returns a direction
function game_loop(map)
  -- Map contains a helpful "first_move" attribute. Here we open the
  -- browser to watch the game unfold
  if map.first_move then
    os.execute("open " .. map.viewUrl)
  end
 
  -- Print the map to the console
  os.execute("clear")
  print(map)

  -- Return a random move
  return ({"Stay", "North", "South", "East", "West"})[math.random(1, 5)]
end

-- Run the game loop
v.play{key = api_key, loop = game_loop}
