# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }
  let(:actor) { create(:user) }
  let(:topic) { create(:topic, user: user) }

  def make_notification(action: "reply", notifiable: topic, recipient: user)
    Notification.notify(recipient: recipient, actor: actor, notifiable: notifiable, action: action)
  end

  describe "GET /notifications" do
    it "requires authentication" do
      get notifications_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists the signed-in user's notifications" do
      sign_in user
      make_notification
      get notifications_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(actor.username)
    end

    it "does not leak another user's notifications" do
      other = create(:user)
      make_notification(recipient: other)
      sign_in user
      get notifications_path
      expect(response.body).not_to include("replied to you")
    end
  end

  describe "PATCH /notifications/:id/read" do
    it "marks the notification read and redirects to its target" do
      sign_in user
      post = create(:post, topic: topic, user: actor)
      notification = make_notification(notifiable: post)

      patch read_notification_path(notification)

      expect(notification.reload.read_at).to be_present
      expect(response).to redirect_to(topic_path(topic, anchor: "post_#{post.id}"))
    end

    it "will not let a user read someone else's notification" do
      other_notification = make_notification(recipient: create(:user))
      sign_in user
      patch read_notification_path(other_notification)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /notifications/read_all" do
    it "marks every unread notification read" do
      sign_in user
      make_notification(action: "reply")
      make_notification(action: "mention")

      expect {
        post read_all_notifications_path
      }.to change { user.notifications.unread.count }.to(0)
    end
  end
end
