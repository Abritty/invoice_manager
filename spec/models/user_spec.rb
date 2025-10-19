require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) do
    User.new(
      first_name: "John",
      last_name: "Doe",
      email_address: "john.doe@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  describe 'validations' do
    it 'should be valid with valid attributes' do
      expect(user).to be_valid
    end

    it 'should require first_name' do
      user.first_name = nil
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to include("can't be blank")
    end

    it 'should require last_name' do
      user.last_name = nil
      expect(user).not_to be_valid
      expect(user.errors[:last_name]).to include("can't be blank")
    end

    it 'should require email_address' do
      user.email_address = nil
      expect { user.save! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(user.errors[:email_address]).to include("can't be blank")
    end

    it 'should require unique email_address' do
      user.save!
      duplicate_user = User.new(
        first_name: "Jane",
        last_name: "Smith",
        email_address: "john.doe@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      expect { duplicate_user.save! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(duplicate_user.errors[:email_address]).to include("has already been taken")
    end
  end

  describe 'normalizations' do
    it 'should normalize email_address to lowercase' do
      user.email_address = "JOHN.DOE@EXAMPLE.COM"
      user.save!
      expect(user.email_address).to eq("john.doe@example.com")
    end

    it 'should normalize first_name' do
      user.first_name = "  john  "
      user.save!
      expect(user.first_name).to eq("John")
    end

    it 'should normalize last_name' do
      user.last_name = "  doe  "
      user.save!
      expect(user.last_name).to eq("Doe")
    end
  end

  describe '#full_name' do
    it 'should return full name' do
      expect(user.full_name).to eq("John Doe")
    end

    it 'should handle nil names in full_name' do
      user.first_name = nil
      user.last_name = nil
      expect(user.full_name.strip).to eq("")
    end
  end

  describe 'associations' do
    it 'should have many sessions' do
      expect(user).to respond_to(:sessions)
      user.save!
      expect(user.sessions.count).to eq(0)
    end

    it 'should destroy associated sessions when user is destroyed' do
      user.save!
      session = user.sessions.create!
      expect { user.destroy }.to change { Session.count }.by(-1)
    end
  end

  describe 'password security' do
    it 'should have secure password' do
      user.save!
      expect(user).to respond_to(:password_digest)
      expect(user.password_digest).not_to be_nil
    end

    it 'should authenticate with correct password' do
      user.save!
      expect(user.authenticate("password123")).to be_truthy
    end

    it 'should not authenticate with incorrect password' do
      user.save!
      expect(user.authenticate("wrongpassword")).to be_falsy
    end
  end
end
