require_relative "../../spec_helper"

Sequel.extension :combine

describe Sequel::Extensions::Combine do
  before do
    Sequel::Dataset.send(:include, Sequel::Extensions::Combine)
    @db = Sequel.mock
  end

  describe "one" do
    it "generates combining sql" do
      combine = @db[:users].combine(one: { group: [@db[:groups], group_id: :id]})
      combine.sql.must_equal "SELECT *, (SELECT row_to_json(ROW) FROM (SELECT * FROM groups WHERE (group_id = id)) AS ROW) AS group FROM users"
    end

    describe "with multiple combines" do
      it "generates proper query" do
        combine = @db[:users].combine(
          one: {
            group: [@db[:groups], group_id: :id],
            company: [@db[:companies], company_id: :id],
          },
        )
        combine.sql.must_equal "SELECT *, (SELECT row_to_json(ROW) FROM (SELECT * FROM groups WHERE (group_id = id)) AS ROW) AS group, (SELECT row_to_json(ROW) FROM (SELECT * FROM companies WHERE (company_id = id)) AS ROW) AS company FROM users"
      end
    end
  end

  describe "many" do
    it "generates combining query" do
      combine = @db[:groups].combine(many: { users: [@db[:users], id: :group_id] })
      combine.sql.must_equal "SELECT *, (SELECT COALESCE(array_to_json(array_agg(row_to_json(ROW))), '[]') FROM (SELECT * FROM users WHERE (id = group_id)) AS ROW) AS users FROM groups"
    end

    describe "with multiple combines" do
      it "generates proper query" do
        combine = @db[:users].combine(
          many: {
            tasks: [@db[:tasks], id: :user_id],
            roles: [@db[:roles], id: :user_id],
          },
        )
        combine.sql.must_equal "SELECT *, (SELECT COALESCE(array_to_json(array_agg(row_to_json(ROW))), '[]') FROM (SELECT * FROM tasks WHERE (id = user_id)) AS ROW) AS tasks, (SELECT COALESCE(array_to_json(array_agg(row_to_json(ROW))), '[]') FROM (SELECT * FROM roles WHERE (id = user_id)) AS ROW) AS roles FROM users"
      end
    end

    describe "with many and one in the same combine" do
      it "generates proper query" do
        combine = @db[:users].combine(
          one: { company: [@db[:companies], company_id: :id]},
          many: { roles: [@db[:roles], id: :user_id]},
        )
        combine.sql.must_equal "SELECT *, (SELECT row_to_json(ROW) FROM (SELECT * FROM companies WHERE (company_id = id)) AS ROW) AS company, (SELECT COALESCE(array_to_json(array_agg(row_to_json(ROW))), '[]') FROM (SELECT * FROM roles WHERE (id = user_id)) AS ROW) AS roles FROM users"
      end
    end

    describe "with nested combines" do
      it "generates the proper query" do
        combine = @db[:projects].combine(
          many: {
            users: [
              @db[:users].combine(one: { city: [@db[:cities], city_id: :id] }),
              id: :project_id,
            ],
          },
        )
        combine.sql.must_equal "SELECT *, (SELECT COALESCE(array_to_json(array_agg(row_to_json(ROW))), '[]') FROM (SELECT *, (SELECT row_to_json(ROW) FROM (SELECT * FROM cities WHERE (city_id = id)) AS ROW) AS city FROM users WHERE (id = project_id)) AS ROW) AS users FROM projects"
      end
    end
  end
end
