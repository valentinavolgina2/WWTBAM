require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, is_admin: true) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }
  subject(:response_status) { response.status }

  describe '#show' do
    context 'when anonymous' do
      before { get :show, id: game_w_questions.id }

      it { expect(response_status).not_to eq(200) }

      it 'redirects to new_user_session_path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'flashes alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in user' do
      before do
        sign_in user
        get :show, id: game_w_questions.id
      end
      let!(:game) { assigns(:game) } # get instance variable @game from controller

      context 'and game is mine' do
        it 'renders show' do
          expect(response).to render_template('show')
        end

        it { expect(response_status).to eq(200) }

        it 'gets not finished game' do
          expect(game.finished?).to be false
        end

        it 'gets this user game' do
          expect(game.user).to eq(user)
        end
      end

      context 'and game is not mine' do
        let!(:game_w_questions) { create(:game_with_questions) }

        it 'redirects to root_path' do
          expect(response).to redirect_to(root_path)
        end

        it { expect(response_status).not_to eq(200) }

        it 'flashes alert' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#create' do
    context 'when anonymous' do
      before { post :create }

      it { expect(response_status).not_to eq(200) }

      it 'redirects to new_user_session_path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'flashes alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in user' do
      before do
        sign_in user

        generate_questions(15)
        post :create
      end
      let!(:game) { assigns(:game) }

      context 'has unfinished game' do
        before do
          expect(game.finished?).to be false

          post :create
        end

        it 'does not create another game' do
          expect { post :create }.to change(Game, :count).by(0)
        end

        it 'redirects to game in progress' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'flashes alert' do
          expect(flash[:alert]).to be
        end
      end

      context 'does not have unfinished games' do
        it 'creates not finished game' do
          expect(game.finished?).to be false
        end

        it 'creates game for this user' do
          expect(game.user).to eq(user)
        end

        it 'redirects to game view' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'flashes notice' do
          expect(flash[:notice]).to be
        end
      end
    end
  end

  describe '#answer' do
    context 'when anonymous' do
      before { put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }

      it { expect(response_status).not_to eq(200) }

      it 'redirects to new_user_session_path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'flashes alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in user' do
      before { sign_in user }

      context 'and game is not finished' do
        before { put :answer, id: game_w_questions.id, letter: answer_key }

        context 'and answer is correct' do
          let!(:answer_key) { game_w_questions.current_game_question.correct_answer_key }
          let!(:game) { assigns(:game) }

          it 'continues game' do
            expect(game.finished?).to be false
          end

          it 'increases game level' do
            expect(game.current_level).to be > 0
          end

          it 'redirects to game view' do
            expect(response).to redirect_to(game_path(game))
          end

          it 'has no flash messages' do
            expect(flash.empty?).to be true
          end
        end

        context 'and answer is not correct' do
          let!(:answer_key) { (%w[a b c d] - [game_w_questions.current_game_question.correct_answer_key]).sample }
          let!(:game) { assigns(:game) }

          it 'finishes game' do
            expect(game.finished?).to be true
          end

          it 'finishes game with fail status' do
            expect(game.status).to eq(:fail)
          end

          it 'does not increase game level' do
            expect(game.current_level).to be 0
          end

          it 'redirects to user profile' do
            expect(response).to redirect_to(user_path(user))
          end

          it 'flashes alert' do
            expect(flash[:alert]).to be
          end
        end
      end

    end
  end

  describe '#take_money' do
    context 'when anonymous' do
      before { put :take_money, id: game_w_questions.id }

      it { expect(response_status).not_to eq(200) }

      it 'redirects to new_user_session_path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'flashes alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in user' do
      context 'when game is not finished' do
        before do
          sign_in user

          game_w_questions.update_attribute(:current_level, 2)

          put :take_money, id: game_w_questions.id
        end
        let!(:game) { assigns(:game) }

        it 'finishes game' do
          expect(game.finished?).to be true
        end

        it 'gets 2nd level prize' do
          expect(game.prize).to eq(Game::PRIZES[1])
        end

        it 'increases user balance' do
          user.reload
          expect(user.balance).to eq(Game::PRIZES[1])
        end

        it 'redirects to user page' do
          expect(response).to redirect_to(user_path(user))
        end

        it 'flashes warning' do
          expect(flash[:warning]).to be
        end
      end
    end
  end

  describe '#help' do
    context 'when anonymous' do
      before { put :help, id: game_w_questions.id, help_type: :fifty_fifty }

      it { expect(response_status).not_to eq(200) }

      it 'redirects to new_user_session_path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'flashes alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in user' do
      before { sign_in user }

      context 'asks audience help' do
        context 'and help is not used' do
          before do
            expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
            expect(game_w_questions.audience_help_used).to be false

            put :help, id: game_w_questions.id, help_type: :audience_help
          end
          let!(:game) { assigns(:game) }

          it 'uses audience help' do
            expect(game.audience_help_used).to be true
          end

          it 'adds audience help to help hash' do
            expect(game.current_game_question.help_hash).to include(:audience_help)
          end

          it 'adds audience help to hash with 4 keys' do
            expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
          end

          it 'continues the game' do
            expect(game.finished?).to be false
          end

          it 'redirects to game view' do
            expect(response).to redirect_to(game_path(game))
          end
        end
      end

      context 'asks 50/50 help' do
        context 'and help is not used' do
          before do
            expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
            expect(game_w_questions.fifty_fifty_used).to be false

            put :help, id: game_w_questions.id, help_type: :fifty_fifty
          end
          let!(:game) { assigns(:game) }

          it 'uses 50/50 help' do
            expect(game.fifty_fifty_used).to be true
          end

          it 'adds 50/50 help to help hash' do
            expect(game.current_game_question.help_hash).to include(:fifty_fifty)
          end

          it 'adds 50/50 help as array of 2 elements' do
            expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq 2
          end

          it 'adds 50/50 help with correct answer key' do
            correct_answer_key = game.current_game_question.correct_answer_key
            expect(game.current_game_question.help_hash[:fifty_fifty]).to include(correct_answer_key)
          end

          it 'continues the game' do
            expect(game.finished?).to be false
          end

          it 'redirects to game view' do
            expect(response).to redirect_to(game_path(game))
          end
        end

        context 'and help already used' do
          before do
            game_w_questions.fifty_fifty_used = true
            game_w_questions.save

            put :help, id: game_w_questions.id, help_type: :fifty_fifty
          end
          let!(:game) { assigns(:game) }

          it 'flashes alert' do
            expect(flash[:alert]).to be
          end

          it 'redirects to game view' do
            expect(response).to redirect_to(game_path(game))
          end
        end
      end

      context 'asks friend call' do
        context 'and help is not used' do
          before do
            expect(game_w_questions.current_game_question.help_hash[:friend_call]).not_to be
            expect(game_w_questions.friend_call_used).to be false

            put :help, id: game_w_questions.id, help_type: :friend_call
          end
          let!(:game) { assigns(:game) }

          it 'uses friend call' do
            expect(game.friend_call_used).to be true
          end

          it 'adds friend call to help hash' do
            expect(game.current_game_question.help_hash).to include(:friend_call)
          end

          it 'adds friend call help with answer key' do
            # 'John thinks that it is option B' - friend call help structure
            expect(%w[A B C D]).to include(game.current_game_question.help_hash[:friend_call].last)
          end

          it 'continues the game' do
            expect(game.finished?).to be false
          end

          it 'redirects to game view' do
            expect(response).to redirect_to(game_path(game))
          end
        end

        context 'and help already used' do
          before do
            game_w_questions.friend_call_used = true
            game_w_questions.save

            put :help, id: game_w_questions.id, help_type: :friend_call
          end
          let!(:game) { assigns(:game) }

          it 'flashes alert' do
            expect(flash[:alert]).to be
          end

          it 'redirects to game view' do
            expect(response).to redirect_to(game_path(game))
          end
        end
      end
    end
  end
end
