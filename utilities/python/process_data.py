def process_data(data):
  """
  Process the input data and return the processed data.

  Args:
    data: The input data to be processed.

  Returns:
    The processed data.
  """
  # Check if the input data is valid.
  if not isinstance(data, list):
    raise ValueError("Input data must be a list.")

  # Process the data.
  processed_data = [item * 2 for item in data]

  # Return the processed data.
  return processed_data


if __name__ == "__main__":
  # Example usage
  data = [1, 2, 3, 4, 5]
  processed_data = process_data(data)
  print(f"Original data: {data}")
  print(f"Processed data: {processed_data}")