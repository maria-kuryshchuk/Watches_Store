require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
  fixtures :products
  include ActiveJob::TestHelper

  # A user goes to the index page. They select a product, adding it to their
  # cart, and check out, filling in their details on the checkout form. When
  # they submit, an order is created containing their information, along with a
  # single line item corresponding to the product they added to their cart.

  test "buying a product" do
    start_order_count = Order.count
    lorem = products(:lorem)

    get "/"
    assert_response :success
    assert_select 'h1', "Your Watches Catalog"

    post '/line_items', params: { product_id: lorem.id }, xhr: true
    assert_response :success

    cart = Cart.find(session[:cart_id])
    assert_equal 1, cart.line_items.size
    assert_equal lorem, cart.line_items[0].product

    get "/orders/new"
    assert_response :success
    assert_select 'legend', 'Please Enter Your Details'

    perform_enqueued_jobs do
      post "/orders", params: {
        order: {
          name: "Mariia Kuryshchuk",
          address: "Sukhomlynskogo,2 Street",
          email: "kuryshchukm@gmail.com",
          pay_type: "Check"
        }
      }
      follow_redirect!

      assert_response :success
      assert_select 'h1', "Your Watches Catalog"
      cart = Cart.find(session[:cart_id])
      assert_equal 0, cart.line_items.size

      assert_equal start_order_count + 1, Order.count
      order = Order.last

      assert_equal "Mariia Kuryshchuk", order.name
      assert_equal "Sukhomlynskogo, 2 Street", order.address
      assert_equal "kuryshchukm@gmail.com", order.email
      assert_equal "Check", order.pay_type

      assert_equal 1, order.line_items.size
      line_item = order.line_items[0]
      assert_equal lorem, line_item.product
      mail = ActionMailer::Base.deliveries.last
    end
  end
end
