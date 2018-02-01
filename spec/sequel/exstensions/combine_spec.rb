require_relative "../../spec_helper"

Sequel.extension :combine

describe Sequel::Extensions::Combine do
  let(:db) { Sequel.mock }

  before { Sequel::Dataset.send(:include, Sequel::Extensions::Combine) }

  context "when adapter is Postgres" do
    before { stub_const("Sequel::Postgres::USES_PG", true) }

    describe "one" do
      subject do 
        db[:users].combine(
          one: { group: [db[:groups], group_id: :id]}
        )
      end

      it "generates combining sql" do
        expect(subject.sql).to eql "SELECT *, (SELECT row_to_json(ROW) FROM (SELECT * FROM groups WHERE (group_id = id)) AS ROW) AS group FROM users"
      end

      describe "with multiple combines" do
        subject do
          db[:users].combine(
            one: {
              group: [db[:groups], group_id: :id],
              company: [db[:companies], company_id: :id],
            },
          )
        end

        it "generates proper query" do
          expect(subject.sql).to eql "SELECT *, (SELECT row_to_json(ROW) FROM (SELECT * FROM groups WHERE (group_id = id)) AS ROW) AS group, (SELECT row_to_json(ROW) FROM (SELECT * FROM companies WHERE (company_id = id)) AS ROW) AS company FROM users"
        end
      end
    end

    describe "many" do
      subject do 
        db[:groups].combine(
          many: { users: [db[:users], id: :group_id] }
        ) 
      end
      it "generates combining query" do
        expect(subject.sql).to eql "SELECT *, (SELECT COALESCE(array_to_json(array_agg(row_to_json(ROW))), '[]') FROM (SELECT * FROM users WHERE (id = group_id)) AS ROW) AS users FROM groups"
      end

      describe "with multiple combines" do
        subject do
          db[:users].combine(
            many: {
              tasks: [db[:tasks], id: :user_id],
              roles: [db[:roles], id: :user_id],
            },
          )
        end

        it "generates proper query" do
          expect(subject.sql).to eql "SELECT *, (SELECT COALESCE(array_to_json(array_agg(row_to_json(ROW))), '[]') FROM (SELECT * FROM tasks WHERE (id = user_id)) AS ROW) AS tasks, (SELECT COALESCE(array_to_json(array_agg(row_to_json(ROW))), '[]') FROM (SELECT * FROM roles WHERE (id = user_id)) AS ROW) AS roles FROM users"
        end
      end

      describe "with many and one in the same combine" do
        subject do
          db[:users].combine(
            one: { company: [db[:companies], company_id: :id]},
            many: { roles: [db[:roles], id: :user_id]},
          )
        end

        it "generates proper query" do
          expect(subject.sql).to eql "SELECT *, (SELECT row_to_json(ROW) FROM (SELECT * FROM companies WHERE (company_id = id)) AS ROW) AS company, (SELECT COALESCE(array_to_json(array_agg(row_to_json(ROW))), '[]') FROM (SELECT * FROM roles WHERE (id = user_id)) AS ROW) AS roles FROM users"
        end
      end

      describe "with nested combines" do
        subject do
          db[:projects].combine(
            many: {
              users: [
                db[:users].combine(one: { city: [db[:cities], city_id: :id] }),
                id: :project_id,
              ],
            },
          )
        end

        it "generates the proper query" do
          expect(subject.sql).to eql "SELECT *, (SELECT COALESCE(array_to_json(array_agg(row_to_json(ROW))), '[]') FROM (SELECT *, (SELECT row_to_json(ROW) FROM (SELECT * FROM cities WHERE (city_id = id)) AS ROW) AS city FROM users WHERE (id = project_id)) AS ROW) AS users FROM projects"
        end
      end
    end
  end

  context "when adapter is different" do
    subject do 
      db[:users].combine(
        one: { group: [db[:groups], group_id: :id]}
      )
    end

    before { stub_const("Sequel::Postgres::USES_PG", false) }

    it "raise error" do
      expect { subject }.to raise_error(Sequel::DatabaseError, "Invalid adapter. PostgreSQL driver not found.")
    end
  end
end
