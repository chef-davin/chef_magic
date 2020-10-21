#
# Chef Infra Documentation
# https://docs.chef.io/libraries/
#

#
# This module name was auto-generated from the cookbook name. This name is a
# single word that starts with a capital letter and then continues to use
# camel-casing throughout the remainder of the name.
#
module ChefMagic
  module DataBagProcessorsHelpers
    # Checks an array in a data bag item to see if the node['name'] exists in the array, allowing processing logic to change how a cookbook reacts to a listed exception.
    #   Accepts a data bag, a data bag item, and up to two array objects to look for within a data bag.
    #   Data Bag Item Example:
    #     {
    #       "id": "uac_exceptions",
    #       "permanent_exceptions": ['node1', 'node2', 'node3']
    #       "temporary_exceptions": ['node4', 'node5']
    #     }
    #   Method usage example with above data bag
    #     data_bag_exception_check?('all_exceptions', 'uac_exceptions', 'permanent_exceptions', 'temporary_exceptions')
    #
    def data_bag_exception_check?(data_bag, data_bag_item, array1 = 'exceptions', array2 = 'overrides')
      exception_array = []
      exception_array += data_bag_item(data_bag, data_bag_item)[array1] unless data_bag_item(data_bag, data_bag_item)[array1].nil?
      exception_array += data_bag_item(data_bag, data_bag_item)[array2] unless data_bag_item(data_bag, data_bag_item)[array2].nil?
      exception_array.any? { |array| Regexp.new(Regexp.escape(node['name']), 'i') =~ array }
    end
  end
end

Chef::DSL::Universal.include ::ChefMagic::DataBagProcessorsHelpers
