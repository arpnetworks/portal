class StripeAccount < Account
  default_scope { where("stripe_customer_id != ''") }

  def self.find(id)
    find_by(stripe_customer_id: id)
  end

  def sync!
    Stripe::Customer.update(stripe_customer_id, {
                              description: display_account_name,
                              address: {
                                line1: address1,
                                line2: address2,
                                city: city,
                                state: state,
                                postal_code: zip,
                                country: country
                              }
                            })
  end
end
