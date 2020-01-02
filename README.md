# pointlake
Position handler for Garry’s Mod

This addon gives you an ability to create and save position groups. You can use them in your code by the time.

How to use:
1. Choose a PointLake toolgun in spawnmenu.
2. Create a new group and click the group node on the tree.
3. Press LMB or RMB to make a position for current group.

If you want to remove a position, you can press R or RMB on the node of position.

API:
1. PointLake.GetGroupPositions(<string> Groupname) -- Gets a group of positions.
2. PointLake.GetRandomPosition(<string> Groupname) -- Gets a random position from group.
3. PointLake.GetPosition(<string> Groupname,<string/number> PositionName) -- Gets a certain position.

!!!DOES NOT WORK IN SINGLEPLAYER!!!
