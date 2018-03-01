local gmod                        = gmod
local pairs                        = pairs
local isfunction        = isfunction
local isstring                = isstring
local IsValid                = IsValid
local ipairs = ipairs
local table = table

module( "hook" )

local Hooks = {}
local Hooksi = {}
local count = {}

--[[---------------------------------------------------------
    Name: GetTable
    Desc: Returns a table of all hooks.
-----------------------------------------------------------]]
function GetTable() return Hooks end
function GetTablei() return Hooksi end


--[[---------------------------------------------------------
    Name: Add
    Args: string hookName, any identifier, function func
    Desc: Add a hook to listen to the specified event.
-----------------------------------------------------------]]
function Add( event_name, name, func, priority )

	if ( !isfunction( func ) ) then return end
	if ( !isstring( event_name ) ) then return end

	Remove( event_name, name )

	if not Hooks[ event_name ] or not Hooks[ event_name ][ name ] then

		if (Hooksi[ event_name ] == nil) then
			Hooksi[ event_name ] = {}
		end

		table.insert(Hooksi[ event_name ], {
			name = name,
			func = func,
			object = not isstring(name),
			priority = priority or 0,
		})

		table.sort(Hooksi[ event_name ], function(a, b)
			return a.priority < b.priority
		end)

		count[ event_name ] = #Hooksi[ event_name ]
	end

	if (Hooks[ event_name ] == nil) then
		Hooks[ event_name ] = {}
	end

	Hooks[ event_name ][ name ] = func
end


--[[---------------------------------------------------------
    Name: Remove
    Args: string hookName, identifier
    Desc: Removes the hook with the given indentifier.
-----------------------------------------------------------]]
function Remove( event_name, name )

	if ( !isstring( event_name ) ) then return end
	if ( !Hooks[ event_name ] ) then return end

	if Hooksi[ event_name ] then
		for i,v in ipairs(Hooksi[ event_name ]) do
			if v.name == name then
				table.remove(Hooksi[event_name], i)
				break
			end
		end
		count[ event_name ] = #Hooksi[ event_name ]

		table.sort(Hooksi[ event_name ], function(a, b)
			return a.priority > b.priority
		end)
	end

	Hooks[ event_name ][ name ] = nil

end


--[[---------------------------------------------------------
    Name: Run
    Args: string hookName, vararg args
    Desc: Calls hooks associated with the hook name.
-----------------------------------------------------------]]
if gmod then
	function Run( name, ... )
		return Call( name, gmod.GetGamemode(), ... )
	end
else
	function Run( name, ... )
		return Call( name, nil, ... )
	end
end


--[[---------------------------------------------------------
    Name: Run
    Args: string hookName, table gamemodeTable, vararg args
    Desc: Calls hooks associated with the hook name.
-----------------------------------------------------------]]
function Call( name, gm, ... )
	--
	-- Run hooks
	--
	local HookTable = Hooksi[ name ]
	if ( HookTable != nil ) then

		local a, b, c, d, e, f;

		for i = count[name], 1, -1 do

			local v = HookTable[i]

			if not v.object then

				--
				-- If it's a string, it's cool
				--
				a, b, c, d, e, f = v.func( ... )

			else

				--
				-- If the key isn't a string - we assume it to be an entity
				-- Or panel, or something else that IsValid works on.
				--
				if v.name:IsValid() then
					a, b, c, d, e, f = v.func( v.name, ... )
				else
					Remove(name, v.name)
				end
			end

			--
			-- Hook returned a value - it overrides the gamemode function
			--
			if ( a != nil ) then
				return a, b, c, d, e, f
			end

		end
	end

	--
	-- Call the gamemode function
	--
	if ( !gm ) then return end

	local GamemodeFunction = gm[ name ]
	if ( GamemodeFunction == nil ) then return end

	return GamemodeFunction( gm, ... )
end
