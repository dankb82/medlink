class SMSReceiptRecorder < SMSResponder
  def intent
    if ["yes", "y", "got it", "ok", "okay"].include? normalized_message
      :approve
    elsif ["no", "n", "flag"].include? normalized_message
      :flag
    end
  end

  def valid?
    intent.present?
  end

  def respond
    unless outstanding_response && outstanding_response.outstanding?
      send_response I18n.t! "sms.no_outstanding_responses"
      return
    end

    if intent == :flag
      response = response_message "flagged"
      outstanding_response.flag!
    elsif intent == :approve
      response = response_message "received"
      outstanding_response.mark_received! by: user
    end
    send_response response
  end

private

  def normalized_message
    message.downcase.strip
  end

  def outstanding_response
    @_outstanding_reminder ||= user.receipt_reminders.latest.try(:response)
  end

  def response_message type
    orders = Order.where(response: outstanding_response).includes(:supply)
    SMS::Condenser.new("sms.orders_#{type}", :supply,
      supplies: orders.map { |o| o.supply.name }.uniq
    ).message
  end
end
