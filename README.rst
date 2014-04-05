=============================
Vindinium Starter Kit for Lua
=============================

Usage
=====

Create a game loop and pass your API key:

.. code-block:: lua

    -- Require the vindinium module
	v = require("vindinlua")

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
	
	v.play{key = "my_api_key", loop = game_loop}
