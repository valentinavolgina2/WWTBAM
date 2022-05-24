require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  describe '::create_game_for_user!' do
    it 'should create new correct game' do
      generate_questions(60)

      game = nil

      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15).and(
          change(Question, :count).by(0)
        )
      )

      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  describe '#status' do
    context 'when game is finished' do
      before(:each) do
        game_w_questions.finished_at = Time.now
        expect(game_w_questions.finished?).to be_truthy
      end

      it 'should return :won' do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
        expect(game_w_questions.status).to eq(:won)
      end

      it 'should return :fail' do
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:fail)
      end

      it 'should return :timeout' do
        game_w_questions.created_at = 1.hour.ago
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:timeout)
      end

      it 'should return :money' do
        expect(game_w_questions.status).to eq(:money)
      end
    end

    context 'when game is not finished' do
      it 'should return :in_progress' do
        expect(game_w_questions.status).to eq(:in_progress)
      end
    end
  end

  describe '#take_money!' do
    it 'should finish game with a prize' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      game_w_questions.take_money!

      prize = game_w_questions.prize
      expect(prize).to eq(Game::PRIZES.first)

      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize
    end
  end

  describe '#current_game_question' do
    it 'should return question with correct level' do
      current_question = game_w_questions.current_game_question
      expect(current_question.level).to eq(game_w_questions.current_level)
    end
  end

  describe '#previous_level' do
    it 'should return current_level - 1' do
      expect(game_w_questions.previous_level).to eq(game_w_questions.current_level - 1)
    end
  end

  describe '#answer_current_question!' do
    before(:each) do
      expect(game_w_questions.status).to eq(:in_progress)
    end

    context 'when answer is correct' do
      context 'when answer the last question' do
        it 'should finish game with prize' do
          game_w_questions.current_level = Question::QUESTION_LEVELS.max
          current_question = game_w_questions.current_game_question

          game_w_questions.answer_current_question!(current_question.correct_answer_key)

          expect(game_w_questions.current_level).to eq(Question::QUESTION_LEVELS.max + 1)
          expect(game_w_questions.status).to eq :won
          expect(game_w_questions.finished?).to be_truthy
          expect(game_w_questions.prize).to eq(Game::PRIZES.last)
        end
      end

      context 'when answer not the last question' do
        it 'should move to next level' do
          current_level = game_w_questions.current_level
          current_question = game_w_questions.current_game_question

          game_w_questions.answer_current_question!(current_question.correct_answer_key)

          expect(game_w_questions.current_level).to eq(current_level + 1)
          expect(game_w_questions.current_game_question).not_to eq(current_question)
          expect(game_w_questions.status).to eq :in_progress
          expect(game_w_questions.finished?).to be_falsey
        end
      end
    end

    context 'when answer is wrong' do
      it 'should finish the game' do
        current_level = game_w_questions.current_level
        current_question = game_w_questions.current_game_question
        wrong_answer_key = (%w(a b c d) - [current_question.correct_answer_key]).sample

        game_w_questions.answer_current_question!(wrong_answer_key)

        expect(game_w_questions.current_level).to eq(current_level)
        expect(game_w_questions.current_game_question).to eq(current_question)
        expect(game_w_questions.status).to eq :fail
        expect(game_w_questions.finished?).to be_truthy
      end
    end

    context 'when answer after time is over' do
      it 'should return false' do
        game_w_questions.created_at = 1.hour.ago

        current_level = 6
        game_w_questions.current_level = current_level

        answer_key = %w(a b c d).sample

        expect(game_w_questions.answer_current_question!(answer_key)).to be_falsey
        expect(game_w_questions.current_level).to eq(current_level)
        expect(game_w_questions.prize).to eq(Game::PRIZES[4])
        expect(game_w_questions.status).to eq(:timeout)
        expect(game_w_questions.finished?).to be_truthy
      end
    end
  end
end
