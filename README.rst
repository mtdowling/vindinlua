=============================
Vindinium Starter Kit for Lua
=============================

Provides a Lua starter kit for `Vindinium <http://vindinium.org>`_, allowing
you to easily create an AI bot to compete against other bots.

Usage
=====

Create a game loop and pass your API key:

.. code-block:: lua

    -- Require the vindinium module
    Vindinium = require("vindinium")

    -- Create a bot function. The bot function is a function that accepts
    -- a Map object and returns a direction string. The direction can be
    -- one of "Stay", "North", "South", "East", or "West".
    function bot(map)
      -- Return a random move
      return ({"Stay", "North", "South", "East", "West"})[math.random(1, 5)]
    end

    Vindinium.play{key="my_api_key", bot=bot}

.. note::

    You try out the example bot by running ``lua example.lua``


Requirements
============

Requires Lua 5.1 or greater, the ``dkjson`` library, and ``luasocket``.

.. code-block:: lua

    luarocks install dkjson
    luarocks install luasocket


Using the Map
=============

The game loop is supplied a map table that provides a list of heroes, mines,
taverns, a collision map, and the tiles of the game. For debugging purposes,
the map can be cast to a string (as seen in the example above).


Map Functions
-------------

``map:getTile(x, y)``
    Returns the tile value for the given grid position.

``map:getNeighbors(x, y)``
    Gets the neighboring tiles for the given coordinates. The return value
    is a table sequence of hashes, each containing an x, y, and tile key value
    pair, where ``"tile"`` is a Tile object.


Map properties
--------------

``map.id``
    Unique identifier of the game

``map.turn``
    Current number of moves since the beginning. This is the total number of
    moves done at this point. Each turn contains 4 move (one for each player).
    So if you want to know the "real" turn number, you need to divide this
    number by 4.

``map.maxTurns``
    Maximum number of turns. Same as above, you may need to divide this
    number by 4.

``map.hero``
    Contains your hero data. See ``map.heroes`` for a description of hero
    data.

``map.heroes``
    Contains a sequence table of heroes. Each element contains a hash of data
    returned from Vindinium with the hero's X and Y positions updated to
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

``map.mines``
    Contains a sequence table of mines. Each element in the sequence is a hash
    containing a "pos" key and "owner" key. The pos key is a hash of "x" and
    "y", and the owner key is a number between 0 and 4 representing the hero
    ID that owns the mine (0 for unclaimed mines).

``map.taverns``
    Contains a sequence table of taverns. Each element in the sequence is a
    hash containing a "pos" key. The pos key is a hash of "x" and  "y" values
    starting at index 1.

``map.grid``
    Contains a grid table of [y][x] (starting at index 1). Each value is set
    to one of the following:

    - -1 impass (Map.TILE.IMPASS)
    - 0 empty (Map.TILE.EMPTY)
    - 1 hero 1 (Map.TILE.HERO_1)
    - 2 hero 2 (Map.TILE.HERO_2)
    - 3 hero 3 (Map.TILE.HERO_3)
    - 4 hero 4 (Map.TILE.HERO_4)
    - 5 unclaimed mine (Map.TILE.MINE_0)
    - 6 mine owned by hero 1 (Map.TILE.MINE_1)
    - 7 mine owned by hero 2 (Map.TILE.MINE_2)
    - 8 mine owned by hero 3 (Map.TILE.MINE_3)
    - 9 mine owned by hero 4 (Map.TILE.MINE_4)
    - 10 tavern  (Map.TILE.TAVERN)

``map.viewUrl``
    A URL that you can open in your browser to view a replay of the game.

``map.playUrl``
    The URL you need to use to send your move orders to the server.


Using Tile objects
==================

Tile functions
--------------

``tile:isEmpty()``
    Returns true if the tile is empty.

``tile:isImpassable()``
    Returns true if the tile is an impassable wood tile.

``tile:isHero()``
    Returns a number from 1 to 4 if the tile is a hero, otherwise returns
    false.

``tile:isMyHero()``
    Returns true if the tile is the playable hero.

``tile:isMine()``
    Returns a number -1 or 1 to 4 if the tile is a mine, where the number
    represents the mine owner (-1 being unowned). If the tile is not a mine,
    returns false.

``tile:isTavern()``
    Returns true if the tile is a tavern.


Tile properties
---------------

``tile.id``
    Returns the ID of the tile. See ``Map.grid`` for a description of IDs.
