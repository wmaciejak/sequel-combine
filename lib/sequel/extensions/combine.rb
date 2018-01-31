# frozen_string_literal: true

require "sequel"

module Sequel
  module Extensions
    module Combine
      ALLOWED_TYPES = %i[many one].freeze
      AGGREGATED_ROW_ALIAS = :ROW

      def combine(options)
        column_mappings = options.map { |type, relations| combine_columns(type, relations) }
        column_mapping = column_mappings.reduce({}, :merge)
        select_append do
          column_mapping.map { |column_name, query| query.as(column_name.to_sym) }
        end
      end

      private

      def combine_columns(type, relations)
        return {} unless ALLOWED_TYPES.include?(type)
        relations.each_with_object({}) do |(relation_name, (dataset, key_mappings)), columns|
          base_query = dataset.where(key_mappings).from_self(alias: AGGREGATED_ROW_ALIAS)
          case type
          when :many
            columns[relation_name] = aggregate_many(base_query)
          when :one
            columns[relation_name] = aggregate_one(base_query)
          end
        end
      end

      def aggregate_many(dataset)
        dataset.select { COALESCE(array_to_json(array_agg(row_to_json(AGGREGATED_ROW_ALIAS))), "[]") }
      end

      def aggregate_one(dataset)
        dataset.select { row_to_json(AGGREGATED_ROW_ALIAS) }
      end
    end
  end

  Dataset.register_extension(:combine, Extensions::Combine)
end
