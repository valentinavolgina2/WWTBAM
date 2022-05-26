require 'rails_helper'

RSpec.describe GameQuestion, type: :model do
  let(:game_question) { create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  describe '#variants' do
    it 'should return correct variants' do
      expect(game_question.variants).to eq({
                                             'a' => game_question.question.answer2,
                                             'b' => game_question.question.answer1,
                                             'c' => game_question.question.answer4,
                                             'd' => game_question.question.answer3
                                           })
    end
  end

  describe '#answer_correct?' do
    it 'should return true' do
      expect(game_question.answer_correct?('b')).to be true
    end
  end

  describe 'text delegate' do
    it 'should return question text' do
      expect(game_question.text).to eq(game_question.question.text)
    end
  end

  describe 'level delegate' do
    it 'should return question level' do
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  describe '#correct_answer_key' do
    context 'when correct answer is b' do
      it 'should return b' do
        expect(game_question.correct_answer_key).to eq 'b'
      end
    end
  end

  describe '#add_audience_help' do
    context 'when audience help was not used' do
      before do
        expect(game_question.help_hash).not_to include(:audience_help)

        game_question.add_audience_help
      end

      it 'adds audience help to help hash' do
        expect(game_question.help_hash).to include(:audience_help)
      end

      it 'adds audience help with 4 keys' do
        ah = game_question.help_hash[:audience_help]
        expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
      end
    end
  end

  describe '#add_fifty_fifty' do
    context 'when fifty fifty help was not used' do
      before do
        expect(game_question.help_hash).not_to include(:fifty_fifty)

        game_question.add_fifty_fifty
      end

      it 'adds fifty fifty help to help hash' do
        expect(game_question.help_hash).to include(:fifty_fifty)
      end

      it 'adds fifty fifty help has 2 keys' do
        expect(game_question.help_hash[:fifty_fifty].size).to eq 2
      end

      it 'adds fifty fifty help with correct answer key' do
        expect(game_question.help_hash[:fifty_fifty]).to include(game_question.correct_answer_key)
      end
    end
  end

  describe '#help_hash' do
    context 'when game just created' do
      it 'returns empty hash' do
        expect(game_question.help_hash).to eq({})
      end
    end

    context 'when add keys to help hash' do
      before do
        game_question.help_hash[:key1] = ['a', 'b']
        game_question.help_hash[:key2] = {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4}
        game_question.help_hash[:key3] = 'Some text'

        expect(game_question.save).to be true
      end
      let!(:game_question_with_hash) { GameQuestion.find(game_question.id) }

      it 'returns hash with added keys' do
        expect(game_question_with_hash.help_hash).to eq({
                                                key1: ['a', 'b'],
                                                key2: {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4},
                                                key3: 'Some text'
                                              })
      end
    end
  end
end
