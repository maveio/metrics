// (c) nanoid.js
export function uuid() {
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  return crypto
  .getRandomValues(new Uint8Array(21))
  .reduce(
    (t, e) =>
      (t +=
        (e &= 63) < 36
          ? e.toString(36)
          : e < 62
          ? (e - 26).toString(36).toUpperCase()
          : e < 63
          ? "_"
          : "-"),
    ""
  );
}
