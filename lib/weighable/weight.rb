require 'weighable/inflections'

module Weighable
  class Weight
    attr_reader :value, :unit

    UNIT = {
      each:      0,
      gram:      1,
      ounce:     2,
      pound:     3,
      milligram: 4,
      kilogram:  5
    }.freeze

    GRAMS_PER_OUNCE     = BigDecimal.new('28.34952')
    GRAMS_PER_POUND     = BigDecimal.new('453.59237')
    OUNCES_PER_POUND    = BigDecimal.new('16')
    MILLIGRAMS_PER_GRAM = BigDecimal.new('1000')
    KILOGRAMS_PER_GRAM  = BigDecimal.new('0.001')
    IDENTITY            = BigDecimal.new('1')

    MILLIGRAMS_PER_OUNCE    = GRAMS_PER_OUNCE * MILLIGRAMS_PER_GRAM
    KILOGRAMS_PER_OUNCE     = GRAMS_PER_OUNCE * KILOGRAMS_PER_GRAM
    MILLIGRAMS_PER_POUND    = GRAMS_PER_POUND * MILLIGRAMS_PER_GRAM
    KILOGRAMS_PER_POUND     = GRAMS_PER_POUND * KILOGRAMS_PER_GRAM
    KILOGRAMS_PER_MILLIGRAM = MILLIGRAMS_PER_GRAM**2

    CONVERSIONS = {
      UNIT[:each] => {}, # TODO: Write tests
      UNIT[:gram] => {
        UNIT[:gram]      => [:*, IDENTITY],
        UNIT[:ounce]     => [:/, GRAMS_PER_OUNCE],
        UNIT[:pound]     => [:/, GRAMS_PER_POUND],
        UNIT[:milligram] => [:*, MILLIGRAMS_PER_GRAM],
        UNIT[:kilogram]  => [:*, KILOGRAMS_PER_GRAM]
      },
      UNIT[:ounce] => {
        UNIT[:gram]      => [:*, GRAMS_PER_OUNCE],
        UNIT[:ounce]     => [:*, IDENTITY],
        UNIT[:pound]     => [:/, OUNCES_PER_POUND],
        UNIT[:milligram] => [:*, MILLIGRAMS_PER_OUNCE],
        UNIT[:kilogram]  => [:*, KILOGRAMS_PER_OUNCE]
      },
      UNIT[:pound] => {
        UNIT[:gram]      => [:*, GRAMS_PER_POUND],
        UNIT[:ounce]     => [:*, OUNCES_PER_POUND],
        UNIT[:pound]     => [:*, IDENTITY],
        UNIT[:milligram] => [:*, MILLIGRAMS_PER_POUND],
        UNIT[:kilogram]  => [:*, KILOGRAMS_PER_POUND]
      },
      UNIT[:milligram] => {
        UNIT[:gram]      => [:/, MILLIGRAMS_PER_GRAM],
        UNIT[:ounce]     => [:/, MILLIGRAMS_PER_OUNCE],
        UNIT[:pound]     => [:/, MILLIGRAMS_PER_POUND],
        UNIT[:milligram] => [:*, IDENTITY],
        UNIT[:kilogram]  => [:/, KILOGRAMS_PER_MILLIGRAM]
      },
      UNIT[:kilogram] => {
        UNIT[:gram]      => [:/, KILOGRAMS_PER_GRAM],
        UNIT[:ounce]     => [:/, KILOGRAMS_PER_OUNCE],
        UNIT[:pound]     => [:/, KILOGRAMS_PER_POUND],
        UNIT[:milligram] => [:*, KILOGRAMS_PER_MILLIGRAM],
        UNIT[:kilogram]  => [:*, IDENTITY]
      }
    }.freeze

    def initialize(value, unit)
      @value = value.to_d
      @unit  = unit.is_a?(Fixnum) ? unit : unit_from_symbol(unit.to_sym)
    end

    def to(unit)
      new_unit = unit.is_a?(Fixnum) ? unit : unit_from_symbol(unit.to_sym)
      operator, conversion = conversion(@unit, new_unit)
      new_value = @value.public_send(operator, conversion)
      Weight.new(new_value, unit)
    end

    UNIT.keys.each do |unit|
      unit = unit.to_s
      define_method "to_#{unit}" do
        to(unit)
      end
      plural = ActiveSupport::Inflector.pluralize(unit)
      alias_method "to_#{plural}", "to_#{unit}" unless unit == plural
    end

    def ==(other)
      other.class == self.class && other.value == @value && other.unit == @unit
    end

    def +(other)
      other = other.to(unit_name)
      Weight.new(@value + other.value, unit_name)
    end

    def -(other)
      other = other.to(unit_name)
      Weight.new(@value - other.value, unit_name)
    end

    def *(other)
      other = other.to(unit_name)
      Weight.new(@value * other.value, unit_name)
    end

    def round(precision = 0)
      @value = @value.round(precision)
      self
    end

    def /(other)
      other = other.to(unit_name)
      Weight.new(@value / other.value, unit_name)
    end

    private

    def unit_name
      unit_from_int(@unit)
    end

    def unit_from_symbol(unit)
      unit = UNIT[unit]
      fail "invalid unit '#{unit}'" unless unit
      unit
    end

    def unit_from_int(int)
      UNIT.find { |_k, v| v == int }.first
    end

    def conversion(from, to)
      conversion = CONVERSIONS[from][to]
      fail "no conversion from #{unit_from_int(from)} to #{unit_from_int(to)}" unless conversion
      conversion
    end
  end
end