BentoSearch.register_engine("catalog") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 6

  conf.for_display do |display|
    display.heading = "Catalog"
    display.hint = "Library books, journals, music, videos, databases, archival collections, and online resources"
  end
end

BentoSearch.register_engine("articles") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 8

  conf.for_display do |display|
    display.heading = "Articles"
    display.hint = "Articles, e-books, dissertations, music, images, and more from a mostly full-text database"
  end
end

BentoSearch.register_engine("reserves") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 3

  conf.for_display do |display|
    display.heading = "Reserves/Exams"
  end
end

BentoSearch.register_engine("databases") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 5

  conf.for_display do |display|
    display.heading = "Databases"
  end
end

BentoSearch.register_engine("website") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 3

  conf.for_display do |display|
    display.heading = "Library Website"
    display.hint = "Information about the libraries from the The Maloney Library website"
  end
end

# bepress institutional repository
BentoSearch.register_engine("flash") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 2

  conf.for_display do |display|
    display.heading = "FLASH"
    display.hint = "Fordham Law Archive of Scholarship & History"
  end
end
