require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping 
    class Postnl < ShippingCalculator
      preference :postnl_letter_20g, :float, :default => 0.54
      preference :postnl_letter_50g, :float, :default => 1.08
      preference :postnl_letter_100g, :float, :default => 1.62
      preference :postnl_letter_250g, :float, :default => 2.16
      preference :postnl_letter_500g, :float, :default => 2.70
      preference :postnl_letter_2000g, :float, :default => 3.24
      preference :postnl_box_2000g, :float, :default => 6.75
      preference :postnl_box_5000g, :float, :default => 6.75
      preference :postnl_box_10000g, :float, :default => 6.75
      preference :postnl_box_20000g, :float, :default => 12.40
      preference :postnl_box_30000g, :float, :default => 12.40
      preference :oversized_class, :string, :default => 'postnl_box_2000g'

      attr_accessible :preferred_postnl_letter_20g,
                      :preferred_postnl_letter_50g,
                      :preferred_postnl_letter_100g,
                      :preferred_postnl_letter_250g,
                      :preferred_postnl_letter_500g,
                      :preferred_postnl_letter_2000g,
                      :preferred_postnl_box_2000g,
                      :preferred_postnl_box_5000g,
                      :preferred_postnl_box_10000g,
                      :preferred_postnl_box_20000g,
                      :preferred_postnl_box_30000g,
                      :preferred_oversized_class

  def self.description
    Spree.t :postnl
  end

  def self.register
    super
  end

  def compute(package)
    content_items = package.contents
    return 0 unless content_items.size > 0

    weight = total_weight(content_items)
    volume = total_volume(content_items)
    di = max_dimensions(content_items)
    
    price = shipment_costs(weight, volume, di[:heigth], di[:width], di[:depth])
    
    return 0 unless price
    price
  end

  private
  def shipment_costs(weight, volume, heigth, width, depth)
    shipment_classes.each do |sc|
      if weight <= sc[:weight] && volume <= sc[:volume] && heigth <= sc[:heigth] && width <= sc[:width] && depth <= sc[:depth]
        return self.send("preferred_#{sc[:class]}".to_sym)
      end
    end
    return self.send("preferred_#{self.preferred_oversized_class}".to_sym)
  end
  
  def shipment_classes
    letter = { heigth: 380, width: 265, depth: 32, volume: 3222400 }
    little_box = { heigth: 1000, width: 500, depth: 500, volume: 250000000 }
    big_box = { heigth: 1750, width: 780, depth: 580, volume: 791700000 }
    [{ class: 'postnl_letter_20g',   weight: 20 }.merge!(letter),
     { class: 'postnl_letter_50g',   weight: 50 }.merge!(letter),
     { class: 'postnl_letter_100g',  weight: 100 }.merge!(letter),
     { class: 'postnl_letter_250g',  weight: 250 }.merge!(letter),
     { class: 'postnl_letter_500g',  weight: 500 }.merge!(letter),
     { class: 'postnl_letter_2000g', weight: 2000 }.merge!(letter),
     { class: 'postnl_box_2000g',    weight: 2000 }.merge!(little_box),      
     { class: 'postnl_box_5000g',    weight: 5000 }.merge!(little_box),
     { class: 'postnl_box_10000g',   weight: 10000 }.merge!(little_box),
     { class: 'postnl_box_20000g',   weight: 20000 }.merge!(big_box),
     { class: 'postnl_box_30000g',   weight: 30000 }.merge!(big_box)]
  end

  def total_weight(content_items)
    weight = 0
    content_items.each do |item|
      weight += item.quantity * (item.variant.weight || self.preferred_default_weight)
    end
    weight
  end

  def total_volume(content_items)
    volume = 0
    content_items.each do |item|
      volume += item.quantity * (
          (item.variant.height ? item.variant.height : 1) * 
          (item.variant.width ? item.variant.width : 1) * 
          (item.variant.depth ? item.variant.depth : 1)
	)
    end
    volume
  end

  def max_dimensions(content_items)
    dimensions = { heigth: 0, width: 0, depth: 0 }
    content_items.each do |item|
      if dimensions[:heigth] < (item.variant.height ? item.variant.height : 1)
        dimensions[:heigth] = (item.variant.height ? item.variant.height : 1)
      end

      if dimensions[:width] < (item.variant.width ? item.variant.width : 1)
        dimensions[:width] = (item.variant.width ? item.variant.width : 1)
      end

      if dimensions[:depth] < (item.variant.depth ? item.variant.depth : 1)
        dimensions[:depth] = (item.variant.depth ? item.variant.depth : 1)
      end
    end
    dimensions
  end

    end
  end
end