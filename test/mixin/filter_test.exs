defmodule ExAliyunOts.MixinTest.Filter do
  use ExUnit.Case

  import ExAliyunOts.Filter

  @result %ExAliyunOts.Var.Filter{
    filter: %ExAliyunOts.Var.CompositeColumnValueFilter{
      combinator: :LO_OR,
      sub_filters: [
        %ExAliyunOts.Var.Filter{
          filter: %ExAliyunOts.Var.CompositeColumnValueFilter{
            combinator: :LO_AND,
            sub_filters: [
              %ExAliyunOts.Var.Filter{
                filter: %ExAliyunOts.Var.SingleColumnValueFilter{
                  column_name: "name",
                  column_value: "updated_attr21",
                  comparator: :CT_EQUAL,
                  ignore_if_missing: true,
                  latest_version_only: true
                },
                filter_type: :FT_SINGLE_COLUMN_VALUE
              },
              %ExAliyunOts.Var.Filter{
                filter: %ExAliyunOts.Var.SingleColumnValueFilter{
                  column_name: "age",
                  column_value: 1,
                  comparator: :CT_GREATER_THAN,
                  ignore_if_missing: false,
                  latest_version_only: true
                },
                filter_type: :FT_SINGLE_COLUMN_VALUE
              }
            ]
          },
          filter_type: :FT_COMPOSITE_COLUMN_VALUE
        },
        %ExAliyunOts.Var.Filter{
          filter: %ExAliyunOts.Var.SingleColumnValueFilter{
            column_name: "class",
            column_value: "1",
            comparator: :CT_EQUAL,
            ignore_if_missing: false,
            latest_version_only: true
          },
          filter_type: :FT_SINGLE_COLUMN_VALUE
        }
      ]
    },
    filter_type: :FT_COMPOSITE_COLUMN_VALUE
  }

  test "filter" do
    value1 = "updated_attr21"
    class_field = "class"
    age_field = "age"
    options = [ignore_if_missing: true, latest_version_only: true]

    filter_result =
      filter(
        ({"name", [ignore_if_missing: true, latest_version_only: true]} == value1 and "age" > 1) or
          "class" == "1"
      )

    name_s = filter({"name", options} == value1)

    filter_result_1 = filter((name_s and "age" > 1) or class_field == "1")
    age_s = filter(age_field > 1)
    c_f = filter(name_s and age_s)

    filter_result_2 = filter(c_f or class_field == "1")

    assert filter_result == @result
    assert filter_result_1 == @result
    assert filter_result_2 == @result
  end
end
