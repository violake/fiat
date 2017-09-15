require 'hashie'
require 'yaml'


class FiatConfig

  def data
    @@data ||= begin
      dir = File.dirname(__FILE__)
      [:fiat, :database, :rabbitmq].reduce(Hashie::Mash.new) do |config, file|
        config.merge(YAML.load_file(File.join(dir, "#{file}.yml")))
      end
    end
  end

  def [] key
    data[key]
  end

  def version
    "1.0.0"
  end
end