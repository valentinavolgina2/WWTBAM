FactoryBot.define do
  factory :question do
    answer1 { "#{rand(2001)}" }
    answer2 { "#{rand(2001)}" }
    answer3 { "#{rand(2001)}" }
    answer4 { "#{rand(2001)}" }

    sequence(:text) { |n| "In which year was A Space Odyssey #{n}?" }

    sequence(:level) { |n| n % 15 }
  end
end
