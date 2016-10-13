BentoSearch.register_engine("catalog") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 6
end

BentoSearch.register_engine("articles") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 8
end

BentoSearch.register_engine("reserves") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 3
end

BentoSearch.register_engine("databases") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 5
end

BentoSearch.register_engine("website") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 3
end

# bepress institutional repository
BentoSearch.register_engine("flash") do |conf|
  conf.engine = "BentoSearch::MockEngine"
  conf.num_results = 2
end
