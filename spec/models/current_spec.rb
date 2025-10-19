require 'rails_helper'

RSpec.describe Current, type: :model do
  let(:user) do
    User.create!(
      first_name: "John",
      last_name: "Doe",
      email_address: "john.doe@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:session) { Session.create!(user: user) }

  describe 'attributes' do
    it 'should have session attribute' do
      expect(Current).to respond_to(:session)
      expect(Current).to respond_to(:session=)
    end
  end

  describe 'user delegation' do
    it 'should delegate user to session' do
      Current.session = session
      expect(Current.user).to eq(user)
    end

    it 'should return nil user when session is nil' do
      Current.session = nil
      expect(Current.user).to be_nil
    end

    it 'should return nil user when session is not set' do
      Current.reset
      expect(Current.user).to be_nil
    end
  end

  describe 'session management' do
    it 'should be able to set and get session' do
      Current.session = session
      expect(Current.session).to eq(session)
    end

    it 'should access user attributes through delegation' do
      Current.session = session
      expect(Current.user.first_name).to eq("John")
      expect(Current.user.last_name).to eq("Doe")
      expect(Current.user.full_name).to eq("John Doe")
      expect(Current.user.email_address).to eq("john.doe@example.com")
    end

    it 'should handle session changes' do
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
      Current.session = session
      expect(Current.user.first_name).to eq("John")

      # Change to another session
      Current.session = another_session
      expect(Current.user.first_name).to eq("Jane")

      # Clear session
      Current.session = nil
      expect(Current.user).to be_nil
    end

    it 'should reset attributes' do
      Current.session = session
      expect(Current.session).to eq(session)
      
      Current.reset
      expect(Current.session).to be_nil
      expect(Current.user).to be_nil
    end
  end
end
