require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      first_name: "John",
      last_name: "Doe",
      email_address: "john.doe@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @session = Session.create!(user: @user)
  end

  test "should have session attribute" do
    assert_respond_to Current, :session
    assert_respond_to Current, :session=
  end

  test "should delegate user to session" do
    Current.session = @session
    assert_equal @user, Current.user
  end

  test "should return nil user when session is nil" do
    Current.session = nil
    assert_nil Current.user
  end

  test "should return nil user when session is not set" do
    # Reset Current attributes
    Current.reset
    assert_nil Current.user
  end

  test "should be able to set and get session" do
    Current.session = @session
    assert_equal @session, Current.session
  end

  test "should access user attributes through delegation" do
    Current.session = @session
    assert_equal "John", Current.user.first_name
    assert_equal "Doe", Current.user.last_name
    assert_equal "John Doe", Current.user.full_name
    assert_equal "john.doe@example.com", Current.user.email_address
  end

  test "should handle session changes" do
    # Create another user and session
    another_user = User.create!(
      first_name: "Jane",
      last_name: "Smith",
      email_address: "jane.smith@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    another_session = Session.create!(user: another_user)

    # Set first session
    Current.session = @session
    assert_equal "John", Current.user.first_name

    # Change to another session
    Current.session = another_session
    assert_equal "Jane", Current.user.first_name

    # Clear session
    Current.session = nil
    assert_nil Current.user
  end

  test "should reset attributes" do
    Current.session = @session
    assert_equal @session, Current.session
    
    Current.reset
    assert_nil Current.session
    assert_nil Current.user
  end
end
