require "rails_helper"

describe PromptForReceiptAcknowledgementJob do
  Given(:alice)    { FactoryGirl.create :pcv, :textable }
  Given(:response) { FactoryGirl.create :response, user: alice, order_count: 1 }

  When(:result) { PromptForReceiptAcknowledgementJob.new.perform response }

  Then { result == true         }
  And  { alice.messages.exists? }
end
