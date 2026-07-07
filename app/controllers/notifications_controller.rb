# frozen_string_literal: true

# The in-app notification inbox and its actions. Every action requires a signed
# in user and only ever touches that user's own notifications.
class NotificationsController < ApplicationController
  before_action :authenticate_user!

  # GET /notifications
  def index
    @pagy, @notifications = pagy(
      current_user.notifications
                  .includes(:actor, :notifiable)
                  .recent
    )
  end

  # PATCH /notifications/:id/read — mark one read, then go to its target.
  def read
    notification = current_user.notifications.find(params[:id])
    notification.update(read_at: Time.current) unless notification.read?
    redirect_to(notification.target_path || notifications_path)
  end

  # POST /notifications/read_all — clear the unread badge.
  def read_all
    current_user.notifications.unread.update_all(read_at: Time.current)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "notification_bell",
          partial: "notifications/bell",
          locals: { count: 0 }
        )
      end
      format.html { redirect_to notifications_path, notice: "All caught up." }
    end
  end
end
