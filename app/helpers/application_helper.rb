module ApplicationHelper
  def fafar_icon(name, class_name: nil)
    classes = [ "icon", class_name ].compact.join(" ")

    tag.svg(class: classes, aria: { hidden: true }) do
      tag.use(href: "#{asset_path('icons.svg')}##{name}")
    end
  end
end
