module ApplicationHelper
  def radio_button(name:, value:, label:)
    label_tag do
      radio_button_tag(name, value.to_s, params[name].to_s == value.to_s) +
        label
    end
  end
end
