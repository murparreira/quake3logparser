class QuakeLogParser
  attr_reader :games

  def initialize(log_file_path)
    @log_file_path = log_file_path
    @games = []
    parse_log
  end

  def parse_log
    current_game = nil

    File.foreach(@log_file_path) do |line|
      # InitGame: is the instruction that sets a new game,
      # So we initialize the report hash with a new game when we read a line with this.
      if line.include?("InitGame:")
        current_game = { total_kills: 0, players: [], kills: {}, kills_by_means: {} }
        @games << current_game
      # ClientUserinfoChanged: is the instruction that reads a player connects,
      # So we extract the player from this lane and add it to the players array of the
      # current game, avoiding duplicates.
      elsif line.include?("ClientUserinfoChanged:")
        player = extract_player(line)
        current_game[:players] << player unless current_game[:players].include?(player)
      # Kill: is the instruction that reads a kill in the game,
      # So we extract the kill information from this line.
      elsif line.include?("Kill:")
        handle_kill(line, current_game)
      end
    end
  end

  # Spliting the line on a backlash occurrence, we always have the player name
  # on the second position of the array.
  def extract_player(line)
    line.split("\\")[1]
  end

  # This method handle the kills from the kill line.
  def handle_kill(line, game)
    # First we add a kill to the total kills of the current game.
    game[:total_kills] += 1
    # Next we have a method to extract the kill details (killer, victim and means)
    # from the line.
    killer, victim, means = extract_kill_details(line)
    # According to the rules, when the killer is the world entity we subtract one 
    # from the victim, also I added a rule to subtract when the killer suicided,
    # it none of these are true, then we add one to the killer.
    if killer == "world" || killer == victim
      game[:kills][victim] ||= 0
      game[:kills][victim] -= 1
    else
      game[:kills][killer] ||= 0
      game[:kills][killer] += 1
    end
    # We also add one to the means of the cause of death of each kill.
    game[:kills_by_means][means] ||= 0
    game[:kills_by_means][means] += 1
  end

  # Here we have the method to extract kill details. All kill lines are 
  # represented as:
  # Kill: {random numbers} {killer name} killed {victim name} by {means}
  # Getting the index from the word killed and by make it possible to pinpoint
  # who is who in this line.
  def extract_kill_details(line)
    parts = line.split(" ").drop(5)
    killed_index = parts.index("killed")
    by_index = parts.rindex("by")
    killer = parts[0..killed_index - 1].join(" ").delete("<>")
    victim = parts[killed_index+ 1..by_index - 1].join(" ")
    means = parts.last
    [killer, victim, means]
  end

  # The method to print the games report.
  def print_report
    @games.each_with_index do |game, index|
      puts "Game #{index + 1}:"
      puts "Total kills: #{game[:total_kills]}"
      puts "Players: #{game[:players].join(', ')}"
      puts "Kills: #{game[:kills]}"
      puts "Kills by means: #{game[:kills_by_means]}"
      puts "\n"
    end
  end
end

# Here we run the game, initializing with the log file from the same 
# directory as the script, and call the print_report method.
parser = QuakeLogParser.new("qgames.log")
parser.print_report
