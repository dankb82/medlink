require "rails_helper"

describe Report::User do
  Given!(:p1) { FactoryGirl.create :phone }
  Given!(:p2) { FactoryGirl.create :phone }

  When(:result) { CSV.parse Report::Users.new(User.all).to_csv, headers: true }

  Then { result.count == 2             }
  And  { result.first.include? "Email" }
end
