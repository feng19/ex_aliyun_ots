defmodule ExAliyunOts.Client do

  alias ExAliyunOts.Client.{Table, Row, Search, Transaction, Tunnel}

  alias ExAliyunOts.{PlainBuffer, Config}

  def create_table(instance_key, var_create_table) do
    encoded_request = Table.request_to_create_table(var_create_table)
    Table.remote_create_table(Config.get(instance_key), encoded_request)
  end

  def list_table(instance_key) do
    encoded_request = Table.request_to_list_table()
    Table.remote_list_table(Config.get(instance_key), encoded_request)
  end

  def delete_table(instance_key, table_name) do
    encoded_request = Table.request_to_delete_table(table_name)
    Table.remote_delete_table(Config.get(instance_key), encoded_request)
  end

  def update_table(instance_key, var_update_table) do
    encoded_request = Table.request_to_update_table(var_update_table)
    Table.remote_update_table(Config.get(instance_key), encoded_request)
  end

  def describe_table(instance_key, var_describe_table) do
    encoded_request = Table.request_to_describe_table(var_describe_table)
    Table.remote_describe_table(Config.get(instance_key), encoded_request)
  end

  def put_row(instance_key, var_put_row) do
    encoded_request = Row.request_to_put_row(var_put_row)
    Row.remote_put_row(Config.get(instance_key), encoded_request)
  end

  def get_row(instance_key, var_get_row) do
    encoded_request = Row.request_to_get_row(var_get_row)
    Row.remote_get_row(Config.get(instance_key), encoded_request)
  end

  def update_row(instance_key, var_update_row) do
    encoded_request = Row.request_to_update_row(var_update_row)
    Row.remote_update_row(Config.get(instance_key), encoded_request)
  end

  def delete_row(instance_key, var_delete_row) do
    encoded_request = Row.request_to_delete_row(var_delete_row)
    Row.remote_delete_row(Config.get(instance_key), encoded_request)
  end

  def get_range(instance_key, var_get_range, next_start_primary_key \\ nil) do
    encoded_request = Row.request_to_get_range(var_get_range, next_start_primary_key)
    remote_get_range(Config.get(instance_key), encoded_request)
  end

  def iterate_get_all_range(instance_key, var_get_range) do
    encoded_request = Row.request_to_get_range(var_get_range)
    iterate_remote_get_range(Config.get(instance_key), encoded_request, var_get_range, nil)
  end

  def batch_get_row(instance_key, vars_batch_get_row) when is_list(vars_batch_get_row) do
    encoded_request = Row.request_to_batch_get_row(vars_batch_get_row)
    Row.remote_batch_get_row(Config.get(instance_key), encoded_request)
  end

  def batch_write_row(instance_key, var_batch_write_row, options \\ [transaction_id: nil]) 
    when is_map(var_batch_write_row) and is_list(options)
    when is_list(var_batch_write_row) and is_list(options) do
    transaction_id = Keyword.get(options, :transaction_id, nil)
    encoded_request = Row.request_to_batch_write_row(var_batch_write_row, transaction_id)
    Row.remote_batch_write_row(Config.get(instance_key), encoded_request)
  end

  def create_search_index(instance_key, var_create_search_index) do
    encoded_request = Search.request_to_create_search_index(var_create_search_index)
    Search.remote_create_search_index(Config.get(instance_key), encoded_request)
  end

  def search(instance_key, var_search_request) do
    encoded_request = Search.request_to_search(var_search_request)
    case Search.remote_search(Config.get(instance_key), encoded_request) do
      {:ok, search_result_response} ->
        {:ok, %{search_result_response | rows: decode_rows(search_result_response.rows)}}
      error_result ->
        error_result
    end
  end

  def delete_search_index(instance_key, var_delete_search_index) do
    encoded_request = Search.request_to_delete_search_index(var_delete_search_index)
    Search.remote_delete_search_index(Config.get(instance_key), encoded_request)
  end

  def list_search_index(instance_key, table_name) do
    encoded_request = Search.request_to_list_search_index(table_name)
    Search.remote_list_search_index(Config.get(instance_key), encoded_request)
  end

  def describe_search_index(instance_key, var_describe_search_index) do
    encoded_request = Search.request_to_describe_search_index(var_describe_search_index)
    Search.remote_describe_search_index(Config.get(instance_key), encoded_request)
  end

  def start_local_transaction(instance_key, var_start_local_transaction) do
    encoded_request = Transaction.request_to_start_local_transaction(var_start_local_transaction)
    Transaction.remote_start_local_transaction(Config.get(instance_key), encoded_request)
  end

  def commit_transaction(instance_key, transaction_id) do
    encoded_request = Transaction.request_to_commit_transaction(transaction_id)
    Transaction.remote_commit_transaction(Config.get(instance_key), encoded_request)
  end

  def abort_transaction(instance_key, transaction_id) do
    encoded_request = Transaction.request_to_abort_transaction(transaction_id)
    Transaction.remote_abort_transaction(Config.get(instance_key), encoded_request)
  end

  def create_tunnel(instance_key, options) do
    encoded_request = Tunnel.request_to_create_tunnel(options)
    Tunnel.remote_create_tunnel(Config.get(instance_key), encoded_request)
  end

  def delete_tunnel(instance_key, options) do
    encoded_request = Tunnel.request_to_delete_tunnel(options)
    Tunnel.remote_delete_tunnel(Config.get(instance_key), encoded_request)
  end

  def list_tunnel(instance_key, table_name) do
    encoded_request = Tunnel.request_to_list_tunnel(table_name)
    Tunnel.remote_list_tunnel(Config.get(instance_key), encoded_request)
  end

  def describe_tunnel(instance_key, options) do
    encoded_request = Tunnel.request_to_describe_tunnel(options)
    Tunnel.remote_describe_tunnel(Config.get(instance_key), encoded_request)
  end

  def connect_tunnel(instance_key, options) do
    encoded_request = Tunnel.request_to_connect_tunnel(options)
    Tunnel.remote_connect_tunnel(Config.get(instance_key), encoded_request)
  end

  def heartbeat(instance_key, options) do
    encoded_request = Tunnel.request_to_heartbeat(options)
    Tunnel.remote_heartbeat(Config.get(instance_key), encoded_request)
  end

  def shutdown_tunnel(instance_key, options) do
    encoded_request = Tunnel.request_to_shutdown(options)
    Tunnel.remote_shutdown(Config.get(instance_key), encoded_request)
  end

  def get_checkpoint(instance_key, options) do
    encoded_request = Tunnel.request_to_get_checkpoint(options)
    Tunnel.remote_get_checkpoint(Config.get(instance_key), encoded_request)
  end

  def read_records(instance_key, options) do
    encoded_request = Tunnel.request_to_readrecords(options)
    Tunnel.remote_readrecords(Config.get(instance_key), encoded_request)
  end

  def checkpoint(instance_key, options) do
    encoded_request = Tunnel.request_to_checkpoint(options)
    Tunnel.remote_checkpoint(Config.get(instance_key), encoded_request)
  end

  defp remote_get_range(instance, request_body) do
    result = Row.remote_get_range(instance, request_body)
    case result do
      {:ok, get_range_response} ->
        {:ok, %{get_range_response | rows: decode_rows(get_range_response.rows)}}
      _ ->
        result
    end
  end

  defp iterate_remote_get_range(instance, request_body, var_get_range, summarized_response, next_start_primary_key \\ nil) do
    response_result =
      if next_start_primary_key == nil do
        Row.remote_get_range(instance, request_body)
      else
        request_body_with_next_start_primary_key = Row.request_to_get_range(var_get_range, next_start_primary_key)
        Row.remote_get_range(instance, request_body_with_next_start_primary_key)
      end

    case response_result do
      {:ok, get_range_response} ->
        new_next_start_primary_key = get_range_response.next_start_primary_key
        if new_next_start_primary_key == nil do
          iterated_response = sum_get_range_response(get_range_response, summarized_response)
          {:ok, %{iterated_response | rows: decode_rows(iterated_response.rows)}}
        else
          updated_summarized_response = sum_get_range_response(get_range_response, summarized_response)
          iterate_remote_get_range(instance, request_body, var_get_range, updated_summarized_response, new_next_start_primary_key)
        end
      _ ->
        response_result
    end
  end

  defp sum_get_range_response(response, nil) do
    %{response | rows: [response.rows]}
  end
  defp sum_get_range_response(response, summarized_response) do
    cu = response.consumed.capacity_unit
    consumed_read = cu.read
    consumed_write = cu.write
    rows = response.rows

    summarized_cu = summarized_response.consumed.capacity_unit
    updated_cu = %{summarized_cu | read: (summarized_cu.read + consumed_read), write: (summarized_cu.write + consumed_write)}
    updated_consumed = %{summarized_response.consumed | capacity_unit: updated_cu}

    summarized_response
    |> Map.put(:consumed, updated_consumed)
    |> Map.put(:rows, summarized_response.rows ++ [rows])
    |> Map.put(:next_start_primary_key, response.next_start_primary_key)
  end

  defp decode_rows(binary_rows) when is_bitstring(binary_rows) do
    PlainBuffer.deserialize_rows(binary_rows)
  end
  defp decode_rows(binary_rows_list) when is_list(binary_rows_list) do
    stream = Task.async_stream(binary_rows_list, fn(rows) ->
      PlainBuffer.deserialize_rows(rows)
    end, timeout: :infinity)
    Enum.reduce(stream, [], fn({:ok, readable_rows}, acc) ->
      acc ++ readable_rows
    end)
  end

end
