BentoSearch.register_engine("catalog") do |conf|
  conf.engine = "BentoSearch::MockEngine"
end

BentoSearch.register_engine("articles") do |conf|
  conf.engine = "BentoSearch::MockEngine"
end

BentoSearch.register_engine("reserves") do |conf|
  conf.engine = "BentoSearch::MockEngine"
end

BentoSearch.register_engine("databases") do |conf|
  conf.engine = "BentoSearch::MockEngine"
end

BentoSearch.register_engine("website") do |conf|
  conf.engine = "BentoSearch::MockEngine"
end

# bepress institutional repository
BentoSearch.register_engine("flash") do |conf|
  conf.engine = "BentoSearch::MockEngine"
end
