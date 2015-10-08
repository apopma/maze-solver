class MazeSolver
  # Implements the A* pathfinding algorithm described at
  # http://www.policyalmanac.org/games/aStarTutorial.htm

  attr_reader :maze, :start, :finish, :open_list, :closed_list, :location,
              :parent, :movement_cost, :heuristic_cost, :net_movement_cost

  MOVE_COST_ORTHO = 10
  MOVE_COST_DIAG  = 14

  def initialize
    @maze   = parse(File.readlines("#{ARGV[0]}.txt"))
    @start  = find_position('S')
    @finish = find_position('E')

    @location = start
    @open_list = [start]
    @closed_list = []

    @parent =            {}           # pos => parent's pos
    @movement_cost =     {start => 0} # pos => cost to move there from @start
    @heuristic_cost =    {}           # pos => manhattan cost for that pos
    @net_movement_cost = {}           # pos => movement + heuristic costs
  end

  def solve
    display
    initial_pathfind
    choose_next_cell

    pathfind until closed_list.include?(finish)

    highlight_completed_path
    write_solution_to_file
  end

  # ----------------------------------------------------------------------------
  private

  def [](row, col)
    maze[row][col]
  end

  def []=(row, col, mark)
    maze[row][col] = mark
  end

  def display
    maze.each { |line| puts line.join }
    # puts "start location is #{start}"
    # puts "ending location is #{finish}"
    # puts "current location is #{@location}"
  end

  def listing
    p "open cells: #{open_list}"
    p "closed cells: #{closed_list}"
    p "parents: #{parent}"
  end

  # ----------------------------------------------------------------------------

  def ortho?(source, dest)
    # one coord pair unchanged
    source.each_index do |idx|
      return true if source[idx] - dest[idx] == 0
    end
    false
  end

  def diagonal?(source, dest)
    # no coord pairs remain the same
    source.each_index do |idx|
      return false unless source[idx] - dest[idx] != 0
    end
    true
  end

  # ----------------------------------------------------------------------------

  def parse(raw_maze)
    # Transforms a raw File#readlines array into a 2D array.
    # Also initializes @maze with the proper array bounds.
    maze = Array.new(raw_maze.size) { Array.new(raw_maze.first.size) }

    maze = raw_maze.map.with_index do |line, row|
      line.chomp.split('').each_with_index do |char, col|
        maze[row][col] = char
      end
    end
  end


  def find_position(char)
    # searches @maze for the first row including the character of interest,
    # then returns the first-located pos of that character in the maze
    row = maze.detect { |this_row| this_row.include?(char) }
    [maze.index(row), row.index(char)]
  end


  def reachable_cells
    # Returns an array of all reachable cells from @location,
    # ignoring walls and cells on the closed list. Breaks if given a 0 location.
    curr_row = location[0]
    curr_col = location[1]

    all_possible_moves = [
          [curr_row, curr_col + 1],     [curr_row, curr_col - 1],
          [curr_row + 1, curr_col],     [curr_row - 1, curr_col],
          [curr_row + 1, curr_col + 1], [curr_row + 1, curr_col - 1],
          [curr_row - 1, curr_col + 1], [curr_row - 1, curr_col - 1]
                         ]

    all_possible_moves.reject do |this_move|
      self[*this_move] == '*' || closed_list.include?(this_move)
    end
  end

  # ----------------------------------------------------------------------------

  def initial_pathfind
    # Adds all reachable cells from @start to the open list,
    # and moves @start to the closed list.
    # Cells have their pos and the adding cell (@start) saved to @parent.
    reachable_cells.each do |reachable_cell|
      open_list << reachable_cell
      parent[reachable_cell] = start
    end
    open_list.delete(location)
    closed_list << location
  end


  def pathfind
    # Moves current location to the closed list,
    # and updates the open list with all newly reachable cells.
    # Updates movement cost for previously reachable cells if cheaper to do so.
    # Then picks the cell with least net movement cost to be the next location.

    open_list.delete(location)
    closed_list << location unless closed_list.include?(location)
    return if location == finish

    reachable_cells.each do |reachable_cell|
      if open_list.include?(reachable_cell)
        update_movement_cost(reachable_cell)

      elsif !(open_list.include?(reachable_cell))
        open_list << reachable_cell
        parent[reachable_cell] = location
      end
    end

    choose_next_cell
  end

  # ----------------------------------------------------------------------------

  def choose_next_cell
    calculate_movement_costs(open_list)
    estimate_heuristic_costs(open_list)
    calculate_net_costs(open_list)

    candidate_locations = {} #pos => net movement cost
    candidate_locations = net_movement_cost.reject do |pos, val|
      pos == @location || !open_list.include?(pos)
      # reject the current location and any cells not on the open list
    end

    candidate_locations.each do |pos, cost|
      if candidate_locations[pos] == candidate_locations.values.min
        # faster to sample from a subset of all minima? last minimum added?
        @location = pos
        # Uncomment the line below to see all cells this algorithm searches.
        # self[*location] = "•" unless self[*location] == 'E'
        candidate_locations.clear
        return
      end
    end
  end

  # ----------------------------------------------------------------------------

  def calculate_movement_costs(cells)
    # Cost to move to the parent cell from the cell in question.
    cells.each do |cell|
      if ortho?(cell, parent[cell])
        movement_cost[cell] = movement_cost[parent[cell]] + MOVE_COST_ORTHO

      elsif diagonal?(cell, parent[cell])
        movement_cost[cell] = movement_cost[parent[cell]] + MOVE_COST_DIAG
      end
    end
  end


  def estimate_heuristic_costs(cells)
    # The Manhattan cost is the movement cost to go straight to the finish
    # from a given cell, orthogonally only and ignoring walls.
    cells.each do |cell|
      manhattan_cost = 0
      manhattan_cost += (cell[0] - finish[0]).abs
      manhattan_cost += (cell[1] - finish[1]).abs
      heuristic_cost[cell] = manhattan_cost * MOVE_COST_ORTHO
    end
  end


  def calculate_net_costs(cells)
    cells.each do |cell|
      net_movement_cost[cell] = (movement_cost[cell] + heuristic_cost[cell])
    end
  end

  # ----------------------------------------------------------------------------

  def update_movement_cost(cell)
    # Sometimes it can be cheaper to move to a previously-checked cell
    # from the current location. This method handles cost updates for that case.

    # When called, this cell doesn't have a movement cost yet.
    # Give it the cost of its parent plus the relevant directionality cost.
    if ortho?(cell, parent[cell])
      movement_cost[cell] = movement_cost[parent[cell]] + MOVE_COST_ORTHO
    elsif diagonal?(cell, parent[cell])
      movement_cost[cell] = movement_cost[parent[cell]] + MOVE_COST_DIAG
    end

    #copy costs into local vars
    new_movement_cost = 0
    current_movement_cost = movement_cost[cell]
    parent_movement_cost = movement_cost[parent[cell]]

    # new movement cost to move to this cell from its parent
    if ortho?(parent[cell], cell)
      new_movement_cost = parent_movement_cost + MOVE_COST_ORTHO
    elsif diagonal?(parent[cell], cell)
      new_movement_cost = parent_movement_cost + MOVE_COST_DIAG
    end

    if new_movement_cost < current_movement_cost
      movement_cost[cell] = new_movement_cost # update cell with its cheaper cost
      parent[cell] = location                 # update cell with its new parent
      estimate_heuristic_costs(cell)          # recalculate cell's other costs
      calculate_net_costs(cell)
    end
  end

  # ----------------------------------------------------------------------------

  def highlight_completed_path
    # From the finish, traces parenthood back to start and writes + for each.
    next_cell_to_write = parent[finish]
    until next_cell_to_write == start
      self[*next_cell_to_write] = '+'
      next_cell_to_write = parent[next_cell_to_write]
    end

    puts "\n"
    display
  end

  def write_solution_to_file
    File.open("#{ARGV[0]}_solved.txt", "w") do |f|
      maze.each { |line| f.puts line.join }
    end
  end

end # ==========================================================================

MazeSolver.new.solve
