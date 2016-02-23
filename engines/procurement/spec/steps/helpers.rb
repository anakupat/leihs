module Helpers

  def travel_to_date(datetime = nil)
    if datetime
      Timecop.travel datetime
    else
      Timecop.return
    end

    # The minimum representable time is 1901-12-13, and the maximum representable time is 2038-01-19
    ActiveRecord::Base.connection.execute \
    "SET TIMESTAMP=unix_timestamp('#{Time.now.iso8601}')"
    mysql_now = ActiveRecord::Base.connection \
    .exec_query('SELECT CURDATE()').rows.flatten.first
    raise 'MySQL current datetime has not been changed' if mysql_now != Date.today
  end

  def currency(amount)
    ActionController::Base.helpers.number_to_currency(
        amount,
        unit: Setting.local_currency_string,
        precision: 0)
  end
end
