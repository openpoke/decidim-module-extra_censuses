# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/elections/test/factories"

FactoryBot.modify do
  factory :election_question do
    trait :borda do
      transient do
        scoring_scale { "start_from_max" }
      end

      question_type { "multiple_option" }
      max_choices { 3 }
      min_choices { 1 }
      settings do
        {
          "voting_method" => "borda",
          "scoring_scale" => scoring_scale
        }
      end
    end
  end

  factory :election_vote do
    trait :with_position do
      transient do
        rank { 1 }
      end

      position { rank }
    end
  end

  factory :election_response_option do
    trait :with_label do
      settings do
        {
          "label" => {
            "title" => { "en" => "Winner" },
            "description" => { "en" => "The winning option" },
            "position" => 1,
            "color" => "#00b551"
          }
        }
      end
    end
  end
end
