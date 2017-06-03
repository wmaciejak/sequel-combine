# frozen_string_literal: true

require "sequel"

module Sequel
  module Extensions
    module Combine
      def combine(options)
        datasets = options.each_with_object([]) do |(type, relations), result|
          result << relations.each_with_object({}) do |(name, (relation, keys)), store|
            base_query = relation.where(keys).from_self(alias: :ROW)
            if type == :many
              store[name] = base_query.select { COALESCE(array_to_json(array_agg(row_to_json(:ROW))), "[]") }
            elsif type == :one
              store[name] = base_query.select { row_to_json(:ROW) }
            end
          end
        end
        select_append do
          datasets.flat_map { |dataset| dataset.map { |col, query| query.as(col.to_sym) } }
        end
      end
    end
  end

  Dataset.register_extension(:combine, Extensions::Combine)
end
