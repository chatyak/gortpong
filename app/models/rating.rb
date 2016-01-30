class Rating < ActiveRecord::Base
  belongs_to :player

  # Cool stuff to display in player profile:
  # TODO: Average Opponent Rating
  # TODO: Average Opponent Rating when I win or lose

  def self.update_ratings(winner, loser)
    current_ratings = {winner: winner.rating.rating, loser: loser.rating.rating}

    # Average opponent ratings
    winner.rating.calculate_avg_opp_rating_win(winner, current_ratings[:loser])
    loser.rating.calculate_avg_opp_rating_loss(loser, current_ratings[:winner])

    # Transformed rating to get ELO probablity
    transformed_winner_rating = 10**(current_ratings[:winner] / 400.to_f)
    transformed_loser_rating = 10**(current_ratings[:loser] / 400.to_f)

    # Expected chance to win from ELO formula
    expected_winner_score = transformed_winner_rating / (transformed_winner_rating + transformed_loser_rating)

    # Positive value based on win probability - winner will go up by this amt and loser will go down by it
    rating_difference = (32 * (1 - expected_winner_score)).to_i

    winner.rating.rating = current_ratings[:winner] + rating_difference
    loser.rating.rating = current_ratings[:loser] - rating_difference

    winner.rating.save
    loser.rating.save

    # Store the new rating if that is the winner's highest ever
    if winner.rating.highest_ever < winner.rating.rating
      winner.rating.highest_ever = winner.rating.rating
      winner.rating.save
    end

    # TODO: WHY DOESN'T THIS WORK?? ?? Does not let me pass in "winner" when resetting data but works if I call it from this method in console
    # The highest_ever_rating method is below
    # if highest_ever_rating(winner)
    #   winner.rating.highest_ever = winner.rating
    #   winner.rating.save
    # end
  end

  # TODO: DRY refactor
  def calculate_avg_opp_rating_win(winning_player, loser_rating)
    if winning_player.rating.avg_opp_rating_win == nil
      winning_player.rating.avg_opp_rating_win = loser_rating
      winning_player.rating.save
    else
      current_average = winning_player.rating.avg_opp_rating_win
      games_played = winning_player.games_played - 1
      total = current_average * games_played + loser_rating
      winning_player.rating.avg_opp_rating_win = total / (games_played + 1)
      winning_player.rating.save
    end
  end

  def calculate_avg_opp_rating_loss(losing_player, winner_rating)
    if losing_player.rating.avg_opp_rating_loss == nil
      losing_player.rating.avg_opp_rating_loss = winner_rating
      losing_player.rating.save
    else
      current_average = losing_player.rating.avg_opp_rating_loss
      games_played = losing_player.games_played - 1
      total = current_average * games_played + winner_rating
      losing_player.rating.avg_opp_rating_loss = total / (games_played + 1)
      losing_player.rating.save
    end
  end

  # def highest_ever_rating(winner)
  #   byebug
  #   if winner.rating.rating > winner.rating.highest_ever
  #     return true
  #   else
  #     return false
  #   end
  # end

end