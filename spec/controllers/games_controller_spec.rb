require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, is_admin: true) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  describe '#show' do
    context 'when anonymous' do
      before { get :show, id: game_w_questions.id }

      it 'returns status not equal 200' do
        expect(response.status).not_to eq(200)
      end

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

        it 'returns status 200' do
          expect(response.status).to eq(200)
        end

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

        it 'returns status is not 200' do
          expect(response.status).not_to eq(200)
        end

        it 'flashes alert' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#create' do
    context 'when anonymous' do
      before { post :create }

      it 'returns status not equal 200' do
        expect(response.status).not_to eq(200)
      end

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

      it 'returns status not equal 200' do
        expect(response.status).not_to eq(200)
      end

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
        context 'and answer is correct' do
          before { put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }
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
      end

    end
  end

  describe '#take_money' do
    context 'when anonymous' do
      before { put :take_money, id: game_w_questions.id }

      it 'returns status not equal 200' do
        expect(response.status).not_to eq(200)
      end

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

      it 'returns status not equal 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirects to new_user_session_path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'flashes alert' do
        expect(flash[:alert]).to be
      end
    end
  end
end
