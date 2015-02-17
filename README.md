# LuaSimC
LuaSimC is a library attempting to wrap Command Line Interface (CLI) of SimulationCraft.

LuaSimC provides a flat, table-like configuration interface for accessing SimC. Profile generation, simulate execution, output parsing could be fully controlled by user.

Please note that the configuration interface is NOT fully object oriented. This is intended. Since simulation takes a large number of CPU time, saving result and loading from file could be crucial for complex simulation tasks. The solution provided by LuaSimC is a utility function that writes a session table into file, during which all metatables that provide fancy OO features are not preserved.
