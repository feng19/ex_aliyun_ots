defmodule ExAliyunOts.Http.Middleware do
  @behaviour Tesla.Middleware

  @moduledoc """
  Config and setup http request

  ### Example usage
  ```
  defmodule MyClient do
    use Tesla

    ExAliyunOts.Http.Middleware, instance: instance, uri: uri, request_body: request_body, decoder: decoder
  end
  ```

  ### Required
  - `:instance` - ots instance
  - `:uri` - ots request uri
  - `:request_body` - the body of post request
  - `:decoder` - the corrresonding decoder to response

  ### Option
  - `:deserialize_row` - need to deserialize row from response
  - `:require_response_size` - return byte size of response body
  """

  alias ExAliyunOts.{PlainBuffer, Protocol, Error}

  alias ExAliyunOts.TableStore.Error, as: ProtoError
  alias ExAliyunOts.Const.ErrorType

  require ErrorType

  def call(env, next, options) do
    instance = Keyword.get(options, :instance)
    uri = Keyword.get(options, :uri)
    request_body = Keyword.get(options, :request_body)
    decoder = Keyword.get(options, :decoder)
    require_deserialize_row = Keyword.get(options, :deserialize_row, false)
    require_response_size = Keyword.get(options, :require_response_size, false)

    env
    |> prepare_request(instance, uri, request_body)
    |> Tesla.run(next)
    |> decode_response(decoder, require_deserialize_row, require_response_size)
  end

  defp prepare_request(env, instance, uri, request_body) do
    headers = Protocol.add_x_ots_to_headers(instance, uri, request_body)

    env
    |> Tesla.put_headers(headers)
    |> Map.put(:url, instance.endpoint <> uri)
    |> Map.put(:body, request_body)
  end

  defp decode_response({:ok, response}, nil, _require_deserialize_row, _require_response_size) do
    if response.status == 200 do
      :ok
    else
      decode_error_response(response)
    end
  end

  defp decode_response({:ok, response}, decoder, require_deserialize_row, require_response_size) do
    if response.status == 200 do
      decode_success_response(response, decoder, require_deserialize_row, require_response_size)
    else
      decode_error_response(response)
    end
  end

  defp decode_response(
         {:error, reason},
         _decoder,
         _require_deserialize_row,
         _require_response_size
       ) do
    {:error, reason}
  end

  defp decode_success_response(
         response,
         decoder,
         true = _require_deserialize_row,
         true = _require_response_size
       ) do
    body = response.body
    readable_result = make_response_row_readable(decoder.(body))
    {:ok, readable_result, byte_size(body)}
  end

  defp decode_success_response(
         response,
         decoder,
         false = _require_deserialize_row,
         true = _require_response_size
       ) do
    body = response.body
    readable_result = decoder.(body)
    {:ok, readable_result, byte_size(body)}
  end

  defp decode_success_response(
         response,
         decoder,
         true = _require_deserialize_row,
         false = _require_response_size
       ) do
    readable_result = make_response_row_readable(decoder.(response.body))
    {:ok, readable_result}
  end

  defp decode_success_response(
         response,
         decoder,
         false = _require_deserialize_row,
         false = _require_response_size
       ) do
    readable_result = decoder.(response.body)
    {:ok, readable_result}
  end

  defp decode_error_response(response) do
    {:error, response_error(response)}
  end

  defp make_response_row_readable(decoded) do
    bytes_row = decoded.row

    if bytes_row != nil do
      readable_row = PlainBuffer.deserialize_row(bytes_row)
      Map.put(decoded, :row, readable_row)
    else
      decoded
    end
  end

  defp response_error(response) do
    tracking =
      Enum.reduce(response.headers, %{request_id: nil, datetime: nil}, &grep_header_tracking/2)

    status_code = response.status

    response_body = response.body

    try do
      proto_err = ProtoError.decode(response_body)

      %Error{
        code: proto_err.code,
        message: proto_err.message,
        request_id: tracking.request_id,
        datetime: tracking.datetime,
        http_status_code: status_code
      }
    rescue
      _error ->
        error_msg = Protocol.bin_to_printable(response_body)

        code =
          if status_code >= 500 and status_code < 600 do
            ErrorType.server_unavailable()
          else
            ErrorType.ots_client_unknown()
          end

        %Error{
          code: code,
          message: error_msg,
          request_id: tracking.request_id,
          datetime: tracking.datetime,
          http_status_code: status_code
        }
    end
  end

  defp grep_header_tracking({"x-ots-requestid", value}, acc) do
    Map.put(acc, :request_id, value)
  end

  defp grep_header_tracking({"x-ots-date", value}, acc) do
    Map.put(acc, :datetime, value)
  end

  defp grep_header_tracking(_, acc) do
    acc
  end
end

defmodule ExAliyunOts.Http do
  import ExAliyunOts.Logger, only: [error: 1]

  alias ExAliyunOts.Error
  alias ExAliyunOts.Const.ErrorType

  require ErrorType

  def client(instance, "/PutRow", request_body, decoder) do
    Tesla.client(
      default_middleware() ++
        [
          {ExAliyunOts.Http.Middleware,
           instance: instance,
           uri: "/PutRow",
           request_body: request_body,
           decoder: decoder,
           deserialize_row: true}
        ]
    )
  end

  def client(instance, "/GetRow", request_body, decoder) do
    Tesla.client(
      default_middleware() ++
        [
          {ExAliyunOts.Http.Middleware,
           instance: instance,
           uri: "/GetRow",
           request_body: request_body,
           decoder: decoder,
           deserialize_row: true}
        ]
    )
  end

  def client(instance, "/UpdateRow", request_body, decoder) do
    Tesla.client(
      default_middleware() ++
        [
          {ExAliyunOts.Http.Middleware,
           instance: instance,
           uri: "/UpdateRow",
           request_body: request_body,
           decoder: decoder,
           deserialize_row: true}
        ]
    )
  end

  def client(instance, "/tunnel/readrecords" = uri, request_body, decoder) do
    Tesla.client(
      default_middleware() ++
        [
          {ExAliyunOts.Http.Middleware,
           instance: instance,
           uri: uri,
           request_body: request_body,
           decoder: decoder,
           require_response_size: true}
        ]
    )
  end

  def client(instance, uri, request_body, decoder) do
    Tesla.client(
      default_middleware() ++
        [
          {ExAliyunOts.Http.Middleware,
           instance: instance, uri: uri, request_body: request_body, decoder: decoder}
        ]
    )
  end

  defp default_middleware() do
    [
      {Tesla.Middleware.Retry, delay: 500, max_retries: 10, should_retry: &match_should_retry?/1}
    ]
  end

  def post(client) do
    Tesla.post(client, "/", nil)
  end

  defp match_should_retry?({:error, %Error{code: ErrorType.row_operation_conflict()}}) do
    true
  end

  defp match_should_retry?({:error, %Error{code: ErrorType.not_enough_capacity_unit()}}) do
    true
  end

  defp match_should_retry?({:error, %Error{code: ErrorType.table_not_ready()}}) do
    true
  end

  defp match_should_retry?({:error, %Error{code: ErrorType.partition_unavailable()}}) do
    true
  end

  defp match_should_retry?({:error, %Error{code: ErrorType.server_busy()}}) do
    true
  end

  defp match_should_retry?({:error, %Error{code: ErrorType.storage_server_busy()}}) do
    true
  end

  defp match_should_retry?(
         {:error,
          %Error{code: ErrorType.quota_exhausted(), message: "Too frequent table operations."}}
       ) do
    true
  end

  defp match_should_retry?({:error, %Error{code: ErrorType.storage_timeout()}}) do
    true
  end

  defp match_should_retry?({:error, %Error{code: ErrorType.server_unavailable()}}) do
    true
  end

  defp match_should_retry?({:error, %Error{code: ErrorType.internal_server_error()}}) do
    true
  end

  defp match_should_retry?(
         {:error, %Error{code: ErrorType.too_frequent_reserved_throughput_adjustment()}}
       ) do
    true
  end

  defp match_should_retry?({:error, %Error{} = error}) do
    error(fn ->
      [
        "** ExAliyunOts occur an error: ",
        inspect(error)
      ]
    end)

    false
  end

  defp match_should_retry?({:error, reason}) do
    error(fn ->
      [
        "** ExAliyunOts occur an error with reason: ",
        inspect(reason),
        ", will retry it."
      ]
    end)

    true
  end

  defp match_should_retry?({:ok, _}) do
    false
  end

  defp match_should_retry?({:ok, _, _}) do
    # for tunnel/readrecords
    false
  end

  defp match_should_retry?(:ok) do
    false
  end
end
