require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_registration_path
    assert_response :success
  end

  test "should create user with valid attributes" do
    assert_difference('User.count') do
      post registrations_path, params: {
        user: {
          first_name: "John",
          last_name: "Doe",
          email_address: "john.doe@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to root_path
  end

  test "should not create user with invalid attributes" do
    assert_no_difference('User.count') do
      post registrations_path, params: {
        user: {
          first_name: "",
          last_name: "",
          email_address: "invalid-email",
          password: "123",
          password_confirmation: "456"
        }
      }
    end
    assert_response :unprocessable_entity
  end
end
