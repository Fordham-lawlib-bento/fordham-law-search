Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "ris_creator" => "RISCreator"
  )
end
