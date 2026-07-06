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
end
