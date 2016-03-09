-- Simple Vindinlua example demonstrating a bot that moves randomly
-- and prints out the map to the console.

-- Require the vindinium module
local Vindinium = require("vindinium")

-- CHANGE YOUR API KEY HERE
local apiKey = arg[1] or "EXAMPLE"

firstMove = true

-- Create a bot function. The bot function is a function that accepts a Map
-- object and returns a direction string. The direction can be one of "Stay",
-- "North", "South", "East", or "West".
--
-- @param map Table containing game state
-- @return string Returns a direction
function bot(map)
  -- Open the browser to watch the game unfold.
  if firstMove then
    os.execute("open " .. map.viewUrl)
    firstMove = false
  end
  -- Print each neighbor of the player.
  for _, t in ipairs(map:getNeighbors(map.hero.pos.x, map.hero.pos.y)) do
    io.write(t.x .. ", " .. t.y .. " | ")
  end
  print("")
  -- Return a random move
  return ({"Stay", "North", "South", "East", "West"})[math.random(1, 5)]
end

-- Run the game loop
Vindinium.play{key=apiKey, bot=bot}
