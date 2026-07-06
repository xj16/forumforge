# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  # Human friendly "3 hours ago".
  def time_ago(time)
    return "" if time.nil?

    content_tag(:time, "#{time_ago_in_words(time)} ago", datetime: time.iso8601, title: time.to_fs(:long))
  end

  # Flash key -> CSS class.
  def flash_class(key)
    case key.to_sym
    when :notice then "flash flash--notice"
    when :alert, :error then "flash flash--alert"
    else "flash"
    end
  end

  def signed_in_meta
    return "" unless user_signed_in?

    tag.meta(name: "current-user-id", content: current_user.id)
  end

  # The signed-in user, resolved safely in ANY render context.
  #
  # Partials like topics/_topic and posts/_post are rendered both from
  # controllers (where `current_user` works) and from Turbo Stream *broadcasts*
  # (a background render with no Warden proxy, where `current_user` raises
  # Devise::MissingWarden). This helper returns nil in the latter case so
  # broadcasts render the signed-out variant; each browser re-personalises on
  # its next request.
  def current_viewer
    current_user
  rescue Devise::MissingWarden, NameError
    nil
  end
end
