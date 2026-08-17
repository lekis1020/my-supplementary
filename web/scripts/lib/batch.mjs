/**
 * Shared batching helper — extracted from 6 identical copies in import_kr_*.mjs.
 */
export function chunk(array, size) {
  if (!Number.isInteger(size) || size <= 0) {
    throw new RangeError(`chunk size must be a positive integer, got ${size}`);
  }
  const output = [];
  for (let index = 0; index < array.length; index += size) {
    output.push(array.slice(index, index + size));
  }
  return output;
}
