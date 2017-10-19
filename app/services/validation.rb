Dir[File.dirname(__FILE__) + '/validation/*.rb'].each {|file| require file }

module Fiat
  FUND_TYPE = Dir["app/models/payments/*.rb"].map!{|file| file.split("/").last.split(".").first }
  module Validation

    ## check csv lines validation
    #  [params]
    #  nil
    #  [return]
    #  nil
    #  [used attribute:]
    #  @column_name : array(symbol)  -- check necessary column names not missing
    #  @payments    : array(hash)    -- check payment type valid
    ##
    def check
      # column names must not missing
      #[:source_id, :source_code, :payment_type, :amount, :currency].each do | column |
      #  raise "column name missing : [#{column.to_s}]" unless @column_name.include?(column)
      #end

      # check validation according to payment type 
      if @source_type == nil || @source_type == "" || !Fiat::FUND_TYPE.include?(@source_type)
        raise "source type error '#{@source_type}' !!"
      end
      validateclass = Fiat.const_get("#{@source_type.capitalize}Validation")
      missing = validateclass.check_columnname(@column_names)
      raise "column missing : [#{missing.to_a.join(",")}]" if missing.size > 0

      #filter data if needed
      @payments = validateclass.filter(@payments) if validateclass.respond_to?("filter")
      raise @payments if @payments.is_a? String

      @payments.each_with_index do |payment,index|
        valid, errormsg = validateclass.validate(payment)
        raise "payments data error: #{errormsg} in line #{index+2} !!" unless valid
      end
    end
  end
end