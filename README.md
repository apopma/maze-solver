# Maze Solver

This is an implementation of the A* pathfinding algorithm as described by [Patrick Lester](http://www.policyalmanac.org/games/aStarTutorial.htm). Given a maze in ASCII where the start and end are denoted by `S` and `E`, and where walls are `*`, it will find the shortest path between start and end.

```
****************     ****************
*         *   E*     *    +    *  +E*
*    *    *  ***     *   +*+   * +***
*    *    *    *     *   +* +  *  + *
*    *    *    *     *  + *  + * +  *
*    *    *    *     * +  *   +*+   *
*S   *         *     *S   *    +    *
****************     ****************
```

## How to Use

* Clone this repo.
* Make some custom mazes or pick one of the pre-defined ones in `/mazes`.
* Run `ruby maze_solver.rb path/to/maze`. There's no need to add `.txt` at the end.
* Solutions will be output as `mazename_solved.txt`, in the same directory the source file is located in.
* Some constraints:
  * A solution should exist.
  * Neither the start nor the end can be at the 'edges' of the maze. Ex:
  ```
  ************E** <-- This won't work: the end is located at the top edge.
  *             *
  *   ******    *
  *        *    *
  *     S  *    *
  *   ******    *
  *             *
  ***************

  ***************
  *   ++++++++E * <-- Place the end here instead.
  *  +******    *
  *   ++   *    *
  *     S  *    *
  *   ******    *
  *             *
  ***************
  ```
