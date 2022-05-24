class Game < ActiveRecord::Base

  PRIZES = [
    100, 200, 300, 500, 1000,
    2000, 4000, 8000, 16000, 32000,
    64000, 125000, 250000, 500000, 1000000
  ].freeze

  FIREPROOF_LEVELS = [4, 9, 14].freeze

  TIME_LIMIT = 35.minutes

  belongs_to :user
  has_many :game_questions, dependent: :destroy

  validates :user, presence: true
  validates :current_level, numericality: {only_integer: true}, allow_nil: false
  validates :prize,
            presence: true,
            numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: PRIZES.last}

  scope :in_progress, -> { where(finished_at: nil) }

  # returns correct new game or dies with exceptions
  def self.create_game_for_user!(user)
    transaction do
      game = create!(user: user)

      Question::QUESTION_LEVELS.each do |i|
        q = Question.where(level: i).order('RANDOM()').first
        ans = [1, 2, 3, 4]
        game.game_questions.create!(question: q, a: ans.shuffle!.pop, b: ans.shuffle!.pop, c: ans.shuffle!.pop, d: ans.shuffle!.pop)
      end
      game
    end
  end

  def previous_game_question
    game_questions.detect { |q| q.question.level == previous_level }
  end

  def current_game_question
    game_questions.detect { |q| q.question.level == current_level }
  end

  def previous_level
    current_level - 1
  end

  def finished?
    finished_at.present?
  end

  def time_out!
    if (Time.now - created_at) > TIME_LIMIT
      finish_game!(fire_proof_prize(previous_level), true)
      true
    end
  end

  # letter = 'a','b','c' or 'd'
  def answer_current_question!(letter)
    return false if time_out! || finished? # законченную игру низя обновлять

    if current_game_question.answer_correct?(letter)
      if current_level == Question::QUESTION_LEVELS.max
        self.current_level += 1
        finish_game!(PRIZES[Question::QUESTION_LEVELS.max], false)
      else
        self.current_level += 1
        save!
      end

      true
    else
      finish_game!(fire_proof_prize(previous_level), true)
      false
    end
  end

  def take_money!
    return if time_out! || finished?
    finish_game!((previous_level > -1) ? PRIZES[previous_level] : 0, false)
  end

  # help_type = :fifty_fifty | :audience_help | :friend_call
  def use_help(help_type)
    help_types = %i(fifty_fifty audience_help friend_call)
    help_type = help_type.to_sym
    raise ArgumentError.new('wrong help_type') unless help_types.include?(help_type)

    unless self["#{help_type}_used"]
      self["#{help_type}_used"] = true
      current_game_question.apply_help!(help_type)
      save
    end
  end


  # Game result:
  # :fail - game is over because of a wrong answer
  # :timeout - game is over because the time is over
  # :won - game is won (all 15 questions are answered)
  # :money - game is finished, user took the money
  # :in_progress - game is in progress
  def status
    return :in_progress unless finished?

    if is_failed
      if (finished_at - created_at) <= TIME_LIMIT
        :fail
      else
        :timeout
      end
    else
      if current_level > Question::QUESTION_LEVELS.max
        :won
      else
        :money
      end
    end
  end

  private

  def finish_game!(amount = 0, failed = true)

    transaction do
      self.prize = amount
      self.finished_at = Time.now
      self.is_failed = failed
      user.balance += amount
      save!
      user.save!
    end
  end

  def fire_proof_prize(answered_level)
    lvl = FIREPROOF_LEVELS.select { |x| x <= answered_level }.last
    lvl.present? ? PRIZES[lvl] : 0
  end

end
