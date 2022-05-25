require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { create(:user) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  describe '::create_game_for_user!' do
    before do
      generate_questions(60)

      game = nil
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15).and(
          change(Question, :count).by(0)
        )
      )
    end
    let(:game) { Game.create_game_for_user!(user) }

    context 'when no errors during transaction' do
      it 'should create game with specified user' do
        expect(game.user).to eq(user)
      end

      it 'should create game with status in progress' do
        expect(game.status).to eq(:in_progress)
      end

      it 'should create game with 15 questions' do
        expect(game.game_questions.size).to eq(15)
      end

      it 'should create game with questions levels fron 0 to 14' do
        expect(game.game_questions.map(&:level)).to eq (0..14).to_a
      end
    end
  end

  describe '#status' do
    context 'when game is finished' do
      let!(:game_w_questions) { create(:game_with_questions, user: user, finished_at: Time.now) }

      before do
        expect(game_w_questions.finished?).to be true
      end

      context 'and game is failed' do
        context 'and time is not out' do
          let!(:game_w_questions) { create(:game_with_questions,
                                           user: user,
                                           finished_at: Time.now,
                                           is_failed: true) }

          it 'should return fail' do
            expect(game_w_questions.status).to eq(:fail)
          end
        end

        context 'and time is out' do
          let!(:game_w_questions) { create(:game_with_questions,
                                           user: user,
                                           finished_at: Time.now,
                                           created_at: 1.hour.ago,
                                           is_failed: true) }

          it 'should return timeout' do
            expect(game_w_questions.status).to eq(:timeout)
          end
        end
      end

      context 'and game is not failed' do
        context 'and level is bigger than max level' do
          let!(:game_w_questions) { create(:game_with_questions,
                                           user: user,
                                           finished_at: Time.now,
                                           current_level: Question::QUESTION_LEVELS.max + 1) }

          it 'should return won' do
            expect(game_w_questions.status).to eq(:won)
          end
        end

        context 'and money is taken' do
          it 'should return :money' do
            expect(game_w_questions.status).to eq(:money)
          end
        end
      end
    end

    context 'when game is not finished' do
      it 'should return :in_progress' do
        expect(game_w_questions.status).to eq(:in_progress)
      end
    end
  end

  describe '#take_money!' do
    before do
      game_w_questions.take_money!
    end

    context 'when game is in progress' do
      context 'and no questions answered' do
        it 'should finish game' do
          expect(game_w_questions.finished?).to be true
        end

        it 'should finish with status money' do
          expect(game_w_questions.status).to eq :money
        end

        it 'should get no prize' do
          expect(game_w_questions.prize).to eq(0)
        end
      end

      context 'and 1 question answered' do
        let!(:game_w_questions) { create(:game_with_questions, user: user, current_level: 1) }

        it 'should finish game' do
          expect(game_w_questions.finished?).to be true
        end

        it 'should finish with status money' do
          expect(game_w_questions.status).to eq :money
        end

        it 'should get first prize' do
          expect(game_w_questions.prize).to eq(Game::PRIZES.first)
        end
      end
    end

    context 'when game is finished' do
      context 'and is won' do
        let!(:game_w_questions) { create(:game_with_questions, current_level: Question::QUESTION_LEVELS.max + 1) }

        it 'should keep won status' do
          expect(game_w_questions.status).to eq :won
        end
      end

      context 'and is failed' do
        let!(:game_w_questions) { create(:game_with_questions, is_failed: true, finished_at: Time.now) }

        it 'should kepp fail status' do
          expect(game_w_questions.status).to eq :fail
        end
      end

      context 'and money taken' do
        it 'should keep money status' do
          expect(game_w_questions.status).to eq :money
        end
      end
    end

    context 'when time is out' do
      let!(:game_w_questions) { create(:game_with_questions, user: user, created_at: 1.hour.ago) }

      it 'should finish game' do
        expect(game_w_questions.finished?).to be true
      end

      it 'should finish with status timeout' do
        expect(game_w_questions.status).to eq :timeout
      end
    end
  end

  describe '#current_game_question' do
    it 'should return question with level equals to game level' do
      expect(game_w_questions.current_game_question.level).to eq(game_w_questions.current_level)
    end
  end

  describe '#previous_level' do
    context 'when current level is 0' do
      it 'should return - 1' do
        expect(game_w_questions.previous_level).to eq(-1)
      end
    end

    context 'when current level is 4' do
      let!(:game_w_questions) { create(:game_with_questions, current_level: 4) }

      it 'should return 3' do
        expect(game_w_questions.previous_level).to eq(3)
      end
    end
  end

  describe '#answer_current_question!' do
    before do
      game_w_questions.answer_current_question!(answer_key)
    end

    context 'when answer is correct' do
      let!(:answer_key) { game_w_questions.current_game_question.correct_answer_key }

      context 'and question is last' do
        let!(:level) { Question::QUESTION_LEVELS.max }
        let!(:game_w_questions) { create(:game_with_questions, user: user, current_level: level) }

        it 'should finish game' do
          expect(game_w_questions.finished?).to be true
        end

        it 'should finish game with status won' do
          expect(game_w_questions.status).to eq :won
        end

        it 'should assign final prize' do
          expect(game_w_questions.prize).to eq(Game::PRIZES.last)
        end
      end

      context 'and question is not last' do
        it 'should move to next level' do
          expect(game_w_questions.current_level).to eq(1)
        end

        it 'should change question' do
          expect(game_w_questions.current_game_question.level).to eq(1)
        end

        it 'should continue game' do
          expect(game_w_questions.finished?).to be false
        end
      end

      context 'and time is over' do
        let!(:game_w_questions) { create(:game_with_questions, user: user, current_level: 6, created_at: 1.hour.ago) }

        it 'should return false' do
          expect(game_w_questions.answer_current_question!(answer_key)).to be false
        end

        it 'should finish the game' do
          expect(game_w_questions.finished?).to be true
        end

        it 'should finish with status timeout' do
          expect(game_w_questions.status).to eq(:timeout)
        end

        it 'should get fireproof prize' do
          expect(game_w_questions.prize).to eq(Game::PRIZES[4])
        end
      end
    end

    context 'when answer is wrong' do
      let!(:answer_key) { (%w[a b c d] - [game_w_questions.current_game_question.correct_answer_key]).sample }

      it 'should finish the game' do
        expect(game_w_questions.finished?).to be true
      end

      it 'should finish with status fail' do
        expect(game_w_questions.status).to eq :fail
      end
    end
  end
end
