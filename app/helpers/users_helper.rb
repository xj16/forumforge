# frozen_string_literal: true

module UsersHelper
  # Simple deterministic avatar colour from the username.
  def avatar_color(username)
    hue = Digest::MD5.hexdigest(username.to_s)[0, 6].to_i(16) % 360
    "hsl(#{hue}, 60%, 55%)"
  end

  def avatar_tag(user, size: 32)
    initial = user.username.to_s[0]&.upcase || "?"
    content_tag(:span, initial,
                class: "avatar",
                style: "background:#{avatar_color(user.username)};width:#{size}px;height:#{size}px;line-height:#{size}px;")
  end
end
