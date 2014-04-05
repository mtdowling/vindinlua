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

Requirements
============

Requires Lua 5.1 or greater and the dkjson library.

.. code-block:: lua

	luarocks install dkjson

Using the Map
=============

The game loop is supplied a map table that provides a list of players, mines,
taverns, a collision map, and the tiles of the game. For debugging purposes,
the map can be cast to a string (as seen in the example above).

map:tile(x, y)
    Returns the tile value for the given grid position.

map:walkable(x, y)
    Returns true if the given grid position is walkable.

map:move_to(dx, dy)
    When given a destination X and Y, the map will perform a BFS to find a
    path to the given position from the player's current X and Y position.
    If a path is found, one of "North", "South", "East", or "West" is
    returned. If no path can be found, the function returns ``nil``.

map.players
    Contains a sequence table of players. Each element contains a hash of data
    returned from Vindinium with the player's X and Y positions updated to
    start at 1 rather than 0.

    .. code-block:: lua

    	{
          id        = 1,
          name      = "vjousse",
          userId    = "j07ws669",
          elo       = 1200,
          pos       = {x=6, y=7},
          life      = 60,
          gold      = 0,
          mineCount = 0,
          spawnPos  = {"x"=6, "y"=7},
          crashed   = false
        }

map.mines
    Contains a sequence table of mines. Each element in the sequence is a hash
    containing a "pos" key and "owner" key. The pos key is a hash of "x" and
    "y", and the owner key is a number between 0 and 4 representing the player
    ID that owns the mine (0 for unclaimed mines).

map.taverns
    Contains a sequence table of taverns. Each element in the sequence is a
    hash containing a "pos" key. The pos key is a hash of "x" and  "y" values
    starting at index 1.

map.collision_map
    Contains a grid table of [y][x] (starting at index 1). Each value is set
    to true or false designating whether or not the current player can walk
    over the given tile.

map.grid
    Contains a grid table of [y][x] (starting at index 1). Each value is set
    to one of the following:

    - -1 impass
    - 0 empty
    - 1 player 1
    - 2 player 2
    - 3 player 3
    - 4 player 4
    - 5 unclaimed mine
    - 6 mine owned by player 1
    - 7 mine owned by player 2
    - 8 mine owned by player 3
    - 9 mine owned by player 4
    - 10 tavern
